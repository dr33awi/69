// lib/features/athkar/screens/athkar_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/infrastructure/services/permissions/simple_permission_service.dart';
import '../../../core/infrastructure/services/favorites/models/favorite_models.dart';
import '../../../core/infrastructure/services/favorites/extensions/favorites_extensions.dart';
import '../../../core/infrastructure/services/text/extensions/text_settings_extensions.dart';
import '../../../core/infrastructure/services/text/models/text_settings_models.dart';
import '../services/athkar_service.dart';
import '../models/athkar_model.dart';
import '../utils/category_utils.dart';
import 'notification_settings_screen.dart';

class AthkarCategoriesScreen extends StatefulWidget {
  const AthkarCategoriesScreen({super.key});

  @override
  State<AthkarCategoriesScreen> createState() => _AthkarCategoriesScreenState();
}

class _AthkarCategoriesScreenState extends State<AthkarCategoriesScreen> {
  late final AthkarService _service;
  late final SimplePermissionService _permissionService;
  
  late Future<List<AthkarCategory>> _futureCategories;

  @override
  void initState() {
    super.initState();
    _service = getIt<AthkarService>();
    _permissionService = getIt<SimplePermissionService>();
    
    _initialize();
  }

  Future<void> _initialize() async {
    _futureCategories = _service.loadCategories();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    await _permissionService.checkNotificationPermission();
  }

  Future<void> _refreshData() async {
    setState(() {
      _futureCategories = _service.loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: ThemeConstants.primary,
                child: FutureBuilder<List<AthkarCategory>>(
                  future: _futureCategories,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoading();
                    }
                    
                    if (snapshot.hasError) {
                      return _buildErrorState();
                    }
                    
                    final categories = snapshot.data ?? [];
                    
                    if (categories.isEmpty) {
                      return _buildEmptyState();
                    }
                    
                    return _buildContent(categories);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
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
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 10.w),
          
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ThemeConstants.accent, ThemeConstants.accentLight],
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
                  color: ThemeConstants.accent.withValues(alpha: 0.3),
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
              Icons.menu_book_rounded,
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
                  'أذكار المسلم',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 17.sp,
                  ),
                ),
                Text(
                  'اذكر الله كثيراً',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          
          // زر إعدادات النصوص
          _buildActionButton(
            icon: Icons.text_fields_rounded,
            color: ThemeConstants.info,
            onTap: _openTextSettings,
          ),
          
          // زر المفضلة
          _buildActionButton(
            icon: Icons.bookmark_rounded,
            color: context.textSecondaryColor,
            onTap: _openFavorites,
          ),
          
          // زر الإشعارات
          _buildActionButton(
            icon: Icons.notifications_outlined,
            color: context.textSecondaryColor,
            onTap: _openNotificationSettings,
          ),
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
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
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

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: ThemeConstants.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: ThemeConstants.accent,
              strokeWidth: 3.w,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل الأذكار...',
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

  Widget _buildErrorState() {
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
            'حدث خطأ في تحميل البيانات',
            style: TextStyle(
              color: context.textSecondaryColor.withOpacity(0.7),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.accent,
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

  Widget _buildEmptyState() {
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
              Icons.menu_book_outlined,
              size: 60.sp,
              color: context.textSecondaryColor.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد أذكار',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontWeight: ThemeConstants.bold,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'لا توجد أذكار متاحة حالياً',
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

  Widget _buildContent(List<AthkarCategory> categories) {
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
                color: ThemeConstants.accent,
              ),
              SizedBox(width: 8.w),
              Text(
                'عدد الفئات: ${categories.length}',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 14.sp,
                  fontWeight: ThemeConstants.medium,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                margin: EdgeInsets.only(bottom: 14.h),
                child: _buildCompactCategoryCard(category),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCategoryCard(AthkarCategory category) {
    final categoryColor = CategoryUtils.getCategoryThemeColor(category.id);
    final categoryIcon = CategoryUtils.getCategoryIcon(category.id);
    final description = CategoryUtils.getCategoryDescription(category.id);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () => _openCategoryDetails(category),
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
                      category.title,
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: ThemeConstants.bold,
                        fontFamily: ThemeConstants.fontFamilyArabic,
                        fontSize: 16.sp,
                      ),
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    Text(
                      description,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        height: 1.3,
                        fontSize: 12.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (category.notifyTime != null && CategoryUtils.shouldShowTime(category.id)) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12.sp,
                            color: ThemeConstants.accent,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            category.notifyTime!.format(context),
                            style: TextStyle(
                              color: ThemeConstants.accent,
                              fontWeight: ThemeConstants.medium,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: categoryColor,
                  size: 18.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategoryDetails(AthkarCategory category) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      AppRouter.athkarDetails,
      arguments: category.id,
    );
  }

  void _openFavorites() {
    HapticFeedback.lightImpact();
    context.openFavoritesScreen(FavoriteContentType.athkar);
  }

  void _openTextSettings() {
    context.showGlobalTextSettings(
      initialContentType: ContentType.athkar,
    );
  }

  void _openNotificationSettings() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AthkarNotificationSettingsScreen(),
      ),
    );
  }
}