// lib/features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:concentric_transition/concentric_transition.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../models/onboarding_page_model.dart';

/// شاشة Onboarding الاحترافية مع تأثيرات Concentric
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<OnboardingPageModel> _pages = OnboardingPages.pages;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // تعطيل auto-rotate
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    // إعادة تفعيل auto-rotate
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      HapticFeedback.mediumImpact();
      
      final storage = getIt<StorageService>();
      await storage.setBool('onboarding_completed', true);
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.permissionsSetup);
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Concentric Transition Pages
          ConcentricPageView(
            colors: _pages.map((page) => page.primaryColor).toList(),
            itemCount: _pages.length,
            onChange: (index) {
              setState(() => _currentPage = index);
              HapticFeedback.lightImpact();
            },
            itemBuilder: (index) {
              return _EnhancedPageView(
                page: _pages[index],
                pageIndex: index,
                totalPages: _pages.length,
              );
            },
            onFinish: _completeOnboarding,
            // خصائص إضافية للتحكم
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 1500),
            opacityFactor: 2.0,
            scaleFactor: 0.3,
            verticalPosition: 0.75,
            direction: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
          ),

          // Custom Page Indicator (أجمل من الافتراضي)
          Positioned(
            bottom: 100.h,
            left: 0,
            right: 0,
            child: _CustomPageIndicator(
              currentPage: _currentPage,
              totalPages: _pages.length,
            ),
          ),

          // Navigation Hint
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _currentPage == _pages.length - 1 ? 1.0 : 0.7,
                duration: const Duration(milliseconds: 300),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentPage == _pages.length - 1
                          ? Icons.check_circle_outline
                          : Icons.swipe,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _currentPage == _pages.length - 1
                          ? 'اسحب للبدء'
                          : 'اسحب للمتابعة',
                      style: TextStyle(
                        fontSize: _currentPage == _pages.length - 1 ? 16.sp : 14.sp,
                        fontWeight: _currentPage == _pages.length - 1
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// عرض محسّن لصفحة Onboarding - بدون Animation
class _EnhancedPageView extends StatelessWidget {
  final OnboardingPageModel page;
  final int pageIndex;
  final int totalPages;

  const _EnhancedPageView({
    required this.page,
    required this.pageIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Badge بدلاً من Animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _buildIconBadge(),
            ),

            SizedBox(height: 48.h),

            // Title with fade-in
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Text(
                page.title,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 16.h),

            // Description
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Text(
                page.description,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 32.h),

            // Features with staggered animation
            if (page.features != null && page.features!.isNotEmpty)
              _buildFeaturesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge() {
    return Container(
      width: 140.w,
      height: 140.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2.w,
            ),
          ),
          child: Icon(
            page.icon,
            size: 50.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: List.generate(
        page.features!.length,
        (index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 800 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: _FeatureItem(text: page.features![index]),
          );
        },
      ),
    );
  }
}

/// عنصر ميزة محسّن
class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2.w,
              ),
            ),
            child: Icon(
              Icons.check,
              size: 18.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.white.withOpacity(0.95),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// مؤشر الصفحات المخصص
class _CustomPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _CustomPageIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) {
          final isActive = index == currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: isActive ? 32.w : 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4.r),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }
}