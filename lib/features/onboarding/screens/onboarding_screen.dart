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
    // حساب ارتفاع الشاشة لتحديد التخطيط المناسب
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    final isMediumScreen = screenHeight >= 600 && screenHeight < 800;
    
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

          // Navigation Hint - موقع ديناميكي حسب حجم الشاشة
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
                        ? 'اسحب للبدء'
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

/// عرض محسّن ومتجاوب لصفحة Onboarding
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
    // حساب المساحات بناءً على حجم الشاشة
    final double topSpace = isSmallScreen ? 30.h : (isMediumScreen ? 45.h : 60.h);
    final double bottomSpace = isSmallScreen ? 80.h : (isMediumScreen ? 110.h : 140.h);
    final double horizontalPadding = isSmallScreen ? 24.w : 32.w;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // استخدام LayoutBuilder لضمان عدم حدوث overflow
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // مساحة علوية ديناميكية
                      SizedBox(height: topSpace),
                      
                      // Icon Badge بحجم متجاوب
                      _buildResponsiveIconBadge(),

                      // Spacer مرن
                      Expanded(
                        flex: isSmallScreen ? 1 : 2,
                        child: Container(),
                      ),

                      // المحتوى الرئيسي
                      _buildMainContent(),

                      // Spacer مرن
                      Expanded(
                        flex: isSmallScreen ? 1 : 2,
                        child: Container(),
                      ),

                      // مساحة سفلية ديناميكية
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

  Widget _buildResponsiveIconBadge() {
    // أحجام متجاوبة للأيقونة
    final double outerSize = isSmallScreen ? 90.w : (isMediumScreen ? 110.w : 130.w);
    final double innerSize = isSmallScreen ? 65.w : (isMediumScreen ? 80.w : 95.w);
    final double iconSize = isSmallScreen ? 32.sp : (isMediumScreen ? 40.sp : 48.sp);
    
    return Container(
      width: outerSize,
      height: outerSize,
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
          width: innerSize,
          height: innerSize,
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
            size: iconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    // أحجام خطوط متجاوبة
    final double titleSize = isSmallScreen ? 20.sp : (isMediumScreen ? 23.sp : 26.sp);
    final double descSize = isSmallScreen ? 13.sp : (isMediumScreen ? 14.sp : 15.sp);
    final double featureSize = isSmallScreen ? 9.sp : 10.sp;
    
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

        // Features بتخطيط متجاوب
        if (page.features != null && page.features!.isNotEmpty)
          _buildResponsiveFeaturesList(featureSize),
      ],
    );
  }

  Widget _buildResponsiveFeaturesList(double fontSize) {
    final double padding = isSmallScreen ? 12.w : 16.w;
    final double borderRadius = isSmallScreen ? 12.r : 16.r;
    final double verticalPadding = isSmallScreen ? 4.h : 6.h;
    
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
              ),
            );
          },
        ),
      ),
    );
  }
}

/// عنصر ميزة متجاوب
class _ResponsiveFeatureItem extends StatelessWidget {
  final String text;
  final double fontSize;

  const _ResponsiveFeatureItem({
    required this.text,
    required this.fontSize,
  });

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
              fontSize: fontSize,
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