// lib/features/home/screens/home_screen.dart
// ✅ محدث مع Promotional Banners

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../app/themes/app_theme.dart';
import '../widgets/category_grid.dart';
import 'package:athkar_app/features/home/daily_quotes/daily_quotes_card.dart';
import 'package:athkar_app/features/home/widgets/home_prayer_times_card.dart';
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/core/infrastructure/firebase/remote_config_manager.dart';
import 'package:athkar_app/core/infrastructure/firebase/special_event/special_event_card.dart';
// ✅ إضافة import للبانرات
import 'package:athkar_app/core/infrastructure/firebase/promotional_banners/utils/banner_helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  late Timer _timer;
  final ValueNotifier<DateTime> _currentTimeNotifier = ValueNotifier(DateTime.now());
  
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTimeNotifier.value = DateTime.now();
    });
    
    // ✅ تهيئة BannerService في الخلفية (اختياري)
    _initializeBannerService();
  }
  
  /// ✅ تهيئة BannerService
  Future<void> _initializeBannerService() async {
    Future.delayed(const Duration(milliseconds: 1500), () {
      try {
        final bannerService = context.bannerService;
        if (bannerService != null && !bannerService.isInitialized) {
          debugPrint('🎯 Initializing BannerService from HomeScreen');
        }
      } catch (e) {
        debugPrint('⚠️ BannerService init error: $e');
      }
    });
  }
  
  @override
  void dispose() {
    _timer.cancel();
    _currentTimeNotifier.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getMessage() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return {
        'greeting': 'صباح الخير',
        'icon': Icons.wb_sunny_outlined,
        'message': 'نسأل الله أن يجعل يومك مباركاً',
      };
    } else if (hour >= 12 && hour < 17) {
      return {
        'greeting': 'مساء النور',
        'icon': Icons.wb_twilight_outlined,
        'message': 'لا تنسَ أذكار المساء',
      };
    } else if (hour >= 17 && hour < 21) {
      return {
        'greeting': 'مساء الخير',
        'icon': Icons.nights_stay_outlined,
        'message': 'أسعد الله مساءك بكل خير',
      };
    } else {
      return {
        'greeting': 'أهلاً بك',
        'icon': Icons.nightlight_outlined,
        'message': 'لا تنسَ أذكار النوم',
      };
    }
  }

  Future<void> _handlePullToRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();
    
    try {
      debugPrint('🔄 Refreshing...');
      
      // ✅ تحديث RemoteConfig
      if (getIt.isRegistered<RemoteConfigManager>()) {
        final manager = getIt<RemoteConfigManager>();
        
        if (manager.isInitialized) {
          final success = await manager.refreshConfig();
          
          if (success) {
            debugPrint('✅ Config refreshed successfully');
            debugPrint('   - Maintenance: ${manager.isMaintenanceModeActive}');
            debugPrint('   - Force Update: ${manager.isForceUpdateRequired}');
          }
        }
      }
      
      // ✅ تحديث البانرات
      final bannerService = context.bannerService;
      if (bannerService != null && bannerService.isInitialized) {
        await bannerService.refresh();
        debugPrint('✅ Banners refreshed');
      }
      
      await Future.delayed(const Duration(milliseconds: 800));
      
    } catch (e) {
      debugPrint('⚠️ Refresh error: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: context.isDarkMode
                            ? [
                                ThemeConstants.darkBackground,
                                ThemeConstants.darkSurface.withValues(alpha: 0.8),
                                ThemeConstants.darkBackground,
                              ]
                            : [
                                ThemeConstants.lightBackground,
                                ThemeConstants.primarySoft.withValues(alpha: 0.1),
                                ThemeConstants.lightBackground,
                              ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                  ),
                  
                  RefreshIndicator(
                    onRefresh: _handlePullToRefresh,
                    color: context.primaryColor,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              SizedBox(height: 10.h),
                              
                              // ✅ 1. Special Event Card (مناسبة واحدة فقط)
                              const SpecialEventCard(),
                              
                              // ✅ 2. Promotional Banners (بانرات متعددة)
                              _buildPromotionalBanners(),
                              
                              const PrayerTimesCard(),
                              
                              SizedBox(height: 16.h),
                              
                              const DailyQuotesCard(),
                              
                              SizedBox(height: 20.h),
                              
                              _buildSectionsHeader(context),
                              
                              SizedBox(height: 12.h),
                            ]),
                          ),
                        ),
                        
                        const CategoryGrid(),
                        
                        SliverToBoxAdapter(
                          child: SizedBox(height: 40.h),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ عرض البانرات الترويجية
  Widget _buildPromotionalBanners() {
    try {
      // استخدام Extension من BannerHelpers
      final bannersWidget = context.showBanners(
        screenName: 'home',
        maxBanners: 3,
      );
      
      // إذا لم توجد بانرات، لا نعرض شيء
      if (bannersWidget == null) {
        return const SizedBox.shrink();
      }
      
      // إضافة مسافة قبل البانرات
      return Column(
        children: [
          SizedBox(height: 12.h),
          bannersWidget,
        ],
      );
      
    } catch (e) {
      debugPrint('⚠️ Error showing banners: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final messageData = _getMessage();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      messageData['icon'] as IconData,
                      color: context.primaryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      messageData['greeting'] as String,
                      style: TextStyle(
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                        fontSize: 15.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Padding(
                  padding: EdgeInsets.only(right: 26.w),
                  child: Text(
                    messageData['message'] as String,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/settings');
              },
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: context.dividerColor.withValues(alpha: 0.3),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 3.r,
                      offset: Offset(0, 1.5.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: context.textPrimaryColor,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 28.h,
            decoration: BoxDecoration(
              gradient: ThemeConstants.primaryGradient,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.apps_rounded,
              color: context.primaryColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الأقسام الرئيسية',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  'اختر القسم المناسب لك',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}