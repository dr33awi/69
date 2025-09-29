// lib/core/infrastructure/firebase/remote_config_service.dart
// Android Only - iOS support removed

import 'dart:async';
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// خدمة Firebase Remote Config - Android Only
class FirebaseRemoteConfigService {
  static final FirebaseRemoteConfigService _instance = FirebaseRemoteConfigService._internal();
  factory FirebaseRemoteConfigService() => _instance;
  FirebaseRemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;
  
  // مفاتيح الإعدادات
  static const String _keyTestConfig = 'Test';
  
  // المعلمات المنفصلة
  static const String _keyAppVersion = 'app_version';
  static const String _keyForceUpdate = 'force_update';
  static const String _keyMaintenanceMode = 'maintenance_mode';
  static const String _keyUpdateUrlAndroid = 'update_url_android';
  
  // باقي المعلمات
  static const String _keyFeaturesConfig = 'features_config';
  static const String _keyNotificationConfig = 'notification_config';
  static const String _keyThemeConfig = 'theme_config';
  static const String _keyAthkarSettings = 'athkar_settings';

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      
      await _setDefaults();
      await _fetchAndActivate();
      
      _isInitialized = true;
      debugPrint('FirebaseRemoteConfigService initialized successfully (Android)');
      _printDebugInfo();
      
    } catch (e) {
      debugPrint('Error initializing Firebase Remote Config: $e');
      throw Exception('Failed to initialize Firebase Remote Config: $e');
    }
  }

  /// تعيين القيم الافتراضية
  Future<void> _setDefaults() async {
    await _remoteConfig.setDefaults({
      // JSON method
      _keyTestConfig: jsonEncode({
        'force_update': false,
        'app_version': '1.0.0',
        'maintenance_mode': false,
        'update_url_android': 'https://play.google.com/store/apps/details?id=com.example.test_athkar_app',
      }),
      
      // Separate parameters
      _keyAppVersion: '1.0.0',
      _keyForceUpdate: false,
      _keyMaintenanceMode: false,
      _keyUpdateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.example.test_athkar_app',
      
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

  // ==================== الحصول على القيم ====================

  /// الحصول على JSON الرئيسي
  Map<String, dynamic> get testConfig {
    try {
      final jsonString = _remoteConfig.getString(_keyTestConfig);
      debugPrint('Test config JSON string: $jsonString');
      
      if (jsonString.isEmpty) {
        return {
          'force_update': false,
          'app_version': '1.0.0',
          'maintenance_mode': false,
          'update_url_android': 'https://play.google.com/store/apps/details?id=com.example.test_athkar_app',
        };
      }
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing test config: $e');
      return {
        'force_update': false,
        'app_version': '1.0.0',
        'maintenance_mode': false,
        'update_url_android': 'https://play.google.com/store/apps/details?id=com.example.test_athkar_app',
      };
    }
  }

  /// إصدار التطبيق المطلوب
  String get requiredAppVersion {
    final separateVersion = _remoteConfig.getString(_keyAppVersion);
    if (separateVersion.isNotEmpty) {
      return separateVersion;
    }
    
    return testConfig['app_version'] as String? ?? '1.0.0';
  }

  /// هل يجب فرض التحديث
  bool get isForceUpdateRequired {
    try {
      final separateForceUpdate = _remoteConfig.getBool(_keyForceUpdate);
      
      if (separateForceUpdate) {
        debugPrint('🚨 FORCE UPDATE REQUIRED FROM SEPARATE PARAMETER!');
        debugPrint('Required version: $requiredAppVersion');
        debugPrint('Update URL: $updateUrl');
      }
      
      return separateForceUpdate;
    } catch (e) {
      debugPrint('Error getting force update from separate parameter: $e');
    }
    
    try {
      final testConfig = this.testConfig;
      final jsonForceUpdate = testConfig['force_update'] as bool? ?? false;
      
      if (jsonForceUpdate) {
        debugPrint('🚨 FORCE UPDATE REQUIRED FROM JSON!');
      }
      
      return jsonForceUpdate;
    } catch (e) {
      debugPrint('Error getting force update from JSON: $e');
    }
    
    return false;
  }

  /// هل التطبيق في وضع الصيانة
  bool get isMaintenanceModeEnabled {
    try {
      final separateMaintenance = _remoteConfig.getBool(_keyMaintenanceMode);
      
      if (separateMaintenance) {
        debugPrint('🔧 MAINTENANCE MODE ENABLED FROM SEPARATE PARAMETER!');
      }
      
      return separateMaintenance;
    } catch (e) {
      debugPrint('Error getting maintenance mode from separate parameter: $e');
    }
    
    try {
      final testConfig = this.testConfig;
      final jsonMaintenance = testConfig['maintenance_mode'] as bool? ?? false;
      
      if (jsonMaintenance) {
        debugPrint('🔧 MAINTENANCE MODE ENABLED FROM JSON!');
      }
      
      return jsonMaintenance;
    } catch (e) {
      debugPrint('Error getting maintenance mode from JSON: $e');
    }
    
    return false;
  }

  /// رابط التحديث - Android Only
  String get updateUrl {
    return updateUrlAndroid;
  }

  /// رابط التحديث Android
  String get updateUrlAndroid {
    // 1. جرب المعلمة المنفصلة
    final separateUrl = _remoteConfig.getString(_keyUpdateUrlAndroid);
    if (separateUrl.isNotEmpty) {
      debugPrint('Update URL Android (separate): $separateUrl');
      return separateUrl;
    }
    
    // 2. جرب JSON
    final testConfig = this.testConfig;
    final jsonUrl = testConfig['update_url_android'] as String?;
    if (jsonUrl != null && jsonUrl.isNotEmpty) {
      debugPrint('Update URL Android (JSON): $jsonUrl');
      return jsonUrl;
    }
    
    // 3. الافتراضي
    return 'https://play.google.com/store/apps/details?id=com.example.test_athkar_app';
  }

  // ==================== باقي الإعدادات ====================

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

  // ==================== Custom Values ====================

  String getCustomString(String key, {String defaultValue = ''}) {
    final value = _remoteConfig.getString(key);
    return value.isEmpty ? defaultValue : value;
  }

  bool getCustomBool(String key, {bool defaultValue = false}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      debugPrint('Error getting custom bool for key $key: $e');
      return defaultValue;
    }
  }

  int getCustomInt(String key, {int defaultValue = 0}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      debugPrint('Error getting custom int for key $key: $e');
      return defaultValue;
    }
  }

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

  // ==================== Debug ====================

  void _printDebugInfo() {
    try {
      debugPrint('========== Remote Config Debug Info (Android) ==========');
      debugPrint('Is initialized: $_isInitialized');
      debugPrint('Last fetch status: ${_remoteConfig.lastFetchStatus}');
      debugPrint('Last fetch time: ${_remoteConfig.lastFetchTime}');
      
      debugPrint('--- Current Values ---');
      debugPrint('Force Update (separate): ${_remoteConfig.getBool(_keyForceUpdate)}');
      debugPrint('App Version (separate): ${_remoteConfig.getString(_keyAppVersion)}');
      debugPrint('Maintenance Mode (separate): ${_remoteConfig.getBool(_keyMaintenanceMode)}');
      debugPrint('Update URL Android: ${_remoteConfig.getString(_keyUpdateUrlAndroid)}');
      
      debugPrint('--- Parsed Values ---');
      debugPrint('Final Force Update: $isForceUpdateRequired');
      debugPrint('Final App Version: $requiredAppVersion');
      debugPrint('Final Maintenance Mode: $isMaintenanceModeEnabled');
      debugPrint('Final Update URL: $updateUrl');
      
      debugPrint('=======================================================');
    } catch (e) {
      debugPrint('Error printing debug info: $e');
    }
  }

  RemoteConfigFetchStatus get lastFetchStatus => _remoteConfig.lastFetchStatus;
  DateTime get lastFetchTime => _remoteConfig.lastFetchTime;
  bool get isInitialized => _isInitialized;

  Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'platform': 'android',
    'last_fetch_status': lastFetchStatus.toString(),
    'last_fetch_time': lastFetchTime.toIso8601String(),
    
    'raw_force_update_separate': _remoteConfig.getBool(_keyForceUpdate),
    'raw_app_version_separate': _remoteConfig.getString(_keyAppVersion),
    'raw_maintenance_mode_separate': _remoteConfig.getBool(_keyMaintenanceMode),
    'raw_update_url_android': _remoteConfig.getString(_keyUpdateUrlAndroid),
    
    'final_force_update': isForceUpdateRequired,
    'final_app_version': requiredAppVersion,
    'final_maintenance_mode': isMaintenanceModeEnabled,
    'final_update_url': updateUrl,
    'test_config_parsed': testConfig,
    
    'features_config': featuresConfig,
  };

  // ==================== Testing ====================

  Future<void> forceRefreshForTesting() async {
    if (!_isInitialized) return;
    
    try {
      debugPrint('🧪 FORCE REFRESH FOR TESTING...');
      
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: Duration.zero,
      ));
      
      final result = await _remoteConfig.fetchAndActivate();
      debugPrint('🧪 Force refresh result: $result');
      
      _printDebugInfo();
      
    } catch (e) {
      debugPrint('🧪 Error in force refresh: $e');
    }
  }

  Future<void> reinitialize() async {
    _isInitialized = false;
    await initialize();
  }

  void dispose() {
    _isInitialized = false;
    debugPrint('FirebaseRemoteConfigService disposed (Android)');
  }
}