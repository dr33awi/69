// lib/features/onboarding/config/onboarding_responsive_config.dart
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تكوين متجاوب لشاشات Onboarding
/// يحتوي على جميع الأحجام المحسوبة بناءً على حجم الشاشة
class OnboardingResponsiveConfig {
  // أنواع الأجهزة
  static bool get isTablet => 1.sw > 600;
  static bool get isLargePhone => 1.sw > 400 && 1.sw <= 600;
  static bool get isSmallPhone => 1.sw <= 400;
  
  static bool get isTallScreen => 1.sh > 700;
  static bool get isShortScreen => 1.sh <= 700;
  
  // ========== أحجام الرسوم المتحركة ==========
  
  /// حجم دائرة الأنيميشن الخارجية
  static double get animationContainerSize {
    if (isTablet) return 180.w;
    if (isLargePhone) return 150.w;
    return 130.w;
  }
  
  /// حجم أنيميشن Lottie نفسه
  static double get lottieAnimationSize {
    if (isTablet) return 130.w;
    if (isLargePhone) return 105.w;
    return 90.w;
  }
  
  /// حجم الأيقونة الاحتياطية
  static double get fallbackIconSize {
    if (isTablet) return 75.w;
    if (isLargePhone) return 65.w;
    return 55.w;
  }
  
  // ========== أحجام النصوص ==========
  
  /// حجم العنوان الرئيسي
  static double get titleFontSize {
    if (isTablet) return 28.sp;
    if (isLargePhone) return 24.sp;
    return 22.sp;
  }
  
  /// حجم العنوان الفرعي
  static double get subtitleFontSize {
    if (isTablet) return 17.sp;
    if (isLargePhone) return 16.sp;
    return 15.sp;
  }
  
  /// حجم نص الميزات
  static double get featureFontSize {
    if (isTablet) return 15.sp;
    if (isLargePhone) return 13.sp;
    return 12.sp;
  }
  
  /// حجم نص الأزرار
  static double get buttonFontSize {
    if (isTablet) return 18.sp;
    if (isLargePhone) return 16.sp;
    return 14.sp;
  }
  
  // ========== المسافات والهوامش ==========
  
  /// هامش أفقي للصفحة
  static double get pageHorizontalPadding {
    if (isTablet) return 36.w;
    if (isLargePhone) return 24.w;
    return 20.w;
  }
  
  /// هامش عمودي للصفحة
  static double get pageVerticalPadding {
    if (isTallScreen) return 20.h;
    return 16.h;
  }
  
  /// مسافة من الأعلى
  static double get topSpacing {
    if (isTallScreen) return 50.h;
    if (isShortScreen) return 25.h;
    return 40.h;
  }
  
  /// مسافة بين العناصر
  static double get itemSpacing {
    if (isTallScreen) return 28.h;
    return 20.h;
  }
  
  /// مسافة صغيرة بين العناصر
  static double get smallItemSpacing {
    if (isTallScreen) return 16.h;
    return 12.h;
  }
  
  // ========== أحجام الأزرار ==========
  
  /// ارتفاع زر الإجراء
  static double get actionButtonHeight {
    if (isTallScreen) return 58.h;
    return 54.h;
  }
  
  /// أقصى عرض للزر على الأجهزة اللوحية
  static double get actionButtonMaxWidth {
    if (isTablet) return 450.w;
    return double.infinity;
  }
  
  /// حجم أيقونة الزر
  static double get buttonIconSize {
    if (isTablet) return 22.sp;
    return 20.sp;
  }
  
  // ========== بطاقات الأذونات ==========
  
  /// هامش داخلي لبطاقة الإذن
  static double get permissionCardPadding {
    if (isTablet) return 20.w;
    return 16.w;
  }
  
  /// المسافة بين بطاقات الأذونات
  static double get permissionCardMargin {
    if (isTallScreen) return 14.h;
    return 12.h;
  }
  
  /// حجم أيقونة الإذن
  static double get permissionIconSize {
    if (isTablet) return 58.w;
    if (isLargePhone) return 54.w;
    return 52.w;
  }
  
  /// حجم أيقونة الإذن الداخلية
  static double get permissionIconInnerSize {
    if (isTablet) return 28.sp;
    return 26.sp;
  }
  
  /// حجم نص عنوان الإذن
  static double get permissionTitleSize {
    if (isTablet) return 17.sp;
    return 16.sp;
  }
  
  /// حجم نص وصف الإذن
  static double get permissionDescriptionSize {
    if (isTablet) return 13.sp;
    return 12.sp;
  }
  
  /// حجم نص شارة "مُفعّل"
  static double get permissionBadgeSize {
    if (isTablet) return 11.sp;
    return 10.sp;
  }
  
  // ========== مؤشر الصفحات ==========
  
  /// عرض النقطة النشطة
  static double get activeIndicatorWidth {
    if (isTablet) return 28.w;
    if (isLargePhone) return 26.w;
    return 24.w;
  }
  
  /// عرض النقطة غير النشطة
  static double get inactiveIndicatorWidth {
    if (isTablet) return 10.w;
    return 8.w;
  }
  
  /// ارتفاع المؤشر
  static double get indicatorHeight {
    if (isTablet) return 10.h;
    return 8.h;
  }
  
  /// المسافة الأفقية بين النقاط
  static double get indicatorHorizontalMargin {
    if (isTablet) return 4.w;
    return 3.w;
  }
  
  /// حجم النقطة الداخلية
  static double get indicatorInnerDotSize {
    if (isTablet) return 5.w;
    return 4.w;
  }
  
