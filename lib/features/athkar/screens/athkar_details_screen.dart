// lib/features/athkar/screens/athkar_details_screen.dart
import 'package:athkar_app/core/infrastructure/services/share/share_extensions.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/models/favorite_models.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/extensions/favorites_extensions.dart';
import 'package:athkar_app/core/infrastructure/services/text_settings/extensions/text_settings_extensions.dart';
import 'package:athkar_app/core/infrastructure/services/text_settings/models/text_settings_models.dart';
import 'package:athkar_app/features/athkar/utils/athkar_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/utils/extensions/string_extensions.dart';
import '../services/athkar_service.dart';
import '../models/athkar_model.dart';
import '../widgets/athkar_item_card.dart';
import '../utils/category_utils.dart';
import 'notification_settings_screen.dart';

class AthkarDetailsScreen extends StatefulWidget {
  final String categoryId;
  
  AthkarDetailsScreen({
    super.key,
    String? categoryId,
  }) : categoryId = categoryId ?? '';

  @override
  State<AthkarDetailsScreen> createState() => _AthkarDetailsScreenState();
}

class _AthkarDetailsScreenState extends State<AthkarDetailsScreen> {
  late final AthkarService _service;
  late final StorageService _storage;
  
  AthkarCategory? _category;
  final Map<int, int> _counts = {};
  final Set<int> _completedItems = {};
  final Map<String, bool> _favoriteStates = {}; // حالات المفضلة
  List<AthkarItem> _visibleItems = [];
  bool _loading = true;
  bool _allCompleted = false;
  bool _wasCompletedOnLoad = false;
  bool _dialogShown = false; // علم لتجنب عرض الحوار مرتين
  
  // إعدادات النص الموحدة
  TextSettings? _textSettings;
  DisplaySettings? _displaySettings;

  @override
  void initState() {
    super.initState();
    _service = getIt<AthkarService>();
    _storage = getIt<StorageService>();
    _load();
  }

