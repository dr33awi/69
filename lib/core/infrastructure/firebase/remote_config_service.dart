// lib/core/infrastructure/firebase/remote_config_service.dart - محدث ومبسط
import 'dart:async';
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class FirebaseRemoteConfigService {
  static final FirebaseRemoteConfigService _instance = FirebaseRemoteConfigService._internal();
  factory FirebaseRemoteConfigService() => _instance;
  FirebaseRemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;
  
  // Cache للقيم المهمة
  bool? _cachedForceUpdate;
  bool? _cachedMaintenanceMode;
  String? _cachedAppVersion;
  
  // مفاتيح الإعدادات الأساسية فقط
  static const String _keyAppVersion = 'app_version';
  static const String _keyForceUpdate = 'force_update';
  static const String _keyMaintenanceMode = 'maintenance_mode';
  static const String _keyUpdateUrlAndroid = 'update_url_android';
  static const String _keyFeaturesConfig = 'features_config';

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
      
      // ✅ تحديث Cache بعد التهيئة
      _updateCache();
      
      _isInitialized = true;
      debugPrint('✅ FirebaseRemoteConfigService initialized');
      _printDebugInfo();
      
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Remote Config: $e');
      throw Exception('Failed to initialize Firebase Remote Config: $e');
    }
  }

  /// ✅ تحديث Cache
  void _updateCache() {
    try {
      // قراءة مرة واحدة فقط
      _cachedForceUpdate = _remoteConfig.getBool(_keyForceUpdate);
      _cachedMaintenanceMode = _remoteConfig.getBool(_keyMaintenanceMode);
      _cachedAppVersion = _remoteConfig.getString(_keyAppVersion);
      
      debugPrint('✅ Cache updated:');
      debugPrint('  - Force Update: $_cachedForceUpdate');
      debugPrint('  - Maintenance: $_cachedMaintenanceMode');
      debugPrint('  - App Version: $_cachedAppVersion');
    } catch (e) {
      debugPrint('⚠️ Error updating cache: $e');
    }
  }

  Future<void> _setDefaults() async {
    await _remoteConfig.setDefaults({
      _keyAppVersion: '1.0.0',
      _keyForceUpdate: false,
      _keyMaintenanceMode: false,
      _keyUpdateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.example.test_athkar_app',
      _keyFeaturesConfig: jsonEncode({
        'prayer_times_enabled': true,
        'qibla_enabled': true,
        'athkar_enabled': true,
        'tasbih_enabled': true,
        'dua_enabled': true,
        'notifications_enabled': true,
      }),
    });
  }

  Future<bool> _fetchAndActivate() async {
    try {
      final fetchResult = await _remoteConfig.fetchAndActivate();
      debugPrint('Remote config fetch result: $fetchResult');
      return fetchResult;
    } catch (e) {
      debugPrint('❌ Error fetching remote config: $e');
      return false;
    }
  }

  /// جلب الإعدادات يدوياً
  Future<bool> refresh() async {
    if (!_isInitialized) return false;
    
    final result = await _fetchAndActivate();
    if (result) {
      _updateCache(); // ✅ تحديث Cache بعد Refresh
      _printDebugInfo();
    }
    return result;
  }

  // ==================== ✅ Getters المحسّنة ====================

  /// إصدار التطبيق المطلوب (من Cache)
  String get requiredAppVersion {
    if (_cachedAppVersion != null && _cachedAppVersion!.isNotEmpty) {
      return _cachedAppVersion!;
    }
    
    // Fallback إلى القراءة المباشرة
    final version = _remoteConfig.getString(_keyAppVersion);
    return version.isNotEmpty ? version : '1.0.0';
  }

  /// هل يجب فرض التحديث (من Cache)
  bool get isForceUpdateRequired {
    if (_cachedForceUpdate != null) {
      if (_cachedForceUpdate!) {
        debugPrint('🚨 FORCE UPDATE REQUIRED (from cache)!');
        debugPrint('Required version: $requiredAppVersion');
      }
      return _cachedForceUpdate!;
    }
    
    // Fallback
    try {
      return _remoteConfig.getBool(_keyForceUpdate);
    } catch (e) {
      debugPrint('⚠️ Error reading force update: $e');
      return false;
    }
  }

  /// هل التطبيق في وضع الصيانة (من Cache)
  bool get isMaintenanceModeEnabled {
    if (_cachedMaintenanceMode != null) {
      if (_cachedMaintenanceMode!) {
        debugPrint('🔧 MAINTENANCE MODE ENABLED (from cache)!');
      }
      return _cachedMaintenanceMode!;
    }
    
    // Fallback
    try {
      return _remoteConfig.getBool(_keyMaintenanceMode);
    } catch (e) {
      debugPrint('⚠️ Error reading maintenance mode: $e');
      return false;
    }
  }

  /// رابط التحديث Android
  String get updateUrlAndroid {
    final url = _remoteConfig.getString(_keyUpdateUrlAndroid);
    if (url.isNotEmpty) return url;
    
    return 'https://play.google.com/store/apps/details?id=com.example.test_athkar_app';
  }

  String get updateUrl => updateUrlAndroid;

  // ==================== Features Config Only ====================

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
      debugPrint('⚠️ Error parsing features config: $e');
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

  // ==================== Custom Values ====================

  String getCustomString(String key, {String defaultValue = ''}) {
    final value = _remoteConfig.getString(key);
    return value.isEmpty ? defaultValue : value;
  }

  bool getCustomBool(String key, {bool defaultValue = false}) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      debugPrint('⚠️ Error getting custom bool for key $key: $e');
      return defaultValue;
    }
  }

  int getCustomInt(String key, {int defaultValue = 0}) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      debugPrint('⚠️ Error getting custom int for key $key: $e');
      return defaultValue;
    }
  }

  Map<String, dynamic>? getCustomJson(String key) {
    try {
      final jsonString = _remoteConfig.getString(key);
      if (jsonString.isEmpty) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ Error parsing custom JSON for key $key: $e');
      return null;
    }
  }

  // ==================== Debug ====================

  void _printDebugInfo() {
    try {
      debugPrint('========== Remote Config Debug Info ==========');
      debugPrint('Is initialized: $_isInitialized');
      debugPrint('Last fetch status: ${_remoteConfig.lastFetchStatus}');
      debugPrint('Last fetch time: ${_remoteConfig.lastFetchTime}');
      debugPrint('--- Cached Values ---');
      debugPrint('Force Update: $_cachedForceUpdate');
      debugPrint('Maintenance Mode: $_cachedMaintenanceMode');
      debugPrint('App Version: $_cachedAppVersion');
      debugPrint('Features Config: ${featuresConfig.toString()}');
      debugPrint('==============================================');
    } catch (e) {
      debugPrint('⚠️ Error printing debug info: $e');
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
    'cached_force_update': _cachedForceUpdate,
    'cached_maintenance': _cachedMaintenanceMode,
    'cached_app_version': _cachedAppVersion,
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
      _updateCache(); // ✅ تحديث Cache
      
      debugPrint('🧪 Force refresh result: $result');
      _printDebugInfo();
      
    } catch (e) {
      debugPrint('🧪 Error in force refresh: $e');
    }
  }

  Future<void> reinitialize() async {
    _isInitialized = false;
    _cachedForceUpdate = null;
    _cachedMaintenanceMode = null;
    _cachedAppVersion = null;
    await initialize();
  }

  void dispose() {
    _isInitialized = false;
    _cachedForceUpdate = null;
    _cachedMaintenanceMode = null;
    _cachedAppVersion = null;
    debugPrint('FirebaseRemoteConfigService disposed');
  }
}