// lib/core/infrastructure/firebase/firebase_initializer.dart - محسّن

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// مهيئ Firebase محسّن
class FirebaseInitializer {
  static bool _isInitialized = false;
  static Exception? _lastError;
  
  /// تهيئة Firebase
  static Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('Firebase already initialized');
      return true;
    }
    
    try {
      debugPrint('Initializing Firebase...');
      
      // تهيئة Firebase Core
      await Firebase.initializeApp();
      
      _isInitialized = true;
      _lastError = null;
      debugPrint('Firebase initialized successfully ✓');
      
      return true;
      
    } catch (e) {
      _lastError = Exception('Firebase initialization failed: $e');
      debugPrint('Failed to initialize Firebase: $e');
      
      if (kDebugMode) {
        debugPrint('App will continue without Firebase services');
      }
      
      // إرجاع false بدلاً من رمي Exception
      // للسماح للتطبيق بالاستمرار
      return false;
    }
  }
  
  /// تهيئة Firebase مع إعادة المحاولة
  static Future<bool> initializeWithRetry({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      if (await initialize()) {
        return true;
      }
      
      if (i < maxRetries - 1) {
        debugPrint('Retrying Firebase initialization in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      }
    }
    
    debugPrint('Firebase initialization failed after $maxRetries attempts');
    return false;
  }
  
  /// التحقق من تهيئة Firebase
  static bool get isInitialized => _isInitialized;
  
  /// الحصول على آخر خطأ
  static Exception? get lastError => _lastError;
  
  /// التحقق من توفر Firebase Apps
  static bool get hasFirebaseApps => Firebase.apps.isNotEmpty;
  
  /// إعادة تهيئة Firebase
  static Future<bool> reinitialize() async {
    _isInitialized = false;
    _lastError = null;
    return await initialize();
  }
  
  /// تنظيف Firebase (للاستخدام في التطوير)
  static void dispose() {
    _isInitialized = false;
    _lastError = null;
    debugPrint('FirebaseInitializer disposed');
  }
  
  /// معلومات التصحيح
  static Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'has_error': _lastError != null,
    'error_message': _lastError?.toString(),
    'firebase_apps_count': Firebase.apps.length,
    'firebase_app_names': Firebase.apps.map((app) => app.name).toList(),
  };
}