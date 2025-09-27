// lib/main.dart - محسن نهائياً مع Lazy Loading حقيقي

import 'dart:async';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
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
import 'core/infrastructure/services/permissions/screens/permission_onboarding_screen.dart';

// Firebase services
import 'core/infrastructure/firebase/firebase_initializer.dart';

// الثيمات والمسارات
import 'app/themes/app_theme.dart';
import 'app/routes/app_router.dart';

// الشاشات
import 'features/home/screens/home_screen.dart';

/// نقطة دخول التطبيق - محسن نهائياً للسرعة القصوى
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
        runApp(AthkarApp());
        
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

/// تهيئة الخدمات المتبقية في الخلفية (بعد ظهور الواجهة)
void _backgroundInitialization() {
  // تأخير قصير للسماح للواجهة بالظهور
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
      debugPrint('App is now fully ready with all services registered lazily!');
      
    } catch (e) {
      debugPrint('❌ Background initialization error: $e');
      // لا نوقف التطبيق، فقط نسجل الخطأ
    }
  });
}

/// تطبيق محسن مع Lazy Loading حقيقي
class AthkarApp extends StatefulWidget {
  const AthkarApp({super.key});

  @override
  State<AthkarApp> createState() => _AthkarAppState();
}

class _AthkarAppState extends State<AthkarApp> {
  late final UnifiedPermissionManager _permissionManager;
  bool _enableMonitor = true;
  String? _initialRoute;
  
  @override
  void initState() {
    super.initState();
    
    _permissionManager = getIt<UnifiedPermissionManager>();
    _initialRoute = _determineInitialRoute();
    
    // إعداد المراقب
    if (_permissionManager.isNewUser) {
      _enableMonitor = false;
    } else {
      _scheduleInitialCheck();
    }
  }
  
  /// تحديد المسار الأولي
  String _determineInitialRoute() {
    if (_permissionManager.isNewUser) {
      debugPrint('مستخدم جديد - عرض شاشة Onboarding');
      return '/onboarding';
    }
    
    debugPrint('مستخدم عائد - عرض الشاشة الرئيسية');
    return AppRouter.home;
  }
  
  /// جدولة الفحص الأولي مع تأخير
  void _scheduleInitialCheck() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted && !_permissionManager.hasCheckedThisSession) {
        debugPrint('[AthkarApp] Performing delayed permission check');
        await _permissionManager.performInitialCheck();
      }
    });
  }
  
  /// تفعيل المراقب بعد Onboarding
  void _enableMonitorAfterOnboarding() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _enableMonitor = true;
        });
        debugPrint('[AthkarApp] Monitor enabled after onboarding');
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
          title: 'تطبيق الأذكار',
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
          initialRoute: _initialRoute,
          
          // المسارات
          routes: {
            AppRouter.home: (context) => const HomeScreen(),
            '/onboarding': (context) => _OnboardingWrapper(
              onComplete: _enableMonitorAfterOnboarding,
            ),
          },
          
          // توليد المسارات
          onGenerateRoute: AppRouter.onGenerateRoute,
          
          // Builder مع مراقب الأذونات
          builder: (context, child) {
            if (child == null) return const SizedBox();
            
            // عدم تطبيق المراقب على Onboarding
            final currentRoute = ModalRoute.of(context)?.settings.name;
            if (currentRoute == '/onboarding') {
              return child;
            }
            
            // تطبيق المراقب إذا كان مفعلاً
            if (_enableMonitor) {
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

/// Wrapper محسن لشاشة Onboarding
class _OnboardingWrapper extends StatelessWidget {
  final VoidCallback? onComplete;
  
  const _OnboardingWrapper({this.onComplete});
  
  @override
  Widget build(BuildContext context) {
    final permissionService = getIt<PermissionService>();
    final permissionManager = getIt<UnifiedPermissionManager>();
    
    return PermissionOnboardingScreen(
      permissionService: permissionService,
      onComplete: (result) async {
        await permissionManager.completeOnboarding(
          skipped: result.skipped,
          grantedPermissions: result.selectedPermissions,
        );
        
        onComplete?.call();
        
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.home,
            (route) => false,
          );
        }
      },
    );
  }
}

/// شاشة الخطأ محسنة
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
                    // أيقونة الخطأ مع حركة
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
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
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // النص
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
                    
                    const SizedBox(height: 32),
                    
                    // تفاصيل الخطأ
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'تفاصيل تقنية',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              error,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // زر إعادة المحاولة
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
                          elevation: 2,
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