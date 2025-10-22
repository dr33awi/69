// lib/core/infrastructure/services/text/models/text_settings_models.dart
import 'package:flutter/material.dart';

/// تعداد أنواع المحتوى المختلفة في التطبيق
enum ContentType {
  athkar('athkar', 'أذكار'),
  dua('dua', 'دعاء'),
  asmaAllah('asma_allah', 'أسماء الله'),
  quran('quran', 'قرآن'),
  hadith('hadith', 'حديث');

  const ContentType(this.key, this.displayName);
  final String key;
  final String displayName;
}

/// إعدادات النص الموحدة
class TextSettings {
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final double letterSpacing;
  final bool showTashkeel;
  final bool showFadl;
  final bool showSource;
  final bool showCounter;
  final bool enableVibration;
  final ContentType contentType;

  const TextSettings({
    required this.fontSize,
    required this.fontFamily,
    required this.lineHeight,
    required this.letterSpacing,
    this.showTashkeel = true,
    this.showFadl = true,
    this.showSource = true,
    this.showCounter = true,
    this.enableVibration = true,
    required this.contentType,
  });

  /// نسخ إعدادات مع تغييرات محددة
  TextSettings copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    double? letterSpacing,
    bool? showTashkeel,
    bool? showFadl,
    bool? showSource,
    bool? showCounter,
    bool? enableVibration,
    ContentType? contentType,
  }) {
    return TextSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      showTashkeel: showTashkeel ?? this.showTashkeel,
      showFadl: showFadl ?? this.showFadl,
      showSource: showSource ?? this.showSource,
      showCounter: showCounter ?? this.showCounter,
      enableVibration: enableVibration ?? this.enableVibration,
      contentType: contentType ?? this.contentType,
    );
  }

  /// تحويل إلى TextStyle للاستخدام المباشر
  TextStyle toTextStyle({Color? color}) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      height: lineHeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// تحويل إلى JSON للحفظ
  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lineHeight': lineHeight,
      'letterSpacing': letterSpacing,
      'showTashkeel': showTashkeel,
      'showFadl': showFadl,
      'showSource': showSource,
      'showCounter': showCounter,
      'enableVibration': enableVibration,
      'contentType': contentType.key,
    };
  }

  /// إنشاء من JSON
  factory TextSettings.fromJson(Map<String, dynamic> json, ContentType contentType) {
    return TextSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
      fontFamily: json['fontFamily'] as String? ?? 'Cairo',
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.8,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.3,
      showTashkeel: json['showTashkeel'] as bool? ?? true,
      showFadl: json['showFadl'] as bool? ?? true,
      showSource: json['showSource'] as bool? ?? true,
      showCounter: json['showCounter'] as bool? ?? true,
      enableVibration: json['enableVibration'] as bool? ?? true,
      contentType: contentType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TextSettings &&
      other.fontSize == fontSize &&
      other.fontFamily == fontFamily &&
      other.lineHeight == lineHeight &&
      other.letterSpacing == letterSpacing &&
      other.showTashkeel == showTashkeel &&
      other.showFadl == showFadl &&
      other.showSource == showSource &&
      other.showCounter == showCounter &&
      other.enableVibration == enableVibration &&
      other.contentType == contentType;
  }

  @override
  int get hashCode {
    return Object.hash(
      fontSize,
      fontFamily,
      lineHeight,
      letterSpacing,
      showTashkeel,
      showFadl,
      showSource,
      showCounter,
      enableVibration,
      contentType,
    );
  }

  @override
  String toString() {
    return 'TextSettings('
        'fontSize: $fontSize, '
        'fontFamily: $fontFamily, '
        'lineHeight: $lineHeight, '
        'letterSpacing: $letterSpacing, '
        'contentType: ${contentType.displayName})';
  }
}

/// قالب جاهز لإعدادات النص
class TextStylePreset {
  final String id;
  final String name;
  final String description;
  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final IconData icon;

  const TextStylePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.fontSize,
    required this.lineHeight,
    required this.letterSpacing,
    required this.icon,
  });

  /// تطبيق القالب على الإعدادات الحالية
  TextSettings applyToSettings(TextSettings currentSettings) {
    return currentSettings.copyWith(
      fontSize: fontSize,
      lineHeight: lineHeight,
      letterSpacing: letterSpacing,
    );
  }
}

