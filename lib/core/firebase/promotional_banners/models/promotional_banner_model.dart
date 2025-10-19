// lib/core/infrastructure/firebase/promotional_banners/models/promotional_banner_model.dart

import 'package:flutter/material.dart';

/// نموذج البانر الترويجي
class PromotionalBanner {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? emoji;
  final List<Color> gradientColors;
  final String? actionText;
  final String? actionRoute;
  final String? actionUrl;
  final BannerPriority priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> targetScreens;
  final int displayFrequencyHours;
  final bool isActive;

  const PromotionalBanner({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.emoji,
    required this.gradientColors,
    this.actionText,
    this.actionRoute,
    this.actionUrl,
    this.priority = BannerPriority.normal,
    this.startDate,
    this.endDate,
    this.targetScreens = const ['home'],
    this.displayFrequencyHours = 24,
    this.isActive = true,
  });

  /// تحويل من JSON
  factory PromotionalBanner.fromJson(Map<String, dynamic> json) {
    try {
      // تحويل Gradient Colors
      List<Color> gradientColors = [];
      if (json['gradient_colors'] != null) {
        final colors = json['gradient_colors'] as List;
        gradientColors = colors
            .map((colorHex) => _parseColor(colorHex.toString()))
            .toList();
      }

      // إذا لم تكن هناك ألوان، استخدم الألوان الافتراضية
      if (gradientColors.isEmpty) {
        gradientColors = [
          const Color(0xFF9C27B0),
          const Color(0xFF673AB7),
        ];
      }

      // تحويل Target Screens
      List<String> targetScreens = ['home'];
      if (json['target_screens'] != null) {
        targetScreens = (json['target_screens'] as List)
            .map((e) => e.toString())
            .toList();
      }

      // تحويل التواريخ
      DateTime? startDate;
      DateTime? endDate;
      
      if (json['start_date'] != null) {
        startDate = DateTime.tryParse(json['start_date'].toString());
      }
      
      if (json['end_date'] != null) {
        endDate = DateTime.tryParse(json['end_date'].toString());
      }

      // تحويل Priority
      BannerPriority priority = BannerPriority.normal;
      if (json['priority'] != null) {
        switch (json['priority'].toString().toLowerCase()) {
          case 'high':
            priority = BannerPriority.high;
            break;
          case 'urgent':
            priority = BannerPriority.urgent;
            break;
          default:
            priority = BannerPriority.normal;
        }
      }

      return PromotionalBanner(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        imageUrl: json['image_url']?.toString(),
        emoji: json['emoji']?.toString(),
        gradientColors: gradientColors,
        actionText: json['action_text']?.toString(),
        actionRoute: json['action_route']?.toString(),
        actionUrl: json['action_url']?.toString(),
        priority: priority,
        startDate: startDate,
        endDate: endDate,
        targetScreens: targetScreens,
        displayFrequencyHours: json['display_frequency_hours'] ?? 24,
        isActive: json['is_active'] ?? true,
      );
    } catch (e) {
      debugPrint('❌ Error parsing promotional banner: $e');
      rethrow;
    }
  }

  /// تحويل HEX إلى Color
  static Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      debugPrint('⚠️ Error parsing color: $hexColor - $e');
      return const Color(0xFF9C27B0);
    }
  }

  /// هل البانر نشط الآن؟
  bool get isCurrentlyActive {
    if (!isActive) return false;

    final now = DateTime.now();

    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }

    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }

    return true;
  }

  /// هل يمكن عرض البانر على هذه الشاشة؟
  bool canShowOnScreen(String screenName) {
    return targetScreens.contains(screenName) || targetScreens.contains('all');
  }

  /// نسخ مع تعديلات
  PromotionalBanner copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? emoji,
    List<Color>? gradientColors,
    String? actionText,
    String? actionRoute,
    String? actionUrl,
    BannerPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetScreens,
    int? displayFrequencyHours,
    bool? isActive,
  }) {
    return PromotionalBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      emoji: emoji ?? this.emoji,
      gradientColors: gradientColors ?? this.gradientColors,
      actionText: actionText ?? this.actionText,
      actionRoute: actionRoute ?? this.actionRoute,
      actionUrl: actionUrl ?? this.actionUrl,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetScreens: targetScreens ?? this.targetScreens,
      displayFrequencyHours: displayFrequencyHours ?? this.displayFrequencyHours,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'PromotionalBanner(id: $id, title: $title, priority: $priority, active: $isCurrentlyActive)';
  }
}

/// أولوية البانر
enum BannerPriority {
  normal,  // عادي
  high,    // مهم
  urgent,  // عاجل
}

extension BannerPriorityExtension on BannerPriority {
  String get displayName {
    switch (this) {
      case BannerPriority.normal:
        return 'عادي';
      case BannerPriority.high:
        return 'مهم';
      case BannerPriority.urgent:
        return 'عاجل';
    }
  }

  int get sortOrder {
    switch (this) {
      case BannerPriority.urgent:
        return 3;
      case BannerPriority.high:
        return 2;
      case BannerPriority.normal:
        return 1;
    }
  }
}