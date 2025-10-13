// lib/main.dart - محدث مع Onboarding + معالج الإشعارات المحسّن
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Service Locator والخدمات
import 'app/di/service_locator.dart';
import 'app/themes/core/theme_notifier.dart';
import 'core/infrastructure/services/permissions/permission_manager.dart';
import 'core/infrastructure/services/permissions/widgets/permission_monitor.dart';
import 'core/infrastructure/services/storage/storage_service.dart';

// ==================== 🔔 خدمات الإشعارات ====================
import 'core/infrastructure/services/notifications/notification_manager.dart';
import 'core/infrastructure/services/notifications/notification_tap_handler.dart';
import 'core/infrastructure/services/notifications/pending_notification_handler.dart';
// ========================================================

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

/// نقطة دخول التطبيق
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runZonedGuarded(
    () async {
      try {
        await _fastBootstrap();
        
        // ==================== 🔔 إعداد معالج الإشعارات ====================
        await _setupNotificationHandler();
        // ==================================================================
        
        final app = const AthkarApp();
        final wrappedApp = DevicePreviewConfig.wrapApp(app);
        runApp(wrappedApp ?? app);
        
        _backgroundInitialization();
        
      } catch (e, s) {
        debugPrint('خطأ في تشغيل التطبيق: $e');
        debugPrint('Stack trace: $s');
        runApp(_ErrorApp(error: e.toString()));
      }
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

// ==================== 🔔 دالة إعداد معالج الإشعارات ====================
/// إعداد معالج النقر على الإشعارات
Future<void> _setupNotificationHandler() async {
  try {
    debugPrint('🔔 [Main] ========== إعداد معالج الإشعارات ==========');
    
    final pendingHandler = PendingNotificationHandler();
    
    // الاستماع لأحداث النقر على الإشعارات
    NotificationManager.instance.onTap.listen(
      (event) async {
        debugPrint('🔔 [Main] ========================================');
        debugPrint('🔔 [Main] تم استقبال حدث نقر على إشعار');
        debugPrint('🔔 [Main] ========================================');
        debugPrint('   📌 Category: ${event.category}');
        debugPrint('   📌 ID: ${event.notificationId}');
        debugPrint('   📌 Timestamp: ${event.timestamp}');
        debugPrint('   📌 Payload: ${event.payload}');
        debugPrint('🔔 [Main] ========================================');
        
        // التحقق من جاهزية Navigator
        final context = AppRouter.navigatorKey.currentContext;
        
        if (context == null || !context.mounted) {
          debugPrint('⏳ [Main] التطبيق ليس جاهزاً بعد، حفظ الإشعار كمعلق');
          pendingHandler.setPendingNotification(event);
          return;
        }
        
        // التطبيق جاهز، معالجة فورية
        debugPrint('✅ [Main] التطبيق جاهز، معالجة فورية');
        
        await Future.delayed(const Duration(milliseconds: 300));
        
        final handler = NotificationTapHandler(
          navigatorKey: AppRouter.navigatorKey,
        );
        
        await handler.handleNotificationTap(event);
      },
      onError: (error) {
        debugPrint('❌ [Main] خطأ في معالجة حدث الإشعار: $error');
      },
      cancelOnError: false,
    );
    
    debugPrint('✅ [Main] تم إعداد معالج الإشعارات بنجاح');
    debugPrint('   - Navigator Key: ${AppRouter.navigatorKey}');
    debugPrint('   - Handler: Ready');
    debugPrint('   - Listener: Active');
    
  } catch (e, stackTrace) {
    debugPrint('❌ [Main] خطأ خطير في إعداد معالج الإشعارات: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}
// ==============================================================================

Future<void> _fastBootstrap() async {
  debugPrint('========== Fast Bootstrap Starting ==========');
  final stopwatch = Stopwatch()..start();
  
  try {
    DevelopmentConfig.initialize();
    
    debugPrint('🔥 تهيئة Firebase Core...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (Firebase.apps.isEmpty) {
      throw Exception('فشل في تهيئة Firebase');
    }
    debugPrint('✅ Firebase initialized. Apps: ${Firebase.apps.length}');
        
    await ServiceLocator.initEssential();
    
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

void _backgroundInitialization() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      debugPrint('========== Background Initialization Starting ==========');
      final stopwatch = Stopwatch()..start();
      
      await ServiceLocator.registerFeatureServices();
      
      try {
        await ServiceLocator.initializeFirebaseInBackground();
        debugPrint('✅ Firebase services initialized in background');
      } catch (e) {
        debugPrint('⚠️ Firebase background init warning: $e');
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

class _AthkarAppState extends State<AthkarApp> {
  late final UnifiedPermissionManager _permissionManager;
  RemoteConfigManager? _configManager;
  bool _configManagerReady = false;

  @override
  void initState() {
    super.initState();
    
    _permissionManager = getIt<UnifiedPermissionManager>();
    
    _initializeConfigManager();
    
    _scheduleInitialPermissionCheck();
    
    // ==================== 🔔 معالجة الإشعارات المعلقة ====================
    _schedulePendingNotificationCheck();
    // =====================================================================
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
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      
      try {
        final storage = getIt<StorageService>();
        final onboardingCompleted = storage.getBool('onboarding_completed') ?? false;
        final permissionsSetupCompleted = storage.getBool('permissions_setup_completed') ?? false;
        
        if (onboardingCompleted && permissionsSetupCompleted) {
          if (!_permissionManager.hasCheckedThisSession) {
            debugPrint('[AthkarApp] Performing initial permission check');
            await _permissionManager.performInitialCheck();
          }
        }
      } catch (e) {
        debugPrint('[AthkarApp] Error checking onboarding status: $e');
      }
    });
  }

  // ==================== 🔔 دالة فحص الإشعارات المعلقة ====================
  
  /// فحص ومعالجة الإشعارات المعلقة بعد تهيئة التطبيق
  void _schedulePendingNotificationCheck() {
    // الانتظار حتى يتم تهيئة التطبيق بالكامل
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      
      try {
        final pendingHandler = PendingNotificationHandler();
        
        if (pendingHandler.hasPendingNotification()) {
          debugPrint('🔔 [AthkarApp] يوجد إشعار معلق، سيتم معالجته الآن');
          
          // الانتظار قليلاً للتأكد من اكتمال بناء الواجهة
          await Future.delayed(const Duration(milliseconds: 500));
          
          await pendingHandler.handlePendingNotification();
          
          // مسح الإشعار بعد المعالجة
          pendingHandler.clearPendingNotification();
          
        } else {
          debugPrint('📭 [AthkarApp] لا يوجد إشعار معلق');
        }
      } catch (e) {
        debugPrint('❌ [AthkarApp] خطأ في معالجة الإشعار المعلق: $e');
      }
    });
  }
  // ===========================================================================

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
            title: 'ذكرني',
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
        screen = const PermissionMonitor(
          showNotifications: true,
          child: HomeScreen(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error determining initial screen: $e');
      screen = const PermissionMonitor(
        showNotifications: true,
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