// lib/core/infrastructure/firebase/messaging/in_app_messaging_service.dart

import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../analytics/analytics_service.dart';

/// خدمة Firebase In-App Messaging
class InAppMessagingService {
  static final InAppMessagingService _instance = InAppMessagingService._internal();
  factory InAppMessagingService() => _instance;
  InAppMessagingService._internal();
  
  FirebaseInAppMessaging? _inAppMessaging;
  bool _isInitialized = false;
  bool _isMessagesSuppressed = false;
  
  // تخزين معلومات الرسائل المعروضة
  final List<MessageInfo> _displayedMessages = [];
  final Map<String, int> _messageFrequency = {};
  
  // Callbacks
  VoidCallback? _onMessageImpressionCallback;
  VoidCallback? _onMessageClickCallback;
  VoidCallback? _onMessageDismissCallback;
  
  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔄 Initializing Firebase In-App Messaging...');
      
      _inAppMessaging = FirebaseInAppMessaging.instance;
      
      // تكوين الإعدادات الأساسية
      await _configureMessaging();
      
      // إعداد المستمعين
      _setupListeners();
      
      _isInitialized = true;
      debugPrint('✅ Firebase In-App Messaging initialized');
      
      // تسجيل الحدث في Analytics
      await _logAnalyticsEvent('in_app_messaging_initialized');
      
    } catch (e) {
      debugPrint('❌ Failed to initialize In-App Messaging: $e');
    }
  }
  
  /// تكوين الرسائل
  Future<void> _configureMessaging() async {
    if (_inAppMessaging == null) return;
    
    try {
      // تفعيل جمع البيانات التلقائي (معطل في Debug mode للاختبار)
      await _inAppMessaging!.setAutomaticDataCollectionEnabled(!kDebugMode);
      
      // في وضع التطوير، تفعيل وضع الاختبار
      if (kDebugMode) {
        debugPrint('📧 In-App Messaging in TEST MODE');
        // يمكنك استخدام Firebase Console لإرسال رسائل اختبار
      }
      
    } catch (e) {
      debugPrint('❌ Failed to configure In-App Messaging: $e');
    }
  }
  
  /// إعداد المستمعين للرسائل
  void _setupListeners() {
    // ملاحظة: Firebase In-App Messaging SDK لا يوفر listeners مباشرة
    // ولكن يمكننا تتبع الأحداث من خلال Analytics
    debugPrint('📧 In-App Messaging listeners ready');
  }
  
  // ==================== التحكم في الرسائل ====================
  
  /// إيقاف/تشغيل عرض الرسائل مؤقتاً
  void suppressMessages(bool suppress) {
    if (_inAppMessaging == null) return;
    
    try {
      _inAppMessaging!.setMessagesSuppressed(suppress);
      _isMessagesSuppressed = suppress;
      
      debugPrint(suppress 
        ? '🔇 In-App Messages suppressed' 
        : '🔔 In-App Messages enabled');
      
      // تسجيل الحدث
      _logAnalyticsEvent('in_app_messages_suppressed', {
        'suppressed': suppress,
      });
      
    } catch (e) {
      debugPrint('❌ Failed to suppress messages: $e');
    }
  }
  
  /// تفعيل جمع البيانات التلقائي
  Future<void> setAutomaticDataCollection(bool enabled) async {
    if (_inAppMessaging == null) return;
    
    try {
      await _inAppMessaging!.setAutomaticDataCollectionEnabled(enabled);
      
      debugPrint(enabled 
        ? '✅ Automatic data collection enabled' 
        : '❌ Automatic data collection disabled');
      
      _logAnalyticsEvent('in_app_data_collection_changed', {
        'enabled': enabled,
      });
      
    } catch (e) {
      debugPrint('❌ Failed to set data collection: $e');
    }
  }
  
  // ==================== Trigger Events ====================
  
  /// تشغيل حدث لعرض رسالة
  Future<void> triggerEvent(String eventName) async {
    if (_inAppMessaging == null) return;
    
    try {
      await _inAppMessaging!.triggerEvent(eventName);
      
      // تتبع تكرار الأحداث
      _messageFrequency[eventName] = (_messageFrequency[eventName] ?? 0) + 1;
      
      debugPrint('🎯 Event triggered: $eventName');
      
      // تسجيل في Analytics
      _logAnalyticsEvent('in_app_event_triggered', {
        'event_name': eventName,
        'frequency': _messageFrequency[eventName],
      });
      
    } catch (e) {
      debugPrint('❌ Failed to trigger event: $e');
    }
  }
  
  // ==================== أحداث خاصة بالتطبيق ====================
  
  /// عرض رسالة ترحيب للمستخدمين الجدد
  Future<void> showWelcomeMessage() async {
    await triggerEvent('welcome_new_user');
  }
  
  /// عرض رسالة للمستخدمين غير النشطين
  Future<void> showReEngagementMessage() async {
    await triggerEvent('user_re_engagement');
  }
  
  /// عرض رسالة بعد إكمال الأذكار
  Future<void> showAthkarCompletionMessage() async {
    await triggerEvent('athkar_completed');
  }
  
  /// عرض رسالة تذكير بالصلاة
  Future<void> showPrayerReminderMessage() async {
    await triggerEvent('prayer_reminder');
  }
  
  /// عرض رسالة نصائح وإرشادات
  Future<void> showTipMessage() async {
    await triggerEvent('app_tips');
  }
  
  /// عرض رسالة تحديث التطبيق
  Future<void> showUpdateMessage() async {
    await triggerEvent('app_update_available');
  }
  
  /// عرض رسالة المناسبات الإسلامية
  Future<void> showIslamicEventMessage(String eventType) async {
    await triggerEvent('islamic_event_$eventType');
  }
  
  /// عرض رسالة تقييم التطبيق
  Future<void> showRatingMessage() async {
    await triggerEvent('request_app_rating');
  }
  
  /// عرض رسالة الميزات الجديدة
  Future<void> showNewFeatureMessage(String feature) async {
    await triggerEvent('new_feature_$feature');
  }
  
  // ==================== حالات خاصة ====================
  
  /// إيقاف الرسائل أثناء الصلاة
  void suppressDuringPrayer(bool isPrayerTime) {
    if (isPrayerTime) {
      suppressMessages(true);
      debugPrint('🕌 Messages suppressed during prayer');
    } else {
      suppressMessages(false);
      debugPrint('✅ Messages enabled after prayer');
    }
  }
  
  /// إيقاف الرسائل أثناء قراءة القرآن
  void suppressDuringQuranReading(bool isReading) {
    if (isReading) {
      suppressMessages(true);
      debugPrint('📖 Messages suppressed during Quran reading');
    } else {
      suppressMessages(false);
      debugPrint('✅ Messages enabled after Quran reading');
    }
  }
  
  // ==================== التحكم المتقدم ====================
  
  /// جدولة رسالة بناءً على شروط
  Future<void> scheduleConditionalMessage({
    required String eventName,
    required bool Function() condition,
    Duration delay = const Duration(seconds: 0),
  }) async {
    Future.delayed(delay, () {
      if (condition()) {
        triggerEvent(eventName);
      }
    });
  }
  
  /// عرض رسائل متسلسلة
  Future<void> showSequentialMessages(List<String> events, Duration interval) async {
    for (int i = 0; i < events.length; i++) {
      await Future.delayed(interval * i);
      await triggerEvent(events[i]);
    }
  }
  
  // ==================== التتبع والإحصائيات ====================
  
  /// تسجيل عرض رسالة
  void recordMessageImpression(String messageId) {
    _displayedMessages.add(MessageInfo(
      id: messageId,
      timestamp: DateTime.now(),
      action: 'impression',
    ));
    
    _onMessageImpressionCallback?.call();
    
    _logAnalyticsEvent('in_app_message_impression', {
      'message_id': messageId,
    });
  }
  
  /// تسجيل نقرة على رسالة
  void recordMessageClick(String messageId) {
    _displayedMessages.add(MessageInfo(
      id: messageId,
      timestamp: DateTime.now(),
      action: 'click',
    ));
    
    _onMessageClickCallback?.call();
    
    _logAnalyticsEvent('in_app_message_click', {
      'message_id': messageId,
    });
  }
  
  /// تسجيل إغلاق رسالة
  void recordMessageDismiss(String messageId) {
    _displayedMessages.add(MessageInfo(
      id: messageId,
      timestamp: DateTime.now(),
      action: 'dismiss',
    ));
    
    _onMessageDismissCallback?.call();
    
    _logAnalyticsEvent('in_app_message_dismiss', {
      'message_id': messageId,
    });
  }
  
  /// الحصول على إحصائيات الرسائل
  Map<String, dynamic> getStatistics() {
    final impressions = _displayedMessages.where((m) => m.action == 'impression').length;
    final clicks = _displayedMessages.where((m) => m.action == 'click').length;
    final dismissals = _displayedMessages.where((m) => m.action == 'dismiss').length;
    
    return {
      'total_impressions': impressions,
      'total_clicks': clicks,
      'total_dismissals': dismissals,
      'click_rate': impressions > 0 ? (clicks / impressions * 100).toStringAsFixed(2) : '0',
      'messages_suppressed': _isMessagesSuppressed,
      'unique_events_triggered': _messageFrequency.length,
      'most_triggered_event': _getMostTriggeredEvent(),
    };
  }
  
  /// الحصول على الحدث الأكثر تكراراً
  String? _getMostTriggeredEvent() {
    if (_messageFrequency.isEmpty) return null;
    
    var maxEvent = _messageFrequency.entries.first;
    for (final entry in _messageFrequency.entries) {
      if (entry.value > maxEvent.value) {
        maxEvent = entry;
      }
    }
    return maxEvent.key;
  }
  
  // ==================== Analytics Integration ====================
  
  /// تسجيل حدث في Analytics
  Future<void> _logAnalyticsEvent(String event, [Map<String, dynamic>? params]) async {
    try {
      final analytics = AnalyticsService();
      await analytics.logEvent(event, params);
    } catch (e) {
      debugPrint('Failed to log analytics event: $e');
    }
  }
  
  // ==================== Callbacks ====================
  
  /// تعيين callback لعرض الرسالة
  void setOnMessageImpression(VoidCallback callback) {
    _onMessageImpressionCallback = callback;
  }
  
  /// تعيين callback للنقر على الرسالة
  void setOnMessageClick(VoidCallback callback) {
    _onMessageClickCallback = callback;
  }
  
  /// تعيين callback لإغلاق الرسالة
  void setOnMessageDismiss(VoidCallback callback) {
    _onMessageDismissCallback = callback;
  }
  
  // ==================== Getters ====================
  
  bool get isInitialized => _isInitialized;
  bool get isMessagesSuppressed => _isMessagesSuppressed;
  List<MessageInfo> get displayedMessages => List.unmodifiable(_displayedMessages);
  Map<String, int> get messageFrequency => Map.unmodifiable(_messageFrequency);
  
  // ==================== Cleanup ====================
  
  /// مسح السجلات
  void clearHistory() {
    _displayedMessages.clear();
    _messageFrequency.clear();
    debugPrint('🧹 In-App Messaging history cleared');
  }
  
  /// تنظيف الموارد
  void dispose() {
    _displayedMessages.clear();
    _messageFrequency.clear();
    _onMessageImpressionCallback = null;
    _onMessageClickCallback = null;
    _onMessageDismissCallback = null;
    _isInitialized = false;
    debugPrint('🧹 InAppMessagingService disposed');
  }
}

/// معلومات الرسالة
class MessageInfo {
  final String id;
  final DateTime timestamp;
  final String action; // impression, click, dismiss
  
  MessageInfo({
    required this.id,
    required this.timestamp,
    required this.action,
  });
}

/// Extension للاستخدام السريع
extension InAppMessagingExtension on BuildContext {
  /// عرض رسالة بسرعة
  Future<void> triggerInAppMessage(String event) async {
    await InAppMessagingService().triggerEvent(event);
  }
  
  /// إيقاف الرسائل مؤقتاً
  void suppressInAppMessages(bool suppress) {
    InAppMessagingService().suppressMessages(suppress);
  }
}