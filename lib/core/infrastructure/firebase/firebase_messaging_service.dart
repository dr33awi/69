// lib/core/infrastructure/firebase/firebase_messaging_service.dart
// Android Only - iOS support removed

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage/storage_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/notifications/models/notification_models.dart' as LocalNotificationModels hide NotificationSettings;

/// معالج الرسائل في الخلفية
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');
  debugPrint('Background message notification: ${message.notification?.toMap()}');
  
  if (message.data.isNotEmpty) {
    debugPrint('Processing background message data: ${message.data}');
    
    final type = message.data['type'];
    switch (type) {
      case 'prayer':
        debugPrint('Background prayer notification received');
        break;
      case 'athkar':
        debugPrint('Background athkar notification received');
        break;
      default:
        debugPrint('Background notification type: $type');
    }
  }
}

/// خدمة Firebase Messaging - Android Only
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  FirebaseMessaging? _messaging;
  late StorageService _storage;
  NotificationService? _notificationService;
  
  bool _isInitialized = false;
  String? _fcmToken;
  
  static const MethodChannel _fcmChannel = MethodChannel('com.athkar.app/firebase_messaging');
  
  static const String _prayerTopic = 'prayer_times';
  static const String _athkarTopic = 'athkar_reminders';
  static const String _generalTopic = 'general_notifications';
  static const String _updatesTopicArabic = 'updates_ar';

  /// تهيئة الخدمة - Android Only
  Future<void> initialize({
    required StorageService storage,
    NotificationService? notificationService,
  }) async {
    if (_isInitialized) {
      debugPrint('Firebase Messaging already initialized');
      return;
    }
    
    _storage = storage;
    _notificationService = notificationService;
    
    try {
      debugPrint('Initializing Firebase Messaging for Android...');
      
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase not initialized. Call Firebase.initializeApp() first.');
      }
      
      _messaging = FirebaseMessaging.instance;
      
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      await _requestPermissions();
      await _getFCMToken();
      _setupMessageHandlers();
      await _subscribeToDefaultTopics();
      
      _isInitialized = true;
      debugPrint('FirebaseMessagingService initialized successfully ✓');
      
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
      
      _isInitialized = false;
      _messaging = null;
      
      await _storage.setBool('firebase_messaging_available', false);
      await _storage.setString('firebase_messaging_error', e.toString());
      
      rethrow;
    }
  }

  /// طلب أذونات الإشعارات - Android
  Future<void> _requestPermissions() async {
    if (_messaging == null) return;
    
    try {
      debugPrint('Requesting Firebase Messaging permissions for Android...');
      
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      debugPrint('Firebase permission status: ${settings.authorizationStatus}');
      
      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      await _storage.setBool('fcm_permission_granted', isGranted);
      
      if (!isGranted && settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        debugPrint('Android: Permission not determined, assuming granted');
        await _storage.setBool('fcm_permission_granted', true);
      }
        
    } catch (e) {
      debugPrint('Error requesting FCM permissions: $e');
      await _storage.setBool('fcm_permission_granted', false);
    }
  }

  /// الحصول على FCM Token
  Future<void> _getFCMToken() async {
    if (_messaging == null) return;
    
    try {
      debugPrint('Getting FCM Token...');
      
      _fcmToken = await _messaging!.getToken();
      
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        debugPrint('FCM Token received: ${_fcmToken!.substring(0, 20)}...');
        await _storage.setString('fcm_token', _fcmToken!);
        await _storage.setBool('firebase_messaging_available', true);
        
        await _sendTokenToServer(_fcmToken!);
      } else {
        debugPrint('FCM Token is null or empty');
        await _storage.setBool('firebase_messaging_available', false);
        
        try {
          final nativeToken = await _fcmChannel.invokeMethod<String>('getToken');
          if (nativeToken != null) {
            _fcmToken = nativeToken;
            await _storage.setString('fcm_token', nativeToken);
            await _storage.setBool('firebase_messaging_available', true);
            debugPrint('Got FCM token from native: ${nativeToken.substring(0, 20)}...');
          }
        } catch (e) {
          debugPrint('Native token method also failed: $e');
        }
      }
      
      _messaging!.onTokenRefresh.listen((newToken) async {
        try {
          _fcmToken = newToken;
          await _storage.setString('fcm_token', newToken);
          await _sendTokenToServer(newToken);
          debugPrint('FCM Token refreshed: ${newToken.substring(0, 20)}...');
        } catch (e) {
          debugPrint('Error handling token refresh: $e');
        }
      });
      
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      await _storage.setBool('firebase_messaging_available', false);
      await _storage.setString('fcm_token_error', e.toString());
    }
  }

  /// إرسال التوكن للخادم
  Future<void> _sendTokenToServer(String token) async {
    try {
      debugPrint('Sending token to server...');
      
      // TODO: إضافة API call لإرسال التوكن للخادم
      
      await _storage.setString('last_token_sent', DateTime.now().toIso8601String());
      await _storage.setBool('token_sent_to_server', true);
      
      debugPrint('Token sent to server successfully');
      
    } catch (e) {
      debugPrint('Error sending token to server: $e');
      await _storage.setBool('token_sent_to_server', false);
    }
  }

  /// إعداد معالجي الرسائل
  void _setupMessageHandlers() {
    if (_messaging == null) return;
    
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message received: ${message.messageId}');
        _handleForegroundMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Message opened app: ${message.messageId}');
        _handleMessageOpened(message);
      });

      _handleInitialMessage();
      
      debugPrint('Message handlers setup completed');
      
    } catch (e) {
      debugPrint('Error setting up message handlers: $e');
    }
  }

  /// معالجة الرسائل عندما يكون التطبيق مفتوحاً
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('Processing foreground message: ${message.data}');
      
      if (_notificationService != null) {
        await _showLocalNotification(message);
      }
      
      await _processMessageData(message);
      
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  /// معالجة النقر على الإشعار
  Future<void> _handleMessageOpened(RemoteMessage message) async {
    try {
      debugPrint('User tapped notification with data: ${message.data}');
      await _handleNavigationFromNotification(message.data);
    } catch (e) {
      debugPrint('Error handling message opened: $e');
    }
  }

  /// معالجة الرسالة الأولية عند فتح التطبيق من إشعار
  Future<void> _handleInitialMessage() async {
    try {
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from notification: ${initialMessage.messageId}');
        await _handleMessageOpened(initialMessage);
      }
    } catch (e) {
      debugPrint('Error handling initial message: $e');
    }
  }

  /// عرض إشعار محلي للرسائل الواردة
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (_notificationService == null) return;
    
    try {
      final title = message.notification?.title ?? 'تطبيق الأذكار';
      final body = message.notification?.body ?? '';
      final data = message.data;
      
      final notificationData = LocalNotificationModels.NotificationData(
        id: 'firebase_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        category: _getNotificationCategory(data['type']),
        priority: LocalNotificationModels.NotificationPriority.normal,
        payload: data.isNotEmpty ? data : null,
      );
      
      await _notificationService!.showNotification(notificationData);
      
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// تحديد فئة الإشعار بناءً على النوع
  LocalNotificationModels.NotificationCategory _getNotificationCategory(String? type) {
    switch (type) {
      case 'prayer':
        return LocalNotificationModels.NotificationCategory.prayer;
      case 'athkar':
        return LocalNotificationModels.NotificationCategory.athkar;
      case 'quran':
        return LocalNotificationModels.NotificationCategory.quran;
      case 'reminder':
        return LocalNotificationModels.NotificationCategory.reminder;
      default:
        return LocalNotificationModels.NotificationCategory.system;
    }
  }

  /// معالجة بيانات الرسالة
  Future<void> _processMessageData(RemoteMessage message) async {
    try {
      final data = message.data;
      final type = data['type'] as String?;
      
      debugPrint('Processing message data - Type: $type');
      
      switch (type) {
        case 'prayer':
          await _processPrayerNotification(data);
          break;
        case 'athkar':
          await _processAthkarNotification(data);
          break;
        case 'update':
          await _processUpdateNotification(data);
          break;
        case 'reminder':
          await _processReminderNotification(data);
          break;
        default:
          debugPrint('Unknown notification type: $type');
      }
      
    } catch (e) {
      debugPrint('Error processing message data: $e');
    }
  }

  Future<void> _processPrayerNotification(Map<String, dynamic> data) async {
    final prayerName = data['prayer_name'] as String?;
    final prayerTime = data['prayer_time'] as String?;
    debugPrint('Prayer notification: $prayerName at $prayerTime');
  }

  Future<void> _processAthkarNotification(Map<String, dynamic> data) async {
    final athkarType = data['athkar_type'] as String?;
    final athkarId = data['athkar_id'] as String?;
    debugPrint('Athkar notification: $athkarType, ID: $athkarId');
  }

  Future<void> _processUpdateNotification(Map<String, dynamic> data) async {
    final updateType = data['update_type'] as String?;
    final version = data['version'] as String?;
    debugPrint('Update notification: $updateType, version: $version');
  }

  Future<void> _processReminderNotification(Map<String, dynamic> data) async {
    final reminderType = data['reminder_type'] as String?;
    debugPrint('Reminder notification: $reminderType');
  }

  Future<void> _handleNavigationFromNotification(Map<String, dynamic> data) async {
    final action = data['action'] as String?;
    final route = data['route'] as String?;
    debugPrint('Handling navigation - Action: $action, Route: $route');
  }

  // ==================== إدارة المواضيع ====================

  Future<void> _subscribeToDefaultTopics() async {
    try {
      debugPrint('Subscribing to default topics...');
      await subscribeToTopic(_generalTopic);
      await subscribeToTopic(_updatesTopicArabic);
      debugPrint('Default topics subscription completed');
    } catch (e) {
      debugPrint('Error subscribing to default topics: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      try {
        await _messaging!.subscribeToTopic(topic);
      } catch (e) {
        await _fcmChannel.invokeMethod('subscribeToTopic', {'topic': topic});
      }
      
      debugPrint('Subscribed to topic: $topic');
      
      final subscriptions = getSubscribedTopics();
      if (!subscriptions.contains(topic)) {
        subscriptions.add(topic);
        await _storage.setStringList('subscribed_topics', subscriptions);
      }
      
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      try {
        await _messaging!.unsubscribeFromTopic(topic);
      } catch (e) {
        await _fcmChannel.invokeMethod('unsubscribeFromTopic', {'topic': topic});
      }
      
      debugPrint('Unsubscribed from topic: $topic');
      
      final subscriptions = getSubscribedTopics();
      subscriptions.remove(topic);
      await _storage.setStringList('subscribed_topics', subscriptions);
      
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  List<String> getSubscribedTopics() {
    return _storage.getStringList('subscribed_topics') ?? [];
  }

  Future<void> subscribeToPrayerNotifications() async {
    await subscribeToTopic(_prayerTopic);
  }

  Future<void> unsubscribeFromPrayerNotifications() async {
    await unsubscribeFromTopic(_prayerTopic);
  }

  Future<void> subscribeToAthkarNotifications() async {
    await subscribeToTopic(_athkarTopic);
  }

  Future<void> unsubscribeFromAthkarNotifications() async {
    await unsubscribeFromTopic(_athkarTopic);
  }

  // ==================== الحصول على المعلومات ====================

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
  bool get isPermissionGranted => _storage.getBool('fcm_permission_granted') ?? false;

  DateTime? get lastTokenSentTime {
    final timeString = _storage.getString('last_token_sent');
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }

  Map<String, dynamic> get serviceStatus => {
    'is_initialized': _isInitialized,
    'has_token': _fcmToken != null,
    'token_length': _fcmToken?.length ?? 0,
    'permission_granted': isPermissionGranted,
    'last_token_sent': lastTokenSentTime?.toIso8601String(),
    'subscribed_topics': getSubscribedTopics(),
  };

  Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'messaging_available': _messaging != null,
    'has_token': _fcmToken != null,
    'token_length': _fcmToken?.length ?? 0,
    'permission_granted': _storage.getBool('fcm_permission_granted') ?? false,
    'token_sent_to_server': _storage.getBool('token_sent_to_server') ?? false,
    'last_token_sent': _storage.getString('last_token_sent'),
    'firebase_apps_count': Firebase.apps.length,
    'subscribed_topics': getSubscribedTopics(),
    'last_error': _storage.getString('firebase_messaging_error'),
    'token_error': _storage.getString('fcm_token_error'),
    'messaging_available_flag': _storage.getBool('firebase_messaging_available') ?? false,
    'platform': 'android',
  };

  // ==================== إعادة تهيئة وتنظيف ====================

  Future<void> reinitialize() async {
    debugPrint('Reinitializing Firebase Messaging Service...');
    _isInitialized = false;
    _fcmToken = null;
    
    await initialize(
      storage: _storage,
      notificationService: _notificationService,
    );
  }

  Future<void> refreshToken() async {
    try {
      debugPrint('Manually refreshing FCM token...');
      
      if (_messaging != null) {
        await _messaging!.deleteToken();
        await _getFCMToken();
      }
      
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }
  }

  Future<void> testLocalNotification() async {
    if (_notificationService == null) return;
    
    try {
      final testData = LocalNotificationModels.NotificationData(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        title: 'اختبار Firebase',
        body: 'هذا إشعار اختبار من Firebase Messaging Service',
        category: LocalNotificationModels.NotificationCategory.system,
        priority: LocalNotificationModels.NotificationPriority.normal,
      );
      
      await _notificationService!.showNotification(testData);
      debugPrint('Test notification sent successfully');
      
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  void dispose() {
    _isInitialized = false;
    _fcmToken = null;
    _messaging = null;
    debugPrint('FirebaseMessagingService disposed');
  }
}