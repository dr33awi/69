// lib/app/themes/core/color_helper.dart
import 'package:flutter/material.dart';

/// مساعد الألوان - يوفر جميع الألوان والتدرجات اللونية للتطبيق
class AppColors {
  AppColors._();

  // ==================== الألوان الأساسية ====================
  
  /// اللون الأساسي للتطبيق (أخضر طبيعي)
  static const Color primary = Color(0xFF5D7052);
  
  /// اللون الأساسي الفاتح
  static const Color primaryLight = Color(0xFF7A8F6E);
  
  /// اللون الأساسي الداكن
  static const Color primaryDark = Color(0xFF4A5A42);
  
  /// اللون الأساسي الناعم
  static const Color primarySoft = Color(0xFF8B9E7E);

  // ==================== الألوان الثانوية ====================
  
  /// اللون الثانوي (بني دافئ)
  static const Color accent = Color(0xFF8B7355);
  
  /// اللون الثانوي الفاتح
  static const Color accentLight = Color(0xFFA89780);
  
  /// اللون الثانوي الداكن
  static const Color accentDark = Color(0xFF6D5A44);

  // ==================== الألوان الثالثية ====================
  
  /// اللون الثالثي (بني ذهبي)
  static const Color tertiary = Color(0xFF9B6B43);
  
  /// اللون الثالثي الفاتح
  static const Color tertiaryLight = Color(0xFFB8856F);
  
  /// اللون الثالثي الداكن
  static const Color tertiaryDark = Color(0xFF7D5636);

  // ==================== ألوان الحالة ====================
  
  /// لون النجاح (أخضر)
  static const Color success = Color(0xFF4CAF50);
  
  /// لون الخطأ (أحمر)
  static const Color error = Color(0xFFE53935);
  
  /// لون التحذير (برتقالي)
  static const Color warning = Color(0xFFFF9800);
  
  /// لون المعلومات (أزرق)
  static const Color info = Color(0xFF2196F3);

  // ==================== ألوان الوضع الفاتح ====================
  
  /// خلفية رئيسية فاتحة
  static const Color lightBackground = Color(0xFFFAFAFA);
  
  /// سطح فاتح
  static const Color lightSurface = Color(0xFFFFFFFF);
  
  /// بطاقة فاتحة
  static const Color lightCard = Color(0xFFFFFFFF);
  
  /// فاصل فاتح
  static const Color lightDivider = Color(0xFFE0E0E0);
  
  /// نص أساسي فاتح
  static const Color lightTextPrimary = Color(0xFF212121);
  
  /// نص ثانوي فاتح
  static const Color lightTextSecondary = Color(0xFF757575);
  
  /// نص تلميحي فاتح
  static const Color lightTextHint = Color(0xFFBDBDBD);

  // ==================== ألوان الوضع الداكن ====================
  
  /// خلفية رئيسية داكنة
  static const Color darkBackground = Color(0xFF121212);
  
  /// سطح داكن
  static const Color darkSurface = Color(0xFF1E1E1E);
  
  /// بطاقة داكنة
  static const Color darkCard = Color(0xFF2C2C2C);
  
  /// فاصل داكن
  static const Color darkDivider = Color(0xFF3A3A3A);
  
  /// نص أساسي داكن
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  
  /// نص ثانوي داكن
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  
  /// نص تلميحي داكن
  static const Color darkTextHint = Color(0xFF6E6E6E);

  // ==================== التدرجات اللونية ====================
  
