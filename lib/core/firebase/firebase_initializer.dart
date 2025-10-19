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
      debugPrint('✅ Firebase already initialized');
      _printStatus();
      return true;
    }
    
    try {
      debugPrint('🔥 Initializing Firebase...');
      final stopwatch = Stopwatch()..start();
      
      // تهيئة Firebase Core
      await Firebase.initializeApp();
      
      // التحقق من نجاح التهيئة
      if (Firebase.apps.isEmpty) {
        throw Exception('No Firebase apps found after initialization');
      }
      
      _isInitialized = true;
      _initializationTime = DateTime.now();
      _lastError = null;
      
      // فحص وتهيئة الخدمات المتاحة
      await _initializeServices();
      
      // إعداد Crashlytics
      await _setupCrashlytics();
      
      stopwatch.stop();
      debugPrint('✅ Firebase initialized successfully in ${stopwatch.elapsedMilliseconds}ms');
      _printStatus();
      
      return true;
      
    } catch (e) {
      _lastError = Exception('Firebase initialization failed: $e');
      debugPrint('❌ Failed to initialize Firebase: $e');
      
      if (kDebugMode) {
        debugPrint('⚠️ App will continue without Firebase services');
        debugPrint('Stack trace: ${StackTrace.current}');
      }
      
      return false;
    }
  }
  
  /// تهيئة جميع خدمات Firebase
  static Future<void> _initializeServices() async {
    debugPrint('🔍 Initializing Firebase services...');
    
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
      debugPrint('  ✅ Firebase Analytics: Available and initialized');
      
    } catch (e) {
      _isAnalyticsAvailable = false;
      debugPrint('  ❌ Firebase Analytics: Not available - $e');
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
      debugPrint('  ✅ Firebase Performance: Available and initialized');
      
    } catch (e) {
      _isPerformanceAvailable = false;
      debugPrint('  ❌ Firebase Performance: Not available - $e');
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
      debugPrint('  ✅ Firebase In-App Messaging: Available and initialized');
      
    } catch (e) {
      _isInAppMessagingAvailable = false;
      debugPrint('  ❌ Firebase In-App Messaging: Not available - $e');
    }
  }
  
  /// تهيئة Firebase Crashlytics
  static Future<void> _initializeCrashlytics() async {
    try {
      // تفعيل Crashlytics Collection
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      
      _isCrashlyticsAvailable = true;
      debugPrint('  ✅ Firebase Crashlytics: Available and initialized');
      
    } catch (e) {
      _isCrashlyticsAvailable = false;
      debugPrint('  ❌ Firebase Crashlytics: Not available - $e');
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
      
      debugPrint('  ✅ Crashlytics error handling setup complete');
      
    } catch (e) {
      debugPrint('  ❌ Failed to setup Crashlytics: $e');
    }
  }
  
  /// فحص Firebase Messaging
  static Future<void> _checkMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      _isMessagingAvailable = token != null;
      debugPrint('  ✅ Firebase Messaging: Available (Token: ${token != null})');
    } catch (e) {
      _isMessagingAvailable = false;
      debugPrint('  ❌ Firebase Messaging: Not available - $e');
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
      debugPrint('  ✅ Firebase Remote Config: Available');
    } catch (e) {
      _isRemoteConfigAvailable = false;
      debugPrint('  ❌ Firebase Remote Config: Not available - $e');
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
      debugPrint('📊 Event logged: $name');
    } catch (e) {
      debugPrint('❌ Failed to log event: $e');
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
      debugPrint('📱 Screen view logged: $screenName');
    } catch (e) {
      debugPrint('❌ Failed to log screen view: $e');
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
      
      debugPrint('👤 User ID set: ${userId ?? 'cleared'}');
    } catch (e) {
      debugPrint('❌ Failed to set user ID: $e');
    }
  }
  
  /// تعيين خصائص المستخدم
  static Future<void> setUserProperty(String name, String? value) async {
    if (_analytics == null || !_isAnalyticsAvailable) return;
    
    try {
      await _analytics!.setUserProperty(name: name, value: value);
      debugPrint('📝 User property set: $name = $value');
    } catch (e) {
      debugPrint('❌ Failed to set user property: $e');
    }
  }
  
  // ==================== Performance Methods ====================
  
  /// بدء تتبع أداء مخصص
  static Trace? startTrace(String name) {
    if (_performance == null || !_isPerformanceAvailable) return null;
    
    try {
      final trace = _performance!.newTrace(name);
      trace.start();
      debugPrint('⏱️ Performance trace started: $name');
      return trace;
    } catch (e) {
      debugPrint('❌ Failed to start trace: $e');
      return null;
    }
  }
  
  /// بدء تتبع طلب HTTP
  static HttpMetric? startHttpMetric(String url, HttpMethod method) {
    if (_performance == null || !_isPerformanceAvailable) return null;
    
    try {
      final metric = _performance!.newHttpMetric(url, method);
      metric.start();
      debugPrint('🌐 HTTP metric started: ${method.name} $url');
      return metric;
    } catch (e) {
      debugPrint('❌ Failed to start HTTP metric: $e');
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
      debugPrint('🐛 Error recorded: $exception');
    } catch (e) {
      debugPrint('❌ Failed to record error: $e');
    }
  }
  
  /// تسجيل رسالة مخصصة
  static void log(String message) {
    if (!_isCrashlyticsAvailable) return;
    
    try {
      FirebaseCrashlytics.instance.log(message);
      debugPrint('📝 Crashlytics log: $message');
    } catch (e) {
      debugPrint('❌ Failed to log message: $e');
    }
  }
  
  /// تعيين مفتاح مخصص
  static Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isCrashlyticsAvailable) return;
    
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
      debugPrint('🔑 Custom key set: $key = $value');
    } catch (e) {
      debugPrint('❌ Failed to set custom key: $e');
    }
  }
  
  // ==================== In-App Messaging Methods ====================
  
  /// تشغيل حدث للرسائل داخل التطبيق
  static Future<void> triggerInAppMessage(String eventName) async {
    if (_inAppMessaging == null || !_isInAppMessagingAvailable) return;
    
    try {
      await _inAppMessaging!.triggerEvent(eventName);
      debugPrint('💬 In-app message event triggered: $eventName');
    } catch (e) {
      debugPrint('❌ Failed to trigger in-app message: $e');
    }
  }
  
  /// إيقاف عرض الرسائل مؤقتاً
  static void suppressInAppMessages(bool suppress) {
    if (_inAppMessaging == null || !_isInAppMessagingAvailable) return;
    
    try {
      _inAppMessaging!.setMessagesSuppressed(suppress);
      debugPrint('💬 In-app messages ${suppress ? 'suppressed' : 'enabled'}');
    } catch (e) {
      debugPrint('❌ Failed to suppress messages: $e');
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
    debugPrint('========== Firebase Status ==========');
    debugPrint('Initialized: $_isInitialized');
    debugPrint('Apps Count: ${Firebase.apps.length}');
    
    if (Firebase.apps.isNotEmpty) {
      debugPrint('Apps:');
      for (final app in Firebase.apps) {
        debugPrint('  - ${app.name} (${app.options.projectId})');
      }
    }
    
    debugPrint('Services:');
    debugPrint('  ✅ Core Services:');
    debugPrint('    - Messaging: ${_isMessagingAvailable ? "✅" : "❌"}');
    debugPrint('    - Remote Config: ${_isRemoteConfigAvailable ? "✅" : "❌"}');
    debugPrint('  📊 Analytics & Monitoring:');
    debugPrint('    - Analytics: ${_isAnalyticsAvailable ? "✅" : "❌"}');
    debugPrint('    - Crashlytics: ${_isCrashlyticsAvailable ? "✅" : "❌"}');
    debugPrint('    - Performance: ${_isPerformanceAvailable ? "✅" : "❌"}');
    debugPrint('    - In-App Messaging: ${_isInAppMessagingAvailable ? "✅" : "❌"}');
    
    if (_initializationTime != null) {
      debugPrint('Initialized at: ${_initializationTime!.toIso8601String()}');
    }
    
    if (_lastError != null) {
      debugPrint('Last Error: ${_lastError!.toString()}');
    }
    
    debugPrint('====================================');
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
    debugPrint('🧹 FirebaseInitializer disposed');
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