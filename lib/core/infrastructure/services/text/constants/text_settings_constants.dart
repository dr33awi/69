// lib/core/infrastructure/services/text/constants/text_settings_constants.dart
import '../models/text_settings_models.dart';

/// ثوابت إعدادات النصوص الموحدة
class TextSettingsConstants {
  TextSettingsConstants._();

  // ==================== مفاتيح التخزين ====================
  
  /// مفاتيح التخزين لكل نوع محتوى
  static const String _baseKey = 'global_text_settings';
  
  static String getSettingsKey(ContentType contentType) => '${_baseKey}_${contentType.key}';
  static String getDisplaySettingsKey(ContentType contentType) => '${_baseKey}_display_${contentType.key}';
  
  // مفاتيح خاصة
  static const String lastUsedPresetKey = 'text_settings_last_preset';
  static const String globalFontFamilyKey = 'text_settings_global_font_family';
  static const String settingsVersionKey = 'text_settings_version';
  
  // ==================== إصدار الإعدادات ====================
  static const int currentVersion = 1;
  
  // ==================== الحدود والقيم ====================
  
  /// حدود حجم الخط
  static const double minFontSize = 12.0;
  static const double maxFontSize = 36.0;
  static const double defaultFontSize = 18.0;
  
  /// حدود تباعد الأسطر
  static const double minLineHeight = 1.0;
  static const double maxLineHeight = 3.0;
  static const double defaultLineHeight = 1.8;
  
  /// حدود تباعد الأحرف
  static const double minLetterSpacing = 0.0;
  static const double maxLetterSpacing = 2.0;
  static const double defaultLetterSpacing = 0.3;
  
  // ==================== الخطوط المتاحة ====================
  
  /// قائمة الخطوط المتاحة في التطبيق
  static const Map<String, String> availableFonts = {
    'Cairo': 'القاهرة',
    'Amiri': 'أميري',
    'Scheherazade New': 'شهرزاد الجديدة',
    'Lateef': 'لطيف',
    'Tajawal': 'تجوال',
    'Harmattan': 'هرمتان',
    'Aref Ruqaa': 'عارف رقعة',
  };
  
  /// أوصاف الخطوط لمساعدة المستخدم
  static const Map<String, String> fontDescriptions = {
    'Cairo': 'خط حديث ومتوازن للاستخدام العام',
    'Amiri': 'خط تقليدي فاخر مناسب للنصوص الدينية',
    'Scheherazade New': 'رائع للنصوص الطويلة والقراءة المريحة',
    'Lateef': 'واضح ومقروء بشكل ممتاز',
    'Tajawal': 'عصري وأنيق للتصاميم الحديثة',
    'Harmattan': 'مميز ومناسب للعناوين والنصوص البارزة',
    'Aref Ruqaa': 'خط رقعة تقليدي وأصيل',
  };
  
  /// تصنيف الخطوط حسب الاستخدام الموصى به
  static const Map<String, List<String>> fontCategories = {
    'reading': ['Scheherazade New', 'Lateef', 'Cairo'],
    'traditional': ['Amiri', 'Aref Ruqaa'],
    'modern': ['Cairo', 'Tajawal', 'Harmattan'],
    'headers': ['Harmattan', 'Amiri', 'Aref Ruqaa'],
  };
  
  /// الخط الافتراضي
  static const String defaultFontFamily = 'Cairo';
  
  // ==================== الإعدادات الافتراضية حسب نوع المحتوى ====================
  
  /// إعدادات الأذكار الافتراضية
  static const TextSettings defaultAthkarSettings = TextSettings(
    fontSize: 18.0,
    fontFamily: 'Cairo',
    lineHeight: 1.8,
    letterSpacing: 0.3,
    showTashkeel: true,
    showFadl: true,
    showSource: true,
    showCounter: true,
    enableVibration: true,
    contentType: ContentType.athkar,
  );
  
