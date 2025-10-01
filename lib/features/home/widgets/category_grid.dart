// lib/features/home/widgets/category_grid.dart - نسخة محسنة ومتناسقة

import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.construction,
              color: ThemeConstants.warning,
              size: ThemeConstants.iconLg,
            ),
            ThemeConstants.space3.w,
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
              padding: const EdgeInsets.all(ThemeConstants.space3),
              decoration: BoxDecoration(
                color: ThemeConstants.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                border: Border.all(
                  color: ThemeConstants.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: ThemeConstants.warning,
                    size: ThemeConstants.iconMd,
                  ),
                  ThemeConstants.space2.w,
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
            ThemeConstants.space3.h,
            Text(
              'نعمل حالياً على تطوير وتحسين هذه الخدمة لتقديم أفضل تجربة ممكنة.',
              style: context.bodyMedium,
            ),
            ThemeConstants.space3.h,
            Container(
              padding: const EdgeInsets.all(ThemeConstants.space3),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: context.primaryColor,
                    size: ThemeConstants.iconMd,
                  ),
                  ThemeConstants.space2.w,
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
      padding: const EdgeInsets.symmetric(horizontal: ThemeConstants.space4),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // الصف الأول: مواقيت الصلاة + الأذكار اليومية
          _buildRow([_categories[0], _categories[1]]),
          
          ThemeConstants.space4.h,
          
          // الصف الثاني: أسماء الله الحسنى (عريض) + اتجاه القبلة
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildWideCard(context, _categories[2]), // أسماء الله
              ),
              ThemeConstants.space4.w,
              Expanded(
                flex: 2,
                child: _buildStandardCard(context, _categories[3]), // القبلة
              ),
            ],
          ),
          
          ThemeConstants.space4.h,
          
          // الصف الثالث: المسبحة + الأدعية
          _buildRow([_categories[4], _categories[5]]),
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
        ThemeConstants.space4.w,
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
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
          child: InkWell(
            onTap: () => _onCategoryTap(category),
            borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // الأيقونة
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          category.isInDevelopment ? Icons.construction : category.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // العنوان
                      Text(
                        category.title,
                        style: context.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 14,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeConstants.warning,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeConstants.warning.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'قيد التطوير',
                          style: context.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: ThemeConstants.bold,
                            fontSize: 9,
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

  // بطاقة عريضة (لأسماء الله الحسنى)
  Widget _buildWideCard(BuildContext context, CategoryItem category) {
    final gradient = _getGradient(category.id, category.isInDevelopment);
    
    return RepaintBoundary(
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
          child: InkWell(
            onTap: () => _onCategoryTap(category),
            borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusXl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      // الأيقونة
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          category.isInDevelopment ? Icons.construction : category.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      
                      const SizedBox(width: 14),
                      
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
                                fontSize: 16,
                                height: 1.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeConstants.warning,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeConstants.warning.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'قيد التطوير',
                          style: context.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: ThemeConstants.bold,
                            fontSize: 9,
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