// lib/features/home/widgets/category_grid.dart - محسّن للشاشات الصغيرة

import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryGrid extends StatefulWidget {
  const CategoryGrid({super.key});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  final Map<String, LinearGradient> _gradientCache = {};

  LinearGradient _getGradient(String categoryId, bool isInDevelopment) {
    final cacheKey = isInDevelopment ? 'dev_mode' : categoryId;
    
    if (_gradientCache.containsKey(cacheKey)) {
      return _gradientCache[cacheKey]!;
    }
    
    final gradient = isInDevelopment 
        ? _getDevelopmentGradient() 
        : AppColors.getCategoryGradient(categoryId);
    
    _gradientCache[cacheKey] = gradient;
    return gradient;
  }

  static const List<CategoryItem> _categories = [
    CategoryItem(
      id: 'prayer_times',
      title: 'مواقيت الصلاة',
      icon: Icons.mosque,
      routeName: '/prayer-times',
      isInDevelopment: false,
    ),
    CategoryItem(
      id: 'athkar',
      title: 'الأذكار اليومية',
      icon: Icons.menu_book_rounded,
      routeName: '/athkar',
      isInDevelopment: false,
    ),
    CategoryItem(
      id: 'asma_allah',  
      title: 'أسماء الله الحسنى',  
      icon: Icons.star_purple500_outlined,  
      routeName: '/asma-allah',
      isInDevelopment: false,
    ),
    CategoryItem(
      id: 'qibla',
      title: 'اتجاه القبلة',
      icon: Icons.explore,
      routeName: '/qibla',
      isInDevelopment: false,
    ),
    CategoryItem(
      id: 'tasbih',
      title: 'المسبحة الرقمية',
      icon: Icons.radio_button_checked,
      routeName: '/tasbih',
      isInDevelopment: false,
    ),
    CategoryItem(
      id: 'dua',
      title: 'الأدعية المأثورة',
      icon: Icons.pan_tool_rounded,
      routeName: '/dua',
      isInDevelopment: false,
    ),
  ];

  void _onCategoryTap(CategoryItem category) {
    HapticFeedback.lightImpact();
    
    if (category.isInDevelopment) {
      _showDevelopmentDialog(category);
      return;
    }
    
    if (category.routeName != null) {
      Navigator.pushNamed(context, category.routeName!).catchError((error) {
        if (mounted) {
          context.showWarningSnackBar('هذه الميزة قيد التطوير');
        }
        return null;
      });
    }
  }

  void _showDevelopmentDialog(CategoryItem category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        contentPadding: EdgeInsets.all(16.r),
        title: Row(
          children: [
            Icon(
              Icons.construction,
              color: ThemeConstants.warning,
              size: 26.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                category.title,
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: ThemeConstants.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: ThemeConstants.warning.withValues(alpha: 0.3),
                  width: 1.w,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ThemeConstants.warning,
                    size: 20.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'هذه الميزة معطلة مؤقتاً للصيانة',
                      style: TextStyle(
                        color: ThemeConstants.warning.darken(0.2),
                        fontWeight: ThemeConstants.medium,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'نعمل حالياً على تطوير وتحسين هذه الخدمة لتقديم أفضل تجربة ممكنة.',
              style: TextStyle(fontSize: 13.sp),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: context.primaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'ستكون متوفرة قريباً بإذن الله',
                      style: TextStyle(
                        color: context.primaryColor,
                        fontWeight: ThemeConstants.semiBold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً', style: TextStyle(fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildRow([_categories[0], _categories[1]]),
          
          SizedBox(height: 12.h),
          
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildWideCard(context, _categories[2]),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: _buildStandardCard(context, _categories[3]),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          _buildRow([_categories[4], _categories[5]]),
        ]),
      ),
    );
  }

  Widget _buildRow(List<CategoryItem> categories) {
    return Row(
      children: [
        Expanded(
          child: _buildStandardCard(context, categories[0]),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStandardCard(context, categories[1]),
        ),
      ],
    );
  }

  Widget _buildStandardCard(BuildContext context, CategoryItem category) {
    final gradient = _getGradient(category.id, category.isInDevelopment);
    
    return RepaintBoundary(
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors[0].withValues(alpha: 0.25),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            onTap: () => _onCategoryTap(category),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.w,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5.w,
                          ),
                        ),
                        child: Icon(
                          category.isInDevelopment ? Icons.construction : category.icon,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                      
                      SizedBox(height: 10.h),
                      
                      Text(
                        category.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 13.sp,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: Offset(0, 1.h),
                              blurRadius: 2.r,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  
                  if (category.isInDevelopment)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeConstants.warning,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeConstants.warning.withValues(alpha: 0.4),
                              blurRadius: 3.r,
                              offset: Offset(0, 1.5.h),
                            ),
                          ],
                        ),
                        child: Text(
                          'قيد التطوير',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: ThemeConstants.bold,
                            fontSize: 8.sp,
                          ),
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

  Widget _buildWideCard(BuildContext context, CategoryItem category) {
    final gradient = _getGradient(category.id, category.isInDevelopment);
    
    return RepaintBoundary(
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors[0].withValues(alpha: 0.25),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            onTap: () => _onCategoryTap(category),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.w,
                ),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5.w,
                          ),
                        ),
                        child: Icon(
                          category.isInDevelopment ? Icons.construction : category.icon,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                      
                      SizedBox(width: 12.w),
                      
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: ThemeConstants.bold,
                                fontSize: 14.sp,
                                height: 1.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    offset: Offset(0, 1.h),
                                    blurRadius: 2.r,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (category.isInDevelopment)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeConstants.warning,
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeConstants.warning.withValues(alpha: 0.4),
                              blurRadius: 3.r,
                              offset: Offset(0, 1.5.h),
                            ),
                          ],
                        ),
                        child: Text(
                          'قيد التطوير',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: ThemeConstants.bold,
                            fontSize: 8.sp,
                          ),
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

  LinearGradient _getDevelopmentGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        ThemeConstants.warning.withValues(alpha: 0.9),
        ThemeConstants.warning.darken(0.2).withValues(alpha: 0.9),
      ],
    );
  }

  @override
  void dispose() {
    _gradientCache.clear();
    super.dispose();
  }
}

class CategoryItem {
  final String id;
  final String title;
  final IconData icon;
  final String? routeName;
  final bool isInDevelopment;

  const CategoryItem({
    required this.id,
    required this.title,
    required this.icon,
    this.routeName,
    this.isInDevelopment = false,
  });
}