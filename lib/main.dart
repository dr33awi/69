// lib/main.dart - محسّن مع دعم Offline Mode
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:athkar_app/core/firebase/promotional_banners/promotional_banner_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

import 'core/firebase/firebase_initializer.dart';

import 'app/di/service_locator.dart';
import 'app/themes/core/theme_notifier.dart';

import 'core/infrastructure/services/storage/storage_service.dart';

import 'core/infrastructure/services/notifications/notification_manager.dart';
import 'core/infrastructure/services/notifications/notification_tap_handler.dart';
import 'core/infrastructure/services/notifications/models/notification_models.dart';

import 'core/infrastructure/config/development_config.dart';
import 'core/infrastructure/services/preview/device_preview_config.dart';

import 'core/firebase/remote_config_manager.dart';

import 'app/themes/app_theme.dart';
import 'app/routes/app_router.dart';

import 'features/home/screens/home_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/screens/permissions_setup_screen.dart';
import 'core/infrastructure/services/permissions/widgets/permission_check_widget.dart';


NotificationAppLaunchDetails? _notificationAppLaunchDetails;
NotificationTapEvent? _pendingNotificationEvent;
bool _isOfflineMode = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await _checkInitialNotification();
  
  runZonedGuarded(
    () async {
      try {
        debugPrint('🚀 ========== App Starting ========== 🚀');
        
        // ✅ التحقق من الاتصال بالإنترنت
        final hasConnection = await _checkInternetConnection();
        
        if (!hasConnection) {
          debugPrint('⚠️ No internet connection detected - Starting in OFFLINE MODE');
          _isOfflineMode = true;
        }
        
        // ✅ التهيئة مع معالجة الوضع Offline
        await _unifiedBootstrap(isOffline: _isOfflineMode);
        await _setupNotificationHandler();
        
        final app = const AthkarApp();
        final wrappedApp = DevicePreviewConfig.wrapApp(app);
        runApp(wrappedApp ?? app);
        
        // ✅ تأجيل Firebase للخلفية إذا كنا online
        if (!_isOfflineMode) {
          _backgroundInitialization();
        } else {
          // في حالة offline، حاول التهيئة لاحقاً عند عودة الإنترنت
          _scheduleFirebaseRetry();
        }
        
        debugPrint('✅ ========== App Started Successfully ========== ✅');
        
      } catch (e, s) {
        debugPrint('❌ ========== CRITICAL ERROR ========== ❌');
        debugPrint('Error: $e');
        debugPrint('Stack: $s');
        
        // في حالة الخطأ، حاول العمل بدون Firebase
        try {
          await _fallbackBootstrap();
          runApp(const AthkarApp());
        } catch (fallbackError) {
          runApp(_ErrorApp(error: e.toString()));
        }
      }
    },
    (error, stack) {
      debugPrint('❌ Uncaught error: $error');
      // لا نسجل في Crashlytics إذا كنا offline
      if (!_isOfflineMode) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (_) {}
      }
    },
  );
}

// ==================== فحص الاتصال بالإنترنت ====================
Future<bool> _checkInternetConnection() async {
  try {
    // Method 1: استخدام Connectivity Plus
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    
    // Method 2: محاولة الاتصال بـ Google DNS
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
        onTimeout: () => [],
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  } catch (e) {
    debugPrint('⚠️ Error checking internet: $e');
    return false; // افترض عدم وجود اتصال في حالة الخطأ
  }
}

// ==================== التهيئة الموحدة مع دعم Offline ====================
Future<void> _unifiedBootstrap({bool isOffline = false}) async {
  debugPrint('⚡ ========== Unified Bootstrap Starting (Offline: $isOffline) ========== ⚡');
  final stopwatch = Stopwatch()..start();
  
  try {
    // 1. Development Config - يعمل دائماً
    DevelopmentConfig.initialize();
    debugPrint('✅ [1/4] Development Config initialized');
    
    // 2. Firebase Core - مشروط بوجود إنترنت
    if (!isOffline) {
      debugPrint('🔥 [2/4] Initializing Firebase Core...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Firebase initialization timeout');
          },
        );
        
        if (Firebase.apps.isEmpty) {
          throw Exception('No Firebase apps found');
        }
        
        debugPrint('✅ [2/4] Firebase Core initialized (${Firebase.apps.length} apps)');
      } catch (firebaseError) {
        debugPrint('⚠️ Firebase initialization failed: $firebaseError');
        debugPrint('⚠️ Continuing in offline mode...');
        _isOfflineMode = true;
      }
    } else {
      debugPrint('⏭️ [2/4] Skipping Firebase (Offline mode)');
    }
    
    // 3. Service Locator - الخدمات الأساسية (تعمل بدون إنترنت)
    debugPrint('📦 [3/4] Initializing Service Locator...');
    await ServiceLocator.initEssential();
    
    if (!ServiceLocator.areEssentialServicesReady()) {
      throw Exception('Essential services not ready');
    }
    
    debugPrint('✅ [3/4] Service Locator initialized');
    
    // 4. Firebase Services - فقط إذا كنا online
    if (!_isOfflineMode) {
      debugPrint('🔥 [4/4] Initializing Firebase Services...');
      try {
        await _initializeFirebaseServicesEarly();
        debugPrint('✅ [4/4] Firebase Services ready');
      } catch (e) {
        debugPrint('⚠️ [4/4] Firebase Services failed (non-critical): $e');
      }
    } else {
      debugPrint('⏭️ [4/4] Skipping Firebase Services (Offline mode)');
    }
    
    stopwatch.stop();
    debugPrint('⚡ ========== Bootstrap Completed in ${stopwatch.elapsedMilliseconds}ms ========== ⚡');
    
  } catch (e) {
    stopwatch.stop();
    debugPrint('❌ Bootstrap Failed after ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('Error: $e');
    
    // في حالة الفشل، حاول التهيئة الاحتياطية
    if (!_isOfflineMode) {
      debugPrint('🔄 Attempting fallback bootstrap...');
      await _fallbackBootstrap();
    } else {
      rethrow;
    }
  }
}