  /// تدرج اللون الأساسي
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  /// تدرج اللون الثانوي
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );
  
  /// تدرج اللون الثالثي
  static const LinearGradient tertiaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tertiary, tertiaryDark],
  );

  // ==================== دوال مساعدة ====================
  
  /// الحصول على لون الخلفية حسب الوضع
  static Color getBackground(bool isDark) {
    return isDark ? darkBackground : lightBackground;
  }
  
  /// الحصول على لون السطح حسب الوضع
  static Color getSurface(bool isDark) {
    return isDark ? darkSurface : lightSurface;
  }
  
  /// الحصول على لون البطاقة حسب الوضع
  static Color getCard(bool isDark) {
    return isDark ? darkCard : lightCard;
  }
  
  /// الحصول على لون النص الأساسي حسب الوضع
  static Color getTextPrimary(bool isDark) {
    return isDark ? darkTextPrimary : lightTextPrimary;
  }
  
  /// الحصول على لون النص الثانوي حسب الوضع
  static Color getTextSecondary(bool isDark) {
    return isDark ? darkTextSecondary : lightTextSecondary;
  }
  
  /// الحصول على لون الفاصل حسب الوضع
  static Color getDivider(bool isDark) {
    return isDark ? darkDivider : lightDivider;
  }

  // ==================== ألوان مواقيت الصلاة ====================
  
  /// الحصول على لون الصلاة
  static Color getPrayerColor(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
      case 'الفجر':
        return const Color(0xFF4A5A82); // أزرق داكن
      case 'dhuhr':
      case 'الظهر':
        return const Color(0xFFD4A574); // ذهبي
      case 'asr':
      case 'العصر':
        return const Color(0xFFE89D5B); // برتقالي
      case 'maghrib':
      case 'المغرب':
        return const Color(0xFFD66B6B); // أحمر وردي
      case 'isha':
      case 'العشاء':
        return const Color(0xFF5A4A7A); // بنفسجي داكن
      case 'sunrise':
      case 'الشروق':
        return const Color(0xFFFFA726); // برتقالي فاتح
      default:
        return primary;
    }
  }
  
  /// الحصول على تدرج الصلاة
  static LinearGradient getPrayerGradient(String prayerName) {
    final color = getPrayerColor(prayerName);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        Color.lerp(color, Colors.black, 0.2)!,
      ],
    );
  }

  // ==================== تدرجات الأقسام ====================
  
  /// الحصول على تدرج القسم
  static LinearGradient getCategoryGradient(String categoryId) {
    switch (categoryId) {
      case 'prayer_times':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5D7052), Color(0xFF4A5A42)],
        );
      
      case 'athkar':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B7355), Color(0xFF6D5A44)],
        );
      
      case 'asma_allah':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B6B43), Color(0xFF7D5636)],
        );
      
      case 'quran':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C5F2D), Color(0xFF234A24)],
        );
      
      case 'qibla':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF556B2F), Color(0xFF445522)],
        );
      
      case 'tasbih':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B8E23), Color(0xFF5A7320)],
        );
      
      case 'dua':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B7355), Color(0xFF6D5A44)],
        );
      
      default:
        return primaryGradient;
    }
  }

  // ==================== تدرج حسب الوقت ====================
  
  /// تدرج لوني حسب وقت اليوم
  static LinearGradient getTimeBasedGradient() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      // صباح: أصفر وبرتقالي
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE082), Color(0xFFFFB74D)],
      );
    } else if (hour >= 12 && hour < 17) {
      // ظهر: أزرق سماوي
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF81D4FA), Color(0xFF4FC3F7)],
      );
    } else if (hour >= 17 && hour < 20) {
      // مساء: برتقالي وأحمر
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF8A65), Color(0xFFE64A19)],
      );
    } else {
      // ليل: أزرق داكن وبنفسجي
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5E35B1), Color(0xFF311B92)],
      );
    }
  }

  // ==================== إنشاء تدرج مخصص ====================
  
  /// إنشاء تدرج لوني مخصص
  static LinearGradient createCustomGradient({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<double>? stops,
  }) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
    );
  }
  
  /// إنشاء تدرج شعاعي
  static RadialGradient createRadialGradient({
    required List<Color> colors,
    AlignmentGeometry center = Alignment.center,
    double radius = 0.5,
    List<double>? stops,
  }) {
    return RadialGradient(
      center: center,
      radius: radius,
      colors: colors,
      stops: stops,
    );
  }
}

// ==================== Extension للألوان ====================

extension ColorExtension on Color {
  /// تفتيح اللون
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// تغميق اللون
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// تشبع اللون
  Color saturate([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final saturation = (hsl.saturation + amount).clamp(0.0, 1.0);
    return hsl.withSaturation(saturation).toColor();
  }

  /// إزالة تشبع اللون
  Color desaturate([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final saturation = (hsl.saturation - amount).clamp(0.0, 1.0);
    return hsl.withSaturation(saturation).toColor();
  }

  /// الحصول على اللون المتباين للنص
  Color get contrastingTextColor {
    final luminance = computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// تحويل إلى Hex String
  String toHex() {
    return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}