  /// إعدادات الدعاء الافتراضية
  static const TextSettings defaultDuaSettings = TextSettings(
    fontSize: 20.0,
    fontFamily: 'Scheherazade New',
    lineHeight: 1.9,
    letterSpacing: 0.4,
    showTashkeel: true,
    showFadl: true,
    showSource: true,
    showCounter: false,
    enableVibration: true,
    contentType: ContentType.dua,
  );
  
  /// إعدادات أسماء الله الافتراضية
  static const TextSettings defaultAsmaAllahSettings = TextSettings(
    fontSize: 30.0,
    fontFamily: 'Amiri',
    lineHeight: 2.0,
    letterSpacing: 0.5,
    showTashkeel: true,
    showFadl: true,
    showSource: true,
    showCounter: false,
    enableVibration: true,
    contentType: ContentType.asmaAllah,
  );
  
  // ==================== خريطة الإعدادات الافتراضية ====================
  
  /// الحصول على الإعدادات الافتراضية لنوع محتوى معين
  static TextSettings getDefaultSettings(ContentType contentType) {
    switch (contentType) {
      case ContentType.athkar:
        return defaultAthkarSettings;
      case ContentType.dua:
        return defaultDuaSettings;
      case ContentType.asmaAllah:
        return defaultAsmaAllahSettings;
    }
  }
  
  // ==================== إعدادات العرض الافتراضية ====================
  
  static const DisplaySettings defaultDisplaySettings = DisplaySettings(
    showTashkeel: true,
    showFadl: true,
    showSource: true,
    showCounter: true,
    enableVibration: true,
    showTranslation: false,
    showTransliteration: false,
  );
  
  // ==================== القوالب المحسّنة حسب نوع المحتوى ====================
  
  /// قوالب خاصة بالأذكار
  static const Map<String, Map<String, double>> athkarPresets = {
    'compact': {
      'fontSize': 16.0,
      'lineHeight': 1.5,
      'letterSpacing': 0.2,
    },
    'comfortable': {
      'fontSize': 18.0,
      'lineHeight': 1.8,
      'letterSpacing': 0.3,
    },
    'accessibility': {
      'fontSize': 36.0,
      'lineHeight': 2.3,
      'letterSpacing': 0.8,
    },
  };
  
  /// قوالب خاصة بالدعاء
  static const Map<String, Map<String, double>> duaPresets = {
    'compact': {
      'fontSize': 18.0,
      'lineHeight': 1.6,
      'letterSpacing': 0.3,
    },
    'comfortable': {
      'fontSize': 20.0,
      'lineHeight': 1.9,
      'letterSpacing': 0.4,
    },
    'accessibility': {
      'fontSize': 28.0,
      'lineHeight': 2.4,
      'letterSpacing': 0.9,
    },
  };
  
  /// قوالب خاصة بأسماء الله
  static const Map<String, Map<String, double>> asmaAllahPresets = {
    'compact': {
      'fontSize': 20.0,
      'lineHeight': 1.7,
      'letterSpacing': 0.4,
    },
    'comfortable': {
      'fontSize': 22.0,
      'lineHeight': 2.0,
      'letterSpacing': 0.5,
    },
    'accessibility': {
      'fontSize': 30.0,
      'lineHeight': 2.5,
      'letterSpacing': 1.0,
    },
  };
  
  /// الحصول على قوالب محددة حسب نوع المحتوى
  static Map<String, Map<String, double>> getPresetsForContentType(ContentType contentType) {
    switch (contentType) {
      case ContentType.athkar:
        return athkarPresets;
      case ContentType.dua:
        return duaPresets;
      case ContentType.asmaAllah:
        return asmaAllahPresets;
    }
  }
  
  // ==================== دوال مساعدة ====================
  
  /// التحقق من صحة حجم الخط
  static double clampFontSize(double fontSize) {
    return fontSize.clamp(minFontSize, maxFontSize);
  }
  