// ==================== التهيئة الاحتياطية ====================
Future<void> _fallbackBootstrap() async {
  debugPrint('🔄 ========== Fallback Bootstrap ========== 🔄');
  _isOfflineMode = true;
  
  try {
    // تهيئة الخدمات الأساسية فقط
    DevelopmentConfig.initialize();
    await ServiceLocator.initEssential();
    
    debugPrint('✅ Fallback bootstrap successful - Running in OFFLINE mode');
  } catch (e) {
    debugPrint('❌ Even fallback bootstrap failed: $e');
    rethrow;
  }
}

// ==================== جدولة إعادة محاولة Firebase ====================
void _scheduleFirebaseRetry() {
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (!_isOfflineMode) {
      timer.cancel();
      return;
    }
    
    debugPrint('🔄 Retrying Firebase initialization...');
    
    final hasConnection = await _checkInternetConnection();
    if (hasConnection) {
      try {
        // محاولة تهيئة Firebase
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        
        // تهيئة خدمات Firebase
        await ServiceLocator.initializeFirebaseInBackground();
        
        _isOfflineMode = false;
        timer.cancel();
        
        debugPrint('✅ Firebase initialized successfully after retry');
        
        // تشغيل التهيئة الخلفية
        _backgroundInitialization();
        
      } catch (e) {
        debugPrint('⚠️ Firebase retry failed: $e');
      }
    }
  });
}

// ==================== تهيئة Firebase Services ====================
Future<void> _initializeFirebaseServicesEarly() async {
  if (_isOfflineMode) return;
  
  try {
    final stopwatch = Stopwatch()..start();
    
    // تهيئة Firebase الأساسية مع timeout
    final firebaseSuccess = await FirebaseInitializer.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ Firebase initialization timeout');
        return false;
      },
    );
    
    if (!firebaseSuccess) {
      debugPrint('⚠️ Firebase initialization returned false');
      return;
    }
    
    // تهيئة Firebase Services من ServiceLocator
    if (ServiceLocator.isFirebaseAvailable) {
      await ServiceLocator.initializeFirebaseInBackground();
      
      stopwatch.stop();
      debugPrint('✅ Firebase Services initialized in ${stopwatch.elapsedMilliseconds}ms');
      
      // طباعة حالة البانرات
      if (getIt.isRegistered<PromotionalBannerManager>()) {
        final bannerManager = getIt<PromotionalBannerManager>();
        if (bannerManager.isInitialized) {
          debugPrint('📊 Banners Status:');
          debugPrint('  - Total: ${bannerManager.allBanners.length}');
          debugPrint('  - Active: ${bannerManager.activeBannersCount}');
        }
      }
    } else {
      debugPrint('⚠️ Firebase not available');
    }
    
  } catch (e) {
    debugPrint('⚠️ Firebase Services init warning: $e');
  }
}

// ==================== التهيئة الخلفية ====================
void _backgroundInitialization() {
  if (_isOfflineMode) return;
  
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      debugPrint('🌟 ========== Background Init Starting ========== 🌟');
      final stopwatch = Stopwatch()..start();
      
      // 1. تسجيل خدمات الميزات
      await ServiceLocator.registerFeatureServices();
      debugPrint('✅ [1/2] Feature services registered');
      
      // 2. Advanced Firebase (Analytics, Performance) - فقط إذا كنا online
      if (!_isOfflineMode) {
        await ServiceLocator.initializeAdvancedFirebaseServices();
        debugPrint('✅ [2/2] Advanced Firebase services initialized');
      }
      
      stopwatch.stop();
      debugPrint('🌟 ========== Background Init Completed in ${stopwatch.elapsedMilliseconds}ms ========== 🌟');
      
    } catch (e) {
      debugPrint('⚠️ Background init warning: $e');
    }
  });
}

