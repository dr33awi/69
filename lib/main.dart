// lib/main.dart - محدث مع خدمات Firebase الجديدة
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

// Firebase Services الجديدة
import 'core/infrastructure/firebase/firebase_initializer.dart';
import 'core/infrastructure/firebase/analytics/analytics_service.dart';
import 'core/infrastructure/firebase/performance/performance_service.dart';

// Service Locator والخدمات
import 'app/di/service_locator.dart';
import 'app/themes/core/theme_notifier.dart';
import 'core/infrastructure/services/permissions/permission_manager.dart';
import 'core/infrastructure/services/permissions/widgets/permission_monitor.dart';
import 'core/infrastructure/services/storage/storage_service.dart';

// خدمات الإشعارات
import 'core/infrastructure/services/notifications/notification_manager.dart';
import 'core/infrastructure/services/notifications/notification_tap_handler.dart';
import 'core/infrastructure/services/notifications/models/notification_models.dart';

// خدمات التطوير والمراقبة
import 'core/infrastructure/config/development_config.dart';
import 'core/infrastructure/services/preview/device_preview_config.dart';

// Firebase services
import 'core/infrastructure/firebase/remote_config_manager.dart';
import 'core/infrastructure/firebase/remote_config_service.dart';
import 'core/infrastructure/firebase/widgets/app_status_monitor.dart';

// الثيمات والمسارات
import 'app/themes/app_theme.dart';
import 'app/routes/app_router.dart';

// الشاشات
import 'features/home/screens/home_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/screens/permissions_setup_screen.dart';

// ==================== متغيرات عامة ====================
NotificationAppLaunchDetails? _notificationAppLaunchDetails;
NotificationTapEvent? _pendingNotificationEvent;

