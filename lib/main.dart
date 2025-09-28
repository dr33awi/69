// lib/main.dart - محدث مع نظام Onboarding

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

// الثيمات والمسارات
import 'app/themes/app_theme.dart';
import 'app/routes/app_router.dart';

// الشاشات
import 'features/home/screens/home_screen.dart';
import 'features/onboarding/screens/onboarding_flow_screen.dart';

/// نقطة دخول التطبيق - محسن مع نظام Onboarding
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
        // تهيئة سريعة جداً (< 300ms)
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

/// تهيئة سريعة جداً - أقل من 300ms
Future<void> _fastBootstrap() async {
  debugPrint('========== Fast Bootstrap Starting ==========');
  final stopwatch = Stopwatch()..start();
  
  try {
    // 1. Firebase Core فقط (سريع)
    debugPrint('تهيئة Firebase Core...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 2. الخدمات الأساسية فقط
    await ServiceLocator.initEssential();
    
    // 3. فحص جاهزية الخدمات الأساسية
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
  Future.delayed(const Duration(milliseconds: 800), () async {
    try {
      debugPrint('========== Background Initialization Starting ==========');
      final stopwatch = Stopwatch()..start();
      
      // 1. تسجيل خدمات الميزات (بدون تهيئة فعلية)
      await ServiceLocator.registerFeatureServices();
      
      // 2. Firebase services في الخلفية
      try {
        await ServiceLocator.initializeFirebaseInBackground();
        debugPrint('✅ Firebase services initialized in background');
      } catch (e) {
        debugPrint('⚠️ Firebase background init warning: $e');
      }
      
      // 3. Firebase additional services
      try {
        await FirebaseInitializer.initialize();
        debugPrint('✅ Firebase additional services initialized');
      } catch (e) {
        debugPrint('⚠️ Firebase additional services warning: $e');
      }
      
      stopwatch.stop();
      debugPrint('========== Background Initialization Completed in ${stopwatch.elapsedMilliseconds}ms 🚀 ==========');
      
    } catch (e) {
      debugPrint('❌ Background initialization error: $e');
    }
  });
}

/// التطبيق الرئيسي مع نظام Onboarding
class AthkarApp extends StatefulWidget {
  const AthkarApp({super.key});

  @override
  State<AthkarApp> createState() => _AthkarAppState();
}

class _AthkarAppState extends State<AthkarApp> {
  late final UnifiedPermissionManager _permissionManager;
  late final StorageService _storage;
  
  bool? _shouldShowOnboarding;

  @override
  void initState() {
    super.initState();
    
    _permissionManager = getIt<UnifiedPermissionManager>();
    _storage = getIt<StorageService>();
    
    _checkOnboardingStatus();
  }

  /// فحص حالة الـ Onboarding
  Future<void> _checkOnboardingStatus() async {
    try {
      // فحص إذا كان الـ onboarding مكتمل
      final isCompleted = _storage.getBool('onboarding_completed') ?? false;
      
      setState(() {
        _shouldShowOnboarding = !isCompleted;
      });
      
      debugPrint('Onboarding status: ${isCompleted ? 'Completed' : 'Needed'}');
      
      // إذا كان مكتمل، قم بالفحص التلقائي للأذونات
      if (isCompleted) {
        _schedulePermissionCheck();
      }
      
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      // في حالة الخطأ، افترض أنه يحتاج onboarding
      setState(() {
        _shouldShowOnboarding = true;
      });
    }
  }

  /// جدولة فحص الأذونات للمستخدمين المُكملين للـ onboarding
  void _schedulePermissionCheck() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted && !_permissionManager.hasCheckedThisSession) {
        debugPrint('[AthkarApp] Performing delayed permission check for existing user');
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
          
          // الشاشة الرئيسية (مع تحديد onboarding)
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
            
            // تطبيق مراقب الأذونات فقط إذا لم يكن onboarding
            if (_shouldShowOnboarding == false) {
              return PermissionMonitor(
                showNotifications: true,
                child: child,
              );
            }
            
            // إذا كان onboarding، لا تطبق المراقب
            return child;
          },
        );
      },
    );
  }

  /// بناء الشاشة الأولية حسب حالة الـ onboarding
  Widget _buildInitialScreen() {
    // أثناء فحص الحالة، عرض شاشة تحميل
    if (_shouldShowOnboarding == null) {
      return const _LoadingScreen();
    }
    
    // إذا كان يحتاج onboarding
    if (_shouldShowOnboarding == true) {
      return const OnboardingFlowScreen();
    }
    
    // إذا كان مكتمل، اعرض الشاشة الرئيسية
    return const HomeScreen();
  }
}

/// شاشة التحميل الأولية
class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF5D7052), Color(0xFF7A8B6F)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // اللوجو المتحرك
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
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
              
              // الوصف
              Text(
                'رفيقك الروحاني اليومي',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontFamily: 'Cairo',
                ),
              ),
              
              const SizedBox(height: 48),
              
              // مؤشر التحميل
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
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