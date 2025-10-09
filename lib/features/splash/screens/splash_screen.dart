// lib/features/splash/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/routes/app_router.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/permission_manager.dart';

/// شاشة البداية مع تحسينات بصرية
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. الانتظار لإظهار الشاشة
      await Future.delayed(const Duration(milliseconds: 800));

      // 2. التهيئة الأساسية (يجب أن تكون جاهزة من main)
      if (!ServiceLocator.isEssentialReady) {
        await ServiceLocator.initEssential();
      }

      // 3. تسجيل خدمات الميزات
      if (!ServiceLocator.areFeatureServicesRegistered) {
        await ServiceLocator.registerFeatureServices();
      }

      // 4. التحقق من حالة التطبيق
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      _navigateToNextScreen();
      
    } catch (e) {
      debugPrint('❌ Splash initialization error: $e');
      if (mounted) {
        _showErrorAndRetry();
      }
    }
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final storage = getIt<StorageService>();

      // فحص إذا أكمل Onboarding
      final onboardingCompleted = storage.getBool('onboarding_completed') ?? false;
      
      if (!onboardingCompleted) {
        // أول مرة - اذهب لـ Onboarding
        Navigator.pushReplacementNamed(context, AppRouter.onboarding);
        return;
      }

      // فحص إذا أكمل إعداد الأذونات
      final permissionsSetupCompleted = 
          storage.getBool('permissions_setup_completed') ?? false;

      if (!permissionsSetupCompleted) {
        // أكمل Onboarding لكن لم يُعد الأذونات
        Navigator.pushReplacementNamed(context, AppRouter.permissionsSetup);
        return;
      }

      // فحص سريع للأذونات الحرجة
      final permissionManager = getIt<UnifiedPermissionManager>();
      final result = await permissionManager.performQuickCheck();

      if (!result.allGranted) {
        // بعض الأذونات مفقودة - اعرض تنبيه اختياري
        Navigator.pushReplacementNamed(context, AppRouter.home);
        // سيظهر PermissionMonitor تلقائياً
      } else {
        // كل شيء جاهز
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }

    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      // في حالة الخطأ، اذهب للـ Home مباشرة
      Navigator.pushReplacementNamed(context, AppRouter.home);
    }
  }

  void _showErrorAndRetry() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: ThemeConstants.error,
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            const Text('خطأ في التهيئة'),
          ],
        ),
        content: const Text(
          'حدث خطأ أثناء تهيئة التطبيق. يرجى المحاولة مرة أخرى.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeApp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primary,
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ThemeConstants.primary,
              ThemeConstants.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo Animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildLogo(),
                  ),
                ),

                const Spacer(flex: 1),

                // Loading Indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40.w,
                        height: 40.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.w,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        'جاري التحميل...',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 60.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 160.w,
      height: 160.w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mosque_rounded,
            size: 80.sp,
            color: Colors.white,
          ),
          SizedBox(height: 12.h),
          Text(
            'حصن المسلم',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}