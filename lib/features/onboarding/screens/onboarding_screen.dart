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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
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
            curve: Curves.easeInOut,
            duration: const Duration(milliseconds: 1500),
            opacityFactor: 2.0,
            scaleFactor: 0.3,
            verticalPosition: 0.75,
            direction: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
          ),

          // Navigation Hint
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Center(
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
        ],
      ),
    );
  }
}

/// عرض محسّن لصفحة Onboarding
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
          children: [
            // مساحة علوية
            SizedBox(height: 60.h),
            
            // Icon Badge
            _buildIconBadge(),

            // Spacer للمحاذاة الوسطية
            const Spacer(),

            // المحتوى في المنتصف
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  page.title,
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12.h),

                // Description
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    page.description,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white.withOpacity(0.92),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 32.h),

                // Features
                if (page.features != null && page.features!.isNotEmpty)
                  _buildFeaturesList(),
              ],
            ),

            // Spacer للمحاذاة الوسطية
            const Spacer(),

            // مساحة سفلية
            SizedBox(height: 140.h),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge() {
    return Container(
      width: 130.w,
      height: 130.w,
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
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 95.w,
          height: 95.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 2.w,
            ),
          ),
          child: Icon(
            page.icon,
            size: 48.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 2.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          page.features!.length,
          (index) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: _FeatureItem(text: page.features![index]),
            );
          },
        ),
      ),
    );
  }
}

/// عنصر ميزة
class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5.w,
          height: 5.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white.withOpacity(0.92),
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}