  // ========== مؤشر حالة الأذونات ==========
  
  /// حجم أيقونة مؤشر الحالة
  static double get statusIndicatorIconSize {
    if (isTablet) return 34.w;
    if (isLargePhone) return 32.w;
    return 30.w;
  }
  
  /// عرض شريط التقدم
  static double get progressBarWidth {
    if (isTablet) return 100.w;
    if (isLargePhone) return 90.w;
    return 80.w;
  }
  
  /// ارتفاع شريط التقدم
  static double get progressBarHeight {
    if (isTablet) return 6.h;
    return 5.h;
  }
  
  /// حجم نص مؤشر الحالة
  static double get statusIndicatorTextSize {
    if (isTablet) return 15.sp;
    if (isLargePhone) return 14.sp;
    return 13.sp;
  }
  
  // ========== قائمة الميزات ==========
  
  /// هامش داخلي لحاوية الميزات
  static double get featuresContainerPadding {
    if (isTablet) return 16.w;
    return 12.w;
  }
  
  /// هامش عمودي لعنصر الميزة
  static double get featureItemVerticalPadding {
    if (isTallScreen) return 5.h;
    return 4.h;
  }
  
  /// حجم نقطة الميزة (bullet)
  static double get featureBulletSize {
    if (isTablet) return 5.w;
    return 4.w;
  }
  
  /// المسافة بين النقطة والنص
  static double get featureBulletSpacing {
    if (isTablet) return 10.w;
    return 8.w;
  }
  
  // ========== الاحتفال بالنجاح ==========
  
  /// حجم أيقونة الاحتفال
  static double get celebrationIconSize {
    if (isTablet) return 75.w;
    if (isLargePhone) return 70.w;
    return 65.w;
  }
  
  /// حجم نص عنوان الاحتفال
  static double get celebrationTitleSize {
    if (isTablet) return 28.sp;
    if (isLargePhone) return 26.sp;
    return 24.sp;
  }
  
  /// حجم نص وصف الاحتفال
  static double get celebrationDescriptionSize {
    if (isTablet) return 16.sp;
    if (isLargePhone) return 15.sp;
    return 14.sp;
  }
  
  // ========== حسابات إضافية ==========
  
  /// حساب نصف قطر الحواف بناءً على الحجم
  static double getBorderRadius(double size) {
    if (isTablet) return size * 1.1;
    return size;
  }
  
  /// حساب حجم الظل بناءً على الارتفاع
  static double getShadowBlur(double baseBlur) {
    if (isTablet) return baseBlur * 1.2;
    return baseBlur;
  }
  
  /// حساب المسافة بين العناصر بناءً على النسبة
  static double getSpacing(double baseSpacing, {double multiplier = 1.0}) {
    if (isTablet) return baseSpacing * 1.15 * multiplier;
    if (isLargePhone) return baseSpacing * 1.0 * multiplier;
    return baseSpacing * 0.9 * multiplier;
  }
  
  /// الحصول على نسبة العرض إلى الارتفاع للشاشة
  static double get screenAspectRatio => 1.sw / 1.sh;
  
  /// هل الشاشة عريضة (landscape)
  static bool get isLandscape => screenAspectRatio > 1.0;
  
  /// هل الشاشة طولية (portrait)
  static bool get isPortrait => screenAspectRatio <= 1.0;
  
  // ========== دوال مساعدة ==========
  
  /// طباعة معلومات الجهاز (للتطوير)
  static void printDeviceInfo() {
    print('═══════════════════════════════════════');
    print('📱 معلومات الجهاز:');
    print('  • العرض: ${1.sw} dp');
    print('  • الارتفاع: ${1.sh} dp');
    print('  • نوع الجهاز: ${_getDeviceType()}');
    print('  • نوع الشاشة: ${_getScreenType()}');
    print('  • الاتجاه: ${isLandscape ? "عرضي" : "طولي"}');
    print('  • نسبة العرض/الارتفاع: ${screenAspectRatio.toStringAsFixed(2)}');
    print('═══════════════════════════════════════');
  }
  
  static String _getDeviceType() {
    if (isTablet) return 'جهاز لوحي';
    if (isLargePhone) return 'هاتف كبير';
    return 'هاتف صغير';
  }
  
  static String _getScreenType() {
    if (isTallScreen) return 'شاشة طويلة';
    return 'شاشة قصيرة';
  }
  
  /// الحصول على التكوين الكامل كخريطة
  static Map<String, dynamic> toMap() {
    return {
      'device': {
        'width': 1.sw,
        'height': 1.sh,
        'isTablet': isTablet,
        'isLargePhone': isLargePhone,
        'isSmallPhone': isSmallPhone,
        'isTallScreen': isTallScreen,
        'isLandscape': isLandscape,
      },
      'animation': {
        'containerSize': animationContainerSize,
        'lottieSize': lottieAnimationSize,
        'fallbackIconSize': fallbackIconSize,
      },
      'text': {
        'title': titleFontSize,
        'subtitle': subtitleFontSize,
        'feature': featureFontSize,
        'button': buttonFontSize,
      },
      'spacing': {
        'horizontal': pageHorizontalPadding,
        'vertical': pageVerticalPadding,
        'top': topSpacing,
        'item': itemSpacing,
      },
      'button': {
        'height': actionButtonHeight,
        'maxWidth': actionButtonMaxWidth,
        'iconSize': buttonIconSize,
      },
    };
  }
}