// lib/core/infrastructure/services/favorites/screens/favorites_screen.dart
// شاشة عرض المفضلات الموحدة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../../app/themes/app_theme.dart';
import '../../../../../app/themes/widgets/states/app_empty_state.dart';
import '../../../../../app/themes/widgets/core/app_loading.dart';
import '../../../../../app/themes/widgets/layout/app_bar.dart';
import '../../../../../app/di/service_locator.dart';
import '../favorites_service.dart';
import '../models/favorite_models.dart';
import '../widgets/favorite_item_card.dart';

/// شاشة المفضلات الموحدة
class UnifiedFavoritesScreen extends StatefulWidget {
  final FavoriteContentType? initialType;

  const UnifiedFavoritesScreen({
    super.key,
    this.initialType,
  });

  @override
  State<UnifiedFavoritesScreen> createState() => _UnifiedFavoritesScreenState();
}

class _UnifiedFavoritesScreenState extends State<UnifiedFavoritesScreen> 
    with SingleTickerProviderStateMixin {
  
  late final FavoritesService _service;
  late TabController _tabController;
  
  bool _isLoading = true;
  List<FavoriteItem> _currentFavorites = [];
  FavoritesStatistics? _statistics;

  @override
  void initState() {
    super.initState();
    _service = getIt<FavoritesService>();
    
    // تهيئة TabController - بدون تاب "الكل"
    _tabController = TabController(
      length: FavoriteContentType.values.length,
      vsync: this,
    );
    
    // تعيين التاب الافتراضي
    if (widget.initialType != null) {
      final index = FavoriteContentType.values.indexOf(widget.initialType!);
      _tabController.index = index;
    }
    
    _tabController.addListener(_onTabChanged);
    
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // تحميل الإحصائيات
      final stats = await _service.getStatistics();
      
      // تحميل المفضلات حسب التاب المختار (بدون "الكل")
      final type = FavoriteContentType.values[_tabController.index];
      final favorites = await _service.getFavoritesByType(type);

      if (mounted) {
        setState(() {
          _statistics = stats;
          _currentFavorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل المفضلات: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  Future<void> _toggleFavorite(FavoriteItem item) async {
    final success = await _service.removeFavorite(item.id);
    
    if (success) {
      HapticFeedback.lightImpact();
      
      // إعادة تحميل البيانات
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت الإزالة من المفضلة'),
            backgroundColor: ThemeConstants.success,
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: () async {
                await _service.addFavorite(item);
                _loadData();
              },
            ),
          ),
        );
      }
    }
  }

  void _clearAllFavorites() async {
    HapticFeedback.lightImpact();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('مسح جميع المفضلات'),
        content: Text('هل أنت متأكد من حذف جميع المفضلات؟\nهذا الإجراء لا يمكن التراجع عنه.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.error,
            ),
            child: Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.clearAllFavorites();
      _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف جميع المفضلات'),
            backgroundColor: ThemeConstants.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _service,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.backgroundColor,
            context.backgroundColor.withValues(alpha: 0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // زر الرجوع
              AppBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              
              SizedBox(width: 8.w),
              
              // أيقونة المفضلة مع تأثير جميل
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeConstants.accent,
                      ThemeConstants.accentLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.accent.withValues(alpha: 0.4),
                      blurRadius: 8.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              
              SizedBox(width: 10.w),
              
              // العنوان
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المفضلة',
                      style: context.titleLarge?.copyWith(
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                        fontSize: 18.sp,
                      ),
                    ),
                    if (_statistics != null && _statistics!.totalCount > 0)
                      Text(
                        '${_statistics!.totalCount} عنصر مفضل',
                        style: context.bodySmall?.copyWith(
                          color: context.textSecondaryColor,
                          fontSize: 11.sp,
                        ),
                      ),
                  ],
                ),
              ),
              
              // زر مسح الكل
              if (_statistics != null && _statistics!.totalCount > 0)
                _buildActionButton(
                  icon: Icons.delete_sweep_rounded,
                  color: ThemeConstants.error,
                  tooltip: 'مسح الكل',
                  onTap: _clearAllFavorites,
                ),
            ],
          ),
          
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 4.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12.r),
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 22.sp,
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.15),
            width: 1.w,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: ThemeConstants.accent,
        unselectedLabelColor: context.textSecondaryColor,
        indicatorColor: ThemeConstants.accent,
        indicatorWeight: 3.h,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: ThemeConstants.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: ThemeConstants.medium,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        indicatorPadding: EdgeInsets.symmetric(horizontal: 8.w),
        labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: FavoriteContentType.values.asMap().entries.map((entry) {
          final index = entry.key;
          final type = entry.value;
          final count = _statistics?.getCountForType(type) ?? 0;
          return Tab(
            height: 50.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: _tabController.index == index
                  ? BoxDecoration(
                      color: ThemeConstants.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type.icon, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(type.displayName),
                  if (count > 0) ...[
                    SizedBox(width: 6.w),
                    _buildTabBadge(count, index),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBadge(int count, int tabIndex) {
    final isActive = _tabController.index == tabIndex;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 7.w,
        vertical: 3.h,
      ),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  ThemeConstants.accent,
                  ThemeConstants.accentLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : ThemeConstants.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: ThemeConstants.accent.withValues(alpha: 0.3),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ]
            : null,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: ThemeConstants.bold,
          color: isActive ? Colors.white : ThemeConstants.accent,
        ),
      ),
    );
  }



  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: AppLoading.page(
          message: 'جاري تحميل المفضلة...',
        ),
      );
    }

    if (_currentFavorites.isEmpty) {
      return AppEmptyState.custom(
        title: 'لا توجد مفضلات',
        message: 'لم تقم بإضافة أي عناصر للمفضلة بعد.\nابدأ بإضافة الأدعية، الأذكار، أو أسماء الله المفضلة لديك.',
        icon: Icons.bookmark_border_rounded,
        iconColor: ThemeConstants.accent,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: ThemeConstants.accent,
      backgroundColor: context.cardColor,
      child: ListView.builder(
        padding: EdgeInsets.all(14.w),
        physics: AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: _currentFavorites.length,
        itemBuilder: (context, index) {
          final item = _currentFavorites[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: FavoriteItemCard(
                item: item,
                onTap: () {
                  // فتح تفاصيل العنصر
                  _openItemDetails(item);
                },
                onToggleFavorite: () => _toggleFavorite(item),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openItemDetails(FavoriteItem item) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailSheet(item),
    );
  }

  Widget _buildDetailSheet(FavoriteItem item) {
    final typeColor = _getTypeColor(item.contentType);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // المقبض
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 45.w,
              height: 5.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.dividerColor.withValues(alpha: 0.4),
                    context.dividerColor.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            
            // الرأس
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.dividerColor.withValues(alpha: 0.1),
                    width: 1.w,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          typeColor,
                          typeColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: typeColor.withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      item.contentType.icon,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.contentType.displayName,
                          style: context.bodySmall?.copyWith(
                            color: typeColor,
                            fontSize: 12.sp,
                            fontWeight: ThemeConstants.semiBold,
                          ),
                        ),
                        Text(
                          item.title,
                          style: context.titleMedium?.copyWith(
                            fontWeight: ThemeConstants.bold,
                            fontSize: 16.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.textSecondaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // المحتوى
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // المحتوى الرئيسي
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            typeColor.withValues(alpha: 0.06),
                            typeColor.withValues(alpha: 0.03),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.12),
                          width: 1.w,
                        ),
                      ),
                      child: Text(
                        item.content,
                        style: context.bodyLarge?.copyWith(
                          color: context.textPrimaryColor,
                          fontSize: 16.sp,
                          height: 2.0,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    
                    // الترجمة/الوصف
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: context.isDarkMode 
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: context.dividerColor.withValues(alpha: 0.1),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.translate_rounded,
                              size: 18.sp,
                              color: context.textSecondaryColor,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                item.subtitle!,
                                style: context.bodyMedium?.copyWith(
                                  color: context.textSecondaryColor,
                                  fontSize: 14.sp,
                                  height: 1.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // المصدر والمرجع
                    if (item.source != null || item.reference != null) ...[
                      SizedBox(height: 16.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 18.sp,
                              color: typeColor,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                '${item.source}${item.reference != null ? ' - ${item.reference}' : ''}',
                                style: context.bodyMedium?.copyWith(
                                  color: typeColor,
                                  fontSize: 13.sp,
                                  fontWeight: ThemeConstants.medium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(FavoriteContentType type) {
    switch (type) {
      case FavoriteContentType.dua:
        return ThemeConstants.primary;
      case FavoriteContentType.athkar:
        return ThemeConstants.accent;
      case FavoriteContentType.asmaAllah:
        return ThemeConstants.tertiary;
    }
  }
}
