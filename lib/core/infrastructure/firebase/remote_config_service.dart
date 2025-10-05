// lib/core/infrastructure/firebase/remote_config_service.dart - النسخة الكاملة مع قائمة الميزات
import 'dart:async';
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// خدمة Firebase Remote Config - مبسطة مع دعم قائمة الميزات
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
  String? _cachedUpdateUrl;
  List<String>? _cachedFeaturesList;
  
  // مفاتيح الإعدادات
  static const String _keyAppVersion = 'app_version';
  static const String _keyForceUpdate = 'force_update';
  static const String _keyMaintenanceMode = 'maintenance_mode';
  static const String _keyUpdateUrlAndroid = 'update_url_android';
  static const String _keyUpdateFeaturesList = 'update_features_list';

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // إعدادات الجلب
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      
      // القيم الافتراضية
      await _setDefaults();
      
      // جلب وتفعيل
      await _fetchAndActivate();
      
      // تحديث Cache
      _updateCache();
      
      _isInitialized = true;
      debugPrint('✅ FirebaseRemoteConfigService initialized');
      _printDebugInfo();
      
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Remote Config: $e');
      _isInitialized = false;
      throw Exception('Failed to initialize Firebase Remote Config: $e');
    }
  }

  /// تحديث Cache
  void _updateCache() {
    try {
      _cachedForceUpdate = _remoteConfig.getBool(_keyForceUpdate);
      _cachedMaintenanceMode = _remoteConfig.getBool(_keyMaintenanceMode);
      _cachedAppVersion = _remoteConfig.getString(_keyAppVersion);
      _cachedUpdateUrl = _remoteConfig.getString(_keyUpdateUrlAndroid);
      
      // تحديث cache قائمة الميزات
      _cachedFeaturesList = _parseFeaturesList();
      
      debugPrint('✅ Cache updated:');
      debugPrint('  - Force Update: $_cachedForceUpdate');
      debugPrint('  - Maintenance: $_cachedMaintenanceMode');
      debugPrint('  - App Version: $_cachedAppVersion');
      debugPrint('  - Update URL: ${_cachedUpdateUrl?.substring(0, 30)}...');
      debugPrint('  - Features Count: ${_cachedFeaturesList?.length}');
    } catch (e) {
      debugPrint('⚠️ Error updating cache: $e');
    }
  }

  /// تحليل قائمة الميزات من JSON
  List<String> _parseFeaturesList() {
    try {
      final jsonString = _remoteConfig.getString(_keyUpdateFeaturesList);
      if (jsonString.isEmpty) {
        return _getDefaultFeaturesList();
      }
      
      // محاولة تحليل JSON
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      
      return _getDefaultFeaturesList();
    } catch (e) {
      debugPrint('⚠️ Error parsing update features list: $e');
      return _getDefaultFeaturesList();
    }
  }

  /// القائمة الافتراضية للميزات
  List<String> _getDefaultFeaturesList() {
    return [
      'تحسينات الأداء',
      'إصلاح الأخطاء', 
      'ميزات جديدة'
    ];
  }

  /// تعيين القيم الافتراضية
  Future<void> _setDefaults() async {
    await _remoteConfig.setDefaults({
      _keyAppVersion: '1.0.0',
      _keyForceUpdate: false,
      _keyMaintenanceMode: false,
      _keyUpdateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.example.test_athkar_app',
      _keyUpdateFeaturesList: jsonEncode([
        'تحسينات الأداء',
        'إصلاح الأخطاء',
        'ميزات جديدة'
      ]),
    });
  }

  /// جلب وتفعيل الإعدادات
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

  /// تحديث الإعدادات يدوياً
  Future<bool> refresh() async {
    if (!_isInitialized) return false;
    
    try {
      final result = await _fetchAndActivate();
      if (result) {
        _updateCache();
        _printDebugInfo();
      }
      return result;
    } catch (e) {
      debugPrint('❌ Error refreshing config: $e');
      return false;
    }
  }

  // ==================== Getters الأساسية ====================

  /// إصدار التطبيق المطلوب
  String get requiredAppVersion {
    if (_cachedAppVersion != null && _cachedAppVersion!.isNotEmpty) {
      return _cachedAppVersion!;
    }
    
    try {
      final version = _remoteConfig.getString(_keyAppVersion);
      return version.isNotEmpty ? version : '1.0.0';
    } catch (e) {
      return '1.0.0';
    }
  }

  /// هل يجب فرض التحديث؟
  bool get isForceUpdateRequired {
    if (_cachedForceUpdate != null) {
      if (_cachedForceUpdate!) {
        debugPrint('🚨 FORCE UPDATE REQUIRED!');
        debugPrint('Required version: $requiredAppVersion');
      }
      return _cachedForceUpdate!;
    }
    
    try {
      return _remoteConfig.getBool(_keyForceUpdate);
    } catch (e) {
      debugPrint('⚠️ Error reading force update: $e');
      return false;
    }
  }

  /// هل التطبيق في وضع الصيانة؟
  bool get isMaintenanceModeEnabled {
    if (_cachedMaintenanceMode != null) {
      if (_cachedMaintenanceMode!) {
        debugPrint('🔧 MAINTENANCE MODE ENABLED!');
      }
      return _cachedMaintenanceMode!;
    }
    
    try {
      return _remoteConfig.getBool(_keyMaintenanceMode);
    } catch (e) {
      debugPrint('⚠️ Error reading maintenance mode: $e');
      return false;
    }
  }

  /// رابط التحديث
  String get updateUrl {
    if (_cachedUpdateUrl != null && _cachedUpdateUrl!.isNotEmpty) {
      return _cachedUpdateUrl!;
    }
    
    try {
      final url = _remoteConfig.getString(_keyUpdateUrlAndroid);
      return url.isNotEmpty ? url : 'https://play.google.com/store/apps/details?id=com.example.athkar_app';
    } catch (e) {
      return 'https://play.google.com/store/apps/details?id=com.example.athkar_app';
    }
  }

  /// قائمة ميزات التحديث
  List<String> get updateFeaturesList {
    if (_cachedFeaturesList != null && _cachedFeaturesList!.isNotEmpty) {
      return _cachedFeaturesList!;
    }
    
    return _parseFeaturesList();
  }

  // Alias للتوافق
  String get updateUrlAndroid => updateUrl;

  // ==================== معلومات الحالة ====================

  RemoteConfigFetchStatus get lastFetchStatus => _remoteConfig.lastFetchStatus;
  DateTime get lastFetchTime => _remoteConfig.lastFetchTime;
  bool get isInitialized => _isInitialized;

  /// معلومات التصحيح
  Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'last_fetch_status': lastFetchStatus.toString(),
    'last_fetch_time': lastFetchTime.toIso8601String(),
    'cached_values': {
      'force_update': _cachedForceUpdate,
      'maintenance_mode': _cachedMaintenanceMode,
      'app_version': _cachedAppVersion,
      'features_count': _cachedFeaturesList?.length,
    },
  };

  /// طباعة معلومات التصحيح
  void _printDebugInfo() {
    try {
      debugPrint('========== Remote Config Info ==========');
      debugPrint('Is initialized: $_isInitialized');
      debugPrint('Last fetch status: ${_remoteConfig.lastFetchStatus}');
      debugPrint('Last fetch time: ${_remoteConfig.lastFetchTime}');
      debugPrint('--- Current Values ---');
      debugPrint('Force Update: $_cachedForceUpdate');
      debugPrint('Maintenance Mode: $_cachedMaintenanceMode');
      debugPrint('App Version: $_cachedAppVersion');
      debugPrint('Features List: $_cachedFeaturesList');
      debugPrint('========================================');
    } catch (e) {
      debugPrint('⚠️ Error printing debug info: $e');
    }
  }

  // ==================== للاختبار فقط ====================

  /// فرض التحديث للاختبار
  Future<void> forceRefreshForTesting() async {
    if (!_isInitialized) return;
    
    try {
      debugPrint('🧪 FORCE REFRESH FOR TESTING...');
      
      // إزالة قيود الوقت للاختبار
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: Duration.zero,
      ));
      
      final result = await _remoteConfig.fetchAndActivate();
      _updateCache();
      
      debugPrint('🧪 Force refresh result: $result');
      _printDebugInfo();
      
      // إعادة الإعدادات الطبيعية
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      
    } catch (e) {
      debugPrint('🧪 Error in force refresh: $e');
    }
  }

  /// إعادة التهيئة
  Future<void> reinitialize() async {
    _isInitialized = false;
    _cachedForceUpdate = null;
    _cachedMaintenanceMode = null;
    _cachedAppVersion = null;
    _cachedUpdateUrl = null;
    _cachedFeaturesList = null;
    await initialize();
  }

  /// تنظيف الموارد
  void dispose() {
    _isInitialized = false;
    _cachedForceUpdate = null;
    _cachedMaintenanceMode = null;
    _cachedAppVersion = null;
    _cachedUpdateUrl = null;
    _cachedFeaturesList = null;
    debugPrint('FirebaseRemoteConfigService disposed');
  }
}