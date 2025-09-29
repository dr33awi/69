// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../app/themes/app_theme.dart';
import '../widgets/category_grid.dart';
import 'package:athkar_app/features/home/daily_quotes/daily_quotes_card.dart';
import 'package:athkar_app/features/home/widgets/home_prayer_times_card.dart';
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/core/infrastructure/firebase/remote_config_manager.dart';

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
  
  // إضافة متغير لحالة التحديث
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
    final hour = _currentTimeNotifier.value.hour;
    
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: ThemeConstants.space4,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              ThemeConstants.space2.h,
                              
                              const PrayerTimesCard(),
                              
                              ThemeConstants.space4.h,
                              
                              const DailyQuotesCard(),
                              
                              ThemeConstants.space6.h,
                              
                              _buildSectionsHeader(context),
                              
                              ThemeConstants.space4.h,
                            ]),
                          ),
                        ),
                        
                        const CategoryGrid(),
                        
                        SliverToBoxAdapter(
                          child: ThemeConstants.space12.h,
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
    
    return ValueListenableBuilder<DateTime>(
      valueListenable: _currentTimeNotifier,
      builder: (context, currentTime, child) {
        final arabicFormatter = DateFormat('EEEE, d MMMM yyyy', 'ar');
        final timeFormatter = DateFormat('hh:mm a', 'ar');
        final dateString = arabicFormatter.format(currentTime);
        final timeString = timeFormatter.format(currentTime);
    
        return Container(
          padding: const EdgeInsets.all(ThemeConstants.space4),
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
                          size: ThemeConstants.iconMd,
                        ),
                        ThemeConstants.space2.w,
                        Text(
                          messageData['greeting'] as String,
                          style: context.titleMedium?.copyWith(
                            fontWeight: ThemeConstants.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    ThemeConstants.space1.h,
                    Padding(
                      padding: const EdgeInsets.only(right: ThemeConstants.space8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            messageData['message'] as String,
                            style: context.bodySmall?.copyWith(
                              color: context.textSecondaryColor,
                            ),
                          ),
                          ThemeConstants.space1.h,
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: context.textSecondaryColor.withValues(alpha: 0.7),
                              ),
                              ThemeConstants.space1.w,
                              Text(
                                dateString,
                                style: context.labelSmall?.copyWith(
                                  color: context.textSecondaryColor.withValues(alpha: 0.8),
                                ),
                              ),
                              ThemeConstants.space3.w,
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: context.textSecondaryColor.withValues(alpha: 0.7),
                              ),
                              ThemeConstants.space1.w,
                              Text(
                                timeString,
                                style: context.labelSmall?.copyWith(
                                  color: context.textSecondaryColor.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/settings');
                  },
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(ThemeConstants.space2),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                      border: Border.all(
                        color: context.dividerColor.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: context.textPrimaryColor,
                      size: ThemeConstants.iconMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionsHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.space4,
        vertical: ThemeConstants.space3,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              gradient: ThemeConstants.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ThemeConstants.space3.w,
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
            ),
            child: Icon(
              Icons.apps_rounded,
              color: context.primaryColor,
              size: 20,
            ),
          ),
          ThemeConstants.space3.w,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الأقسام الرئيسية',
                  style: context.titleMedium?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
                Text(
                  'اختر القسم المناسب لك',
                  style: context.labelSmall?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// معالج Pull to Refresh - مع تحديث Remote Config
  Future<void> _handlePullToRefresh() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();
    
    try {
      debugPrint('🔄 [HomeScreen] Starting refresh...');
      
      // 1. محاولة تحديث Remote Config
      await _refreshRemoteConfig();
      
      // 2. تأخير قصير لتجربة مستخدم أفضل
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

  /// تحديث Remote Config
  Future<bool> _refreshRemoteConfig() async {
    try {
      debugPrint('🔧 [HomeScreen] Fetching Remote Config updates...');
      
      // التحقق من توفر RemoteConfigManager
      if (!getIt.isRegistered<RemoteConfigManager>()) {
        debugPrint('⚠️ [HomeScreen] RemoteConfigManager not registered');
        return false;
      }
      
      final configManager = getIt<RemoteConfigManager>();
      
      // التحقق من أنه مُهيأ
      if (!configManager.isInitialized) {
        debugPrint('⚠️ [HomeScreen] RemoteConfigManager not initialized');
        return false;
      }
      
      // تحديث الإعدادات
      final success = await configManager.refreshConfig();
      
      if (success) {
        debugPrint('✅ [HomeScreen] Remote Config updated successfully');
        
        // طباعة القيم المحدثة
        debugPrint('📊 Updated Config Values:');
        debugPrint('  - Prayer Times Enabled: ${configManager.isPrayerTimesFeatureEnabled}');
        debugPrint('  - Qibla Enabled: ${configManager.isQiblaFeatureEnabled}');
        debugPrint('  - Athkar Enabled: ${configManager.isAthkarFeatureEnabled}');
        debugPrint('  - Notifications Enabled: ${configManager.isNotificationsFeatureEnabled}');
        debugPrint('  - Maintenance Mode: ${configManager.isMaintenanceModeActive}');
        debugPrint('  - Force Update: ${configManager.isForceUpdateRequired}');
        
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

  /// إظهار رسالة التحديث
  void _showRefreshMessage(String message, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green 
                ? Icons.check_circle_outline 
                : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}