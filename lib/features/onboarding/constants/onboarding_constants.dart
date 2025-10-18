// lib/features/onboarding/constants/onboarding_constants.dart

import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ثوابت لشاشات Onboarding لتبسيط الكود وتسهيل الصيانة
class OnboardingConstants {
  OnboardingConstants._();

  // ══════════════════════════════════════════════════════════
  // Responsive Sizes - أحجام الشاشات
  // ══════════════════════════════════════════════════════════
  
  static const double smallScreenThreshold = 600;
  static const double mediumScreenThreshold = 800;

  // ══════════════════════════════════════════════════════════
  // Spacing - المسافات
  // ══════════════════════════════════════════════════════════
  
  /// Top spacing for small screens
  static double get topSpaceSmall => 30.h;
  /// Top spacing for medium screens
  static double get topSpaceMedium => 45.h;
  /// Top spacing for large screens
  static double get topSpaceLarge => 60.h;

  /// Bottom spacing for small screens
  static double get bottomSpaceSmall => 80.h;
  /// Bottom spacing for medium screens
  static double get bottomSpaceMedium => 110.h;
  /// Bottom spacing for large screens
  static double get bottomSpaceLarge => 140.h;

  /// Horizontal padding for small screens
  static double get horizontalPaddingSmall => 24.w;
  /// Horizontal padding for normal screens
  static double get horizontalPaddingNormal => 32.w;

  // ══════════════════════════════════════════════════════════
  // Font Sizes - أحجام الخطوط
  // ══════════════════════════════════════════════════════════
  
  /// Title font size for small screens
  static double get titleSizeSmall => 22.sp;
  /// Title font size for medium screens
  static double get titleSizeMedium => 25.sp;
  /// Title font size for large screens
  static double get titleSizeLarge => 28.sp;

  /// Description font size for small screens
  static double get descSizeSmall => 14.sp;
  /// Description font size for medium screens
  static double get descSizeMedium => 15.sp;
  /// Description font size for large screens
  static double get descSizeLarge => 16.sp;

  /// Feature text font size for small screens
  static double get featureSizeSmall => 12.sp;
  /// Feature text font size for medium screens
  static double get featureSizeMedium => 13.sp;
  /// Feature text font size for large screens
  static double get featureSizeLarge => 14.sp;

  // ══════════════════════════════════════════════════════════
  // Border & Radius - الحواف والزوايا
  // ══════════════════════════════════════════════════════════
  
  /// Border radius for small screens
  static double get borderRadiusSmall => 14.r;
  /// Border radius for normal screens
  static double get borderRadiusNormal => 18.r;

  /// Border width
  static double get borderWidth => 2.w;

  // ══════════════════════════════════════════════════════════
  // Durations - المدد الزمنية
  // ══════════════════════════════════════════════════════════
  
  static const Duration pageTransitionDuration = Duration(milliseconds: 1500);
  static const Duration indicatorAnimationDuration = Duration(milliseconds: 300);
  static const Duration permissionRequestDelay = Duration(milliseconds: 500);

  // ══════════════════════════════════════════════════════════
  // Animation Values - قيم الرسوم المتحركة
  // ══════════════════════════════════════════════════════════
  
  static const double concentricOpacityFactor = 2.0;
  static const double concentricScaleFactor = 0.3;
  static const double concentricVerticalPosition = 0.75;

  // ══════════════════════════════════════════════════════════
  // Helper Methods - دوال مساعدة
  // ══════════════════════════════════════════════════════════
  
  /// Get top spacing based on screen size
  static double getTopSpacing(double screenHeight) {
    if (screenHeight < smallScreenThreshold) return topSpaceSmall;
    if (screenHeight < mediumScreenThreshold) return topSpaceMedium;
    return topSpaceLarge;
  }

  /// Get bottom spacing based on screen size
  static double getBottomSpacing(double screenHeight) {
    if (screenHeight < smallScreenThreshold) return bottomSpaceSmall;
    if (screenHeight < mediumScreenThreshold) return bottomSpaceMedium;
    return bottomSpaceLarge;
  }

  /// Get horizontal padding based on screen size
  static double getHorizontalPadding(double screenHeight) {
    return screenHeight < smallScreenThreshold 
        ? horizontalPaddingSmall 
        : horizontalPaddingNormal;
  }

  /// Get title font size based on screen size
  static double getTitleSize(double screenHeight) {
    if (screenHeight < smallScreenThreshold) return titleSizeSmall;
    if (screenHeight < mediumScreenThreshold) return titleSizeMedium;
    return titleSizeLarge;
  }

  /// Get description font size based on screen size
  static double getDescSize(double screenHeight) {
    if (screenHeight < smallScreenThreshold) return descSizeSmall;
    if (screenHeight < mediumScreenThreshold) return descSizeMedium;
    return descSizeLarge;
  }

  /// Get feature text font size based on screen size
  static double getFeatureSize(double screenHeight) {
    if (screenHeight < smallScreenThreshold) return featureSizeSmall;
    if (screenHeight < mediumScreenThreshold) return featureSizeMedium;
    return featureSizeLarge;
  }

  /// Get border radius based on screen size
  static double getBorderRadius(double screenHeight) {
    return screenHeight < smallScreenThreshold 
        ? borderRadiusSmall 
        : borderRadiusNormal;
  }

  /// Check if screen is small
  static bool isSmallScreen(double screenHeight) {
    return screenHeight < smallScreenThreshold;
  }

  /// Check if screen is medium
  static bool isMediumScreen(double screenHeight) {
    return screenHeight >= smallScreenThreshold && 
           screenHeight < mediumScreenThreshold;
  }

  /// Check if screen is large
  static bool isLargeScreen(double screenHeight) {
    return screenHeight >= mediumScreenThreshold;
  }
}
