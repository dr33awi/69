// lib/features/athkar/screens/athkar_details_screen.dart
import 'package:athkar_app/core/infrastructure/services/share/share_extensions.dart';
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
  List<AthkarItem> _visibleItems = [];
  bool _loading = true;
  bool _allCompleted = false;
  bool _wasCompletedOnLoad = false;
  double _fontSize = 18.0;

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
      _fontSize = await _service.getSavedFontSize();
      
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
    
    setState(() {
      _allCompleted = completed >= total && total > 0;
    });
  }

  void _onItemTap(AthkarItem item) {
    HapticFeedback.lightImpact();
    
    setState(() {
      final currentCount = _counts[item.id] ?? 0;
      if (currentCount < item.count) {
        _counts[item.id] = currentCount + 1;
        
        if (_counts[item.id]! >= item.count) {
          _completedItems.add(item.id);
          HapticFeedback.mediumImpact();
          _updateVisibleItems();
        }
      }
      _checkCompletion();
    });
    
    _saveProgress();
  }

  void _onItemLongPress(AthkarItem item) {
    HapticFeedback.mediumImpact();
    
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
      _updateVisibleItems();
    });
    _saveProgress();
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

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        contentPadding: EdgeInsets.all(16.r),
        title: Row(
          children: [
            Icon(
              Icons.text_fields_rounded,
              color: ThemeConstants.primary,
              size: 20.sp,
            ),
            SizedBox(width: 6.w),
            Text('حجم الخط', style: TextStyle(fontSize: 16.sp)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFontSizeOption('صغير', 16.0),
            _buildFontSizeOption('متوسط', 18.0),
            _buildFontSizeOption('كبير', 22.0),
            _buildFontSizeOption('كبير جداً', 26.0),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(String label, double size) {
    final isSelected = _fontSize == size;
    
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            setState(() => _fontSize = size);
            
            await _service.saveFontSize(size);
            
            if (mounted) Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: isSelected 
                  ? ThemeConstants.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isSelected 
                    ? ThemeConstants.primary.withOpacity(0.3)
                    : context.dividerColor.withOpacity(0.2),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? ThemeConstants.primary : context.textSecondaryColor,
                  size: 18.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: size.sp,
                      fontWeight: isSelected ? ThemeConstants.semiBold : ThemeConstants.regular,
                      color: isSelected ? ThemeConstants.primary : context.textPrimaryColor,
                    ),
                  ),
                ),
                Text(
                  '${size.toInt()}px',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 10.sp,
                  ),
                ),
              ],
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
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withOpacity(0.25),
                  blurRadius: 6.r,
                  offset: Offset(0, 3.h),
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
            Container(
              margin: EdgeInsets.only(left: 6.w),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showFontSizeDialog();
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: context.dividerColor.withOpacity(0.3),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 3.r,
                          offset: Offset(0, 1.5.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.text_fields_rounded,
                      color: context.textPrimaryColor,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ),
            
            Container(
              margin: EdgeInsets.only(left: 6.w),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AthkarNotificationSettingsScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: context.dividerColor.withOpacity(0.3),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 3.r,
                          offset: Offset(0, 1.5.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: context.textPrimaryColor,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(AthkarCategory category) {
    if (_visibleItems.isEmpty && _completedItems.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  color: ThemeConstants.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ThemeConstants.success.withOpacity(0.3),
                    width: 2.w,
                  ),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 50.sp,
                  color: ThemeConstants.success,
                ),
              ),
              
              SizedBox(height: 20.h),
              
              Text(
                'أحسنت! أكملت جميع الأذكار',
                style: TextStyle(
                  color: ThemeConstants.success,
                  fontWeight: ThemeConstants.bold,
                  fontSize: 18.sp,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 10.h),
              
              Text(
                'جعله الله في ميزان حسناتك',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 24.h),
              
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      text: 'مشاركة',
                      icon: Icons.share_rounded,
                      onPressed: _shareProgress,
                      color: ThemeConstants.success,
                    ),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  Expanded(
                    child: AppButton.primary(
                      text: 'البدء من جديد',
                      icon: Icons.refresh_rounded,
                      onPressed: _resetAll,
                      backgroundColor: ThemeConstants.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.all(12.r),
        itemCount: _visibleItems.length,
        itemBuilder: (context, index) {
          final item = _visibleItems[index];
          final currentCount = _counts[item.id] ?? 0;
          final isCompleted = _completedItems.contains(item.id);
          
          final originalIndex = category.athkar.indexOf(item);
          final number = originalIndex + 1;
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _visibleItems.length - 1 ? 10.h : 0,
            ),
            child: AthkarItemCard(
              item: item,
              currentCount: currentCount,
              isCompleted: isCompleted,
              number: number,
              color: CategoryUtils.getCategoryThemeColor(category.id),
              fontSize: _fontSize,
              onTap: () => _onItemTap(item),
              onLongPress: () => _onItemLongPress(item),
              onShare: () => _shareItem(item),
            ),
          );
        },
      ),
    );
  }
}