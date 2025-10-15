// lib/core/infrastructure/firebase/analytics/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import '../utils/firebase_helpers.dart';

/// خدمة Firebase Analytics للتتبع المنظم
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _isInitialized = false;
  
  // تخزين معلومات الجلسة
  DateTime? _sessionStartTime;
  int _screenViewCount = 0;
  int _eventCount = 0;
  
  /// تهيئة Analytics
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      
      // تفعيل Analytics (معطل في Debug mode)
      await _analytics!.setAnalyticsCollectionEnabled(true);
      
      // تعيين خصائص التطبيق الأساسية
      await _setDefaultProperties();
      
      // بدء جلسة جديدة
      await _startSession();
      
      _isInitialized = true;
      debugPrint('✅ AnalyticsService initialized');
      
    } catch (e) {
      debugPrint('❌ Failed to initialize AnalyticsService: $e');
    }
  }
  
  /// تعيين الخصائص الافتراضية
  Future<void> _setDefaultProperties() async {
    if (_analytics == null) return;
    
    try {
      // لغة التطبيق
      await _analytics!.setUserProperty(
        name: 'app_language',
        value: 'arabic',
      );
      
      // نوع المستخدم
      await _analytics!.setUserProperty(
        name: 'user_type',
        value: 'standard',
      );
      
      // منصة التطبيق
      await _analytics!.setUserProperty(
        name: 'platform',
        value: 'android',
      );
      
    } catch (e) {
      debugPrint('❌ Failed to set default properties: $e');
    }
  }
  
  /// بدء جلسة جديدة
  Future<void> _startSession() async {
    _sessionStartTime = DateTime.now();
    _screenViewCount = 0;
    _eventCount = 0;
    
    await logEvent(AnalyticsEvents.sessionStart, {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// إنهاء الجلسة
  Future<void> endSession() async {
    if (_sessionStartTime == null) return;
    
    final duration = DateTime.now().difference(_sessionStartTime!);
    
    await logEvent(AnalyticsEvents.sessionEnd, {
      'duration_seconds': duration.inSeconds,
      'screen_views': _screenViewCount,
      'events_count': _eventCount,
    });
  }
  
  // ==================== Screen Tracking ====================
  
  /// تتبع فتح شاشة
  Future<void> logScreenView(String screenName, {Map<String, dynamic>? extras}) async {
    if (_analytics == null) return;
    
    try {
      _screenViewCount++;
      
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
      
      // تسجيل معلومات إضافية
      if (extras != null && extras.isNotEmpty) {
        final extraParams = Map<String, dynamic>.from(extras);
        extraParams['screen_name'] = screenName;
        await logEvent('screen_view_details', extraParams);
      }
      
      debugPrint('📱 Screen viewed: $screenName');
      
    } catch (e) {
      debugPrint('❌ Failed to log screen view: $e');
    }
  }
  
  // ==================== Event Tracking ====================
  
  /// تسجيل حدث عام
  Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    if (_analytics == null) return;
    
    try {
      _eventCount++;
      
      // تنظيف اسم الحدث
      final eventName = FirebaseHelpers.sanitizeEventName(name);
      
      // تحويل المعاملات مع إضافة المعاملات الافتراضية
      Map<String, Object>? firebaseParams;
      
      if (parameters != null) {
        final baseParams = FirebaseHelpers.convertToFirebaseParams(parameters);
        firebaseParams = FirebaseHelpers.addDefaultEventParams(baseParams);
      } else {
        firebaseParams = FirebaseHelpers.addDefaultEventParams(null);
      }
      
      // التحقق من الحدود والتنظيف
      firebaseParams = FirebaseHelpers.validateAndLimitParams(firebaseParams);
      
      await _analytics!.logEvent(
        name: eventName,
        parameters: firebaseParams,
      );
      
      debugPrint('📊 Event: $eventName ${parameters != null ? '($parameters)' : ''}');
      
    } catch (e) {
      debugPrint('❌ Failed to log event: $e');
    }
  }
  
  // ==================== User Tracking ====================
  
  /// تعيين معرف المستخدم
  Future<void> setUserId(String? userId) async {
    if (_analytics == null) return;
    
    try {
      await _analytics!.setUserId(id: userId);
      debugPrint('👤 User ID set: ${userId ?? 'anonymous'}');
    } catch (e) {
      debugPrint('❌ Failed to set user ID: $e');
    }
  }
  
  /// تعيين خاصية للمستخدم
  Future<void> setUserProperty(String name, String? value) async {
    if (_analytics == null) return;
    
    try {
      await _analytics!.setUserProperty(name: name, value: value);
      debugPrint('📝 User property: $name = $value');
    } catch (e) {
      debugPrint('❌ Failed to set user property: $e');
    }
  }
  
  // ==================== Prayer Tracking ====================
  
  /// تتبع وقت الصلاة
  Future<void> logPrayerTime(String prayerName, {bool onTime = false}) async {
    await logEvent(AnalyticsEvents.prayerViewed, {
      'prayer_name': prayerName,
      'on_time': onTime,
      'hour': DateTime.now().hour,
    });
  }
  
  /// تتبع إشعار الصلاة
  Future<void> logPrayerNotification(String prayerName, String action) async {
    await logEvent(AnalyticsEvents.prayerNotification, {
      'prayer_name': prayerName,
      'action': action, // shown, clicked, dismissed
    });
  }
  
  // ==================== Athkar Tracking ====================
  
  /// تتبع قراءة الأذكار
  Future<void> logAthkarRead(String category, {int? count}) async {
    await logEvent(AnalyticsEvents.athkarRead, {
      'category': category,
      'count': count ?? 1,
      'time_of_day': _getTimeOfDay(),
    });
  }
  
  /// تتبع إكمال الأذكار
  Future<void> logAthkarCompleted(String category, int duration) async {
    await logEvent(AnalyticsEvents.athkarCompleted, {
      'category': category,
      'duration_seconds': duration,
      'completion_time': DateTime.now().toIso8601String(),
    });
  }
  
  // ==================== Tasbih Tracking ====================
  
  /// تتبع التسبيح
  Future<void> logTasbihCount(String dhikr, int count) async {
    await logEvent(AnalyticsEvents.tasbihCounted, {
      'dhikr_type': dhikr,
      'count': count,
      'session_time': DateTime.now().toIso8601String(),
    });
  }
  
  /// تتبع هدف التسبيح
  Future<void> logTasbihGoalReached(String dhikr, int goal) async {
    await logEvent(AnalyticsEvents.tasbihGoalReached, {
      'dhikr_type': dhikr,
      'goal': goal,
    });
  }
  
  // ==================== Qibla Tracking ====================
  
  /// تتبع استخدام القبلة
  Future<void> logQiblaUsed({double? accuracy}) async {
    await logEvent(AnalyticsEvents.qiblaUsed, {
      'accuracy': accuracy,
      'has_permission': true,
    });
  }
  
  // ==================== Settings Tracking ====================
  
  /// تتبع تغيير الإعدادات
  Future<void> logSettingChanged(String settingName, dynamic newValue) async {
    await logEvent(AnalyticsEvents.settingChanged, {
      'setting_name': settingName,
      'new_value': newValue.toString(),
    });
  }
  
  /// تتبع تغيير الثيم
  Future<void> logThemeChanged(String theme) async {
    await logEvent(AnalyticsEvents.themeChanged, {
      'theme': theme,
    });
    
    // تحديث خاصية المستخدم
    await setUserProperty('preferred_theme', theme);
  }
  
  // ==================== Sharing Tracking ====================
  
  /// تتبع المشاركة
  Future<void> logShare(String contentType, String method) async {
    await logEvent(AnalyticsEvents.contentShared, {
      'content_type': contentType,
      'share_method': method,
    });
  }
  
  // ==================== Error Tracking ====================
  
  /// تتبع الأخطاء
  Future<void> logError(String errorType, String message) async {
    await logEvent(AnalyticsEvents.errorOccurred, {
      'error_type': errorType,
      'message': message,
      'screen': await _getCurrentScreen(),
    });
  }
  
  // ==================== App Lifecycle ====================
  
  /// تتبع فتح التطبيق
  Future<void> logAppOpen() async {
    if (_analytics == null) return;
    
    try {
      await _analytics!.logAppOpen();
      await _startSession();
      debugPrint('📱 App opened');
    } catch (e) {
      debugPrint('❌ Failed to log app open: $e');
    }
  }
  
  /// تتبع تحديث التطبيق
  Future<void> logAppUpdate(String oldVersion, String newVersion) async {
    await logEvent(AnalyticsEvents.appUpdated, {
      'old_version': oldVersion,
      'new_version': newVersion,
    });
  }
  
  // ==================== Helper Methods ====================
  
  /// الحصول على وقت اليوم
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }
  
  /// الحصول على الشاشة الحالية
  Future<String> _getCurrentScreen() async {
    // يمكن تحسين هذا باستخدام NavigatorObserver
    return 'unknown';
  }
  
  // ==================== Getters ====================
  
  bool get isInitialized => _isInitialized;
  FirebaseAnalyticsObserver? get observer => _observer;
  
  /// معلومات الجلسة
  Map<String, dynamic> get sessionInfo => {
    'start_time': _sessionStartTime?.toIso8601String(),
    'duration': _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!).inSeconds 
      : 0,
    'screen_views': _screenViewCount,
    'events': _eventCount,
  };
  
  /// تنظيف
  void dispose() {
    endSession();
    _isInitialized = false;
    _analytics = null;
    _observer = null;
  }
}

