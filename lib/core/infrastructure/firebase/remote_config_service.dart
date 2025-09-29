// lib/core/infrastructure/firebase/remote_config_service.dart - محسن ومصحح

import 'dart:async';
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// خدمة Firebase Remote Config محسنة مع دعم JSON والمعلمات المنفصلة
class FirebaseRemoteConfigService {
  static final FirebaseRemoteConfigService _instance = FirebaseRemoteConfigService._internal();
  factory FirebaseRemoteConfigService() => _instance;
  FirebaseRemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;
  
  // مفاتيح الإعدادات - طريقتان مختلفتان
  static const String _keyTestConfig = 'Test'; // JSON method
  
  // المعلمات المنفصلة (أفضل)
  static const String _keyAppVersion = 'app_version';
  static const String _keyForceUpdate = 'force_update';
  static const String _keyMaintenanceMode = 'maintenance_mode';
  static const String _keyFeaturesConfig = 'features_config';
  static const String _keyNotificationConfig = 'notification_config';
  static const String _keyThemeConfig = 'theme_config';
  static const String _keyAthkarSettings = 'athkar_settings';

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // إعداد التحديث التلقائي
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5), // تقليل المدة للاختبار
      ));
      
      // تعيين القيم الافتراضية
      await _setDefaults();
      
      // جلب الإعدادات الأولية
      await _fetchAndActivate();
      
      _isInitialized = true;
      debugPrint('FirebaseRemoteConfigService initialized successfully');
      
      // طباعة معلومات التشخيص
      _printDebugInfo();
      
    } catch (e) {
      debugPrint('Error initializing Firebase Remote Config: $e');
      throw Exception('Failed to initialize Firebase Remote Config: $e');
    }
  }

  /// تعيين القيم الافتراضية - دعم الطريقتين
  Future<void> _setDefaults() async {
    await _remoteConfig.setDefaults({
      // JSON method (طريقة واحدة)
      _keyTestConfig: jsonEncode({
        'force_update': false,
        'app_version': '1.0.0',
        'maintenance_mode': false,
      }),
      
      // Separate parameters method (الطريقة المفضلة)
      _keyAppVersion: '1.0.0',
      _keyForceUpdate: false,
      _keyMaintenanceMode: false,
      
      // باقي الإعدادات
      _keyFeaturesConfig: jsonEncode({
        'prayer_times_enabled': true,
        'qibla_enabled': true,
        'athkar_enabled': true,
        'tasbih_enabled': true,
        'dua_enabled': true,
        'notifications_enabled': true,
      }),
      _keyNotificationConfig: jsonEncode({
        'prayer_notifications': true,
        'athkar_reminders': true,
        'daily_motivations': true,
        'custom_notifications': true,
      }),
      _keyThemeConfig: jsonEncode({
        'primary_color': '#2E7D32',
        'accent_color': '#4CAF50',
        'dark_mode_enabled': true,
        'custom_themes': [],
      }),
      _keyAthkarSettings: jsonEncode({
        'auto_scroll_enabled': true,
        'vibration_feedback': true,
        'sound_effects': false,
        'reading_mode': 'normal',
      }),
    });
  }

  /// جلب وتفعيل الإعدادات
  Future<bool> _fetchAndActivate() async {
    try {
      debugPrint('Fetching remote config...');
      
      final fetchResult = await _remoteConfig.fetchAndActivate();
      debugPrint('Remote config fetch result: $fetchResult');
      debugPrint('Last fetch status: ${_remoteConfig.lastFetchStatus}');
      debugPrint('Last fetch time: ${_remoteConfig.lastFetchTime}');
      
      return fetchResult;
    } catch (e) {
      debugPrint('Error fetching remote config: $e');
      return false;
    }
  }

  /// جلب الإعدادات يدوياً
  Future<bool> refresh() async {
    if (!_isInitialized) {
      debugPrint('Remote config not initialized');
      return false;
    }
    
    final result = await _fetchAndActivate();
    if (result) {
      _printDebugInfo();
    }
    return result;
  }

  // ==================== الحصول على القيم - دعم الطريقتين ====================

  /// الحصول على JSON الرئيسي من معلمة "Test"
  Map<String, dynamic> get testConfig {
    try {
      final jsonString = _remoteConfig.getString(_keyTestConfig);
      debugPrint('Test config JSON string: $jsonString');
      
      if (jsonString.isEmpty) {
        debugPrint('Test config is empty, using defaults');
        return {
          'force_update': false,
          'app_version': '1.0.0',
          'maintenance_mode': false,
        };
      }
      
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint('Test config decoded: $decoded');
      return decoded;
      
    } catch (e) {
      debugPrint('Error parsing test config: $e');
      return {
        'force_update': false,
        'app_version': '1.0.0',
        'maintenance_mode': false,
      };
    }
  }

  /// إصدار التطبيق المطلوب - أولوية للمعلمة المنفصلة
  String get requiredAppVersion {
    // 1. جرب المعلمة المنفصلة أولاً
    final separateVersion = _remoteConfig.getString(_keyAppVersion);
    if (separateVersion.isNotEmpty) {
      debugPrint('App version from separate parameter: $separateVersion');
      return separateVersion;
    }
    
    // 2. جرب JSON كبديل
    final testConfig = this.testConfig;
    final jsonVersion = testConfig['app_version'] as String? ?? '1.0.0';
    debugPrint('App version from JSON: $jsonVersion');
    return jsonVersion;
  }

  /// هل يجب فرض التحديث - أولوية للمعلمة المنفصلة
  bool get isForceUpdateRequired {
    // 1. جرب المعلمة المنفصلة أولاً
    try {
      final separateForceUpdate = _remoteConfig.getBool(_keyForceUpdate);
      debugPrint('Force update from separate parameter: $separateForceUpdate');
      
      // تحقق إضافي - إذا كانت القيمة true، طباعة معلومات إضافية
      if (separateForceUpdate) {
        debugPrint('🚨 FORCE UPDATE REQUIRED FROM SEPARATE PARAMETER!');
        debugPrint('Required version: ${requiredAppVersion}');
      }
      
      return separateForceUpdate;
    } catch (e) {
      debugPrint('Error getting force update from separate parameter: $e');
    }
    
    // 2. جرب JSON كبديل
    try {
      final testConfig = this.testConfig;
      final jsonForceUpdate = testConfig['force_update'] as bool? ?? false;
      debugPrint('Force update from JSON: $jsonForceUpdate');
      
      if (jsonForceUpdate) {
        debugPrint('🚨 FORCE UPDATE REQUIRED FROM JSON!');
      }
      
      return jsonForceUpdate;
    } catch (e) {
      debugPrint('Error getting force update from JSON: $e');
    }
    
    return false;
  }

  /// هل التطبيق في وضع الصيانة - أولوية للمعلمة المنفصلة
  bool get isMaintenanceModeEnabled {
    // 1. جرب المعلمة المنفصلة أولاً
    try {
      final separateMaintenance = _remoteConfig.getBool(_keyMaintenanceMode);
      debugPrint('Maintenance mode from separate parameter: $separateMaintenance');
      
      if (separateMaintenance) {
        debugPrint('🔧 MAINTENANCE MODE ENABLED FROM SEPARATE PARAMETER!');
      }
      
      return separateMaintenance;
    } catch (e) {
      debugPrint('Error getting maintenance mode from separate parameter: $e');
    }
    
    // 2. جرب JSON كبديل
    try {
      final testConfig = this.testConfig;
      final jsonMaintenance = testConfig['maintenance_mode'] as bool? ?? false;
      debugPrint('Maintenance mode from JSON: $jsonMaintenance');
      
      if (jsonMaintenance) {
        debugPrint('🔧 MAINTENANCE MODE ENABLED FROM JSON!');
      }
      
      return jsonMaintenance;
    } catch (e) {
      debugPrint('Error getting maintenance mode from JSON: $e');
    }
    
    return false;
  }

  // ==================== باقي الإعدادات ====================

  /// إعدادات الميزات
  Map<String, dynamic> get featuresConfig {
    try {
      final jsonString = _remoteConfig.getString(_keyFeaturesConfig);
      if (jsonString.isEmpty) {
        return {
          'prayer_times_enabled': true,
          'qibla_enabled': true,
          'athkar_enabled': true,
          'tasbih_enabled': true,
          'dua_enabled': true,
          'notifications_enabled': true,
        };
      }
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing features config: $e');
      return {
        'prayer_times_enabled': true,
        'qibla_enabled': true,
        'athkar_enabled': true,
        'tasbih_enabled': true,
        'dua_enabled': true,
        'notifications_enabled': true,
      };
    }
  }

  /// إعدادات الإشعارات
  Map<String, dynamic> get notificationConfig {
    try {
      final jsonString = _remoteConfig.getString(_keyNotificationConfig);
      if (jsonString.isEmpty) {
        return {
          'prayer_notifications': true,
          'athkar_reminders': true,
          'daily_motivations': true,
          'custom_notifications': true,
        };
      }
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing notification config: $e');
      return {
        'prayer_notifications': true,
        'athkar_reminders': true,
        'daily_motivations': true,
        'custom_notifications': true,
      };
    }
  }

  /// إعدادات الثيم
  Map<String, dynamic> get themeConfig {
    try {
      final jsonString = _remoteConfig.getString(_keyThemeConfig);
      if (jsonString.isEmpty) {
        return {
          'primary_color': '#2E7D32',
          'accent_color': '#4CAF50',
          'dark_mode_enabled': true,
          'custom_themes': [],
        };
      }
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing theme config: $e');
      return {
        'primary_color': '#2E7D32',
        'accent_color': '#4CAF50',
        'dark_mode_enabled': true,
        'custom_themes': [],
      };
    }
  }

  /// إعدادات الأذكار
  Map<String, dynamic> get athkarSettings {
    try {
      final jsonString = _remoteConfig.getString(_keyAthkarSettings);
      if (jsonString.isEmpty) {
        return {
          'auto_scroll_enabled': true,
          'vibration_feedback': true,
          'sound_effects': false,
          'reading_mode': 'normal',
        };
      }
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing athkar settings: $e');
      return {
        'auto_scroll_enabled': true,
        'vibration_feedback': true,
        'sound_effects': false,
        'reading_mode': 'normal',
      };
    }
  }

  // ==================== الحصول على معلومات مخصصة ====================

  /// الحصول على قيمة مخصصة
  String getCustomString(String key, {String defaultValue = ''}) {
    final value = _remoteConfig.getString(key);
    return value.isEmpty ? defaultValue : value;
  }

  /// الحصول على قيمة منطقية مخصصة
  bool getCustomBool(String key, {bool defaultValue = false}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      debugPrint('Error getting custom bool for key $key: $e');
      return defaultValue;
    }
  }

  /// الحصول على قيمة رقمية مخصصة
  int getCustomInt(String key, {int defaultValue = 0}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      debugPrint('Error getting custom int for key $key: $e');
      return defaultValue;
    }
  }

  /// الحصول على JSON مخصص
  Map<String, dynamic>? getCustomJson(String key) {
    try {
      final jsonString = _remoteConfig.getString(key);
      if (jsonString.isEmpty) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing custom JSON for key $key: $e');
      return null;
    }
  }

  // ==================== التشخيص والمعلومات ====================

  /// طباعة معلومات التشخيص
  void _printDebugInfo() {
    try {
      debugPrint('========== Remote Config Debug Info ==========');
      debugPrint('Is initialized: $_isInitialized');
      debugPrint('Last fetch status: ${_remoteConfig.lastFetchStatus}');
      debugPrint('Last fetch time: ${_remoteConfig.lastFetchTime}');
      
      // طباعة جميع القيم الحالية
      debugPrint('--- Current Values ---');
      debugPrint('Force Update (separate): ${_remoteConfig.getBool(_keyForceUpdate)}');
      debugPrint('App Version (separate): ${_remoteConfig.getString(_keyAppVersion)}');
      debugPrint('Maintenance Mode (separate): ${_remoteConfig.getBool(_keyMaintenanceMode)}');
      debugPrint('Test Config JSON: ${_remoteConfig.getString(_keyTestConfig)}');
      
      // طباعة القيم المستخلصة
      debugPrint('--- Parsed Values ---');
      debugPrint('Final Force Update: $isForceUpdateRequired');
      debugPrint('Final App Version: $requiredAppVersion');
      debugPrint('Final Maintenance Mode: $isMaintenanceModeEnabled');
      
      debugPrint('===============================================');
    } catch (e) {
      debugPrint('Error printing debug info: $e');
    }
  }

  /// حالة آخر جلب
  RemoteConfigFetchStatus get lastFetchStatus => _remoteConfig.lastFetchStatus;

  /// وقت آخر جلب ناجح
  DateTime get lastFetchTime => _remoteConfig.lastFetchTime;

  /// هل الخدمة مهيأة
  bool get isInitialized => _isInitialized;

  /// معلومات تشخيصية شاملة
  Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'last_fetch_status': lastFetchStatus.toString(),
    'last_fetch_time': lastFetchTime.toIso8601String(),
    
    // القيم الخام
    'raw_force_update_separate': _remoteConfig.getBool(_keyForceUpdate),
    'raw_app_version_separate': _remoteConfig.getString(_keyAppVersion),
    'raw_maintenance_mode_separate': _remoteConfig.getBool(_keyMaintenanceMode),
    'raw_test_config_json': _remoteConfig.getString(_keyTestConfig),
    
    // القيم المستخلصة
    'final_force_update': isForceUpdateRequired,
    'final_app_version': requiredAppVersion,
    'final_maintenance_mode': isMaintenanceModeEnabled,
    'test_config_parsed': testConfig,
    
    // معلومات إضافية
    'features_config': featuresConfig,
  };

  // ==================== إدارة دورة الحياة ====================

  /// اختبار فوري - للتطوير فقط
  Future<void> forceRefreshForTesting() async {
    if (!_isInitialized) return;
    
    try {
      debugPrint('🧪 FORCE REFRESH FOR TESTING...');
      
      // تقليل minimum fetch interval للاختبار
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: Duration.zero, // بدون حد أدنى للاختبار
      ));
      
      final result = await _remoteConfig.fetchAndActivate();
      debugPrint('🧪 Force refresh result: $result');
      
      _printDebugInfo();
      
    } catch (e) {
      debugPrint('🧪 Error in force refresh: $e');
    }
  }

  /// إعادة تهيئة الخدمة
  Future<void> reinitialize() async {
    _isInitialized = false;
    await initialize();
  }

  /// تنظيف الموارد
  void dispose() {
    _isInitialized = false;
    debugPrint('FirebaseRemoteConfigService disposed');
  }
}