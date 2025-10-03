// lib/features/athkar/screens/athkar_categories_screen.dart - محدث

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../services/athkar_service.dart';
import '../models/athkar_model.dart';
import '../widgets/athkar_category_card.dart';
import 'notification_settings_screen.dart';

class AthkarCategoriesScreen extends StatefulWidget {
  const AthkarCategoriesScreen({super.key});

  @override
  State<AthkarCategoriesScreen> createState() => _AthkarCategoriesScreenState();
}

class _AthkarCategoriesScreenState extends State<AthkarCategoriesScreen> {
  late final AthkarService _service;
  late final PermissionService _permissionService;
  
  late Future<List<AthkarCategory>> _futureCategories;

  @override
  void initState() {
    super.initState();
    _service = getIt<AthkarService>();
    _permissionService = getIt<PermissionService>();
    
    _initialize();
  }

  Future<void> _initialize() async {
    _futureCategories = _service.loadCategories();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    await _permissionService.checkPermissionStatus(
      AppPermissionType.notification,
    );
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
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.only(top: 8.h),
                    ),
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اختر فئة الأذكار',
                              style: context.titleLarge?.copyWith(
                                fontWeight: ThemeConstants.bold,
                                color: context.textPrimaryColor,
                                fontSize: 24.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'اقرأ الأذكار اليومية وحافظ على ذكر الله في كل وقت',
                              style: context.bodyMedium?.copyWith(
                                color: context.textSecondaryColor,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    FutureBuilder<List<AthkarCategory>>(
                      future: _futureCategories,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return SliverFillRemaining(
                            child: Center(
                              child: AppLoading.page(
                                message: 'جاري تحميل الأذكار...',
                              ),
                            ),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          return SliverFillRemaining(
                            child: AppEmptyState.error(
                              message: 'حدث خطأ في تحميل البيانات',
                              onRetry: _refreshData,
                            ),
                          );
                        }
                        
                        final categories = snapshot.data ?? [];
                        
                        if (categories.isEmpty) {
                          return SliverFillRemaining(
                            child: AppEmptyState.noData(
                              message: 'لا توجد أذكار متاحة حالياً',
                            ),
                          );
                        }
                        
                        return SliverPadding(
                          padding: EdgeInsets.all(16.w),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16.h,
                              crossAxisSpacing: 16.w,
                              childAspectRatio: 0.8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final category = categories[index];
                                
                                return AthkarCategoryCard(
                                  category: category,
                                  onTap: () => _openCategoryDetails(category),
                                );
                              },
                              childCount: categories.length,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: 32.h),
                    ),
                  ],
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 12.w),
          
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ThemeConstants.accent, ThemeConstants.accentLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.accent.withValues(alpha: 0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              Icons.menu_book_rounded,
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
                  'أذكار المسلم',
                  style: context.titleLarge?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  'اذكر الله كثيراً',
                  style: context.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            margin: EdgeInsets.only(left: 8.w),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
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
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: context.dividerColor.withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: context.textPrimaryColor,
                    size: 24.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
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
}