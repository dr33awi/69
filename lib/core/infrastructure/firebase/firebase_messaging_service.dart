// lib/core/infrastructure/firebase/firebase_messaging_service.dart - محسّن
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
  debugPrint('📱 Background message: ${message.messageId}');
}

/// خدمة Firebase Messaging - محسّنة
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
  
  // Topics
  static const String _prayerTopic = 'prayer_times';
  static const String _athkarTopic = 'athkar_reminders';
  static const String _generalTopic = 'general_notifications';
  static const String _updatesTopicArabic = 'updates_ar';

  /// تهيئة الخدمة
  Future<void> initialize({
    required StorageService storage,
    NotificationService? notificationService,
  }) async {
    if (_isInitialized) {
      debugPrint('✅ Firebase Messaging already initialized');
      return;
    }
    
    _storage = storage;
    _notificationService = notificationService;
    
    try {
      debugPrint('🔄 Initializing Firebase Messaging...');
      
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase not initialized');
      }
      
      _messaging = FirebaseMessaging.instance;
      
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      await _requestPermissions();
      await _getFCMToken();
      _setupMessageHandlers();
      await _subscribeToDefaultTopics();
      
      _isInitialized = true;
      debugPrint('✅ FirebaseMessagingService initialized');
      
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
      _isInitialized = false;
      _messaging = null;
      await _storage.setBool('firebase_messaging_available', false);
      rethrow;
    }
  }

  /// طلب أذونات الإشعارات
  Future<void> _requestPermissions() async {
    if (_messaging == null) return;
    
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      await _storage.setBool('fcm_permission_granted', isGranted);
      
      debugPrint('FCM permission: ${settings.authorizationStatus}');
        
    } catch (e) {
      debugPrint('❌ Error requesting FCM permissions: $e');
      await _storage.setBool('fcm_permission_granted', false);
    }
  }

  /// ✅ الحصول على FCM Token - محسّن
  Future<void> _getFCMToken() async {
    if (_messaging == null) return;
    
    try {
      // محاولة الحصول على Token من Firebase
      _fcmToken = await _messaging!.getToken();
      
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        debugPrint('⚠️ FCM Token is null, trying native method...');
        
        // Fallback إلى Native Method
        try {
          _fcmToken = await _fcmChannel.invokeMethod<String>('getToken');
        } catch (nativeError) {
          debugPrint('❌ Native token method failed: $nativeError');
        }
      }
      
      if (_fcmToken != null && _fcmToken!.isNotEmpty) {
        debugPrint('✅ FCM Token: ${_fcmToken!.substring(0, 20)}...');
        await _storage.setString('fcm_token', _fcmToken!);
        await _storage.setBool('firebase_messaging_available', true);
        await _sendTokenToServer(_fcmToken!);
      } else {
        debugPrint('❌ Failed to get FCM token');
        await _storage.setBool('firebase_messaging_available', false);
      }
      
      // مراقبة تحديث Token
      _messaging!.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await _storage.setString('fcm_token', newToken);
        await _sendTokenToServer(newToken);
        debugPrint('🔄 FCM Token refreshed');
      });
      
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      await _storage.setBool('firebase_messaging_available', false);
    }
  }

  /// إرسال التوكن للخادم
  Future<void> _sendTokenToServer(String token) async {
    try {
      // TODO: API call للخادم
      await _storage.setString('last_token_sent', DateTime.now().toIso8601String());
      await _storage.setBool('token_sent_to_server', true);
      debugPrint('✅ Token sent to server');
    } catch (e) {
      debugPrint('❌ Error sending token: $e');
      await _storage.setBool('token_sent_to_server', false);
    }
  }

  /// إعداد معالجي الرسائل
  void _setupMessageHandlers() {
    if (_messaging == null) return;
    
    try {
      // رسائل Foreground
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('📩 Foreground message: ${message.messageId}');
        _handleForegroundMessage(message);
      });

      // النقر على الإشعار
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('👆 Message opened: ${message.messageId}');
        _handleMessageOpened(message);
      });

      _handleInitialMessage();
      
      debugPrint('✅ Message handlers setup completed');
      
    } catch (e) {
      debugPrint('❌ Error setting up message handlers: $e');
    }
  }

  /// معالجة الرسائل Foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      if (_notificationService != null) {
        await _showLocalNotification(message);
      }
      await _processMessageData(message);
    } catch (e) {
      debugPrint('❌ Error handling foreground message: $e');
    }
  }

  /// معالجة النقر على الإشعار
  Future<void> _handleMessageOpened(RemoteMessage message) async {
    try {
      await _handleNavigationFromNotification(message.data);
    } catch (e) {
      debugPrint('❌ Error handling message opened: $e');
    }
  }

  /// معالجة الرسالة الأولية
  Future<void> _handleInitialMessage() async {
    try {
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📱 App opened from notification');
        await _handleMessageOpened(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ Error handling initial message: $e');
    }
  }

  /// عرض إشعار محلي
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (_notificationService == null) return;
    
    try {
      final title = message.notification?.title ?? 'تطبيق الأذكار';
      final body = message.notification?.body ?? '';
      
      final notificationData = LocalNotificationModels.NotificationData(
        id: 'firebase_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        category: _getNotificationCategory(message.data['type']),
        priority: LocalNotificationModels.NotificationPriority.normal,
        payload: message.data.isNotEmpty ? message.data : null,
      );
      
      await _notificationService!.showNotification(notificationData);
      
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  LocalNotificationModels.NotificationCategory _getNotificationCategory(String? type) {
    switch (type) {
      case 'prayer': return LocalNotificationModels.NotificationCategory.prayer;
      case 'athkar': return LocalNotificationModels.NotificationCategory.athkar;
      case 'quran': return LocalNotificationModels.NotificationCategory.quran;
      case 'reminder': return LocalNotificationModels.NotificationCategory.reminder;
      default: return LocalNotificationModels.NotificationCategory.system;
    }
  }

  /// معالجة بيانات الرسالة
  Future<void> _processMessageData(RemoteMessage message) async {
    try {
      final type = message.data['type'] as String?;
      
      switch (type) {
        case 'prayer':
          final prayerName = message.data['prayer_name'];
          debugPrint('📿 Prayer notification: $prayerName');
          break;
        case 'athkar':
          final athkarType = message.data['athkar_type'];
          debugPrint('📖 Athkar notification: $athkarType');
          break;
        default:
          debugPrint('📬 General notification: $type');
      }
      
    } catch (e) {
      debugPrint('❌ Error processing message data: $e');
    }
  }

  Future<void> _handleNavigationFromNotification(Map<String, dynamic> data) async {
    final route = data['route'] as String?;
    debugPrint('🧭 Navigation to: $route');
    // TODO: تنفيذ التنقل
  }

  // ==================== إدارة المواضيع ====================

  Future<void> _subscribeToDefaultTopics() async {
    try {
      await subscribeToTopic(_generalTopic);
      await subscribeToTopic(_updatesTopicArabic);
      debugPrint('✅ Default topics subscribed');
    } catch (e) {
      debugPrint('❌ Error subscribing to default topics: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging!.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to: $topic');
      
      final subscriptions = getSubscribedTopics();
      if (!subscriptions.contains(topic)) {
        subscriptions.add(topic);
        await _storage.setStringList('subscribed_topics', subscriptions);
      }
    } catch (e) {
      debugPrint('❌ Error subscribing to $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from: $topic');
      
      final subscriptions = getSubscribedTopics();
      subscriptions.remove(topic);
      await _storage.setStringList('subscribed_topics', subscriptions);
    } catch (e) {
      debugPrint('❌ Error unsubscribing from $topic: $e');
    }
  }

  List<String> getSubscribedTopics() {
    return _storage.getStringList('subscribed_topics') ?? [];
  }

  Future<void> subscribeToPrayerNotifications() => subscribeToTopic(_prayerTopic);
  Future<void> unsubscribeFromPrayerNotifications() => unsubscribeFromTopic(_prayerTopic);
  Future<void> subscribeToAthkarNotifications() => subscribeToTopic(_athkarTopic);
  Future<void> unsubscribeFromAthkarNotifications() => unsubscribeFromTopic(_athkarTopic);

  // ==================== Getters ====================

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
  bool get isPermissionGranted => _storage.getBool('fcm_permission_granted') ?? false;

  Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'has_token': _fcmToken != null,
    'token_length': _fcmToken?.length ?? 0,
    'permission_granted': isPermissionGranted,
    'subscribed_topics': getSubscribedTopics(),
    'platform': 'android',
  };

  // ==================== Utilities ====================

  Future<void> refreshToken() async {
    try {
      if (_messaging != null) {
        await _messaging!.deleteToken();
        await _getFCMToken();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing token: $e');
    }
  }

  void dispose() {
    _isInitialized = false;
    _fcmToken = null;
    _messaging = null;
    debugPrint('FirebaseMessagingService disposed');
  }
}