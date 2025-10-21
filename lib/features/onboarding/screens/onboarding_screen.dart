// lib/features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:concentric_transition/concentric_transition.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../models/onboarding_page_model.dart';
import '../constants/onboarding_constants.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
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
                screenHeight: screenHeight,
              );
            },
            onFinish: _completeOnboarding,
            curve: Curves.easeInOut,
            duration: OnboardingConstants.pageTransitionDuration,
            opacityFactor: OnboardingConstants.concentricOpacityFactor,
            scaleFactor: OnboardingConstants.concentricScaleFactor,
            verticalPosition: OnboardingConstants.concentricVerticalPosition,
            direction: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
          ),

          // زر التخطي (Skip)
          Positioned(
            top: 40.h,
            right: 20.w,
            child: SafeArea(
              child: TextButton(
                onPressed: _completeOnboarding,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                child: Text(
                  'تخطي',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Page Indicators (النقاط)
          Positioned(
            top: 40.h,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: OnboardingConstants.indicatorAnimationDuration,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: _currentPage == index ? 24.w : 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // تلميح التمرير في الأسفل
          Positioned(
            bottom: OnboardingConstants.isSmallScreen(screenHeight) ? 24.h : 40.h,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentPage == _pages.length - 1
                        ? Icons.check_circle_outline
                        : Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: OnboardingConstants.isSmallScreen(screenHeight) ? 16.sp : 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    _currentPage == _pages.length - 1
                        ? ' ابدأ الآن'
                        : 'اسحب للمتابعة',
                    style: TextStyle(
                      fontSize: _currentPage == _pages.length - 1 
                          ? (OnboardingConstants.isSmallScreen(screenHeight) ? 14.sp : 16.sp)
                          : (OnboardingConstants.isSmallScreen(screenHeight) ? 12.sp : 14.sp),
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
  final double screenHeight;

  const _ResponsivePageView({
    required this.page,
    required this.pageIndex,
    required this.totalPages,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final double topSpace = OnboardingConstants.getTopSpacing(screenHeight);
    final double bottomSpace = OnboardingConstants.getBottomSpacing(screenHeight);
    final double horizontalPadding = OnboardingConstants.getHorizontalPadding(screenHeight);
    
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
                        flex: OnboardingConstants.isSmallScreen(screenHeight) ? 1 : 2,
                        child: Container(),
                      ),

                      _buildMainContent(),

                      Expanded(
                        flex: OnboardingConstants.isSmallScreen(screenHeight) ? 1 : 2,
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
    final double titleSize = OnboardingConstants.getTitleSize(screenHeight);
    final double descSize = OnboardingConstants.getDescSize(screenHeight);
    final double featureSize = OnboardingConstants.getFeatureSize(screenHeight);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Semantics(
          header: true,
          label: 'عنوان الصفحة: ${page.title}',
          child: Text(
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
        ),

        SizedBox(height: OnboardingConstants.isSmallScreen(screenHeight) ? 8.h : 12.h),

        // Description
        if (page.description.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: OnboardingConstants.isSmallScreen(screenHeight) ? 12.w : 20.w,
            ),
            child: Semantics(
              label: 'وصف: ${page.description}',
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
          ),

        SizedBox(height: OnboardingConstants.isSmallScreen(screenHeight) ? 20.h : 32.h),

        // Features
        if (page.features != null && page.features!.isNotEmpty)
          _buildResponsiveFeaturesList(featureSize),
      ],
    );
  }

  Widget _buildResponsiveFeaturesList(double fontSize) {
    final double padding = OnboardingConstants.isSmallScreen(screenHeight) ? 14.w : 18.w;
    final double borderRadius = OnboardingConstants.getBorderRadius(screenHeight);
    final double verticalPadding = OnboardingConstants.isSmallScreen(screenHeight) ? 8.h : 10.h;
    final double bulletSize = OnboardingConstants.isSmallScreen(screenHeight) ? 7.w : 8.w;
    
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