  @override
  void dispose() {
    if (_allCompleted && !_wasCompletedOnLoad) {
      _resetAllSilently();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cat = await _service.getCategoryById(widget.categoryId);
      if (!mounted) return;
      
      final savedProgress = _loadSavedProgress();
      
      // تحميل الإعدادات الموحدة للأذكار
      await _loadTextSettings();
      await _loadFavoriteStates();
      
      bool wasAlreadyCompleted = false;
      if (cat != null) {
        int totalRequired = 0;
        int totalCompleted = 0;
        
        for (var item in cat.athkar) {
          totalRequired += item.count;
          final completed = savedProgress[item.id] ?? 0;
          totalCompleted += completed.clamp(0, item.count);
        }
        
        wasAlreadyCompleted = totalCompleted >= totalRequired && totalRequired > 0;
      }
      
      setState(() {
        _category = cat;
        _wasCompletedOnLoad = wasAlreadyCompleted;
        
        if (cat != null) {
          for (var i = 0; i < cat.athkar.length; i++) {
            final item = cat.athkar[i];
            _counts[item.id] = savedProgress[item.id] ?? 0;
            if (_counts[item.id]! >= item.count) {
              _completedItems.add(item.id);
            }
          }
          _updateVisibleItems();
          _checkCompletion();
        }
        _loading = false;
      });
      
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('حدث خطأ في تحميل الأذكار'),
          backgroundColor: ThemeConstants.error,
        ),
      );
    }
  }

  Future<void> _loadTextSettings() async {
    // تحميل الإعدادات الموحدة من TextSettingsService
    _textSettings = await context.getTextSettings(ContentType.athkar);
    _displaySettings = await context.getDisplaySettings(ContentType.athkar);
  }

  /// تحميل حالات المفضلة لجميع الأذكار
  Future<void> _loadFavoriteStates() async {
    if (_category == null) return;
    
    try {
      for (final item in _category!.athkar) {
        final isFavorite = await _service.isFavorite(item.id.toString());
        _favoriteStates[item.id.toString()] = isFavorite;
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // في حالة الخطأ، نتجاهل ونواصل
    }
  }

  /// تبديل حالة المفضلة لذكر معين
  Future<void> _toggleFavorite(AthkarItem item) async {
    try {
      HapticFeedback.lightImpact();
      
      final wasAdded = await _service.toggleFavorite(
        athkarId: item.id.toString(),
        text: item.text,
        fadl: item.fadl,
        source: _category?.title,
        categoryId: _category?.id,
        count: item.count,
      );
      
      setState(() {
        _favoriteStates[item.id.toString()] = wasAdded;
      });
      
      // إظهار رسالة تأكيد
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasAdded ? 'تمت إضافة الذكر للمفضلة' : 'تمت إزالة الذكر من المفضلة',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحديث المفضلة'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _updateVisibleItems() {
    if (_category == null) return;
    
    _visibleItems = _category!.athkar
        .where((item) => !_completedItems.contains(item.id))
        .toList();
  }

  Map<int, int> _loadSavedProgress() {
    final key = 'athkar_progress_${widget.categoryId}';
    final data = _storage.getMap(key);
    if (data == null) return {};
    
    return data.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> _saveProgress() async {
    final key = 'athkar_progress_${widget.categoryId}';
    final data = _counts.map((k, v) => MapEntry(k.toString(), v));
    await _storage.setMap(key, data);
  }

  void _checkCompletion() {
    if (_category == null) return;
    
    int completed = 0;
    int total = 0;
    
    for (final item in _category!.athkar) {
      final count = _counts[item.id] ?? 0;
      completed += count.clamp(0, item.count);
      total += item.count;
    }
    
    final wasCompleted = _allCompleted;
    final isNowCompleted = completed >= total && total > 0;
    
    setState(() {
      _allCompleted = isNowCompleted;
    });
    
    // عرض حوار الإكمال عندما يكمل المستخدم لأول مرة
    if (!wasCompleted && isNowCompleted && !_dialogShown && !_wasCompletedOnLoad) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCompletionDialog();
        }
      });
    }
  }

  void _onItemTap(AthkarItem item) {
    if (_displaySettings?.enableVibration ?? true) {
      HapticFeedback.lightImpact();
    }
    
    setState(() {
      final currentCount = _counts[item.id] ?? 0;
      if (currentCount < item.count) {
        _counts[item.id] = currentCount + 1;
        
        if (_counts[item.id]! >= item.count) {
          _completedItems.add(item.id);
          if (_displaySettings?.enableVibration ?? true) {
            HapticFeedback.mediumImpact();
          }
          _updateVisibleItems();
        }
      }
      _checkCompletion();
    });
    
    _saveProgress();
  }

  void _onItemLongPress(AthkarItem item) {
    if (_displaySettings?.enableVibration ?? true) {
      HapticFeedback.mediumImpact();
    }
    
    setState(() {
      _counts[item.id] = 0;
      _completedItems.remove(item.id);
      _updateVisibleItems();
      _checkCompletion();
    });
    
    _saveProgress();
    context.showAthkarInfoSnackBar('تم إعادة تعيين العداد');
  }

  Future<void> _shareProgress() async {
    final completedTexts = _category!.athkar
        .where((item) => _completedItems.contains(item.id))
        .map((item) => item.text.truncate(50))
        .toList();
    
    await context.shareService.shareAthkarProgress(
      _category!.title,
      completedTexts,
    );
  }

  void _resetAll() {
    setState(() {
      _counts.clear();
      _completedItems.clear();
      _allCompleted = false;
      _wasCompletedOnLoad = false;
      _dialogShown = false;
      _updateVisibleItems();
    });
    _saveProgress();
    
    // إظهار رسالة تأكيد
    context.showAthkarInfoSnackBar('تم إعادة تعيين جميع الأذكار');
  }

  Future<void> _resetAllSilently() async {
    _counts.clear();
    _completedItems.clear();
    final key = 'athkar_progress_${widget.categoryId}';
    await _storage.remove(key);
  }

  Future<void> _shareItem(AthkarItem item) async {
    await context.shareAthkar(
      item.text,
      fadl: item.fadl,
      source: item.source,
      categoryTitle: _category!.title,
    );
  }

  /// عرض حوار الإكمال
  void _showCompletionDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400.w,
          ),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: ThemeConstants.success.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: ThemeConstants.success.withOpacity(0.3),
                blurRadius: 24.r,
                offset: Offset(0, 8.h),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أيقونة النجاح
                  Container(
                    width: 100.r,
                    height: 100.r,
                    decoration: BoxDecoration(
                      color: ThemeConstants.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ThemeConstants.success.withOpacity(0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeConstants.success.withOpacity(0.2),
                          blurRadius: 20.r,
                          offset: Offset(0, 8.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 60.sp,
                      color: ThemeConstants.success,
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // العنوان
                  Text(
                    'بارك الله فيك',
                    style: TextStyle(
                      color: ThemeConstants.success,
                      fontWeight: ThemeConstants.bold,
                      fontSize: 22.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // النص
                  Text(
                    'أتممت جميع أذكار ${_category?.title ?? 'هذه الفئة'}',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 16.sp,
                      fontWeight: ThemeConstants.medium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 8.h),
                                    
                  SizedBox(height: 28.h),
                  
                  // الأزرار
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton.success(
                        text: 'البدء من جديد',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          Navigator.pop(context);
                          _resetAll();
                        },
                        isFullWidth: true,
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      AppButton.outline(
                        text: 'مشاركة',
                        icon: Icons.share_rounded,
                        onPressed: () {
                          Navigator.pop(context);
                          _shareProgress();
                        },
                        color: ThemeConstants.success,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // زر الإغلاق
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text(
                      'إغلاق',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context, 'جاري تحميل الأذكار...'),
              Expanded(
                child: Center(
                  child: AppLoading.page(
                    message: 'جاري تحميل الأذكار...',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_category == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context, 'الأذكار'),
              Expanded(
                child: AppEmptyState.error(
                  message: 'تعذر تحميل الأذكار المطلوبة',
                  onRetry: _load,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final category = _category!;
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context, category.title, category: category),
            Expanded(
              child: _buildContent(category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, String title, {AthkarCategory? category}) {
    const gradient = LinearGradient(
      colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 8.w),
          
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withValues(alpha: 0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              category?.icon ?? Icons.menu_book,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          
          SizedBox(width: 8.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 16.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category != null)
                  Text(
                    '${category.athkar.length} ذكر - ${_completedItems.length} مكتمل',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11.sp,
                    ),
                  )
                else
                  Text(
                    'الأذكار والأدعية',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11.sp,
                    ),
                  ),
              ],
            ),
          ),
          
          if (category != null) ...[
            // زر إعادة التعيين
            if (_completedItems.isNotEmpty)
              _buildActionButton(
                icon: Icons.restart_alt_rounded,
                color: ThemeConstants.warning,
                onTap: () async {
                  final shouldReset = await _showResetConfirmationDialog();
                  if (shouldReset == true) {
                    _resetAll();
                  }
                },
              ),
            
            // زر إعدادات النص
            _buildActionButton(
              icon: Icons.text_fields_rounded,
              color: ThemeConstants.info,
              onTap: () async {
                if (_displaySettings?.enableVibration ?? true) {
                  HapticFeedback.lightImpact();
                }
                await context.showGlobalTextSettings(
                  initialContentType: ContentType.athkar,
                );
                await _loadTextSettings();
                setState(() {});
              },
            ),
            
            // زر المفضلة
            _buildActionButton(
              icon: Icons.bookmark_rounded,
              color: context.textSecondaryColor,
              onTap: () {
                HapticFeedback.lightImpact();
                context.openFavoritesScreen(FavoriteContentType.athkar);
              },
            ),
            
            // زر الإشعارات
            _buildActionButton(
              icon: Icons.notifications_outlined,
              color: context.textSecondaryColor,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AthkarNotificationSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 2.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: context.dividerColor.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.06),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDarkMode ? 0.08 : 0.03),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }

  /// عرض حوار تأكيد إعادة التعيين
  Future<bool?> _showResetConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        backgroundColor: context.cardColor,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: ThemeConstants.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: ThemeConstants.warning.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.restart_alt_rounded,
                color: ThemeConstants.warning,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'إعادة التعيين',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: ThemeConstants.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'هل تريد إعادة تعيين تقدمك في هذه الأذكار؟\nسيتم حذف جميع العدادات والبدء من جديد.',
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.6,
            color: context.textSecondaryColor,
          ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 14.sp,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.warning,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              elevation: 0,
            ),
            child: Text(
              'إعادة تعيين',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AthkarCategory category) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.all(14.r),
        itemCount: _visibleItems.length,
        itemBuilder: (context, index) {
          final item = _visibleItems[index];
          final currentCount = _counts[item.id] ?? 0;
          final isCompleted = _completedItems.contains(item.id);
          
          final originalIndex = category.athkar.indexOf(item);
          final number = originalIndex + 1;
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _visibleItems.length - 1 ? 12.h : 0,
            ),
            child: AthkarItemCard(
              item: item,
              currentCount: currentCount,
              isCompleted: isCompleted,
              number: number,
              color: CategoryUtils.getCategoryThemeColor(category.id),
              textSettings: _textSettings,
              displaySettings: _displaySettings,
              onTap: () => _onItemTap(item),
              onLongPress: () => _onItemLongPress(item),
              onShare: () => _shareItem(item),
              onFavorite: () => _toggleFavorite(item),
              isFavorite: _favoriteStates[item.id.toString()] ?? false,
            ),
          );
        },
      ),
    );
  }
}