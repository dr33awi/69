// lib/features/dua/screens/dua_categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/text_settings/extensions/text_settings_extensions.dart';
import '../../../core/infrastructure/services/text_settings/models/text_settings_models.dart';
import '../services/dua_service.dart';
import '../models/dua_model.dart';
import 'dua_list_screen.dart';
import 'dua_search_screen.dart';

class DuaCategoriesScreen extends StatefulWidget {
  const DuaCategoriesScreen({super.key});

  @override
  State<DuaCategoriesScreen> createState() => _DuaCategoriesScreenState();
}

class _DuaCategoriesScreenState extends State<DuaCategoriesScreen> {
  late final DuaService _service;
  
  List<DuaCategory> _categories = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = context.duaService;
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final categories = await _service.loadCategories();
      final stats = await _service.getStatistics();
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في تحميل البيانات';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.06),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              
              SizedBox(width: 10.w),
              
              Container(
                padding: EdgeInsets.all(9.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ThemeConstants.tertiary, ThemeConstants.tertiaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.tertiary.withValues(alpha: 0.3),
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
                  FlutterIslamicIcons.solidPrayer,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              
              SizedBox(width: 10.w),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الأدعية المأثورة',
                      style: TextStyle(
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                        fontSize: 17.sp,
                      ),
                    ),
                    Text(
                      'ادعُ ربك بقلب خاشع',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              
              // زر إعدادات النصوص
              Container(
                margin: EdgeInsets.only(left: 2.w),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14.r),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await context.showGlobalTextSettings(
                        initialContentType: ContentType.dua,
                      );
                      setState(() {});
                    },
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
                            color: Colors.black.withValues(
                              alpha: context.isDarkMode ? 0.15 : 0.06,
                            ),
                            blurRadius: 12.r,
                            offset: Offset(0, 4.h),
                            spreadRadius: -2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: context.isDarkMode ? 0.08 : 0.03,
                            ),
                            blurRadius: 6.r,
                            offset: Offset(0, 2.h),
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.text_fields_rounded,
                        color: ThemeConstants.info,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // شريط البحث
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openSearch();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ),
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
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: context.textSecondaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'ابحث في الأدعية...',
              style: TextStyle(
                color: context.textSecondaryColor.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ThemeConstants.tertiary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                color: ThemeConstants.tertiary,
                strokeWidth: 3.w,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'جاري تحميل الأدعية...',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 16.sp,
                fontWeight: ThemeConstants.medium,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'يرجى الانتظار قليلاً',
              style: TextStyle(
                color: context.textSecondaryColor.withOpacity(0.7),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60.sp,
                color: Colors.red.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'حدث خطأ',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontWeight: ThemeConstants.bold,
                fontSize: 20.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _error!,
              style: TextStyle(
                color: context.textSecondaryColor.withOpacity(0.7),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.tertiary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: context.textSecondaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pan_tool_outlined,
                size: 60.sp,
                color: context.textSecondaryColor.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد أدعية',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontWeight: ThemeConstants.bold,
                fontSize: 20.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'لا توجد أدعية متاحة حالياً',
              style: TextStyle(
                color: context.textSecondaryColor.withOpacity(0.7),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: context.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.06),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.08 : 0.03),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
                spreadRadius: -1,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 16.sp,
                color: ThemeConstants.tertiary,
              ),
              SizedBox(width: 8.w),
              Text(
                'عدد الفئات: ${_categories.length}',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 14.sp,
                  fontWeight: ThemeConstants.medium,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: ThemeConstants.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${_statistics['totalDuas'] ?? 0} دعاء',
                  style: TextStyle(
                    color: ThemeConstants.tertiary,
                    fontSize: 12.sp,
                    fontWeight: ThemeConstants.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: ThemeConstants.tertiary,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  child: _buildCompactCategoryCard(category),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCategoryCard(DuaCategory category) {
    final categoryColor = _getCategoryColor(category.id);
    final categoryIcon = _getCategoryIcon(category.icon);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () => _openCategory(category),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: categoryColor.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.06),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.08 : 0.03),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
                spreadRadius: -1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [categoryColor, categoryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.15),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  categoryIcon,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              
              SizedBox(width: 12.w),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontWeight: ThemeConstants.bold,
                        fontFamily: ThemeConstants.fontFamilyArabic,
                        fontSize: 16.sp,
                      ),
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    Text(
                      category.description,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        height: 1.3,
                        fontSize: 12.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${category.duasCount}',
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: ThemeConstants.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.chevron_left_rounded,
                      color: categoryColor,
                      size: 18.sp,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return ThemeConstants.primary;
      case 'sahihain':
        return ThemeConstants.accent;
      case 'sunan':
        return ThemeConstants.tertiary;
      case 'other_authentic':
        return ThemeConstants.primaryDark;
      default:
        return ThemeConstants.tertiary;
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'book_quran':
        return Icons.menu_book;
      case 'book_hadith':
        return Icons.book;
      case 'book_sunnah':
        return Icons.auto_stories;
      case 'verified':
        return Icons.verified;
      default:
        return Icons.pan_tool_rounded;
    }
  }

  void _openCategory(DuaCategory category) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DuaListScreen(category: category),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DuaSearchScreen(),
      ),
    );
  }
}

