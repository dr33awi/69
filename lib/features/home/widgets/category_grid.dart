// lib/features/home/widgets/category_grid.dart - محسّن مع أيقونات إسلامية

import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

class CategoryGrid extends StatefulWidget {
  const CategoryGrid({super.key});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  final Map<String, LinearGradient> _gradientCache = {};

  LinearGradient _getGradient(String categoryId) {
    if (_gradientCache.containsKey(categoryId)) {
      return _gradientCache[categoryId]!;
    }
    
    final gradient = AppColors.getCategoryGradient(categoryId);
    
    _gradientCache[categoryId] = gradient;
    return gradient;
  }

  static const List<CategoryItem> _categories = [
    CategoryItem(
      id: 'prayer_times',
      title: 'مواقيت الصلاة',
      icon: FlutterIslamicIcons.solidMosque,
      routeName: '/prayer-times',
    ),
    CategoryItem(
      id: 'athkar',
      title: 'الأذكار اليومية',
      icon: Icons.menu_book_rounded,
      routeName: '/athkar',
    ),
    CategoryItem(
      id: 'asma_allah',  
      title: 'أسماء الله الحسنى',  
      icon: FlutterIslamicIcons.solidAllah,
      routeName: '/asma-allah',
    ),
    CategoryItem(
      id: 'qibla',
      title: 'اتجاه القبلة',
      icon: FlutterIslamicIcons.solidQibla,
      routeName: '/qibla',
    ),
    CategoryItem(
      id: 'tasbih',
      title: 'المسبحة الرقمية',
      icon: FlutterIslamicIcons.solidTasbihHand,
      routeName: '/tasbih',
    ),
    CategoryItem(
      id: 'dua',
      title:  'الأدعية الإسلامية',
      icon: FlutterIslamicIcons.solidPrayer,
      routeName: '/dua',
    ),
  ];

  void _onCategoryTap(CategoryItem category) {
    HapticFeedback.lightImpact();
    
    if (category.routeName != null) {
      Navigator.pushNamed(context, category.routeName!).catchError((error) {
        if (mounted) {
          context.showWarningSnackBar('حدث خطأ في فتح الصفحة');
        }
        return null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // حماية من البيانات الفارغة
    if (_categories.isEmpty || _categories.length < 6) {
      return const SliverToBoxAdapter(
        child: SizedBox.shrink(),
      );
    }
    
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            try {
              switch (index) {
                case 0:
                  return _buildRow([_categories[0], _categories[1]]);
                case 1:
                  return SizedBox(height: 12.h);
                case 2:
                  return Row(
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
                  );
                case 3:
                  return SizedBox(height: 12.h);
                case 4:
                  return _buildRow([_categories[4], _categories[5]]);
                default:
                  return null;
              }
            } catch (e) {
              // تسجيل الخطأ وإرجاع widget فارغ
              return const SizedBox.shrink();
            }
          },
          childCount: 5, // 3 صفوف + 2 spacers
        ),
      ),
    );
  }

  Widget _buildRow(List<CategoryItem> categories) {
    // حماية من null - التأكد من وجود عنصرين على الأقل
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // إذا كان هناك عنصر واحد فقط
    if (categories.length == 1) {
      return _buildStandardCard(context, categories[0]);
    }
    
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

  Widget _buildStandardCard(BuildContext context, CategoryItem? category) {
    // حماية من null
    if (category == null) {
      return const SizedBox.shrink();
    }
    
    final gradient = _getGradient(category.id);
    
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
                          category.icon,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideCard(BuildContext context, CategoryItem? category) {
    // حماية من null
    if (category == null) {
      return const SizedBox.shrink();
    }
    
    final gradient = _getGradient(category.id);
    
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
                          category.icon,
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
                ],
              ),
            ),
          ),
        ),
      ),
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

  const CategoryItem({
    required this.id,
    required this.title,
    required this.icon,
    this.routeName,
  });
}