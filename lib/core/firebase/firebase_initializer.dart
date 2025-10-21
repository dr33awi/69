// lib/core/infrastructure/firebase/firebase_initializer.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';

/// مهيئ Firebase محسّن مع دعم جميع الخدمات
class FirebaseInitializer {
  static bool _isInitialized = false;
  static Exception? _lastError;
  static DateTime? _initializationTime;
  
  // حالة الخدمات المختلفة
  static bool _isMessagingAvailable = false;
  static bool _isRemoteConfigAvailable = false;
  static bool _isAnalyticsAvailable = false;
  static bool _isCrashlyticsAvailable = false;
  static bool _isPerformanceAvailable = false;
  static bool _isInAppMessagingAvailable = false;
  
  // مراجع الخدمات
  static FirebaseAnalytics? _analytics;
  static FirebasePerformance? _performance;
  static FirebaseInAppMessaging? _inAppMessaging;
  
  /// تهيئة Firebase Core والخدمات
  static Future<bool> initialize() async {
    if (_isInitialized) {
      _printStatus();
      return true;
    }

    try {
      final stopwatch = Stopwatch()..start();

      // التحقق من توفر Firebase apps (تم تهيئتها مسبقاً)
      if (Firebase.apps.isEmpty) {
        debugPrint('⚠️ No Firebase apps available - running in offline mode');
        return false;
      }

      _isInitialized = true;
      _initializationTime = DateTime.now();
      _lastError = null;

      // فحص وتهيئة الخدمات المتاحة (بدون رمي استثناءات)
      await _initializeServices();

      // إعداد Crashlytics (اختياري)
      await _setupCrashlytics();

      stopwatch.stop();
      _printStatus();

      return true;

    } catch (e) {
      _lastError = Exception('Firebase initialization failed: $e');
      debugPrint('⚠️ Firebase initialization failed (offline mode): $e');

      return false;
    }
  }
  
  /// تهيئة جميع خدمات Firebase
  static Future<void> _initializeServices() async {
    // تهيئة Firebase Analytics
    await _initializeAnalytics();
    
    // تهيئة Firebase Performance Monitoring
    await _initializePerformance();
    
    // تهيئة Firebase In-App Messaging
    await _initializeInAppMessaging();
    
    // فحص Firebase Messaging (موجود مسبقاً)
    await _checkMessaging();
    
    // فحص Firebase Remote Config (موجود مسبقاً)
    await _checkRemoteConfig();
    
    // تهيئة Crashlytics
    await _initializeCrashlytics();
  }
  
  /// تهيئة Firebase Analytics
  static Future<void> _initializeAnalytics() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      
      // تفعيل جمع البيانات
      await _analytics!.setAnalyticsCollectionEnabled(!kDebugMode);
      
      // تعيين خصائص المستخدم الافتراضية
      await _analytics!.setUserProperty(
        name: 'app_language',
        value: 'ar',
      );
      
      // تسجيل حدث بدء التطبيق
      await _analytics!.logAppOpen();
      
