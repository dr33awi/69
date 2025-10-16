// lib/core/infrastructure/firebase/promotional_banners/models/promotional_banner_model.dart

import 'package:flutter/material.dart';

/// موديل البانر الترويجي
class PromotionalBanner {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String actionUrl;
  final String actionText;
  final BannerPriority priority;
  final BannerType type;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> targetScreens;
  final List<String> targetCountries;
  final List<Color> gradientColors;
  final String icon;
  final int maxDisplayCount; // عدد مرات العرض القصوى
  final Duration minDisplayInterval; // الحد الأدنى بين العروض
  
  const PromotionalBanner({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl = '',
    this.actionUrl = '',
    this.actionText = 'اكتشف المزيد',
    this.priority = BannerPriority.normal,
    this.type = BannerType.card,
    required this.startDate,
    required this.endDate,
    this.targetScreens = const [],
    this.targetCountries = const [],
    List<Color>? gradientColors,
    this.icon = '🎉',
    this.maxDisplayCount = 5,
    this.minDisplayInterval = const Duration(hours: 12),
  }) : gradientColors = gradientColors ?? const [Color(0xFF6B46C1), Color(0xFF9333EA)];

  /// هل البانر نشط؟
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// هل البانر مستهدف لهذه الشاشة؟
  bool isTargetingScreen(String? screenName) {
    if (screenName == null) return true;
    if (targetScreens.isEmpty) return true;
    return targetScreens.contains(screenName);
  }

  /// هل البانر مستهدف لهذا البلد؟
  bool isTargetingCountry(String? countryCode) {
    if (countryCode == null) return true;
    if (targetCountries.isEmpty) return true;
    return targetCountries.contains(countryCode);
  }

  /// حساب النقاط للترتيب
  int get priorityScore {
    int score = priority.points;
    
    // زيادة النقاط للبانرات القريبة من الانتهاء
    final now = DateTime.now();
    final remaining = endDate.difference(now);
    
    if (remaining.inDays <= 1) {
      score += 50; // ينتهي اليوم!
    } else if (remaining.inDays <= 3) {
      score += 30; // ينتهي قريباً
    } else if (remaining.inDays <= 7) {
      score += 10; // أقل من أسبوع
    }
    
    return score;
  }

  /// الوقت المتبقي
  Duration? get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return null;
    return endDate.difference(now);
  }

  /// إنشاء من Map (Firebase)
  factory PromotionalBanner.fromMap(Map<String, dynamic> map) {
    return PromotionalBanner(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      actionUrl: map['action_url']?.toString() ?? '',
      actionText: map['action_text']?.toString() ?? 'اكتشف المزيد',
      priority: BannerPriority.fromString(map['priority']?.toString()),
      type: BannerType.fromString(map['type']?.toString()),
      startDate: _parseDate(map['start_date']) ?? DateTime.now(),
      endDate: _parseDate(map['end_date']) ?? DateTime.now().add(const Duration(days: 7)),
      targetScreens: _parseStringList(map['target_screens']),
      targetCountries: _parseStringList(map['target_countries']),
      gradientColors: _parseGradientColors(map['gradient_colors']),
      icon: map['icon']?.toString() ?? '🎉',
      maxDisplayCount: map['max_display_count'] as int? ?? 5,
      minDisplayInterval: Duration(
        hours: map['min_display_interval_hours'] as int? ?? 12,
      ),
    );
  }

  /// تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'action_text': actionText,
      'priority': priority.name,
      'type': type.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'target_screens': targetScreens,
      'target_countries': targetCountries,
      'gradient_colors': gradientColors.map((c) => '#${c.value.toRadixString(16).substring(2)}').toList(),
      'icon': icon,
      'max_display_count': maxDisplayCount,
      'min_display_interval_hours': minDisplayInterval.inHours,
    };
  }

  // Helper methods
  static DateTime? _parseDate(dynamic dateData) {
    if (dateData == null) return null;
    try {
      return DateTime.parse(dateData.toString());
    } catch (e) {
      return null;
    }
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<Color> _parseGradientColors(dynamic colorsData) {
    if (colorsData == null || colorsData is! List || colorsData.isEmpty) {
      return [const Color(0xFF6B46C1), const Color(0xFF9333EA)];
    }

    try {
      final colors = colorsData
          .map((colorHex) => _parseHexColor(colorHex.toString()))
          .where((color) => color != null)
          .cast<Color>()
          .toList();

      if (colors.isEmpty) {
        return [const Color(0xFF6B46C1), const Color(0xFF9333EA)];
      } else if (colors.length == 1) {
        colors.add(colors.first.withOpacity(0.7));
      }

      return colors;
    } catch (e) {
      return [const Color(0xFF6B46C1), const Color(0xFF9333EA)];
    }
  }

  static Color? _parseHexColor(String hexColor) {
    try {
      String hex = hexColor.trim();
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse('0x$hex'));
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => 'PromotionalBanner(id: $id, title: $title, priority: ${priority.name})';
}

/// أولويات البانر
enum BannerPriority {
  low(100),
  normal(200),
  high(300),
  urgent(400);

  final int points;
  const BannerPriority(this.points);

  static BannerPriority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low': return BannerPriority.low;
      case 'high': return BannerPriority.high;
      case 'urgent': return BannerPriority.urgent;
      default: return BannerPriority.normal;
    }
  }
}

/// أنواع البانر
enum BannerType {
  card,      // كارد عادي
  carousel,  // سلايدر متعدد
  dialog,    // نافذة منبثقة
  inline,    // مدمج في المحتوى
  sticky;    // ثابت في الأعلى

  static BannerType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'carousel': return BannerType.carousel;
      case 'dialog': return BannerType.dialog;
      case 'inline': return BannerType.inline;
      case 'sticky': return BannerType.sticky;
      default: return BannerType.card;
    }
  }
}