/// قوالب النصوص الجاهزة
class TextStylePresets {
  static const compact = TextStylePreset(
    id: 'compact',
    name: 'مضغوط',
    description: 'مناسب للشاشات الصغيرة',
    fontSize: 16.0,
    lineHeight: 1.5,
    letterSpacing: 0.1,
    icon: Icons.compress,
  );

  static const comfortable = TextStylePreset(
    id: 'comfortable',
    name: 'قراءة مريحة',
    description: 'متوازن ومناسب لمعظم الاستخدامات',
    fontSize: 20.0,
    lineHeight: 2.0,
    letterSpacing: 0.5,
    icon: Icons.visibility,
  );

  static const large = TextStylePreset(
    id: 'large',
    name: 'كبير',
    description: 'للقراءة الواضحة',
    fontSize: 24.0,
    lineHeight: 2.2,
    letterSpacing: 0.7,
    icon: Icons.zoom_in,
  );

  static const accessibility = TextStylePreset(
    id: 'accessibility',
    name: 'كبار السن',
    description: 'محسّن لكبار السن وضعاف البصر',
    fontSize: 28.0,
    lineHeight: 2.5,
    letterSpacing: 1.0,
    icon: Icons.accessibility,
  );

  /// جميع القوالب المتاحة
  static const List<TextStylePreset> all = [
    compact,
    comfortable,
    large,
    accessibility,
  ];

  /// البحث عن قالب بالمعرف
  static TextStylePreset? getById(String id) {
    try {
      return all.firstWhere((preset) => preset.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// إعدادات خاصة للعرض والتحكم
class DisplaySettings {
  final bool showTashkeel;
  final bool showFadl;
  final bool showSource;
  final bool showCounter;
  final bool enableVibration;
  final bool showTranslation;
  final bool showTransliteration;

  const DisplaySettings({
    this.showTashkeel = true,
    this.showFadl = true,
    this.showSource = true,
    this.showCounter = true,
    this.enableVibration = true,
    this.showTranslation = false,
    this.showTransliteration = false,
  });

  DisplaySettings copyWith({
    bool? showTashkeel,
    bool? showFadl,
    bool? showSource,
    bool? showCounter,
    bool? enableVibration,
    bool? showTranslation,
    bool? showTransliteration,
  }) {
    return DisplaySettings(
      showTashkeel: showTashkeel ?? this.showTashkeel,
      showFadl: showFadl ?? this.showFadl,
      showSource: showSource ?? this.showSource,
      showCounter: showCounter ?? this.showCounter,
      enableVibration: enableVibration ?? this.enableVibration,
      showTranslation: showTranslation ?? this.showTranslation,
      showTransliteration: showTransliteration ?? this.showTransliteration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showTashkeel': showTashkeel,
      'showFadl': showFadl,
      'showSource': showSource,
      'showCounter': showCounter,
      'enableVibration': enableVibration,
      'showTranslation': showTranslation,
      'showTransliteration': showTransliteration,
    };
  }

  factory DisplaySettings.fromJson(Map<String, dynamic> json) {
    return DisplaySettings(
      showTashkeel: json['showTashkeel'] as bool? ?? true,
      showFadl: json['showFadl'] as bool? ?? true,
      showSource: json['showSource'] as bool? ?? true,
      showCounter: json['showCounter'] as bool? ?? true,
      enableVibration: json['enableVibration'] as bool? ?? true,
      showTranslation: json['showTranslation'] as bool? ?? false,
      showTransliteration: json['showTransliteration'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is DisplaySettings &&
      other.showTashkeel == showTashkeel &&
      other.showFadl == showFadl &&
      other.showSource == showSource &&
      other.showCounter == showCounter &&
      other.enableVibration == enableVibration &&
      other.showTranslation == showTranslation &&
      other.showTransliteration == showTransliteration;
  }

  @override
  int get hashCode {
    return Object.hash(
      showTashkeel,
      showFadl,
      showSource,
      showCounter,
      enableVibration,
      showTranslation,
      showTransliteration,
    );
  }
}