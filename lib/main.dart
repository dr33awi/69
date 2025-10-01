// lib/main.dart - محسّن مع flutter_screenutil
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
import 'features/onboarding/services/onboarding_service.dart';

/// نقطة دخول التطبيق
Future<void> main() async {
  // تهيئة ربط Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // تعيين اتجاه التطبيق
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // تشغيل التطبيق مع معالجة الأخطاء
  runZonedGuarded(
    () async {
      try {
        // تهيئة سريعة + Firebase بشكل صحيح
        await _fastBootstrap();
        
        // تشغيل التطبيق فوراً
        runApp(const AthkarApp());
        
        // تهيئة الباقي في الخلفية
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

/// تهيئة سريعة - مع Firebase Remote Config
Future<void> _fastBootstrap() async {
  debugPrint('========== Fast Bootstrap Starting ==========');
  final stopwatch = Stopwatch()..start();
  
  try {
    // 1. تهيئة Firebase FIRST
    debugPrint('🔥 تهيئة Firebase Core...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (Firebase.apps.isEmpty) {
      throw Exception('فشل في تهيئة Firebase');
    }
    debugPrint('✅ Firebase initialized. Apps: ${Firebase.apps.length}');
    
    // 2. الخدمات الأساسية
    await ServiceLocator.initEssential();
    
    // 3. تسجيل OnboardingService
    if (!getIt.isRegistered<OnboardingService>()) {
      getIt.registerLazySingleton<OnboardingService>(
        () => OnboardingService(getIt<StorageService>()),
      );
    }
    
    // 4. تهيئة Firebase Remote Config IMMEDIATELY (مهم جداً!)
    await _initializeRemoteConfigEarly();
    
    // 5. فحص جاهزية الخدمات
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

/// تهيئة Remote Config مبكراً (قبل عرض أول شاشة)
Future<void> _initializeRemoteConfigEarly() async {
  try {
    debugPrint('🔧 تهيئة Remote Config مبكراً...');
    
    // تسجيل الخدمات إذا لم تكن مسجلة
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
    
    // تهيئة Remote Config Service
    final remoteConfigService = getIt<FirebaseRemoteConfigService>();
    await remoteConfigService.initialize();
    
    // تهيئة Manager
    final configManager = getIt<RemoteConfigManager>();
    await configManager.initialize(
      remoteConfig: remoteConfigService,
      storage: getIt<StorageService>(),
    );
    
    // طباعة القيم الحالية للتأكد
    debugPrint('📊 Remote Config Status:');
    debugPrint('  - Force Update: ${remoteConfigService.isForceUpdateRequired}');
    debugPrint('  - Maintenance: ${remoteConfigService.isMaintenanceModeEnabled}');
    debugPrint('  - App Version: ${remoteConfigService.requiredAppVersion}');
    debugPrint('✅ Remote Config initialized successfully');
    
  } catch (e) {
    debugPrint('⚠️ Remote Config early init failed (non-critical): $e');
    // نستمر حتى لو فشلت - التطبيق سيعمل بدون Remote Config
  }
}

/// تهيئة الخدمات المتبقية في الخلفية
void _backgroundInitialization() {
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      debugPrint('========== Background Initialization Starting ==========');
      final stopwatch = Stopwatch()..start();
      
      // 1. تسجيل خدمات الميزات
      await ServiceLocator.registerFeatureServices();
      
      // 2. باقي Firebase services
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
  late final OnboardingService _onboardingService;
  RemoteConfigManager? _configManager;
  bool _configManagerReady = false;

  @override
  void initState() {
    super.initState();
    
    _permissionManager = getIt<UnifiedPermissionManager>();
    _onboardingService = getIt<OnboardingService>();
    
    // محاولة الحصول على Config Manager
    _initializeConfigManager();
    
    // جدولة فحص الأذونات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_onboardingService.shouldShowOnboarding) {
        _schedulePermissionCheck();
      }
    });
  }

  /// تهيئة Config Manager
  void _initializeConfigManager() {
    try {
      if (getIt.isRegistered<RemoteConfigManager>()) {
        _configManager = getIt<RemoteConfigManager>();
        
        // فحص إذا كان مُهيئاً
        if (_configManager!.isInitialized) {
          setState(() => _configManagerReady = true);
          debugPrint('✅ Config Manager ready in AthkarApp');
          
          // طباعة القيم الحالية
          debugPrint('Current Remote Config Values:');
          debugPrint('  - Force Update: ${_configManager!.isForceUpdateRequired}');
          debugPrint('  - Maintenance: ${_configManager!.isMaintenanceModeActive}');
        } else {
          debugPrint('⚠️ Config Manager registered but not initialized yet');
          
          // محاولة مرة أخرى بعد ثانية
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

  /// جدولة فحص الأذونات
  void _schedulePermissionCheck() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted && !_permissionManager.hasCheckedThisSession) {
        debugPrint('[AthkarApp] Performing initial permission check');
        await _permissionManager.performInitialCheck();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: getIt<ThemeNotifier>(),
      builder: (context, themeMode, child) {
        // تهيئة ScreenUtil
        return ScreenUtilInit(
          // حجم الشاشة المرجعي للتصميم
          designSize: const Size(375, 812), // iPhone X size كمرجع
          
          // السماح بتغيير حجم النص
          minTextAdapt: true,
          
          // تقسيم الشاشة
          splitScreenMode: true,
          
          builder: (context, child) {
            return MaterialApp(
              // معلومات التطبيق
              title: 'حصن المسلم',
              debugShowCheckedModeBanner: false,
              
              // الثيمات
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              
              // اللغة العربية
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              
              // التنقل
              navigatorKey: AppRouter.navigatorKey,
              
              // الشاشة الأولى
              home: _buildInitialScreen(),
              
              // توليد المسارات
              onGenerateRoute: AppRouter.onGenerateRoute,
              
              // Builder مع مراقب الأذونات
              builder: (context, child) {
                if (child == null) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                
                // تطبيق مراقب الأذونات على الشاشة الرئيسية فقط
                if (child is HomeScreen) {
                  return PermissionMonitor(
                    showNotifications: true,
                    child: child,
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

  /// بناء الشاشة الأولى
  Widget _buildInitialScreen() {
    Widget initialScreen;
    
    try {
      if (_onboardingService.shouldShowOnboarding) {
        debugPrint('🎯 Starting with onboarding screen');
        initialScreen = const OnboardingScreen();
      } else {
        debugPrint('🏠 Starting with home screen directly');
        initialScreen = const HomeScreen();
      }
    } catch (e) {
      debugPrint('❌ Error determining initial screen: $e');
      initialScreen = const HomeScreen();
    }
    
    // لف الشاشة بـ AppStatusMonitor إذا كان متوفراً
    return _wrapWithAppMonitor(initialScreen);
  }

  /// لف الشاشة بـ AppStatusMonitor (Force Update & Maintenance)
  Widget _wrapWithAppMonitor(Widget screen) {
    // إذا كان Config Manager جاهزاً، استخدمه
    if (_configManagerReady && _configManager != null) {
      debugPrint('✅ Wrapping with AppStatusMonitor (Config Manager ready)');
      return AppStatusMonitor(
        configManager: _configManager,
        child: screen,
      );
    }
    
    // إذا لم يكن جاهزاً بعد، عرض الشاشة مع إمكانية التحديث لاحقاً
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
                        // أيقونة الخطأ
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