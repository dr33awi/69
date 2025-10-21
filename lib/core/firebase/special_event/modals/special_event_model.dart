// lib/core/infrastructure/firebase/special_event/modals/special_event_model.dart
// ✅ محدث - إضافة دعم GIF

import 'package:flutter/material.dart';
import '../../../../app/themes/app_theme.dart';

/// موديل بيانات المناسبة الخاصة
class SpecialEventModel {
  final bool isActive;
  final String title;
  final dynamic description;
  final String icon;
  final String backgroundImage;
  final bool isGif; // ✅ جديد - للتحقق من نوع الصورة
  final List<Color> gradientColors;
  final String actionText;
  final String actionUrl;
  final DateTime? startDate;
  final DateTime? endDate;

  const SpecialEventModel({
    required this.isActive,
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundImage,
    this.isGif = false, // ✅ افتراضي false
    required this.gradientColors,
    required this.actionText,
    required this.actionUrl,
    this.startDate,
    this.endDate,
  });

  /// إنشاء من Map (Firebase)
  factory SpecialEventModel.fromMap(Map<String, dynamic> map) {
    final backgroundImage = map['background_image']?.toString() ?? '';
    
    return SpecialEventModel(
      isActive: map['is_active'] ?? false,
      title: map['title']?.toString() ?? '',
      description: map['description'],
      icon: map['icon']?.toString() ?? '',
      backgroundImage: backgroundImage,
      isGif: map['is_gif'] ?? _isGifUrl(backgroundImage), // ✅ من Firebase أو تلقائي
      gradientColors: _parseGradientColors(map['gradient_colors']),
      actionText: map['action_text']?.toString() ?? '',
      actionUrl: map['action_url']?.toString() ?? '',
      startDate: _parseDate(map['start_date']),
      endDate: _parseDate(map['end_date']),
    );
  }

  /// موديل فارغ
  factory SpecialEventModel.empty() {
    return SpecialEventModel(
      isActive: false,
      title: '',
      description: '',
      icon: '',
      backgroundImage: '',
      isGif: false,
      gradientColors: _getDefaultColors(),
      actionText: '',
      actionUrl: '',
    );
  }

  /// ✅ التحقق تلقائياً من امتداد الرابط
  static bool _isGifUrl(String url) {
    if (url.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.gif') || lowerUrl.contains('.gif?');
  }

  /// getter للحصول على قائمة النصوص
  List<String> get descriptionLines {
    if (description is List) {
      return (description as List)
          .map((e) => e.toString())
          .where((line) => line.isNotEmpty)
          .toList();
    } else if (description is String) {
      final text = description as String;
      if (text.contains('\n')) {
        return text.split('\n').where((line) => line.trim().isNotEmpty).toList();
      } else if (text.contains('|')) {
        return text.split('|').where((line) => line.trim().isNotEmpty).toList();
      }
      return [text];
    }
    return [];
  }

  /// الحصول على وصف واحد للتوافق
  String get descriptionText {
    final lines = descriptionLines;
    if (lines.isEmpty) return '';
    return lines.join(' • ');
  }

  /// التحقق من صلاحية المناسبة
  bool get isValid {
    if (!isActive || title.isEmpty) return false;
    
    final now = DateTime.now();
    
    if (startDate == null && endDate == null) return true;
    
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    return true;
  }

  /// حساب الوقت المتبقي
  Duration? get remainingTime {
    if (endDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return null;
    return endDate!.difference(now);
  }

  /// دالة للحصول على الألوان الافتراضية من ThemeConstants
  static List<Color> _getDefaultColors() {
    return [
      ThemeConstants.primary,
      ThemeConstants.primaryDark,
    ];
  }

  /// تحويل الألوان من HEX
  static List<Color> _parseGradientColors(dynamic colorsData) {
    if (colorsData == null || colorsData is! List || colorsData.isEmpty) {
      return _getDefaultColors();
    }

    try {
      final colors = colorsData
          .map((colorHex) => _parseHexColor(colorHex.toString()))
          .where((color) => color != null)
          .cast<Color>()
          .toList();

      if (colors.isEmpty) {
        return _getDefaultColors();
      } else if (colors.length == 1) {
        colors.add(colors.first.withOpacity(0.7));
      }
      
      return colors;
    } catch (e) {
      return _getDefaultColors();
    }
  }

  /// تحويل HEX لـ Color
  static Color? _parseHexColor(String hexColor) {
    try {
      String hex = hexColor.trim();
      
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      }
      
      if (hex.length == 6) {
        hex = 'FF$hex';
      } else if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
        hex = 'FF$hex';
      } else if (hex.length != 8) {
        return null;
      }
      
      return Color(int.parse('0x$hex'));
    } catch (e) {
      return null;
    }
  }

  /// تحويل التاريخ
  static DateTime? _parseDate(dynamic dateData) {
    if (dateData == null) return null;
    
    try {
      final dateStr = dateData.toString();
      if (dateStr.isEmpty || dateStr == 'null') return null;
      return DateTime.tryParse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'is_active': isActive,
      'title': title,
      'description': description,
      'icon': icon,
      'background_image': backgroundImage,
      'is_gif': isGif, // ✅ إضافة الحقل الجديد
      'gradient_colors': gradientColors.map((c) => '#${c.value.toRadixString(16).substring(2)}').toList(),
      'action_text': actionText,
      'action_url': actionUrl,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  /// نسخ مع تعديل
  SpecialEventModel copyWith({
    bool? isActive,
    String? title,
    dynamic description,
    String? icon,
    String? backgroundImage,
    bool? isGif,
    List<Color>? gradientColors,
    String? actionText,
    String? actionUrl,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return SpecialEventModel(
      isActive: isActive ?? this.isActive,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      isGif: isGif ?? this.isGif,
      gradientColors: gradientColors ?? this.gradientColors,
      actionText: actionText ?? this.actionText,
      actionUrl: actionUrl ?? this.actionUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  String toString() {
    return 'SpecialEventModel(title: $title, isActive: $isActive, isValid: $isValid, isGif: $isGif)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SpecialEventModel &&
        other.isActive == isActive &&
        other.title == title &&
        other.icon == icon &&
        other.backgroundImage == backgroundImage &&
        other.isGif == isGif &&
        other.actionText == actionText &&
        other.actionUrl == actionUrl &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      isActive,
      title,
      icon,
      backgroundImage,
      isGif,
      actionText,
      actionUrl,
      startDate,
      endDate,
    );
  }
}