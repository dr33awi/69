// lib/app/themes/text_styles.dart - محدث مع flutter_screenutil
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme_constants.dart';

/// أنماط النصوص الموحدة للتطبيق مع ScreenUtil
class AppTextStyles {
  AppTextStyles._();

  // ===== أنماط العناوين مع ScreenUtil =====
  static TextStyle get h1 => TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.bold,
    height: 1.3,
    fontFamily: 'Cairo',
  );

  static TextStyle get h2 => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
    fontFamily: 'Cairo',
  );

  static TextStyle get h3 => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: 'Cairo',
  );

  static TextStyle get h4 => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: 'Cairo',
  );

  static TextStyle get h5 => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    height: 1.5,
    fontFamily: 'Cairo',
  );

  // ===== أنماط النص الأساسي مع ScreenUtil =====
  static TextStyle get body1 => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    height: 1.6,
    fontFamily: 'Cairo',
  );

  static TextStyle get body2 => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    height: 1.6,
    fontFamily: 'Cairo',
  );

  // ===== أنماط التسميات مع ScreenUtil =====
  static TextStyle get label1 => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 1.4,
    fontFamily: 'Cairo',
  );

  static TextStyle get label2 => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    height: 1.4,
    fontFamily: 'Cairo',
  );

  static TextStyle get caption => TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.normal,
    height: 1.4,
    fontFamily: 'Cairo',
  );

  // ===== أنماط الأزرار مع ScreenUtil =====
  static TextStyle get button => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFamily: 'Cairo',
  );

  static TextStyle get buttonSmall => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFamily: 'Cairo',
  );

  // ===== أنماط خاصة بالمحتوى الإسلامي مع ScreenUtil =====
  static TextStyle get quran => TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.normal,
    height: 2.0,
    fontFamily: 'Amiri',
  );

  static TextStyle get athkar => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.normal,
    height: 1.8,
    fontFamily: 'Cairo',
  );

  static TextStyle get dua => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    height: 1.7,
    fontFamily: 'Cairo',
  );

  // ===== إنشاء TextTheme للتطبيق =====
  static TextTheme createTextTheme({
    required Color color,
    Color? secondaryColor,
  }) {
    final Color effectiveSecondaryColor = secondaryColor ?? color.withValues(alpha: 0.7);
    
    return TextTheme(
      // Display styles
      displayLarge: h1.copyWith(color: color),
      displayMedium: h2.copyWith(color: color),
      displaySmall: h3.copyWith(color: color),
      
      // Headline styles
      headlineLarge: h1.copyWith(color: color),
      headlineMedium: h2.copyWith(color: color),
      headlineSmall: h3.copyWith(color: color),
      
      // Title styles
      titleLarge: h4.copyWith(color: color),
      titleMedium: h5.copyWith(color: color),
      titleSmall: h5.copyWith(color: color, fontSize: 14.sp),
      
      // Body styles
      bodyLarge: body1.copyWith(color: color),
      bodyMedium: body2.copyWith(color: effectiveSecondaryColor),
      bodySmall: caption.copyWith(color: effectiveSecondaryColor),
      
      // Label styles
      labelLarge: label1.copyWith(color: color),
      labelMedium: label2.copyWith(color: effectiveSecondaryColor),
      labelSmall: caption.copyWith(color: effectiveSecondaryColor),
    );
  }

  // ===== أنماط مخصصة حسب السياق =====
  
  /// نص للعناوين الرئيسية في الصفحات
  static TextStyle pageTitle(BuildContext context) {
    return h2.copyWith(
      color: ThemeConstants.textPrimary(context),
    );
  }

  /// نص للعناوين الفرعية
  static TextStyle sectionTitle(BuildContext context) {
    return h4.copyWith(
      color: ThemeConstants.textPrimary(context),
    );
  }

  /// نص للمحتوى الرئيسي
  static TextStyle contentText(BuildContext context) {
    return body1.copyWith(
      color: ThemeConstants.textPrimary(context),
    );
  }

  /// نص للمعلومات الثانوية
  static TextStyle secondaryText(BuildContext context) {
    return body2.copyWith(
      color: ThemeConstants.textSecondary(context),
    );
  }

  /// نص للتلميحات
  static TextStyle hintText(BuildContext context) {
    return caption.copyWith(
      color: ThemeConstants.textSecondary(context).withValues(alpha: 0.7),
    );
  }

  /// نص للأخطاء
  static TextStyle errorText(BuildContext context) {
    return caption.copyWith(
      color: ThemeConstants.error,
    );
  }

  /// نص للنجاح
  static TextStyle successText(BuildContext context) {
    return body2.copyWith(
      color: ThemeConstants.success,
      fontWeight: FontWeight.w500,
    );
  }

  /// نص للتحذيرات
  static TextStyle warningText(BuildContext context) {
    return body2.copyWith(
      color: ThemeConstants.warning,
      fontWeight: FontWeight.w500,
    );
  }

  /// نص للمعلومات
  static TextStyle infoText(BuildContext context) {
    return body2.copyWith(
      color: ThemeConstants.info,
    );
  }

  /// نص للروابط
  static TextStyle linkText(BuildContext context) {
    return body2.copyWith(
      color: ThemeConstants.primary,
      decoration: TextDecoration.underline,
    );
  }

  /// أنماط مخصصة للقرآن والأذكار بأحجام مختلفة
  
  // أحجام الخط للقرآن
  static TextStyle get quranSmall => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.normal,
    height: 1.8,
    fontFamily: 'Amiri',
  );

  static TextStyle get quranMedium => TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.normal,
    height: 2.0,
    fontFamily: 'Amiri',
  );

  static TextStyle get quranLarge => TextStyle(
    fontSize: 26.sp,
    fontWeight: FontWeight.normal,
    height: 2.2,
    fontFamily: 'Amiri',
  );

  static TextStyle get quranExtraLarge => TextStyle(
    fontSize: 30.sp,
    fontWeight: FontWeight.normal,
    height: 2.4,
    fontFamily: 'Amiri',
  );

  // أحجام الخط للأذكار
  static TextStyle get athkarSmall => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    height: 1.6,
    fontFamily: 'Cairo',
  );

  static TextStyle get athkarMedium => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.normal,
    height: 1.8,
    fontFamily: 'Cairo',
  );

  static TextStyle get athkarLarge => TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.normal,
    height: 2.0,
    fontFamily: 'Cairo',
  );

  static TextStyle get athkarExtraLarge => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.normal,
    height: 2.2,
    fontFamily: 'Cairo',
  );
}