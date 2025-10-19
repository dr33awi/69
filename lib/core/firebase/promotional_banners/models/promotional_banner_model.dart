// lib/core/infrastructure/firebase/promotional_banners/models/promotional_banner_model.dart
// ✅ محسّن مع دعم ألوان AppColors من Firebase + أنواع البانرات

import 'package:flutter/material.dart';

/// نوع البانر
enum BannerType {
  general,       // عام
  update,        // تحديث التطبيق
  feature,       // ميزة جديدة
  announcement,  // إعلان
  promotion,     // عرض ترويجي
}

extension BannerTypeExtension on BannerType {
  String get displayName {
    switch (this) {
      case BannerType.general:
        return 'عام';
      case BannerType.update:
        return 'تحديث';
      case BannerType.feature:
        return 'ميزة جديدة';
      case BannerType.announcement:
        return 'إعلان';
      case BannerType.promotion:
        return 'عرض ترويجي';
    }
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

/// نموذج البانر الترويجي
class PromotionalBanner {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? emoji;
  final String? backgroundImage; // ✅ جديد: صورة خلفية
  final List<Color> gradientColors;
  final String? colorTheme;
  final String? actionText;
  final String? actionRoute;
  final String? actionUrl;
  final BannerPriority priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> targetScreens;
  final int displayFrequencyHours;
  final bool isActive;
  final BannerType bannerType;
  final String? minAppVersion;
  final bool dismissForever;

  const PromotionalBanner({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.emoji,
    this.backgroundImage, // ✅
    required this.gradientColors,
    this.colorTheme,
    this.actionText,
    this.actionRoute,
    this.actionUrl,
    this.priority = BannerPriority.normal,
    this.startDate,
    this.endDate,
    this.targetScreens = const ['home'],
    this.displayFrequencyHours = 24,
    this.isActive = true,
    this.bannerType = BannerType.general,
    this.minAppVersion,
    this.dismissForever = false,
  });

  /// تحويل من JSON
  factory PromotionalBanner.fromJson(Map<String, dynamic> json) {
    try {
      List<Color> gradientColors = [];
      String? colorTheme;

      // ✅ أولاً: التحقق من وجود color_theme
      if (json['color_theme'] != null) {
        colorTheme = json['color_theme'].toString().toLowerCase();
        gradientColors = _getThemeColors(colorTheme);
        
        debugPrint('🎨 Using color theme: $colorTheme');
      } 
      // ثانياً: التحقق من gradient_colors
      else if (json['gradient_colors'] != null) {
        final colors = json['gradient_colors'] as List;
        gradientColors = colors
            .map((colorHex) => _parseColor(colorHex.toString()))
            .toList();
            
        debugPrint('🎨 Using custom gradient colors: ${colors.length} colors');
      }

      // إذا لم تكن هناك ألوان، استخدم الألوان الافتراضية
      if (gradientColors.isEmpty) {
        gradientColors = [
          const Color(0xFF5D7052), // primary
          const Color(0xFF4A5A41), // primaryDark
        ];
        debugPrint('🎨 Using default colors');
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

      // ✅ تحويل Banner Type
      BannerType bannerType = BannerType.general;
      if (json['banner_type'] != null) {
        switch (json['banner_type'].toString().toLowerCase()) {
          case 'update':
            bannerType = BannerType.update;
            break;
          case 'feature':
            bannerType = BannerType.feature;
            break;
          case 'announcement':
            bannerType = BannerType.announcement;
            break;
          case 'promotion':
            bannerType = BannerType.promotion;
            break;
          default:
            bannerType = BannerType.general;
        }
      }

      return PromotionalBanner(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        imageUrl: json['image_url']?.toString(),
        emoji: json['emoji']?.toString(),
        backgroundImage: json['background_image']?.toString(), // ✅
        gradientColors: gradientColors,
        colorTheme: colorTheme,
        actionText: json['action_text']?.toString(),
        actionRoute: json['action_route']?.toString(),
        actionUrl: json['action_url']?.toString(),
        priority: priority,
        startDate: startDate,
        endDate: endDate,
        targetScreens: targetScreens,
        displayFrequencyHours: json['display_frequency_hours'] ?? 24,
        isActive: json['is_active'] ?? true,
        bannerType: bannerType,
        minAppVersion: json['min_app_version']?.toString(),
        dismissForever: json['dismiss_forever'] ?? false,
      );
    } catch (e) {
      debugPrint('❌ Error parsing promotional banner: $e');
      rethrow;
    }
  }

  /// ✅ الحصول على ألوان الثيم من AppColors
  static List<Color> _getThemeColors(String theme) {
    switch (theme) {
      // Gradients رئيسية
      case 'primary':
        return [
          const Color(0xFF5D7052),
          const Color(0xFF4A5A41),
        ];
      
      case 'accent':
        return [
          const Color(0xFFD4A574),
          const Color(0xFFC89456),
        ];
      
      case 'tertiary':
        return [
          const Color(0xFF7B8FA3),
          const Color(0xFF5E7489),
        ];

      // Success
      case 'success':
        return [
          const Color(0xFF4CAF50),
          const Color(0xFF388E3C),
        ];

      // Error
      case 'error':
        return [
          const Color(0xFFF44336),
          const Color(0xFFD32F2F),
        ];

      // Warning
      case 'warning':
        return [
          const Color(0xFFFF9800),
          const Color(0xFFF57C00),
        ];

      // Info
      case 'info':
        return [
          const Color(0xFF2196F3),
          const Color(0xFF1976D2),
        ];

      // ✅ Prayer colors - للبانرات المتعلقة بالصلاة
      case 'fajr':
        return [
          const Color(0xFF1A237E),
          const Color(0xFF0D47A1),
        ];

      case 'dhuhr':
        return [
          const Color(0xFFFF6F00),
          const Color(0xFFE65100),
        ];

      case 'asr':
        return [
          const Color(0xFFFF8F00),
          const Color(0xFFEF6C00),
        ];

      case 'maghrib':
        return [
          const Color(0xFF4A148C),
          const Color(0xFF6A1B9A),
        ];

      case 'isha':
        return [
          const Color(0xFF263238),
          const Color(0xFF37474F),
        ];

      // ✅ Time-based gradients
      case 'morning':
        return [
          const Color(0xFFFFA726),
          const Color(0xFFFF7043),
        ];

      case 'evening':
        return [
          const Color(0xFF5C6BC0),
          const Color(0xFF3949AB),
        ];

      case 'night':
        return [
          const Color(0xFF283593),
          const Color(0xFF1A237E),
        ];

      // ✅ Special themes
      case 'ramadan':
        return [
          const Color(0xFF6A1B9A),
          const Color(0xFF4A148C),
        ];

      case 'friday':
        return [
          const Color(0xFF388E3C),
          const Color(0xFF2E7D32),
        ];

      case 'celebration':
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFFB300),
        ];

      // Default
      default:
        debugPrint('⚠️ Unknown theme: $theme, using primary');
        return [
          const Color(0xFF5D7052),
          const Color(0xFF4A5A41),
        ];
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
      return const Color(0xFF5D7052);
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
    String? backgroundImage, // ✅
    List<Color>? gradientColors,
    String? colorTheme,
    String? actionText,
    String? actionRoute,
    String? actionUrl,
    BannerPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? targetScreens,
    int? displayFrequencyHours,
    bool? isActive,
    BannerType? bannerType,
    String? minAppVersion,
    bool? dismissForever,
  }) {
    return PromotionalBanner(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      emoji: emoji ?? this.emoji,
      backgroundImage: backgroundImage ?? this.backgroundImage, // ✅
      gradientColors: gradientColors ?? this.gradientColors,
      colorTheme: colorTheme ?? this.colorTheme,
      actionText: actionText ?? this.actionText,
      actionRoute: actionRoute ?? this.actionRoute,
      actionUrl: actionUrl ?? this.actionUrl,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetScreens: targetScreens ?? this.targetScreens,
      displayFrequencyHours: displayFrequencyHours ?? this.displayFrequencyHours,
      isActive: isActive ?? this.isActive,
      bannerType: bannerType ?? this.bannerType,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      dismissForever: dismissForever ?? this.dismissForever,
    );
  }

  @override
  String toString() {
    return 'PromotionalBanner(id: $id, title: $title, type: ${bannerType.displayName}, theme: $colorTheme, priority: ${priority.displayName}, active: $isCurrentlyActive)';
  }
}