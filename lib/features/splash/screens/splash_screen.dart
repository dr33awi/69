// lib/features/splash/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/routes/app_router.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../app/di/service_locator.dart';

/// شاشة البداية مع تحسينات بصرية
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
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
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  /// تهيئة التطبيق مع فحص الأذونات
  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));

      // تحقق من حالة المستخدم الجديد
      final storageService = getIt<StorageService>();
      final isFirstTime = await storageService.getBool('is_first_time') ?? true;

      if (!mounted) {
        return;
      }

      if (isFirstTime) {
        // المستخدم الجديد - اذهب لشاشة الترحيب
        Navigator.pushReplacementNamed(context, AppRouter.onboarding);
        return;
      }

      // النظام الجديد يطلب الأذونات عند الحاجة تلقائياً
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } catch (e) {
      // في حالة خطأ، اذهب للشاشة الرئيسية
      debugPrint('خطأ في تهيئة التطبيق: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    }
  }

  /// Builds the main splash screen interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with enhanced animations
                Hero(
                  tag: 'app-logo',
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 120.w,
                            height: 120.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  context.primaryColor,
                                  context.primaryColor
                                      .withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25.r),
                              boxShadow: [
                                BoxShadow(
                                  color: context.primaryColor
                                      .withOpacity(0.3),
                                  blurRadius: 20.r,
                                  spreadRadius: 5.r,
                                  offset: Offset(0, 10.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.mosque,
                              size: 60.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 30.h),

                // App name with typing effect
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Hero(
                        tag: 'app-title',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            'أذكار المسلم',
                            style: context.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.primaryColor,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 10.h),

                // App description
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'تطبيق الأذكار والأدعية',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color:
                              context.textPrimaryColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),

                SizedBox(height: 50.h),

                // Enhanced loading indicator
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 50.w,
                        height: 50.h,
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: context.primaryColor
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: CircularProgressIndicator(
                          strokeWidth: 3.w,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.primaryColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 30.h),

                // Version info (optional)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'الإصدار 1.0.0',
                        style: context.textTheme.bodySmall?.copyWith(
                          color:
                              context.textPrimaryColor.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}