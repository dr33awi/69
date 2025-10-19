// lib/core/firebase/remote_config_service.dart
// ✅ نسخة محسّنة مع إصلاح مشكلة Fetch

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
  DateTime? _lastFetchTime;
  
  Map<String, dynamic> _cachedValues = {};
  
  static const String _keyAppVersion = 'app_version';
  static const String _keyForceUpdate = 'force_update';
  static const String _keyMaintenanceMode = 'maintenance_mode';
  static const String _keyUpdateUrlAndroid = 'update_url_android';
  static const String _keyUpdateFeaturesList = 'update_features_list';
  static const String _keySpecialEvent = 'special_event_data';
  static const String _keyPromotionalBanners = 'promotional_banners';

  /// ✅ تهيئة محسّنة مع Fetch أفضل
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ FirebaseRemoteConfigService already initialized');
      return;
    }
    
    try {
      debugPrint('🔄 Initializing FirebaseRemoteConfigService...');
      final stopwatch = Stopwatch()..start();
      
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // ✅ إعدادات محسّنة
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode 
          ? Duration.zero  // في التطوير: جلب فوري
          : const Duration(hours: 1), // في الإنتاج: كل ساعة
      ));
      
      // تعيين القيم الافتراضية
      await _setDefaults();
      
      // ✅ جلب وتفعيل
      bool fetchSuccess = false;
      
      try {
        // المحاولة الأولى
        debugPrint('🔄 Fetching from Firebase (attempt 1)...');
        fetchSuccess = await _remoteConfig.fetchAndActivate();
        
        if (fetchSuccess) {
          debugPrint('✅ Fresh data fetched successfully');
        } else {
          debugPrint('ℹ️ No new data, using cached values');
        }
      } catch (e) {
        debugPrint('⚠️ Fetch failed, trying activate cached: $e');
        
        // محاولة تفعيل القيم المخزنة
        try {
          await _remoteConfig.activate();
          debugPrint('✅ Activated cached values');
        } catch (activateError) {
          debugPrint('⚠️ Activate failed: $activateError');
        }
      }
      
      // ✅ تحديث Cache بعد التفعيل
      await Future.delayed(const Duration(milliseconds: 200));
      _updateAllCache();
      
      _isInitialized = true;
      _lastFetchTime = DateTime.now();
      
      stopwatch.stop();
      debugPrint('✅ FirebaseRemoteConfigService initialized in ${stopwatch.elapsedMilliseconds}ms');
      _printDebugInfo();
      
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Remote Config: $e');
      _isInitialized = false;
      _loadDefaultValues();
    }
  }

  /// ✅ تحديث محسّن
  Future<bool> refresh() async {
    if (!_isInitialized) {
      await initialize();
      return _isInitialized;
    }
    
    try {
      debugPrint('🔄 Refreshing remote config...');
      
      // ✅ السماح بـ Fetch حتى لو كان قريب
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero, // السماح بالتحديث الفوري
      ));
      
      bool result = false;
      
      try {
        debugPrint('🔄 Fetching remote config (attempt 1)...');
        result = await _remoteConfig.fetchAndActivate();
        
        if (result) {
          debugPrint('✅ Fetched fresh data successfully');
        } else {
          debugPrint('ℹ️ No new data available');
        }
      } catch (e) {
        debugPrint('⚠️ Fetch error, trying activate: $e');
        
        try {
          await _remoteConfig.activate();
          debugPrint('✅ Activated cached values');
          result = false; // لم نحصل على بيانات جديدة
        } catch (activateError) {
          debugPrint('⚠️ Activate failed: $activateError');
          return false;
        }
      }
      
      // ✅ تحديث Cache
      await Future.delayed(const Duration(milliseconds: 200));
      _updateAllCache();
      _lastFetchTime = DateTime.now();
      
      // ✅ إعادة الإعدادات الطبيعية
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode 
          ? Duration.zero 
          : const Duration(hours: 1),
      ));
      
      _printDebugInfo();
      return true; // نجحت العملية حتى لو لم تكن هناك بيانات جديدة
      
    } catch (e) {
      debugPrint('❌ Error refreshing config: $e');
      return false;
    }
  }

  void _updateAllCache() {
    try {
      _cachedValues = {
        _keyForceUpdate: _remoteConfig.getBool(_keyForceUpdate),
        _keyMaintenanceMode: _remoteConfig.getBool(_keyMaintenanceMode),
        _keyAppVersion: _remoteConfig.getString(_keyAppVersion),
        _keyUpdateUrlAndroid: _remoteConfig.getString(_keyUpdateUrlAndroid),
        _keyUpdateFeaturesList: _parseFeaturesList(),
        _keySpecialEvent: _parseSpecialEvent(),
        _keyPromotionalBanners: _parsePromotionalBanners(),
      };
      
      debugPrint('✅ Cache updated with ${_cachedValues.length} values');
    } catch (e) {
      debugPrint('⚠️ Error updating cache: $e');
    }
  }

  void _loadDefaultValues() {
    _cachedValues = {
      _keyForceUpdate: false,
      _keyMaintenanceMode: false,
      _keyAppVersion: '1.0.0',
      _keyUpdateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.example.athkar_app',
      _keyUpdateFeaturesList: ['تحسينات الأداء', 'إصلاح الأخطاء', 'ميزات جديدة'],
      _keySpecialEvent: null,
      _keyPromotionalBanners: [],
    };
    
    debugPrint('⚠️ Using default values');
  }

  Future<void> _setDefaults() async {
    await _remoteConfig.setDefaults({
      _keyAppVersion: '1.0.0',
      _keyForceUpdate: false,
      _keyMaintenanceMode: false,
      _keyUpdateUrlAndroid: 'https://play.google.com/store/apps/details?id=com.example.athkar_app',
      _keyUpdateFeaturesList: jsonEncode([
        'تحسينات الأداء',
        'إصلاح الأخطاء',
        'ميزات جديدة'
      ]),
      _keySpecialEvent: jsonEncode({
        'is_active': false,
        'title': '',
        'description': '',
        'icon': '🌙',
        'gradient_colors': ['#9C27B0', '#673AB7'],
      }),
      _keyPromotionalBanners: jsonEncode([]),
    });
  }

  // ==================== Getters ====================

  String get requiredAppVersion {
    if (_cachedValues.containsKey(_keyAppVersion)) {
      return _cachedValues[_keyAppVersion] ?? '1.0.0';
    }
    
    try {
      final version = _remoteConfig.getString(_keyAppVersion);
      _cachedValues[_keyAppVersion] = version;
      return version.isNotEmpty ? version : '1.0.0';
    } catch (e) {
      return '1.0.0';
    }
  }

  bool get isForceUpdateRequired {
    if (_cachedValues.containsKey(_keyForceUpdate)) {
      return _cachedValues[_keyForceUpdate] ?? false;
    }
    
    try {
      final value = _remoteConfig.getBool(_keyForceUpdate);
      _cachedValues[_keyForceUpdate] = value;
      return value;
    } catch (e) {
      return false;
    }
  }

  bool get isMaintenanceModeEnabled {
    if (_cachedValues.containsKey(_keyMaintenanceMode)) {
      return _cachedValues[_keyMaintenanceMode] ?? false;
    }
    
    try {
      final value = _remoteConfig.getBool(_keyMaintenanceMode);
      _cachedValues[_keyMaintenanceMode] = value;
      return value;
    } catch (e) {
      return false;
    }
  }

  String get updateUrl {
    if (_cachedValues.containsKey(_keyUpdateUrlAndroid)) {
      return _cachedValues[_keyUpdateUrlAndroid] ?? 'https://play.google.com/store/apps/details?id=com.example.athkar_app';
    }
    
    try {
      final url = _remoteConfig.getString(_keyUpdateUrlAndroid);
      _cachedValues[_keyUpdateUrlAndroid] = url;
      return url.isNotEmpty ? url : 'https://play.google.com/store/apps/details?id=com.example.athkar_app';
    } catch (e) {
      return 'https://play.google.com/store/apps/details?id=com.example.athkar_app';
    }
  }

  List<String> get updateFeaturesList {
    if (_cachedValues.containsKey(_keyUpdateFeaturesList)) {
      return _cachedValues[_keyUpdateFeaturesList] ?? _getDefaultFeaturesList();
    }
    
    final features = _parseFeaturesList();
    _cachedValues[_keyUpdateFeaturesList] = features;
    return features;
  }

  Map<String, dynamic>? get specialEventData {
    if (_cachedValues.containsKey(_keySpecialEvent)) {
      return _cachedValues[_keySpecialEvent];
    }
    
    final event = _parseSpecialEvent();
    _cachedValues[_keySpecialEvent] = event;
    return event;
  }

  List<dynamic> get promotionalBanners {
    if (_cachedValues.containsKey(_keyPromotionalBanners)) {
      return _cachedValues[_keyPromotionalBanners] ?? [];
    }
    
    final banners = _parsePromotionalBanners();
    _cachedValues[_keyPromotionalBanners] = banners;
    return banners;
  }

  // ==================== Parsing ====================

  List<String> _parseFeaturesList() {
    try {
      final jsonString = _remoteConfig.getString(_keyUpdateFeaturesList);
      if (jsonString.isEmpty) return _getDefaultFeaturesList();
      
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing features list: $e');
    }
    return _getDefaultFeaturesList();
  }

  Map<String, dynamic>? _parseSpecialEvent() {
    try {
      final jsonString = _remoteConfig.getString(_keySpecialEvent);
      if (jsonString.isEmpty) return null;
      
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        if (decoded['start_date'] != null && decoded['end_date'] != null) {
          try {
            final startDate = DateTime.parse(decoded['start_date']);
            final endDate = DateTime.parse(decoded['end_date']);
            final now = DateTime.now();
            
            decoded['is_active'] = decoded['is_active'] == true && 
                                  now.isAfter(startDate) && 
                                  now.isBefore(endDate);
          } catch (_) {}
        }
        return decoded;
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing special event: $e');
    }
    return null;
  }

  List<dynamic> _parsePromotionalBanners() {
    try {
      final jsonString = _remoteConfig.getString(_keyPromotionalBanners);
      
      if (jsonString.isEmpty) {
        debugPrint('⚠️ promotional_banners is empty in Remote Config');
        return [];
      }
      
      debugPrint('📄 Raw promotional_banners JSON: ${jsonString.substring(0, jsonString.length > 100 ? 100 : jsonString.length)}...');
      
      final dynamic decoded = jsonDecode(jsonString);
      
      if (decoded is List) {
        debugPrint('✅ Found ${decoded.length} promotional banners in config');
        return decoded;
      } else {
        debugPrint('⚠️ promotional_banners is not a list: ${decoded.runtimeType}');
      }
    } catch (e) {
      debugPrint('❌ Error parsing promotional banners: $e');
    }
    return [];
  }

  List<String> _getDefaultFeaturesList() {
    return ['تحسينات الأداء', 'إصلاح الأخطاء', 'ميزات جديدة'];
  }

  // ==================== Status ====================

  RemoteConfigFetchStatus get lastFetchStatus => _remoteConfig.lastFetchStatus;
  DateTime get lastFetchTime => _lastFetchTime ?? _remoteConfig.lastFetchTime;
  bool get isInitialized => _isInitialized;

  Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'last_fetch_status': lastFetchStatus.toString(),
    'last_fetch_time': lastFetchTime.toIso8601String(),
    'time_since_last_fetch': _lastFetchTime != null 
      ? '${DateTime.now().difference(_lastFetchTime!).inSeconds}s ago'
      : 'never',
    'cached_values': {
      'force_update': isForceUpdateRequired,
      'maintenance_mode': isMaintenanceModeEnabled,
      'app_version': requiredAppVersion,
      'features_count': updateFeaturesList.length,
      'special_event_active': specialEventData?['is_active'] ?? false,
      'promotional_banners_count': promotionalBanners.length,
    },
  };

  void _printDebugInfo() {
    try {
      debugPrint('========== Remote Config Info ==========');
      debugPrint('Is initialized: $_isInitialized');
      debugPrint('Last fetch status: ${_remoteConfig.lastFetchStatus}');
      debugPrint('Last fetch time: ${lastFetchTime}');
      debugPrint('--- Current Values ---');
      debugPrint('Force Update: ${isForceUpdateRequired}');
      debugPrint('Maintenance Mode: ${isMaintenanceModeEnabled}');
      debugPrint('App Version: ${requiredAppVersion}');
      debugPrint('Features List: ${updateFeaturesList}');
      debugPrint('Promotional Banners: ${promotionalBanners.length}');
      
      if (promotionalBanners.isNotEmpty) {
        debugPrint('--- Banner Details ---');
        for (var i = 0; i < promotionalBanners.length; i++) {
          final banner = promotionalBanners[i];
          if (banner is Map) {
            debugPrint('  Banner ${i + 1}:');
            debugPrint('    - ID: ${banner['id']}');
            debugPrint('    - Title: ${banner['title']}');
            debugPrint('    - Active: ${banner['is_active']}');
          }
        }
      } else {
        debugPrint('⚠️ No promotional banners found!');
        debugPrint('💡 Add banners to Firebase Console:');
        debugPrint('   Remote Config > promotional_banners (JSON)');
      }
      
      if (specialEventData != null) {
        debugPrint('Special Event:');
        debugPrint('  - Active: ${specialEventData!['is_active']}');
        debugPrint('  - Title: ${specialEventData!['title']}');
      }
      debugPrint('========================================');
    } catch (e) {
      debugPrint('⚠️ Error printing debug info: $e');
    }
  }

  /// ✅ فرض التحديث للاختبار
  Future<void> forceRefreshForTesting() async {
    if (!_isInitialized) {
      await initialize();
      return;
    }
    
    try {
      debugPrint('🧪 FORCE REFRESH FOR TESTING...');
      
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: Duration.zero,
      ));
      
      final result = await _remoteConfig.fetchAndActivate();
      await Future.delayed(const Duration(milliseconds: 200));
      _updateAllCache();
      _lastFetchTime = DateTime.now();
      
      debugPrint('🧪 Force refresh result: $result');
      _printDebugInfo();
      
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));
      
    } catch (e) {
      debugPrint('🧪 Error in force refresh: $e');
    }
  }

  Future<void> reinitialize() async {
    debugPrint('🔄 Reinitializing FirebaseRemoteConfigService...');
    _isInitialized = false;
    _cachedValues.clear();
    _lastFetchTime = null;
    await initialize();
  }

  void dispose() {
    _isInitialized = false;
    _cachedValues.clear();
    _lastFetchTime = null;
    debugPrint('🧹 FirebaseRemoteConfigService disposed');
  }
}