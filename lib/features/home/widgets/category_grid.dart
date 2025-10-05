// lib/features/home/widgets/category_grid.dart - محدث مع القرآن الكريم

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
      id: 'quran',
      title: 'القرآن الكريم',
      icon: Icons.book,
      routeName: '/quran',
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
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.construction,
              color: ThemeConstants.warning,
              size: 32.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              category.title,
              style: context.titleLarge?.copyWith(
                fontWeight: ThemeConstants.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: ThemeConstants.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
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
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'هذه الميزة معطلة مؤقتاً للصيانة والتطوير',
                      style: context.bodyMedium?.copyWith(
                        color: ThemeConstants.warning.darken(0.2),
                        fontWeight: ThemeConstants.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'نعمل حالياً على تطوير وتحسين هذه الخدمة لتقديم أفضل تجربة ممكنة.',
              style: context.bodyMedium,
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: context.primaryColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'ستكون متوفرة قريباً بإذن الله',
                      style: context.bodyMedium?.copyWith(
                        color: context.primaryColor,
                        fontWeight: ThemeConstants.semiBold,
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
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // الصف الأول: مواقيت الصلاة + الأذكار اليومية
          _buildRow([_categories[0], _categories[1]]),
          
          SizedBox(height: 16.h),
          
          // الصف الثاني: أسماء الله الحسنى (عريض) + القرآن الكريم
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildWideCard(context, _categories[2]), // أسماء الله
              ),
              SizedBox(width: 16.w),
              Expanded(
                flex: 2,
                child: _buildStandardCard(context, _categories[3]), // القرآن
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // الصف الثالث: اتجاه القبلة + المسبحة
          _buildRow([_categories[4], _categories[5]]),
          
          SizedBox(height: 16.h),
          
          // الصف الرابع: الأدعية (عريض)
          _buildWideCard(context, _categories[6]),
        ]),
      ),
    );
  }

  // بناء صف متساوي
  Widget _buildRow(List<CategoryItem> categories) {
    return Row(
      children: [
        Expanded(
          child: _buildStandardCard(context, categories[0]),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildStandardCard(context, categories[1]),
        ),
      ],
    );
  }

  // بطاقة قياسية
  Widget _buildStandardCard(BuildContext context, CategoryItem category) {
    final gradient = _getGradient(category.id, category.isInDevelopment);
    
    return RepaintBoundary(
      child: Container(
        height: 140.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors[0].withValues(alpha: 0.3),
              blurRadius: 12.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          child: InkWell(
            onTap: () => _onCategoryTap(category),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
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
                      // الأيقونة
                      Container(
                        width: 56.w,
                        height: 56.h,
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
                          size: 28.sp,
                        ),
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      // العنوان
                      Text(
                        category.title,
                        style: context.titleSmall?.copyWith(
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
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  
                  // شارة "قيد التطوير"
                  if (category.isInDevelopment)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeConstants.warning,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeConstants.warning.withValues(alpha: 0.4),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Text(
                          'قيد التطوير',
                          style: context.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: ThemeConstants.bold,
                            fontSize: 9.sp,
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

  // بطاقة عريضة
  Widget _buildWideCard(BuildContext context, CategoryItem category) {
    final gradient = _getGradient(category.id, category.isInDevelopment);
    
    return RepaintBoundary(
      child: Container(
        height: 140.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors[0].withValues(alpha: 0.3),
              blurRadius: 12.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          child: InkWell(
            onTap: () => _onCategoryTap(category),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.w,
                ),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      // الأيقونة
                      Container(
                        width: 56.w,
                        height: 56.h,
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
                          size: 28.sp,
                        ),
                      ),
                      
                      SizedBox(width: 14.w),
                      
                      // النص
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.title,
                              style: context.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: ThemeConstants.bold,
                                fontSize: 16.sp,
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
                  
                  // شارة "قيد التطوير"
                  if (category.isInDevelopment)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeConstants.warning,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeConstants.warning.withValues(alpha: 0.4),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Text(
                          'قيد التطوير',
                          style: context.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: ThemeConstants.bold,
                            fontSize: 9.sp,
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