      _isAnalyticsAvailable = true;
    } catch (e) {
      _isAnalyticsAvailable = false;
    }
  }
  
  /// تهيئة Firebase Performance Monitoring
  static Future<void> _initializePerformance() async {
    try {
      _performance = FirebasePerformance.instance;
      
      // تفعيل Performance Monitoring
      await _performance!.setPerformanceCollectionEnabled(!kDebugMode);
      
      // بدء تتبع أداء التطبيق
      final Trace appStartTrace = _performance!.newTrace('app_start');
      await appStartTrace.start();
      
      // إضافة معلومات مخصصة
      appStartTrace.putAttribute('platform', defaultTargetPlatform.name);
      appStartTrace.putAttribute('debug_mode', kDebugMode.toString());
      
      await appStartTrace.stop();
      
      _isPerformanceAvailable = true;
    } catch (e) {
      _isPerformanceAvailable = false;
    }
  }
  
  /// تهيئة Firebase In-App Messaging
  static Future<void> _initializeInAppMessaging() async {
    try {
      _inAppMessaging = FirebaseInAppMessaging.instance;
      
      // تفعيل عرض الرسائل تلقائياً
      await _inAppMessaging!.setAutomaticDataCollectionEnabled(!kDebugMode);
      
      // يمكن تخصيص عرض الرسائل
      if (kDebugMode) {
        // في وضع التطوير، عرض رسائل الاختبار
        await _inAppMessaging!.triggerEvent('test_event');
      }
      
      _isInAppMessagingAvailable = true;
    } catch (e) {
      _isInAppMessagingAvailable = false;
    }
  }
  
  /// تهيئة Firebase Crashlytics
  static Future<void> _initializeCrashlytics() async {
    try {
      // تفعيل Crashlytics Collection
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      
      _isCrashlyticsAvailable = true;
    } catch (e) {
      _isCrashlyticsAvailable = false;
    }
  }
  
  /// إعداد Crashlytics لالتقاط الأخطاء
  static Future<void> _setupCrashlytics() async {
    if (!_isCrashlyticsAvailable) return;
    
    try {
      // التقاط أخطاء Flutter
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      
      // التقاط أخطاء Zone
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
    }
  }
  
  /// فحص Firebase Messaging
  static Future<void> _checkMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      _isMessagingAvailable = token != null;
    } catch (e) {
      _isMessagingAvailable = false;
    }
  }
  
  /// فحص Firebase Remote Config
  static Future<void> _checkRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      _isRemoteConfigAvailable = true;
    } catch (e) {
      _isRemoteConfigAvailable = false;
    }
  }
  
  // ==================== Analytics Methods ====================
  
  /// تسجيل حدث مخصص
  static Future<void> logEvent(String name, [Map<String, dynamic>? parameters]) async {
    if (_analytics == null || !_isAnalyticsAvailable) return;
    
    try {
      // تحويل Map<String, dynamic> إلى Map<String, Object>
      Map<String, Object>? firebaseParams;
      if (parameters != null) {
        firebaseParams = {};
        parameters.forEach((key, value) {
          if (value != null) {
            firebaseParams![key] = value;
          }
        });
      }
      
      await _analytics!.logEvent(
        name: name,
        parameters: firebaseParams,
      );
    } catch (e) {
    }
  }
  
  /// تسجيل فتح شاشة
  static Future<void> logScreenView(String screenName, [String? screenClass]) async {
    if (_analytics == null || !_isAnalyticsAvailable) return;
    
    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
    }
  }
  
  /// تعيين معرف المستخدم
  static Future<void> setUserId(String? userId) async {
    if (_analytics == null || !_isAnalyticsAvailable) return;
    
    try {
      await _analytics!.setUserId(id: userId);
      
      // أيضاً تعيين في Crashlytics
      if (_isCrashlyticsAvailable) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? 'anonymous');
      }
    } catch (e) {
    }
  }
  
  /// تعيين خصائص المستخدم
  static Future<void> setUserProperty(String name, String? value) async {
    if (_analytics == null || !_isAnalyticsAvailable) return;
    
    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e) {
    }
  }
  
  // ==================== Performance Methods ====================
  
  /// بدء تتبع أداء مخصص
  static Trace? startTrace(String name) {
    if (_performance == null || !_isPerformanceAvailable) return null;
    
    try {
      final trace = _performance!.newTrace(name);
      trace.start();
      return trace;
    } catch (e) {
      return null;
    }
  }
  
  /// بدء تتبع طلب HTTP
  static HttpMetric? startHttpMetric(String url, HttpMethod method) {
    if (_performance == null || !_isPerformanceAvailable) return null;
    
    try {
      final metric = _performance!.newHttpMetric(url, method);
      metric.start();
      return metric;
    } catch (e) {
      return null;
    }
  }
  
  // ==================== Crashlytics Methods ====================
  
  /// تسجيل خطأ غير قاتل
  static Future<void> recordError(dynamic exception, StackTrace? stack, {bool fatal = false}) async {
    if (!_isCrashlyticsAvailable) return;
    
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        fatal: fatal,
      );
    } catch (e) {
    }
  }
  
  /// تسجيل رسالة مخصصة
  static void log(String message) {
    if (!_isCrashlyticsAvailable) return;
    
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (e) {
    }
  }
  
  /// تعيين مفتاح مخصص
  static Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isCrashlyticsAvailable) return;
    
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
    }
  }
  
  // ==================== In-App Messaging Methods ====================
  
  /// تشغيل حدث للرسائل داخل التطبيق
  static Future<void> triggerInAppMessage(String eventName) async {
    if (_inAppMessaging == null || !_isInAppMessagingAvailable) return;
    
    try {
      await _inAppMessaging!.triggerEvent(eventName);
    } catch (e) {
    }
  }
  
  /// إيقاف عرض الرسائل مؤقتاً
  static void suppressInAppMessages(bool suppress) {
    if (_inAppMessaging == null || !_isInAppMessagingAvailable) return;
    
    try {
      _inAppMessaging!.setMessagesSuppressed(suppress);
    } catch (e) {
    }
  }
  
  // ==================== Getters ====================
  
  static bool get isInitialized => _isInitialized;
  static bool get isAnalyticsAvailable => _isAnalyticsAvailable;
  static bool get isCrashlyticsAvailable => _isCrashlyticsAvailable;
  static bool get isPerformanceAvailable => _isPerformanceAvailable;
  static bool get isInAppMessagingAvailable => _isInAppMessagingAvailable;
  static bool get isMessagingAvailable => _isMessagingAvailable;
  static bool get isRemoteConfigAvailable => _isRemoteConfigAvailable;
  
  static FirebaseAnalytics? get analytics => _analytics;
  static FirebasePerformance? get performance => _performance;
  static FirebaseInAppMessaging? get inAppMessaging => _inAppMessaging;
  
  /// طباعة حالة Firebase
  static void _printStatus() {
    if (Firebase.apps.isNotEmpty) {
      for (final app in Firebase.apps) {
      }
    }
    if (_initializationTime != null) {
    }
    
    if (_lastError != null) {
    }
  }
  
  /// معلومات التصحيح
  static Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'has_error': _lastError != null,
    'error_message': _lastError?.toString(),
    'initialization_time': _initializationTime?.toIso8601String(),
    'firebase_apps_count': Firebase.apps.length,
    'firebase_app_names': Firebase.apps.map((app) => app.name).toList(),
    'services': {
      'messaging': _isMessagingAvailable,
      'remote_config': _isRemoteConfigAvailable,
      'analytics': _isAnalyticsAvailable,
      'crashlytics': _isCrashlyticsAvailable,
      'performance': _isPerformanceAvailable,
      'in_app_messaging': _isInAppMessagingAvailable,
    },
    'platform': defaultTargetPlatform.name,
  };
  
  /// تنظيف Firebase
  static void dispose() {
    _isInitialized = false;
    _lastError = null;
    _initializationTime = null;
    _isMessagingAvailable = false;
    _isRemoteConfigAvailable = false;
    _isAnalyticsAvailable = false;
    _isCrashlyticsAvailable = false;
    _isPerformanceAvailable = false;
    _isInAppMessagingAvailable = false;
    _analytics = null;
    _performance = null;
    _inAppMessaging = null;
  }
}

/// أنواع خدمات Firebase
enum FirebaseService {
  messaging,
  remoteConfig,
  analytics,
  crashlytics,
  performance,
  auth,
  firestore,
  storage,
  functions,
  database,
  inAppMessaging,
}