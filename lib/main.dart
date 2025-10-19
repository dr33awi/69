// lib/main.dart - النسخة المُحسّنة والنهائية
import 'dart:async';
import 'dart:convert';
import 'package:athkar_app/core/firebase/remote_config_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

// Firebase Services
import 'core/firebase/firebase_initializer.dart';

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

// خدمات التطوير
import 'core/infrastructure/config/development_config.dart';
import 'core/infrastructure/services/preview/device_preview_config.dart';

// Firebase UI
import 'core/firebase/remote_config_manager.dart';
import 'core/firebase/widgets/app_status_monitor.dart';

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
        debugPrint('🚀 ========== App Starting ========== 🚀');
        
        // تهيئة سريعة وموحدة
        await _unifiedBootstrap();
        
        // إعداد معالج الإشعارات
        await _setupNotificationHandler();
        
        final app = const AthkarApp();
        final wrappedApp = DevicePreviewConfig.wrapApp(app);
        runApp(wrappedApp ?? app);
        
        // تهيئة الخدمات غير الحرجة في الخلفية
        _backgroundInitialization();
        
        debugPrint('✅ ========== App Started Successfully ========== ✅');
        
      } catch (e, s) {
        debugPrint('❌ ========== CRITICAL ERROR ========== ❌');
        debugPrint('Error: $e');
        debugPrint('Stack: $s');
        
        // تسجيل الخطأ في Crashlytics
        FirebaseCrashlytics.instance.recordError(e, s, fatal: true);
        
        runApp(_ErrorApp(error: e.toString()));
      }
    },
    (error, stack) {
      debugPrint('❌ Uncaught error: $error');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

// ==================== التهيئة الموحدة ====================
Future<void> _unifiedBootstrap() async {
  debugPrint('⚡ ========== Unified Bootstrap Starting ========== ⚡');
  final stopwatch = Stopwatch()..start();
  
  try {
    // 1. Development Config
    DevelopmentConfig.initialize();
    debugPrint('✅ [1/5] Development Config initialized');
    
    // 2. Firebase Core
    debugPrint('🔥 [2/5] Initializing Firebase Core...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (Firebase.apps.isEmpty) {
      throw Exception('❌ No Firebase apps found after initialization');
    }
    
    debugPrint('✅ [2/5] Firebase Core initialized (${Firebase.apps.length} apps)');
    
    // 3. Service Locator (الخدمات الأساسية)
    debugPrint('📦 [3/5] Initializing Service Locator...');
    await ServiceLocator.initEssential();
    
    if (!ServiceLocator.areEssentialServicesReady()) {
      throw Exception('❌ Essential services not ready');
    }
    
    debugPrint('✅ [3/5] Service Locator initialized');
    
    // 4. ✅ تهيئة Remote Config مبكراً (هام جداً!)
    debugPrint('⚙️ [4/5] Initializing Remote Config Service...');
    await _initializeRemoteConfigEarly();
    debugPrint('✅ [4/5] Remote Config Service ready');
    
    // 5. Firebase Services الأخرى
    debugPrint('🔥 [5/5] Initializing Other Firebase Services...');
    final firebaseSuccess = await FirebaseInitializer.initialize();
    
    if (firebaseSuccess) {
      debugPrint('✅ [5/5] Firebase Services initialized');
    }
    
    stopwatch.stop();
    debugPrint('⚡ ========== Bootstrap Completed in ${stopwatch.elapsedMilliseconds}ms ========== ⚡');
    
  } catch (e, s) {
    stopwatch.stop();
    debugPrint('❌ Bootstrap Failed after ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('Error: $e');
    rethrow;
  }
}

/// ✅ تهيئة Remote Config مبكراً وبشكل منفصل
Future<void> _initializeRemoteConfigEarly() async {
  try {
    // تسجيل FirebaseRemoteConfigService
    if (!getIt.isRegistered<FirebaseRemoteConfigService>()) {
      getIt.registerSingleton<FirebaseRemoteConfigService>(
        FirebaseRemoteConfigService(),
      );
    }
    
    // تهيئة الخدمة
    final remoteConfig = getIt<FirebaseRemoteConfigService>();
    await remoteConfig.initialize();
    
    // تسجيل RemoteConfigManager
    if (!getIt.isRegistered<RemoteConfigManager>()) {
      getIt.registerSingleton<RemoteConfigManager>(
        RemoteConfigManager(),
      );
    }
    
    // تهيئة Manager
    final configManager = getIt<RemoteConfigManager>();
    final storage = getIt<StorageService>();
    
    await configManager.initialize(
      remoteConfig: remoteConfig,
      storage: storage,
    );
    
    debugPrint('✅ Remote Config fully initialized:');
    debugPrint('  - Force Update: ${configManager.isForceUpdateRequired}');
    debugPrint('  - Maintenance: ${configManager.isMaintenanceModeActive}');
    debugPrint('  - App Version: ${configManager.requiredAppVersion}');
    
  } catch (e) {
    debugPrint('⚠️ Remote Config init failed (non-critical): $e');
    // لا نوقف التطبيق، نستمر مع القيم الافتراضية
  }
}

// ✅ تعديل _backgroundInitialization لتجنب التكرار
void _backgroundInitialization() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      debugPrint('🌟 ========== Background Init Starting ========== 🌟');
      final stopwatch = Stopwatch()..start();
      
      // 1. تسجيل خدمات الميزات (Lazy)
      await ServiceLocator.registerFeatureServices();
      debugPrint('✅ [1/3] Feature services registered (lazy)');
      
      // 2. ✅ تحديث Firebase Services (بدون إعادة تهيئة Remote Config)
      if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final remoteConfig = getIt<FirebaseRemoteConfigService>();
        
        // تحديث فقط إذا لم تكن محدثة
        if (remoteConfig.isInitialized) {
          final timeSinceLastFetch = DateTime.now().difference(remoteConfig.lastFetchTime);
          if (timeSinceLastFetch.inMinutes > 5) {
            await remoteConfig.refresh();
            debugPrint('✅ [2/3] Remote Config refreshed in background');
          }
        }
      }
      
      // 3. Advanced Firebase (Analytics, Performance)
      await ServiceLocator.initializeAdvancedFirebaseServices();
      debugPrint('✅ [3/3] Advanced Firebase services initialized');
      
      stopwatch.stop();
      debugPrint('🌟 ========== Background Init Completed in ${stopwatch.elapsedMilliseconds}ms ========== 🌟');
      
    } catch (e) {
      debugPrint('⚠️ Background init warning: $e');
    }
  });
}
// ==================== فحص الإشعار الأولي ====================
Future<void> _checkInitialNotification() async {
  try {
    debugPrint('🔍 Checking initial notification...');
    
    final plugin = FlutterLocalNotificationsPlugin();
    _notificationAppLaunchDetails = await plugin.getNotificationAppLaunchDetails();
    
    if (_notificationAppLaunchDetails?.didNotificationLaunchApp == true) {
      final response = _notificationAppLaunchDetails!.notificationResponse;
      
      if (response?.payload != null) {
        debugPrint('📱 App launched from notification!');
        
        try {
          final payloadData = jsonDecode(response!.payload!);
          _pendingNotificationEvent = NotificationTapEvent(
            notificationId: payloadData['id'] ?? 'unknown',
            category: NotificationCategory.values[payloadData['category'] ?? 0],
            payload: payloadData['payload'] ?? {},
          );
          
          debugPrint('✅ Pending notification saved for processing');
        } catch (e) {
          debugPrint('⚠️ Error parsing notification payload: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('⚠️ Error checking initial notification: $e');
  }
}

// ==================== إعداد معالج الإشعارات ====================
Future<void> _setupNotificationHandler() async {
  try {
    debugPrint('🔔 Setting up notification handler...');
    
    final handler = NotificationTapHandler(
      navigatorKey: AppRouter.navigatorKey,
    );
    
    // معالجة الإشعار المعلق
    if (_pendingNotificationEvent != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_pendingNotificationEvent != null) {
          handler.handleNotificationTap(_pendingNotificationEvent!);
          _pendingNotificationEvent = null;
        }
      });
    }
    
    // الاستماع للإشعارات الجديدة
    NotificationManager.instance.onTap.listen(
      handler.handleNotificationTap,
      onError: (error) => debugPrint('❌ Notification handler error: $error'),
      cancelOnError: false,
    );
    
    debugPrint('✅ Notification handler ready');
    
  } catch (e, s) {
    debugPrint('❌ Failed to setup notification handler: $e');
    debugPrint('Stack: $s');
  }
}

// ==================== التطبيق الرئيسي ====================
class AthkarApp extends StatefulWidget {
  const AthkarApp({super.key});

  @override
  State<AthkarApp> createState() => _AthkarAppState();
}

class _AthkarAppState extends State<AthkarApp> with WidgetsBindingObserver {
  RemoteConfigManager? _configManager;
  bool _configManagerReady = false;
  late final UnifiedPermissionManager _permissionManager;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processPendingNotificationIfAny();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    _permissionManager = getIt<UnifiedPermissionManager>();
    
    _initializeConfigManager();
    _scheduleInitialPermissionCheck();
    _processPendingNotificationIfAny();
  }

  void _processPendingNotificationIfAny() {
    if (_pendingNotificationEvent != null) {
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
          debugPrint('✅ Config Manager ready');
        } else {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _configManager!.isInitialized) {
              setState(() => _configManagerReady = true);
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
        final permissionsCompleted = storage.getBool('permissions_setup_completed') ?? false;
        
        if (onboardingCompleted && permissionsCompleted) {
          if (!_permissionManager.hasCheckedThisSession) {
            await _permissionManager.performInitialCheck();
          }
        }
      } catch (e) {
        debugPrint('⚠️ Permission check error: $e');
      }
    });
  }

  Widget _buildInitialScreen() {
    Widget screen;
    bool skipPermissionCheck = false;
    
    try {
      final storage = getIt<StorageService>();
      final onboardingCompleted = storage.getBool('onboarding_completed') ?? false;
      final permissionsCompleted = storage.getBool('permissions_setup_completed') ?? false;
      
      if (!onboardingCompleted) {
        return const OnboardingScreen();
      } else if (!permissionsCompleted) {
        return const PermissionsSetupScreen();
      } else {
        skipPermissionCheck = _permissionManager.hasCheckedThisSession;
        screen = PermissionMonitor(
          showNotifications: true,
          skipInitialCheck: skipPermissionCheck,
          child: const HomeScreen(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error determining screen: $e');
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
      return AppStatusMonitor(
        configManager: _configManager,
        child: screen,
      );
    }
    return screen;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: getIt<ThemeNotifier>(),
      builder: (context, themeMode, _) {
        return ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) {
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
                return child ?? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==================== شاشة الخطأ ====================
class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80.sp, color: Colors.red),
                        SizedBox(height: 24.h),
                        Text(
                          'عذراً، حدث خطأ',
                          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'يرجى إعادة المحاولة',
                          style: TextStyle(fontSize: 16.sp),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32.h),
                        ElevatedButton.icon(
                          onPressed: () => main(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
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