/// نقطة دخول التطبيق
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // فحص الإشعار الأولي
  await _checkInitialNotification();
  
  runZonedGuarded(
    () async {
      try {
        // تهيئة سريعة مع Firebase المحسن
        await _fastBootstrap();
        
        // إعداد معالج الإشعارات
        await _setupNotificationHandler();
        
        final app = const AthkarApp();
        final wrappedApp = DevicePreviewConfig.wrapApp(app);
        runApp(wrappedApp ?? app);
        
        // تهيئة الخدمات في الخلفية
        _backgroundInitialization();
        
      } catch (e, s) {
        debugPrint('خطأ في تشغيل التطبيق: $e');
        debugPrint('Stack trace: $s');
        
        // تسجيل الخطأ في Crashlytics إذا كان متاحاً
        if (FirebaseInitializer.isCrashlyticsAvailable) {
          await FirebaseCrashlytics.instance.recordError(e, s, fatal: true);
        }
        
        runApp(_ErrorApp(error: e.toString()));
      }
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');
      
      // تسجيل الأخطاء غير المعالجة في Crashlytics
      if (FirebaseInitializer.isCrashlyticsAvailable) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

// ==================== فحص الإشعار الأولي ====================
Future<void> _checkInitialNotification() async {
  try {
    debugPrint('🔍 [Main] فحص الإشعار الأولي عند بدء التطبيق...');
    
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    
    _notificationAppLaunchDetails = await flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();
    
    if (_notificationAppLaunchDetails != null) {
      final didNotificationLaunchApp = 
          _notificationAppLaunchDetails!.didNotificationLaunchApp;
      
      if (didNotificationLaunchApp) {
        debugPrint('✅ [Main] التطبيق تم فتحه من إشعار!');
        
        final response = _notificationAppLaunchDetails!.notificationResponse;
        if (response != null && response.payload != null) {
          debugPrint('📦 [Main] Payload: ${response.payload}');
          
          try {
            final payloadData = jsonDecode(response.payload!);
            
            _pendingNotificationEvent = NotificationTapEvent(
              notificationId: payloadData['id'] ?? 'unknown',
              category: NotificationCategory.values[
                payloadData['category'] ?? 0
              ],
              payload: payloadData['payload'] ?? {},
            );
            
            debugPrint('🎯 [Main] تم حفظ الإشعار المعلق للمعالجة');
            debugPrint('   - Category: ${_pendingNotificationEvent!.category}');
            debugPrint('   - ID: ${_pendingNotificationEvent!.notificationId}');
            
          } catch (e) {
            debugPrint('❌ [Main] خطأ في تحليل payload: $e');
          }
        }
      } else {
        debugPrint('ℹ️ [Main] التطبيق لم يتم فتحه من إشعار');
      }
    }
  } catch (e) {
    debugPrint('❌ [Main] خطأ في فحص الإشعار الأولي: $e');
  }
}

// ==================== إعداد معالج الإشعارات ====================
Future<void> _setupNotificationHandler() async {
  try {
    debugPrint('🔔 [Main] ========== إعداد معالج الإشعارات ==========');
    
    final handler = NotificationTapHandler(
      navigatorKey: AppRouter.navigatorKey,
    );
    
    // معالجة الإشعار المعلق إن وجد
    if (_pendingNotificationEvent != null) {
      debugPrint('🎯 [Main] معالجة الإشعار المعلق...');
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_pendingNotificationEvent != null) {
          debugPrint('🚀 [Main] تنفيذ معالجة الإشعار المعلق الآن');
          handler.handleNotificationTap(_pendingNotificationEvent!);
          _pendingNotificationEvent = null;
        }
      });
    }
    
    // الاستماع للإشعارات المستقبلية
    NotificationManager.instance.onTap.listen(
      (event) {
        debugPrint('🔔 [Main] ========================================');
        debugPrint('🔔 [Main] تم استقبال حدث نقر على إشعار');
        debugPrint('🔔 [Main] ========================================');
        debugPrint('   📌 Category: ${event.category}');
        debugPrint('   📌 ID: ${event.notificationId}');
        debugPrint('   📌 Timestamp: ${event.timestamp}');
        debugPrint('   📌 Payload: ${event.payload}');
        debugPrint('🔔 [Main] ========================================');
        
        handler.handleNotificationTap(event);
      },
      onError: (error) {
        debugPrint('❌ [Main] خطأ في معالجة حدث الإشعار: $error');
      },
      cancelOnError: false,
    );
    
    debugPrint('✅ [Main] تم إعداد معالج الإشعارات بنجاح');
    
  } catch (e, stackTrace) {
    debugPrint('❌ [Main] خطأ خطير في إعداد معالج الإشعارات: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

// ==================== Fast Bootstrap ====================
Future<void> _fastBootstrap() async {
  debugPrint('========== Fast Bootstrap Starting ==========');
  final stopwatch = Stopwatch()..start();
  
  try {
    DevelopmentConfig.initialize();
    
    // تهيئة Firebase Core مع الخدمات المتقدمة
    debugPrint('🔥 تهيئة Firebase Core والخدمات المتقدمة...');
    
    // 1. تهيئة Firebase Core
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (Firebase.apps.isEmpty) {
      throw Exception('فشل في تهيئة Firebase');
    }
    debugPrint('✅ Firebase Core initialized. Apps: ${Firebase.apps.length}');
    
    // 2. تهيئة جميع خدمات Firebase (Analytics, Crashlytics, Performance, etc.)
    final firebaseInitSuccess = await FirebaseInitializer.initialize();
    if (firebaseInitSuccess) {
      debugPrint('✅ Firebase Initializer completed successfully');
      debugPrint('   - Analytics: ${FirebaseInitializer.isAnalyticsAvailable}');
      debugPrint('   - Crashlytics: ${FirebaseInitializer.isCrashlyticsAvailable}');
      debugPrint('   - Performance: ${FirebaseInitializer.isPerformanceAvailable}');
      debugPrint('   - Messaging: ${FirebaseInitializer.isMessagingAvailable}');
      debugPrint('   - Remote Config: ${FirebaseInitializer.isRemoteConfigAvailable}');
    } else {
      debugPrint('⚠️ Firebase Initializer returned false, but continuing...');
    }
    
    // 3. تهيئة Service Locator الأساسي
    await ServiceLocator.initEssential();
    
    // 4. تهيئة Remote Config مبكراً
    await _initializeRemoteConfigEarly();
    
    if (!ServiceLocator.areEssentialServicesReady()) {
      throw Exception('فشل في تهيئة الخدمات الأساسية');
    }
    
    stopwatch.stop();
    debugPrint('========== Fast Bootstrap Completed in ${stopwatch.elapsedMilliseconds}ms ⚡ ==========');
    
  } catch (e, s) {
    stopwatch.stop();
    debugPrint('❌ Fast Bootstrap Failed: $e');
    debugPrint('Stack trace: $s');
    rethrow;
  }
}

// ==================== تهيئة Remote Config مبكراً ====================
Future<void> _initializeRemoteConfigEarly() async {
  try {
    debugPrint('🔧 تهيئة Remote Config مبكراً...');
    
    if (!getIt.isRegistered<FirebaseRemoteConfigService>()) {
      getIt.registerLazySingleton<FirebaseRemoteConfigService>(
        () => FirebaseRemoteConfigService(),
      );
    }
    
    if (!getIt.isRegistered<RemoteConfigManager>()) {
      getIt.registerLazySingleton<RemoteConfigManager>(
        () => RemoteConfigManager(),
      );
    }
    
    final remoteConfigService = getIt<FirebaseRemoteConfigService>();
    await remoteConfigService.initialize();
    
    debugPrint('🔄 Forcing refresh of Remote Config...');
    bool refreshSuccess = await remoteConfigService.refresh();
    debugPrint('  - First refresh result: $refreshSuccess');
    
    if (remoteConfigService.requiredAppVersion == "1.0.0" || 
        remoteConfigService.requiredAppVersion == "1.1.0") {
      debugPrint('⚠️ Default values detected, trying force refresh...');
      await remoteConfigService.forceRefreshForTesting();
      refreshSuccess = await remoteConfigService.refresh();
      debugPrint('  - Second refresh result: $refreshSuccess');
    }
    
    final configManager = getIt<RemoteConfigManager>();
    await configManager.initialize(
      remoteConfig: remoteConfigService,
      storage: getIt<StorageService>(),
    );
    
    debugPrint('📊 Final Remote Config Values:');
    debugPrint('  - Force Update: ${remoteConfigService.isForceUpdateRequired}');
    debugPrint('  - Maintenance: ${remoteConfigService.isMaintenanceModeEnabled}');
    debugPrint('  - App Version: ${remoteConfigService.requiredAppVersion}');
    debugPrint('  - Update URL: ${remoteConfigService.updateUrl}');
    
    if (remoteConfigService.requiredAppVersion == "1.0.0" || 
        remoteConfigService.requiredAppVersion == "1.1.0") {
      debugPrint('⚠️ WARNING: Still using default app_version!');
      debugPrint('⚠️ Check Firebase Console and publish changes');
    } else {
      debugPrint('✅ Remote Config initialized with Firebase values');
    }
    
  } catch (e) {
    debugPrint('⚠️ Remote Config early init failed (non-critical): $e');
  }
}

// ==================== Background Initialization ====================
void _backgroundInitialization() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      debugPrint('========== Background Initialization Starting ==========');
      final stopwatch = Stopwatch()..start();
      
      // 1. تسجيل خدمات الميزات
      await ServiceLocator.registerFeatureServices();
      
      // 2. تهيئة Firebase Services في الخلفية
      try {
        await ServiceLocator.initializeFirebaseInBackground();
        debugPrint('✅ Firebase services initialized in background');
      } catch (e) {
        debugPrint('⚠️ Firebase background init warning: $e');
      }
      
      // 3. تهيئة خدمات Firebase المتقدمة (Analytics, Performance)
      try {
        await ServiceLocator.initializeAdvancedFirebaseServices();
        debugPrint('✅ Advanced Firebase services initialized in background');
        
        // تسجيل حدث بدء التطبيق
        if (getIt.isRegistered<AnalyticsService>()) {
          final analytics = getIt<AnalyticsService>();
          if (analytics.isInitialized) {
            await analytics.logAppOpen();
            debugPrint('📊 App open event logged to Analytics');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Advanced Firebase init warning: $e');
      }
      
      stopwatch.stop();
      debugPrint('========== Background Initialization Completed in ${stopwatch.elapsedMilliseconds}ms 🚀 ==========');
      
    } catch (e) {
      debugPrint('❌ Background initialization error: $e');
    }
  });
}

