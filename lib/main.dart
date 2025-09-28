// lib/main.dart - محدث مع نظام Onboarding و Firebase صحيح

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
import 'core/infrastructure/firebase/firebase_initializer.dart';
import 'core/infrastructure/firebase/firebase_messaging_service.dart';
import 'core/infrastructure/firebase/remote_config_service.dart';

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
    
    // فحص الخدمات المسجلة
    final hasMessaging = getIt.isRegistered<FirebaseMessagingService>();
    final hasRemoteConfig = getIt.isRegistered<FirebaseRemoteConfigService>();
    
    debugPrint('Firebase Messaging Service: ${hasMessaging ? "مسجلة" : "غير مسجلة"}');
    debugPrint('Firebase Remote Config Service: ${hasRemoteConfig ? "مسجلة" : "غير مسجلة"}');
    
    debugPrint('=====================================');
    
  } catch (e) {
    debugPrint('Error printing Firebase status: $e');
  }
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
  
  Widget? _initialScreen;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    
    _permissionManager = getIt<UnifiedPermissionManager>();
    _onboardingService = getIt<OnboardingService>();
    
    _determineInitialScreen();
  }

  /// تحديد الشاشة الأولى
  void _determineInitialScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // فحص إذا كان يحتاج onboarding
        if (_onboardingService.shouldShowOnboarding) {
          debugPrint('🎯 Showing onboarding screen');
          setState(() {
            _initialScreen = const OnboardingScreen();
            _isInitializing = false;
          });
        } else {
          debugPrint('🏠 Showing home screen directly');
          setState(() {
            _initialScreen = const HomeScreen();
            _isInitializing = false;
          });
          
          // فحص الأذونات إذا لم يكن onboarding
          _schedulePermissionCheck();
        }
      } catch (e) {
        debugPrint('❌ Error determining initial screen: $e');
        // في حالة الخطأ، انتقل للشاشة الرئيسية
        setState(() {
          _initialScreen = const HomeScreen();
          _isInitializing = false;
        });
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
          
          // الشاشة الأولى
          home: _isInitializing ? const _SplashScreen() : _initialScreen,
          
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
}

/// شاشة تحميل بسيطة
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // شعار التطبيق
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.mosque,
                color: Colors.white,
                size: 60,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // اسم التطبيق
            const Text(
              'حصن المسلم',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            
            const SizedBox(height: 8),
            
            // وصف مختصر
            Text(
              'رفيقك في الذكر والدعاء',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
                fontFamily: 'Cairo',
              ),
            ),
            
            const SizedBox(height: 48),
            
            // مؤشر التحميل
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                    
                    const SizedBox(height: 24),
                    
                    // تفاصيل الخطأ
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفاصيل الخطأ:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
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