  /// التحقق من صحة تباعد الأسطر
  static double clampLineHeight(double lineHeight) {
    return lineHeight.clamp(minLineHeight, maxLineHeight);
  }
  
  /// التحقق من صحة تباعد الأحرف
  static double clampLetterSpacing(double letterSpacing) {
    return letterSpacing.clamp(minLetterSpacing, maxLetterSpacing);
  }
  
  /// التحقق من صحة الخط
  static String validateFontFamily(String fontFamily) {
    return availableFonts.containsKey(fontFamily) ? fontFamily : defaultFontFamily;
  }
  
  /// التحقق من صحة نوع المحتوى
  static ContentType parseContentType(String? contentTypeKey) {
    if (contentTypeKey == null) return ContentType.athkar;
    
    try {
      return ContentType.values.firstWhere(
        (type) => type.key == contentTypeKey,
      );
    } catch (_) {
      return ContentType.athkar;
    }
  }
  
  /// الحصول على الخط المناسب لنوع المحتوى
  static String getRecommendedFontFamily(ContentType contentType) {
    switch (contentType) {
      case ContentType.athkar:
        return 'Cairo';
      case ContentType.dua:
        return 'Scheherazade New';
      case ContentType.asmaAllah:
        return 'Amiri';
    }
  }
  
  /// الحصول على وصف الخط
  static String getFontDescription(String fontFamily) {
    return fontDescriptions[fontFamily] ?? 'خط عربي جميل';
  }
  
  /// الحصول على الخطوط الموصى بها لنوع المحتوى
  static List<String> getRecommendedFontsForContentType(ContentType contentType) {
    switch (contentType) {
      case ContentType.athkar:
        return ['Cairo', 'Lateef', 'Tajawal'];
      case ContentType.dua:
        return ['Scheherazade New', 'Amiri', 'Lateef'];
      case ContentType.asmaAllah:
        return ['Amiri', 'Harmattan', 'Aref Ruqaa'];
    }
  }
  
  /// التحقق من وجود الخط في القائمة
  static bool isFontAvailable(String fontFamily) {
    return availableFonts.containsKey(fontFamily);
  }
  
  /// الحصول على اسم الخط بالعربي
  static String getFontDisplayName(String fontFamily) {
    return availableFonts[fontFamily] ?? fontFamily;
  }
  
  /// الحصول على جميع الخطوط المتاحة كقائمة
  static List<String> getAllFontFamilies() {
    return availableFonts.keys.toList();
  }
  
  /// الحصول على الخطوط حسب التصنيف
  static List<String> getFontsByCategory(String category) {
    return fontCategories[category] ?? [];
  }
  
  /// التحقق من أن الخط موصى به لنوع المحتوى
  static bool isRecommendedFont(String fontFamily, ContentType contentType) {
    final recommended = getRecommendedFontsForContentType(contentType);
    return recommended.contains(fontFamily);
  }
}

/// قالب نمط النص
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
    fontSize: 32.0,
    lineHeight: 2.0,
    letterSpacing: 0.5,
  );

  // قالب واضح - الإعداد القياسي والافتراضي
  static const clear = TextStylePreset(
    name: 'واضح',
    fontSize: 36.0,
    lineHeight: 1.8,
    letterSpacing: 0.3,
  );

  // قالب مضغوط - لعرض المزيد من المحتوى
  static const compact = TextStylePreset(
    name: 'مضغوط',
    fontSize: 20.0,
    lineHeight: 1.5,
    letterSpacing: 0.2,
  );

  /// قائمة جميع القوالب المتاحة
  /// 
  /// للتحكم بالقوالب المعروضة:
  /// - احذف أي سطر لإخفاء القالب
  /// - أضف قوالب جديدة بعد تعريفها أعلاه
  /// - رتّب القوالب حسب الأولوية
  static const List<TextStylePreset> all = [
    comfortable,  // قراءة مريحة
    clear,        // واضح
    compact,      // مضغوط
  ];
}