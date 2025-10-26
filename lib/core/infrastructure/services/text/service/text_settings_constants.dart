// lib/core/infrastructure/services/text/constants/text_settings_constants.dart
import '../models/text_settings_models.dart';

/// ثوابت إعدادات النصوص
class TextSettingsConstants {
  TextSettingsConstants._();

  // نطاقات القيم
  static const double minFontSize = 14.0;
  static const double maxFontSize = 32.0;
  static const double minLineHeight = 1.0;
  static const double maxLineHeight = 3.0;
  static const double minLetterSpacing = -0.5;
  static const double maxLetterSpacing = 2.0;

  // الإعدادات الافتراضية لكل نوع محتوى
  static TextSettings getDefaultSettings(ContentType contentType) {
    switch (contentType) {
      case ContentType.athkar:
        return const TextSettings(
          contentType: ContentType.athkar,
          fontSize: 18.0,
          fontFamily: 'Amiri',
          lineHeight: 1.8,
          letterSpacing: 0.3,
        );
      case ContentType.dua:
        return const TextSettings(
          contentType: ContentType.dua,
          fontSize: 18.0,
          fontFamily: 'Amiri',
          lineHeight: 1.8,
          letterSpacing: 0.3,
        );
      case ContentType.asmaAllah:
        return const TextSettings(
          contentType: ContentType.asmaAllah,
          fontSize: 20.0,
          fontFamily: 'Amiri',
          lineHeight: 2.0,
          letterSpacing: 0.5,
        );
    }
  }

  // إعدادات العرض الافتراضية
  static const DisplaySettings defaultDisplaySettings = DisplaySettings(
    showTashkeel: true,
    showFadl: true,
    showSource: true,
    showCounter: true,
    enableVibration: true,
  );

  // الخطوط المتاحة
  static const List<String> availableFonts = [
    'Amiri',
    'Lateef',
    'Scheherazade',
    'Cairo',
    'Tajawal',
    'Almarai',
    'ElMessiri',
    'Markazi',
    'Noto Naskh Arabic',
    'Harmattan',
  ];

  // أسماء الخطوط المعروضة بالعربية
  static const Map<String, String> fontDisplayNames = {
    'Amiri': 'أميري',
    'Lateef': 'لطيف',
    'Scheherazade': 'شهرزاد',
    'Cairo': 'القاهرة',
    'Tajawal': 'تجوال',
    'Almarai': 'المرعي',
    'ElMessiri': 'المسيري',
    'Markazi': 'مركزي',
    'Noto Naskh Arabic': 'نسخ',
    'Harmattan': 'هرمتن',
  };
}

/// قالب نمط النص (بدون أيقونات - متوافق مع التصميم الجديد)
class TextStylePreset {
  final String name;
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;

  const TextStylePreset({
    required this.name,
    required this.fontSize,
    required this.lineHeight,
    required this.letterSpacing,
  });

  /// تطبيق القالب على إعدادات موجودة
  TextSettings applyToSettings(TextSettings currentSettings) {
    return currentSettings.copyWith(
      fontSize: fontSize,
      lineHeight: lineHeight,
      letterSpacing: letterSpacing,
    );
  }
}

/// القوالب الجاهزة
class TextStylePresets {
  TextStylePresets._();

  // قالب قراءة مريحة - للقراءة الطويلة والمريحة
  static const comfortable = TextStylePreset(
    name: 'قراءة مريحة',
    fontSize: 22.0,
    lineHeight: 2.0,
    letterSpacing: 0.5,
  );

  // قالب واضح - الإعداد القياسي والافتراضي
  static const clear = TextStylePreset(
    name: 'واضح',
    fontSize: 18.0,
    lineHeight: 1.8,
    letterSpacing: 0.3,
  );

  // قالب مضغوط - لعرض المزيد من المحتوى
  static const compact = TextStylePreset(
    name: 'مضغوط',
    fontSize: 16.0,
    lineHeight: 1.5,
    letterSpacing: 0.2,
  );

  // قالب موسع - حجم كبير مع تباعد واسع
  static const expanded = TextStylePreset(
    name: 'موسع',
    fontSize: 24.0,
    lineHeight: 2.2,
    letterSpacing: 0.8,
  );

  /// قائمة جميع القوالب المتاحة
  /// 
  /// 🎯 للتحكم بالقوالب المعروضة:
  /// - احذف أي سطر لإخفاء القالب
  /// - أضف قوالب جديدة (بعد تعريفها أعلاه)
  /// - رتّب القوالب حسب الأولوية
  /// 
  /// مثال:
  /// static const List<TextStylePreset> all = [
  ///   comfortable,  // ✅ سيظهر
  ///   clear,        // ✅ سيظهر
  ///   // compact,   // ❌ معلق - لن يظهر
  /// ];
  static const List<TextStylePreset> all = [
    comfortable,  // قراءة مريحة
    clear,        // واضح
    // compact,   // مضغوط (معطل)
    // expanded,  // موسع (معطل)
  ];
}