/// أحداث Analytics المعرفة مسبقاً
class AnalyticsEvents {
  // App Lifecycle
  static const String sessionStart = 'session_start';
  static const String sessionEnd = 'session_end';
  static const String appUpdated = 'app_updated';
  
  // Prayer Events
  static const String prayerViewed = 'prayer_viewed';
  static const String prayerNotification = 'prayer_notification';
  static const String prayerTimeChanged = 'prayer_time_changed';
  
  // Athkar Events
  static const String athkarRead = 'athkar_read';
  static const String athkarCompleted = 'athkar_completed';
  static const String athkarFavorited = 'athkar_favorited';
  
  // Tasbih Events
  static const String tasbihCounted = 'tasbih_counted';
  static const String tasbihReset = 'tasbih_reset';
  static const String tasbihGoalSet = 'tasbih_goal_set';
  static const String tasbihGoalReached = 'tasbih_goal_reached';
  
  // Qibla Events
  static const String qiblaUsed = 'qibla_used';
  static const String qiblaCalibrated = 'qibla_calibrated';
  
  // Settings Events
  static const String settingChanged = 'setting_changed';
  static const String themeChanged = 'theme_changed';
  static const String notificationToggled = 'notification_toggled';
  
  // Content Events
  static const String contentShared = 'content_shared';
  static const String contentCopied = 'content_copied';
  static const String contentFavorited = 'content_favorited';
  
  // Error Events
  static const String errorOccurred = 'error_occurred';
  static const String permissionDenied = 'permission_denied';
}

/// Extension للاستخدام السريع
extension AnalyticsExtension on BuildContext {
  /// تسجيل عرض الشاشة بسرعة
  Future<void> logScreen(String screenName) async {
    await AnalyticsService().logScreenView(screenName);
  }
  
  /// تسجيل حدث بسرعة
  Future<void> logEvent(String event, [Map<String, dynamic>? params]) async {
    await AnalyticsService().logEvent(event, params);
  }
}