/// التطبيق الرئيسي
class AthkarApp extends StatefulWidget {
  const AthkarApp({super.key});

  @override
  State<AthkarApp> createState() => _AthkarAppState();
}

class _AthkarAppState extends State<AthkarApp> with WidgetsBindingObserver {
  late final UnifiedPermissionManager _permissionManager;
  RemoteConfigManager? _configManager;
  bool _configManagerReady = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _permissionManager = getIt<UnifiedPermissionManager>();
    
    _initializeConfigManager();
    _scheduleInitialPermissionCheck();
    _processPendingNotificationIfAny();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('🔄 [AthkarApp] App lifecycle state: $state');
    
    if (state == AppLifecycleState.resumed) {
      _processPendingNotificationIfAny();
    }
  }
  
  void _processPendingNotificationIfAny() {
    if (_pendingNotificationEvent != null) {
      debugPrint('🎯 [AthkarApp] وجد إشعار معلق، سيتم معالجته...');
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_pendingNotificationEvent != null && mounted) {
          final handler = NotificationTapHandler(
            navigatorKey: AppRouter.navigatorKey,
          );
          
          handler.handleNotificationTap(_pendingNotificationEvent!);
          _pendingNotificationEvent = null;
        }
      });
    }
  }

  void _initializeConfigManager() {
    try {
      if (getIt.isRegistered<RemoteConfigManager>()) {
        _configManager = getIt<RemoteConfigManager>();
        
        if (_configManager!.isInitialized) {
          setState(() => _configManagerReady = true);
          debugPrint('✅ Config Manager ready in AthkarApp');
          
          debugPrint('Current Remote Config Values:');
          debugPrint('  - Force Update: ${_configManager!.isForceUpdateRequired}');
          debugPrint('  - Maintenance: ${_configManager!.isMaintenanceModeActive}');
          debugPrint('  - Required Version: ${_configManager!.requiredAppVersion}');
        } else {
          debugPrint('⚠️ Config Manager registered but not initialized yet');
          
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _configManager!.isInitialized) {
              setState(() => _configManagerReady = true);
              debugPrint('✅ Config Manager ready after delay');
            }
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Config Manager not available: $e');
    }
  }

  void _scheduleInitialPermissionCheck() {
    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;
      
      try {
        final storage = getIt<StorageService>();
        final onboardingCompleted = storage.getBool('onboarding_completed') ?? false;
        final permissionsSetupCompleted = storage.getBool('permissions_setup_completed') ?? false;
        
        if (onboardingCompleted && permissionsSetupCompleted) {
          if (!_permissionManager.hasCheckedThisSession) {
            debugPrint('[AthkarApp] Performing initial permission check (ONCE)');
            await _permissionManager.performInitialCheck();
          } else {
            debugPrint('[AthkarApp] Initial check already done, skipping');
          }
        } else {
          debugPrint('[AthkarApp] Skipping permission check - setup not completed');
        }
      } catch (e) {
        debugPrint('[AthkarApp] Error checking onboarding status: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: getIt<ThemeNotifier>(),
      builder: (context, themeMode, child) {
        return ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          
          builder: (context, child) {
            return MaterialApp(
              title: 'حصن المسلم',
              debugShowCheckedModeBanner: false,
              
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              
              navigatorKey: AppRouter.navigatorKey,
              
              home: _buildInitialScreen(),
              
              onGenerateRoute: AppRouter.onGenerateRoute,
              
              builder: (context, child) {
                if (child == null) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                return child;
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInitialScreen() {
    Widget screen;
    bool skipPermissionMonitorCheck = false;
    
    try {
      final storage = getIt<StorageService>();
      final onboardingCompleted = storage.getBool('onboarding_completed') ?? false;
      final permissionsSetupCompleted = storage.getBool('permissions_setup_completed') ?? false;
      
      if (!onboardingCompleted) {
        debugPrint('🎬 Starting with onboarding');
        return const OnboardingScreen();
        
      } else if (!permissionsSetupCompleted) {
        debugPrint('🔐 Starting with permissions setup');
        return const PermissionsSetupScreen();
        
      } else {
        debugPrint('🏠 Starting with home screen');
        
        skipPermissionMonitorCheck = _permissionManager.hasCheckedThisSession;
        
        debugPrint('[AthkarApp] skipPermissionMonitorCheck: $skipPermissionMonitorCheck');
        
        screen = PermissionMonitor(
          showNotifications: true,
          skipInitialCheck: skipPermissionMonitorCheck,
          child: const HomeScreen(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error determining initial screen: $e');
      screen = const PermissionMonitor(
        showNotifications: true,
        skipInitialCheck: true,
        child: HomeScreen(),
      );
    }
    
    return _wrapWithAppMonitor(screen);
  }

  Widget _wrapWithAppMonitor(Widget screen) {
    if (_configManagerReady && _configManager != null) {
      debugPrint('✅ Wrapping with AppStatusMonitor (Config Manager ready)');
      return AppStatusMonitor(
        configManager: _configManager,
        child: screen,
      );
    }
    
    debugPrint('⏳ AppStatusMonitor not ready yet, showing screen directly');
    return screen;
  }
}

/// شاشة الخطأ
class _ErrorApp extends StatelessWidget {
  final String error;
  
  const _ErrorApp({required this.error});
  
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(32.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 80.sp,
                            color: Colors.red.shade700,
                          ),
                        ),
                        
                        SizedBox(height: 32.h),
                        
                        Text(
                          'عذراً، حدث خطأ',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        Text(
                          'حدث خطأ أثناء تهيئة التطبيق\nيرجى إعادة المحاولة',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.black54,
                            height: 1.5,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 48.h),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton.icon(
                            onPressed: () => main(),
                            icon: Icon(Icons.refresh, size: 24.sp),
                            label: Text(
                              'إعادة المحاولة',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
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
          ),
        );
      },
    );
  }
}