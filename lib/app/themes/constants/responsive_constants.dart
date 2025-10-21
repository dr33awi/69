// lib/app/themes/constants/responsive_constants.dart
// ثوابت الأبعاد المتجاوبة للتطبيق الإسلامي

import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ثوابت الأبعاد المتجاوبة المُستخدمة في التطبيق
class ResponsiveConstants {
  
  // ==================== التباعد (Spacing) ====================
  
  /// تباعد صغير جداً - للفواصل الدقيقة
  static double get spaceXS => 4.w;
  
  /// تباعد صغير - بين العناصر القريبة
  static double get spaceSM => 8.w;
  
  /// تباعد متوسط - التباعد الافتراضي
  static double get spaceMD => 12.w;
  
  /// تباعد كبير - بين المجموعات
  static double get spaceLG => 16.w;
  
  /// تباعد كبير جداً - بين الأقسام
  static double get spaceXL => 24.w;
  
  /// تباعد ضخم - للهوامش الخارجية
  static double get spaceXXL => 32.w;

  // ==================== أحجام الخطوط (Typography) ====================
  
  /// نص صغير جداً - للملاحظات والمعلومات الثانوية
  static double get fontXS => 10.sp;
  
  /// نص صغير - للنصوص الثانوية
  static double get fontSM => 12.sp;
  
  /// نص عادي - للمحتوى الأساسي
  static double get fontMD => 14.sp;
  
  /// نص كبير - للعناوين الفرعية
  static double get fontLG => 16.sp;
  
  /// نص كبير جداً - للعناوين الرئيسية
  static double get fontXL => 18.sp;
  
  /// نص ضخم - للعناوين المهمة
  static double get fontXXL => 20.sp;
  
  /// نص عملاق - للعناوين الأساسية
  static double get fontXXXL => 24.sp;

  // ==================== الأبعاد الدائرية (Border Radius) ====================
  
  /// زوايا صغيرة - للعناصر الصغيرة
  static double get radiusSM => 8.r;
  
  /// زوايا متوسطة - الافتراضي للبطاقات
  static double get radiusMD => 12.r;
  
  /// زوايا كبيرة - للبطاقات المهمة
  static double get radiusLG => 16.r;
  
  /// زوايا كبيرة جداً - للحاويات الكبيرة
  static double get radiusXL => 20.r;
  
  /// زوايا ضخمة - للشاشات الكاملة
  static double get radiusXXL => 28.r;

  // ==================== أحجام الأيقونات (Icon Sizes) ====================
  
  /// أيقونة صغيرة جداً
  static double get iconXS => 12.sp;
  
  /// أيقونة صغيرة
  static double get iconSM => 16.sp;
  
  /// أيقونة متوسطة - الافتراضي
  static double get iconMD => 20.sp;
  
  /// أيقونة كبيرة
  static double get iconLG => 24.sp;
  
  /// أيقونة كبيرة جداً
  static double get iconXL => 32.sp;
  
  /// أيقونة ضخمة
  static double get iconXXL => 48.sp;

  // ==================== أبعاد المكونات (Component Dimensions) ====================
  
  /// ارتفاع الأزرار الصغيرة
  static double get buttonHeightSM => 36.h;
  
  /// ارتفاع الأزرار المتوسطة
  static double get buttonHeightMD => 44.h;
  
  /// ارتفاع الأزرار الكبيرة
  static double get buttonHeightLG => 52.h;
  
  /// ارتفاع حقول النص
  static double get inputHeight => 48.h;
  
  /// ارتفاع البطاقات الصغيرة
  static double get cardHeightSM => 80.h;
  
  /// ارتفاع البطاقات المتوسطة
  static double get cardHeightMD => 120.h;
  
  /// ارتفاع البطاقات الكبيرة
  static double get cardHeightLG => 200.h;

  // ==================== عروض المكونات (Component Widths) ====================
  
  /// عرض الأيقونات المربعة الصغيرة
  static double get avatarSizeSM => 32.w;
  
  /// عرض الأيقونات المربعة المتوسطة
  static double get avatarSizeMD => 48.w;
  
  /// عرض الأيقونات المربعة الكبيرة
  static double get avatarSizeLG => 64.w;
  
  /// عرض الحد الأدنى للحاويات
  static double get containerMinWidth => 280.w;
  
  /// العرض الأقصى للمحتوى في الشاشات الكبيرة
  static double get maxContentWidth => 400.w;

  // ==================== الظلال (Elevations) ====================
  
  /// ظل خفيف
  static double get elevationSM => 2.r;
  
  /// ظل متوسط
  static double get elevationMD => 4.r;
  
  /// ظل قوي
  static double get elevationLG => 8.r;
  
  /// ظل قوي جداً
  static double get elevationXL => 12.r;

  // ==================== أبعاد خاصة بالتطبيق الإسلامي ====================
  
  /// ارتفاع بطاقة الصلاة
  static double get prayerCardHeight => 100.h;
  
  /// ارتفاع بطاقة الذكر
  static double get dhikrCardHeight => 140.h;
  
  /// حجم أيقونة القبلة
  static double get qiblaIconSize => 120.sp;
  
  /// ارتفاع شريط مواقيت الصلاة
  static double get prayerTimeBarHeight => 60.h;
  
  /// عرض عداد التسبيح
  static double get tasbihCounterSize => 180.w;

  // ==================== تباعد خاص بالتخطيط (Layout Spacing) ====================
  
  /// هامش الشاشة الخارجي
  static double get screenPadding => 16.w;
  
  /// تباعد بين أقسام الشاشة الرئيسية
  static double get sectionSpacing => 24.h;
  
  /// تباعد بين العناصر في القوائم
  static double get listItemSpacing => 12.h;
  
  /// تباعد بين عناصر الشبكة
  static double get gridSpacing => 12.w;

  // ==================== دوال مساعدة (Helper Functions) ====================
  
  /// الحصول على تباعد حسب الحجم
  static double spacing(String size) {
    switch (size) {
      case 'xs': return spaceXS;
      case 'sm': return spaceSM;
      case 'md': return spaceMD;
      case 'lg': return spaceLG;
      case 'xl': return spaceXL;
      case 'xxl': return spaceXXL;
      default: return spaceMD;
    }
  }
  
  /// الحصول على حجم خط حسب النوع
  static double fontSize(String size) {
    switch (size) {
      case 'xs': return fontXS;
      case 'sm': return fontSM;
      case 'md': return fontMD;
      case 'lg': return fontLG;
      case 'xl': return fontXL;
      case 'xxl': return fontXXL;
      case 'xxxl': return fontXXXL;
      default: return fontMD;
    }
  }
  
  /// الحصول على حجم أيقونة حسب النوع
  static double iconSize(String size) {
    switch (size) {
      case 'xs': return iconXS;
      case 'sm': return iconSM;
      case 'md': return iconMD;
      case 'lg': return iconLG;
      case 'xl': return iconXL;
      case 'xxl': return iconXXL;
      default: return iconMD;
    }
  }
}

