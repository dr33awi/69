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
    
    // تهيئة TabController
    _tabController = TabController(
      length: FavoriteContentType.values.length + 1, // +1 للكل
      vsync: this,
    );
    
    // تعيين التاب الافتراضي
    if (widget.initialType != null) {
      final index = FavoriteContentType.values.indexOf(widget.initialType!) + 1;
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
      
      // تحميل المفضلات حسب التاب المختار
      List<FavoriteItem> favorites;
      if (_tabController.index == 0) {
        // الكل
        favorites = await _service.getAllFavorites();
      } else {
        // نوع معين
        final type = FavoriteContentType.values[_tabController.index - 1];
        favorites = await _service.getFavoritesByType(type);
      }

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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
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
              
              // أيقونة المفضلة
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeConstants.accent,
                      ThemeConstants.accentLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.accent.withValues(alpha: 0.3),
                      blurRadius: 6.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              
              SizedBox(width: 8.w),
              
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
                        fontSize: 17.sp,
                      ),
                    ),
                    if (_statistics != null && _statistics!.totalCount > 0)
                      Text(
                        '${_statistics!.totalCount} عنصر',
                        style: context.bodySmall?.copyWith(
                          color: context.textSecondaryColor,
                          fontSize: 10.sp,
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
      margin: EdgeInsets.only(left: 2.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: context.dividerColor.withValues(alpha: 0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 3.r,
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



  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: ThemeConstants.accent,
        unselectedLabelColor: context.textSecondaryColor,
        indicatorColor: ThemeConstants.accent,
        indicatorWeight: 3.h,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: ThemeConstants.semiBold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: ThemeConstants.regular,
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.all_inclusive_rounded, size: 18.sp),
                SizedBox(width: 4.w),
                Text('الكل'),
                if (_statistics != null && _statistics!.totalCount > 0) ...[
                  SizedBox(width: 4.w),
                  _buildTabBadge(_statistics!.totalCount),
                ],
              ],
            ),
          ),
          ...FavoriteContentType.values.map((type) {
            final count = _statistics?.getCountForType(type) ?? 0;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type.icon, size: 18.sp),
                  SizedBox(width: 4.w),
                  Text(type.displayName),
                  if (count > 0) ...[
                    SizedBox(width: 4.w),
                    _buildTabBadge(count),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTabBadge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: ThemeConstants.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: ThemeConstants.bold,
          color: ThemeConstants.accent,
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
      child: ListView.builder(
        padding: EdgeInsets.all(12.w),
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: _currentFavorites.length,
        itemBuilder: (context, index) {
          final item = _currentFavorites[index];
          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            child: FavoriteItemCard(
              item: item,
              onTap: () {
                // فتح تفاصيل العنصر
                _openItemDetails(item);
              },
              onToggleFavorite: () => _toggleFavorite(item),
            ),
          );
        },
      ),
    );
  }

  void _openItemDetails(FavoriteItem item) {
    HapticFeedback.lightImpact();
    // TODO: فتح شاشة التفاصيل حسب نوع المحتوى
    // سيتم تنفيذ هذا لاحقاً
  }
}
