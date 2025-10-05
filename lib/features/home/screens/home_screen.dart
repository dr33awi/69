// lib/features/home/screens/home_screen.dart - محدث بدون التاريخ والساعة

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
      debugPrint('🔄 [HomeScreen] Starting refresh...');
      
      await _refreshRemoteConfig();
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      debugPrint('✅ [HomeScreen] Refresh completed successfully');
      
    } catch (e) {
      debugPrint('❌ [HomeScreen] Refresh error: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<bool> _refreshRemoteConfig() async {
    try {
      debugPrint('🔧 [HomeScreen] Fetching Remote Config updates...');
      
      if (!getIt.isRegistered<RemoteConfigManager>()) {
        debugPrint('⚠️ [HomeScreen] RemoteConfigManager not registered');
        return false;
      }
      
      final configManager = getIt<RemoteConfigManager>();
      
      if (!configManager.isInitialized) {
        debugPrint('⚠️ [HomeScreen] RemoteConfigManager not initialized');
        return false;
      }
      
      final success = await configManager.refreshConfig();
      
      if (success) {
        debugPrint('✅ [HomeScreen] Remote Config updated successfully');
        
        debugPrint('📊 Updated Config Values:');
        debugPrint('  - Maintenance Mode: ${configManager.isMaintenanceModeActive}');
        debugPrint('  - Force Update: ${configManager.isForceUpdateRequired}');
        debugPrint('  - Required Version: ${configManager.requiredAppVersion}');
        
        if (configManager.isMaintenanceModeActive) {
          debugPrint('🔧 App is now in maintenance mode');
        }
        
        if (configManager.isForceUpdateRequired) {
          debugPrint('🚨 Force update is now required');
        }
        
        return true;
      } else {
        debugPrint('⚠️ [HomeScreen] Remote Config update returned false');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ [HomeScreen] Remote Config refresh error: $e');
      return false;
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
                            horizontal: 20.w,
                            vertical: 8.h,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              SizedBox(height: 12.h),
                              
                              const SpecialEventCard(),
                              
                              const PrayerTimesCard(),
                              
                              SizedBox(height: 20.h),
                              
                              const DailyQuotesCard(),
                              
                              SizedBox(height: 24.h),
                              
                              _buildSectionsHeader(context),
                              
                              SizedBox(height: 16.h),
                            ]),
                          ),
                        ),
                        
                        const CategoryGrid(),
                        
                        SliverToBoxAdapter(
                          child: SizedBox(height: 48.h),
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

  Widget _buildCustomAppBar(BuildContext context) {
    final messageData = _getMessage();
    
    return Container(
      padding: EdgeInsets.all(16.w),
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
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      messageData['greeting'] as String,
                      style: context.titleMedium?.copyWith(
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.only(right: 32.w),
                  child: Text(
                    messageData['message'] as String,
                    style: context.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/settings');
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
                  Icons.settings_outlined,
                  color: context.textPrimaryColor,
                  size: 24.sp,
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
        horizontal: 16.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 32.h,
            decoration: BoxDecoration(
              gradient: ThemeConstants.primaryGradient,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.apps_rounded,
              color: context.primaryColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الأقسام الرئيسية',
                  style: context.titleMedium?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  'اختر القسم المناسب لك',
                  style: context.labelSmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
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