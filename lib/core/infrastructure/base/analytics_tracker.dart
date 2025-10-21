// lib/core/infrastructure/base/analytics_tracker.dart
import 'package:flutter/material.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/firebase/analytics/analytics_service.dart';

/// نظام موحد لتتبع Analytics في كل التطبيق
///
/// يوفر:
/// - واجهة موحدة لجميع الخدمات
/// - تتبع الأحداث بشكل مركزي
/// - معالجة آمنة للأخطاء
class AnalyticsTracker {
  AnalyticsTracker._();

  static AnalyticsService? get _analytics {
    try {
      return getIt.isRegistered<AnalyticsService>() ? getIt<AnalyticsService>() : null;
    } catch (e) {
      debugPrint('[AnalyticsTracker] Error getting analytics service: $e');
      return null;
    }
  }

  /// تتبع حدث عام
  static Future<void> trackEvent(
    String name, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      final analytics = _analytics;
      if (analytics != null && analytics.isInitialized) {
        await analytics.logEvent(name, params);
      }
    } catch (e) {
      debugPrint('[AnalyticsTracker] Error tracking event: $e');
    }
  }

  /// تتبع عرض شاشة
  static Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? extras,
  }) async {
    try {
      final analytics = _analytics;
      if (analytics != null && analytics.isInitialized) {
        await analytics.logScreenView(screenName, extras: extras);
      }
    } catch (e) {
      debugPrint('[AnalyticsTracker] Error tracking screen view: $e');
    }
  }

  /// تتبع إجراء مستخدم
  static Future<void> trackUserAction(
    String action,
    String category, {
    Map<String, dynamic>? params,
  }) async {
    return trackEvent('user_$action', {
      'category': category,
      'action': action,
      ...?params,
    });
  }

  /// تتبع فتح ميزة
  static Future<void> trackFeatureUsage(
    String featureName, {
    Map<String, dynamic>? params,
  }) async {
    return trackEvent('feature_used', {
      'feature_name': featureName,
      ...?params,
    });
  }

  /// تتبع ضغطة زر
  static Future<void> trackButtonClick(
    String buttonName, {
    String? screen,
    Map<String, dynamic>? params,
  }) async {
    return trackEvent('button_click', {
      'button_name': buttonName,
      if (screen != null) 'screen': screen,
      ...?params,
    });
  }

  /// تتبع مشاركة محتوى
  static Future<void> trackShare(
    String contentType, {
    String? contentId,
    String? method,
  }) async {
    return trackEvent('share', {
      'content_type': contentType,
      if (contentId != null) 'content_id': contentId,
      if (method != null) 'share_method': method,
    });
  }

  /// تتبع إشعار
  static Future<void> trackNotification(
    String notificationType, {
    String? action,
    bool? delivered,
  }) async {
    return trackEvent('notification', {
      'type': notificationType,
      if (action != null) 'action': action,
      if (delivered != null) 'delivered': delivered,
    });
  }

  /// تتبع بحث
  static Future<void> trackSearch(
    String searchTerm, {
    String? category,
    int? resultsCount,
  }) async {
    return trackEvent('search', {
      'search_term': searchTerm,
      if (category != null) 'category': category,
      if (resultsCount != null) 'results_count': resultsCount,
    });
  }

  /// تتبع خطأ
  static Future<void> trackError(
    String errorType,
    String errorMessage, {
    String? screen,
    bool? fatal,
  }) async {
    return trackEvent('error_occurred', {
      'error_type': errorType,
      'error_message': errorMessage,
      if (screen != null) 'screen': screen,
      if (fatal != null) 'fatal': fatal,
    });
  }

  /// تتبع إنجاز
  static Future<void> trackAchievement(
    String achievementName, {
    Map<String, dynamic>? params,
  }) async {
    return trackEvent('achievement_unlocked', {
      'achievement_name': achievementName,
      ...?params,
    });
  }

  /// تتبع تغيير إعداد
  static Future<void> trackSettingChange(
    String settingName,
    dynamic value, {
    dynamic oldValue,
  }) async {
    return trackEvent('setting_changed', {
      'setting_name': settingName,
      'new_value': value.toString(),
      if (oldValue != null) 'old_value': oldValue.toString(),
    });
  }

  /// تتبع جلسة المستخدم
  static Future<void> trackSessionStart() async {
    return trackEvent('session_start', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> trackSessionEnd({
    Duration? duration,
  }) async {
    return trackEvent('session_end', {
      'timestamp': DateTime.now().toIso8601String(),
      if (duration != null) 'duration_seconds': duration.inSeconds,
    });
  }
}

/// Events خاصة بالميزات الإسلامية

/// تتبع أحداث الأذكار
class AthkarAnalytics {
  static Future<void> trackAthkarViewed(String category) {
    return AnalyticsTracker.trackEvent('athkar_viewed', {
      'category': category,
    });
  }

  static Future<void> trackAthkarCompleted(String category, int count) {
    return AnalyticsTracker.trackEvent('athkar_completed', {
      'category': category,
      'count': count,
    });
  }

  static Future<void> trackAthkarFavorited(String athkarId) {
    return AnalyticsTracker.trackEvent('athkar_favorited', {
      'athkar_id': athkarId,
    });
  }

  static Future<void> trackAthkarShared(String athkarId) {
    return AnalyticsTracker.trackShare('athkar', contentId: athkarId);
  }
}

/// تتبع أحداث الصلاة
class PrayerAnalytics {
  static Future<void> trackPrayerTimeViewed() {
    return AnalyticsTracker.trackFeatureUsage('prayer_times');
  }

  static Future<void> trackPrayerNotificationSet(String prayerName) {
    return AnalyticsTracker.trackEvent('prayer_notification_set', {
      'prayer_name': prayerName,
    });
  }

  static Future<void> trackQiblaUsed() {
    return AnalyticsTracker.trackFeatureUsage('qibla_compass');
  }

  static Future<void> trackAdhanPlayed(String prayerName) {
    return AnalyticsTracker.trackEvent('adhan_played', {
      'prayer_name': prayerName,
    });
  }
}

/// تتبع أحداث التسبيح
class TasbihAnalytics {
  static Future<void> trackTasbihUsed(String dhikrType) {
    return AnalyticsTracker.trackEvent('tasbih_used', {
      'dhikr_type': dhikrType,
    });
  }

  static Future<void> trackTasbihCompleted(String dhikrType, int count) {
    return AnalyticsTracker.trackEvent('tasbih_completed', {
      'dhikr_type': dhikrType,
      'count': count,
    });
  }

  static Future<void> trackCustomDhikrCreated() {
    return AnalyticsTracker.trackEvent('custom_dhikr_created');
  }
}

/// تتبع أحداث الأدعية
class DuaAnalytics {
  static Future<void> trackDuaViewed(String duaId) {
    return AnalyticsTracker.trackEvent('dua_viewed', {
      'dua_id': duaId,
    });
  }

  static Future<void> trackDuaFavorited(String duaId) {
    return AnalyticsTracker.trackEvent('dua_favorited', {
      'dua_id': duaId,
    });
  }

  static Future<void> trackDuaShared(String duaId) {
    return AnalyticsTracker.trackShare('dua', contentId: duaId);
  }

  static Future<void> trackDuaSearched(String searchTerm, int resultsCount) {
    return AnalyticsTracker.trackSearch(
      searchTerm,
      category: 'dua',
      resultsCount: resultsCount,
    );
  }
}

/// Extension لتسهيل الاستخدام من BuildContext
extension AnalyticsExtension on BuildContext {
  /// تتبع سريع للشاشة
  Future<void> logScreen(String screenName) {
    return AnalyticsTracker.trackScreenView(screenName);
  }

  /// تتبع سريع لحدث
  Future<void> logEvent(String name, [Map<String, dynamic>? params]) {
    return AnalyticsTracker.trackEvent(name, params);
  }

  /// تتبع سريع لضغطة زر
  Future<void> logButtonClick(String buttonName) {
    return AnalyticsTracker.trackButtonClick(buttonName);
  }
}
