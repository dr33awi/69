// lib/features/athkar/screens/athkar_categories_screen.dart
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
                              style: TextStyle(
                                fontWeight: ThemeConstants.bold,
                                color: context.textPrimaryColor,
                                fontSize: 22.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'اقرأ الأذكار اليومية وحافظ على ذكر الله في كل وقت',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 13.sp,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12.h,
                              crossAxisSpacing: 12.w,
                              childAspectRatio: 0.9,
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
                      padding: EdgeInsets.only(bottom: 24.h),
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
      padding: EdgeInsets.all(14.r),
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
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 10.w),
          
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ThemeConstants.accent, ThemeConstants.accentLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.accent.withOpacity(0.3),
                  blurRadius: 6.r,
                  offset: Offset(0, 3.h),
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
                  padding: EdgeInsets.all(7.r),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: context.dividerColor.withOpacity(0.3),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 3.r,
                        offset: Offset(0, 2.h),
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