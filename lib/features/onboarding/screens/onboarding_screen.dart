// lib/features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:concentric_transition/concentric_transition.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../models/onboarding_page_model.dart';

/// شاشة Onboarding محسّنة لجميع أحجام الشاشات
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    final isMediumScreen = screenHeight >= 600 && screenHeight < 800;
    
    return Scaffold(
      body: Stack(
        children: [
          ConcentricPageView(
            colors: _pages.map((page) => page.primaryColor).toList(),
            itemCount: _pages.length,
            onChange: (index) {
              setState(() => _currentPage = index);
              HapticFeedback.lightImpact();
            },
            itemBuilder: (index) {
              return _ResponsivePageView(
                page: _pages[index],
                pageIndex: index,
                totalPages: _pages.length,
                isSmallScreen: isSmallScreen,
                isMediumScreen: isMediumScreen,
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

          Positioned(
            bottom: isSmallScreen ? 24.h : 40.h,
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
                    size: isSmallScreen ? 16.sp : 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    _currentPage == _pages.length - 1
                        ? 'اضغط للبدء'
                        : 'اسحب للمتابعة',
                    style: TextStyle(
                      fontSize: _currentPage == _pages.length - 1 
                          ? (isSmallScreen ? 14.sp : 16.sp)
                          : (isSmallScreen ? 12.sp : 14.sp),
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

class _ResponsivePageView extends StatelessWidget {
  final OnboardingPageModel page;
  final int pageIndex;
  final int totalPages;
  final bool isSmallScreen;
  final bool isMediumScreen;

  const _ResponsivePageView({
    required this.page,
    required this.pageIndex,
    required this.totalPages,
    required this.isSmallScreen,
    required this.isMediumScreen,
  });

  @override
  Widget build(BuildContext context) {
    final double topSpace = isSmallScreen ? 30.h : (isMediumScreen ? 45.h : 60.h);
    final double bottomSpace = isSmallScreen ? 80.h : (isMediumScreen ? 110.h : 140.h);
    final double horizontalPadding = isSmallScreen ? 24.w : 32.w;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: topSpace),

                      Expanded(
                        flex: isSmallScreen ? 1 : 2,
                        child: Container(),
                      ),

                      _buildMainContent(),

                      Expanded(
                        flex: isSmallScreen ? 1 : 2,
                        child: Container(),
                      ),

                      SizedBox(height: bottomSpace),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final double titleSize = isSmallScreen ? 22.sp : (isMediumScreen ? 25.sp : 28.sp);
    final double descSize = isSmallScreen ? 14.sp : (isMediumScreen ? 15.sp : 16.sp);
    final double featureSize = isSmallScreen ? 12.sp : (isMediumScreen ? 13.sp : 14.sp);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          page.title,
          style: TextStyle(
            fontSize: titleSize,
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

        SizedBox(height: isSmallScreen ? 8.h : 12.h),

        // Description
        if (page.description.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12.w : 20.w,
            ),
            child: Text(
              page.description,
              style: TextStyle(
                fontSize: descSize,
                color: Colors.white.withOpacity(0.92),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        SizedBox(height: isSmallScreen ? 20.h : 32.h),

        // Features
        if (page.features != null && page.features!.isNotEmpty)
          _buildResponsiveFeaturesList(featureSize),
      ],
    );
  }

  Widget _buildResponsiveFeaturesList(double fontSize) {
    final double padding = isSmallScreen ? 14.w : 18.w;
    final double borderRadius = isSmallScreen ? 14.r : 18.r;
    final double verticalPadding = isSmallScreen ? 8.h : 10.h;
    final double bulletSize = isSmallScreen ? 7.w : 8.w;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(borderRadius),
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
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              child: _ResponsiveFeatureItem(
                text: page.features![index],
                fontSize: fontSize,
                bulletSize: bulletSize,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResponsiveFeatureItem extends StatelessWidget {
  final String text;
  final double fontSize;
  final double bulletSize;

  const _ResponsiveFeatureItem({
    required this.text,
    required this.fontSize,
    required this.bulletSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Container(
            width: bulletSize,
            height: bulletSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}