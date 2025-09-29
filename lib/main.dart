// lib/main.dart - بدون سبلاش سكرين
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
        // تهيئة سريعة جداً (< 500ms)
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

/// تهيئة سريعة جداً - أقل من 500ms
Future<void> _fastBootstrap() async {
  debugPrint('========== Fast Bootstrap Starting ==========');
  final stopwatch = Stopwatch()..start();
  
  try {
    // 1. تهيئة Firebase بشكل صحيح
    debugPrint('تهيئة Firebase Core...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // فحص نجاح تهيئة Firebase
    if (Firebase.apps.isEmpty) {
      throw Exception('فشل في تهيئة Firebase');
    }
    
    debugPrint('Firebase initialized successfully. Apps: ${Firebase.apps.length}');
    
    // 2. الخدمات الأساسية فقط
    await ServiceLocator.initEssential();
    
    // 3. تسجيل OnboardingService
    if (!getIt.isRegistered<OnboardingService>()) {
      getIt.registerLazySingleton<OnboardingService>(
        () => OnboardingService(getIt<StorageService>()),
      );
    }
    
    // 4. فحص جاهزية الخدمات الأساسية
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

/// تهيئة الخدمات المتبقية في الخلفية
void _backgroundInitialization() {
  Future.delayed(const Duration(milliseconds: 1000), () async {
    try {
      debugPrint('========== Background Initialization Starting ==========');
      final stopwatch = Stopwatch()..start();
      
      // 1. تسجيل خدمات الميزات (بدون تهيئة فعلية)
      await ServiceLocator.registerFeatureServices();
      
      // 2. Firebase services في الخلفية مع فحص صحيح
      try {
        await _initializeFirebaseServices();
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

/// تهيئة خدمات Firebase بشكل صحيح
Future<void> _initializeFirebaseServices() async {
  try {
    // فحص إذا كان Firebase مُهيأ
    if (Firebase.apps.isEmpty) {
      debugPrint('Firebase not initialized, skipping services');
      return;
    }
    
    // تهيئة Firebase services عبر Service Locator
    await ServiceLocator.initializeFirebaseInBackground();
    
    // طباعة حالة الخدمات للتشخيص
    _printFirebaseStatus();
    
  } catch (e) {
    debugPrint('Error initializing Firebase services: $e');
  }
}

/// طباعة حالة Firebase للتشخيص
void _printFirebaseStatus() {
  try {
    debugPrint('========== Firebase Status ==========');
    debugPrint('Firebase Apps: ${Firebase.apps.length}');
    
    for (final app in Firebase.apps) {
      debugPrint('App: ${app.name}, Options: ${app.options.projectId}');
    }
    
    debugPrint('=====================================');
    
  } catch (e) {
    debugPrint('Error printing Firebase status: $e');
  }
}

/// التطبيق الرئيسي - بدون سبلاش سكرين
class AthkarApp extends StatefulWidget {
  const AthkarApp({super.key});

  @override
  State<AthkarApp> createState() => _AthkarAppState();
}

class _AthkarAppState extends State<AthkarApp> {
  late final UnifiedPermissionManager _permissionManager;
  late final OnboardingService _onboardingService;

  @override
  void initState() {
    super.initState();
    
    _permissionManager = getIt<UnifiedPermissionManager>();
    _onboardingService = getIt<OnboardingService>();
    
    // جدولة فحص الأذونات إذا لم يكن onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_onboardingService.shouldShowOnboarding) {
        _schedulePermissionCheck();
      }
    });
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
        return MaterialApp(
          // معلومات التطبيق
          title: 'حصن المسلم',
          debugShowCheckedModeBanner: false,
          
          // الثيمات
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          
          // اللغة العربية فقط
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          
          // التنقل
          navigatorKey: AppRouter.navigatorKey,
          
          // الشاشة الأولى مباشرة (بدون سبلاش)
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
            
            // تطبيق مراقب الأذونات فقط على الشاشة الرئيسية
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
  }

  /// بناء الشاشة الأولى مباشرة
  Widget _buildInitialScreen() {
    // تحديد الشاشة المناسبة مباشرة
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
      // في حالة الخطأ، انتقل للشاشة الرئيسية
      initialScreen = const HomeScreen();
    }
    
    // إضافة مراقب التحديث إذا كان متوفراً
    return _wrapWithAppMonitor(initialScreen);
  }

  /// إضافة مراقب التحديث إذا كان متوفراً
  Widget _wrapWithAppMonitor(Widget screen) {
    try {
      final configManager = getIt.isRegistered<RemoteConfigManager>() 
          ? getIt<RemoteConfigManager>() 
          : null;
      
      if (configManager != null && configManager.isInitialized) {
        return AppStatusMonitor(
          configManager: configManager,
          child: screen,
        );
      }
    } catch (e) {
      debugPrint('Remote Config Manager not available: $e');
    }
    
    // إذا لم يكن Remote Config متوفر، عرض الشاشة مباشرة
    return screen;
  }
}

/// شاشة الخطأ
class _ErrorApp extends StatelessWidget {
  final String error;
  
  const _ErrorApp({required this.error});
  
  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة الخطأ
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red.shade700,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    const Text(
                      'عذراً، حدث خطأ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'حدث خطأ أثناء تهيئة التطبيق\nيرجى إعادة المحاولة',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                        height: 1.5,
                        fontFamily: 'Cairo',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => main(),
                        icon: const Icon(Icons.refresh, size: 24),
                        label: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
  }
}