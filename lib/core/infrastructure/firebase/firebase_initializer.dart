// lib/core/infrastructure/firebase/firebase_initializer.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// مهيئ Firebase محسّن مع دعم جميع الخدمات
class FirebaseInitializer {
  static bool _isInitialized = false;
  static Exception? _lastError;
  static DateTime? _initializationTime;
  
  // حالة الخدمات المختلفة
  static bool _isMessagingAvailable = false;
  static bool _isRemoteConfigAvailable = false;
  
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
      
      // فحص الخدمات المتاحة
      await _checkAvailableServices();
      
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
  
  /// فحص الخدمات المتاحة
  static Future<void> _checkAvailableServices() async {
    debugPrint('🔍 Checking available Firebase services...');
    
    // فحص Firebase Messaging
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      _isMessagingAvailable = token != null;
      debugPrint('  ✅ Firebase Messaging: Available (Token: ${token != null})');
    } catch (e) {
      _isMessagingAvailable = false;
      debugPrint('  ❌ Firebase Messaging: Not available - $e');
    }
    
    // فحص Firebase Remote Config
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
  
  /// تهيئة Firebase مع إعادة المحاولة
  static Future<bool> initializeWithRetry({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    debugPrint('🔄 Attempting Firebase initialization with retry...');
    
    for (int i = 0; i < maxRetries; i++) {
      debugPrint('  Attempt ${i + 1}/$maxRetries...');
      
      if (await initialize()) {
        return true;
      }
      
      if (i < maxRetries - 1) {
        debugPrint('  ⏱️ Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      }
    }
    
    debugPrint('❌ Firebase initialization failed after $maxRetries attempts');
    return false;
  }
  
  /// إعادة تهيئة Firebase (مفيد للتطوير)
  static Future<bool> reinitialize() async {
    debugPrint('🔄 Reinitializing Firebase...');
    
    _isInitialized = false;
    _lastError = null;
    _initializationTime = null;
    _isMessagingAvailable = false;
    _isRemoteConfigAvailable = false;
    
    return await initialize();
  }
  
  /// التحقق من جاهزية خدمة معينة
  static bool isServiceAvailable(FirebaseService service) {
    if (!_isInitialized) return false;
    
    switch (service) {
      case FirebaseService.messaging:
        return _isMessagingAvailable;
      case FirebaseService.remoteConfig:
        return _isRemoteConfigAvailable;
      default:
        return false;
    }
  }
  
  /// انتظار جاهزية Firebase
  static Future<bool> waitForInitialization({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isInitialized) return true;
    
    debugPrint('⏳ Waiting for Firebase initialization...');
    
    final stopwatch = Stopwatch()..start();
    
    while (!_isInitialized && stopwatch.elapsed < timeout) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    stopwatch.stop();
    
    if (_isInitialized) {
      debugPrint('✅ Firebase ready after ${stopwatch.elapsedMilliseconds}ms');
      return true;
    } else {
      debugPrint('❌ Firebase initialization timeout after ${timeout.inSeconds} seconds');
      return false;
    }
  }
  
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
    debugPrint('  - Messaging: ${_isMessagingAvailable ? "✅" : "❌"}');
    debugPrint('  - Remote Config: ${_isRemoteConfigAvailable ? "✅" : "❌"}');
    
    if (_initializationTime != null) {
      debugPrint('Initialized at: ${_initializationTime!.toIso8601String()}');
    }
    
    if (_lastError != null) {
      debugPrint('Last Error: ${_lastError!.toString()}');
    }
    
    debugPrint('====================================');
  }
  
  /// تنظيف Firebase (للاستخدام في التطوير)
  static void dispose() {
    _isInitialized = false;
    _lastError = null;
    _initializationTime = null;
    _isMessagingAvailable = false;
    _isRemoteConfigAvailable = false;
    debugPrint('🧹 FirebaseInitializer disposed');
  }
  
  // ==================== Getters ====================
  
  /// التحقق من تهيئة Firebase
  static bool get isInitialized => _isInitialized;
  
  /// الحصول على آخر خطأ
  static Exception? get lastError => _lastError;
  
  /// التحقق من توفر Firebase Apps
  static bool get hasFirebaseApps => Firebase.apps.isNotEmpty;
  
  /// الحصول على وقت التهيئة
  static DateTime? get initializationTime => _initializationTime;
  
  /// التحقق من توفر Messaging
  static bool get isMessagingAvailable => _isMessagingAvailable;
  
  /// التحقق من توفر Remote Config
  static bool get isRemoteConfigAvailable => _isRemoteConfigAvailable;
  
  /// الحصول على قائمة التطبيقات
  static List<FirebaseApp> get apps => Firebase.apps;
  
  /// الحصول على التطبيق الافتراضي
  static FirebaseApp? get defaultApp {
    try {
      return Firebase.app();
    } catch (e) {
      return null;
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
    },
    'platform': defaultTargetPlatform.name,
  };
  
  /// طباعة معلومات التصحيح
  static void printDebugInfo() {
    debugPrint('========== Firebase Debug Info ==========');
    final info = debugInfo;
    info.forEach((key, value) {
      if (value is Map) {
        debugPrint('$key:');
        value.forEach((k, v) {
          debugPrint('  $k: $v');
        });
      } else if (value is List) {
        debugPrint('$key: ${value.join(", ")}');
      } else {
        debugPrint('$key: $value');
      }
    });
    debugPrint('========================================');
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
}

/// Extension methods للتحقق السريع
extension FirebaseInitializerExtensions on BuildContext {
  /// التحقق من جاهزية Firebase
  bool get isFirebaseReady => FirebaseInitializer.isInitialized;
  
  /// التحقق من توفر خدمة معينة
  bool isFirebaseServiceAvailable(FirebaseService service) {
    return FirebaseInitializer.isServiceAvailable(service);
  }
  
  /// الحصول على معلومات Firebase
  Map<String, dynamic> get firebaseDebugInfo => FirebaseInitializer.debugInfo;
}