// ==================== معالج الإشعارات ====================
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

Future<void> _setupNotificationHandler() async {
  try {
    debugPrint('🔔 Setting up notification handler...');
    
    final handler = NotificationTapHandler(
      navigatorKey: AppRouter.navigatorKey,
    );
    
    if (_pendingNotificationEvent != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_pendingNotificationEvent != null) {
          handler.handleNotificationTap(_pendingNotificationEvent!);
          _pendingNotificationEvent = null;
        }
      });
    }
    
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

// ==================== Widget للأخطاء ====================
class _ErrorApp extends StatelessWidget {
  final String error;
  
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'حدث خطأ في تشغيل التطبيق',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'يرجى إعادة تشغيل التطبيق',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      error,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade800,
                      ),
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
  StreamSubscription? _connectivitySubscription;
  bool _hasShownOfflineMessage = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
    _initializeConfigManager();
    _scheduleInitialPermissionCheck();
    _processPendingNotificationIfAny();
    _monitorConnectivity();
    
    // عرض رسالة الوضع Offline إذا لزم الأمر
    if (_isOfflineMode && !_hasShownOfflineMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOfflineMessage();
      });
    }
  }

  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
      if (!result.contains(ConnectivityResult.none) && _isOfflineMode) {
        debugPrint('📡 Internet connection restored!');
        
        // محاولة تهيئة Firebase إذا لم تكن مهيأة
        if (Firebase.apps.isEmpty) {
          try {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
            await ServiceLocator.initializeFirebaseInBackground();
            _isOfflineMode = false;
            
            if (mounted) {
              _showOnlineMessage();
            }
          } catch (e) {
            debugPrint('⚠️ Failed to initialize Firebase after reconnection: $e');
          }
        }
      } else if (result.contains(ConnectivityResult.none) && !_isOfflineMode) {
        debugPrint('📡 Internet connection lost!');
        _isOfflineMode = true;
        
        if (mounted && !_hasShownOfflineMessage) {
          _showOfflineMessage();
        }
      }
    });
  }

  void _showOfflineMessage() {
    if (!mounted) return;
    
    _hasShownOfflineMessage = true;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'التطبيق يعمل بدون اتصال بالإنترنت',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _showOnlineMessage() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'تم استعادة الاتصال بالإنترنت',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processPendingNotificationIfAny();
      
      // فحص الاتصال عند العودة للتطبيق
      _checkAndUpdateConnectivity();
    }
  }

  Future<void> _checkAndUpdateConnectivity() async {
    final hasConnection = await _checkInternetConnection();
    
    if (hasConnection && _isOfflineMode) {
      // عاد الإنترنت
      _isOfflineMode = false;
      _showOnlineMessage();
      
      // محاولة تهيئة Firebase إذا لم تكن مهيأة
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          await ServiceLocator.initializeFirebaseInBackground();
        } catch (e) {
          debugPrint('⚠️ Failed to initialize Firebase: $e');
        }
      }
    } else if (!hasConnection && !_isOfflineMode) {
      // فقدان الإنترنت
      _isOfflineMode = true;
      _showOfflineMessage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    super.dispose();
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
    // لا نهيئ ConfigManager في وضع Offline
    if (_isOfflineMode) return;
    
    try {
      if (getIt.isRegistered<RemoteConfigManager>()) {
        _configManager = getIt<RemoteConfigManager>();
        
        if (_configManager!.isInitialized) {
          debugPrint('✅ Config Manager ready');
        } else {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && _configManager!.isInitialized) {
              debugPrint('✅ Config Manager ready (delayed)');
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
          debugPrint('✅ Permissions already completed - using new simple system');
        }
      } catch (e) {
        debugPrint('⚠️ Permission check error: $e');
      }
    });
  }

  Widget _buildInitialScreen() {
    try {
      final storage = getIt<StorageService>();
      final onboardingCompleted = storage.getBool('onboarding_completed') ?? false;
      final permissionsCompleted = storage.getBool('permissions_setup_completed') ?? false;
      
      if (!onboardingCompleted) {
        return const OnboardingScreen();
      } else if (!permissionsCompleted) {
        return const PermissionsSetupScreen();
      } else {
        return const HomeScreen();
      }
    } catch (e) {
      debugPrint('❌ Error determining screen: $e');
      return const HomeScreen();
    }
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
                return PermissionCheckWidget(
                  showWarningCard: true,
                  child: child ?? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}