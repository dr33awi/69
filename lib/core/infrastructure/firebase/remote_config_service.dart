// lib/core/infrastructure/firebase/remote_config_service.dart
// ✅ محدث مع دعم Promotional Banners

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
  
  // Cache
  bool? _cachedForceUpdate;
  bool? _cachedMaintenanceMode;
  String? _cachedAppVersion;
  String? _cachedUpdateUrl;
  List<String>? _cachedFeaturesList;
  Map<String, dynamic>? _cachedSpecialEvent;
  List<dynamic>? _cachedPromotionalBanners; // ✅ جديد
  
  // مفاتيح الإعدادات
  static const String _keyAppVersion = 'app_version';
  static const String _keyForceUpdate = 'force_update';
  static const String _keyMaintenanceMode = 'maintenance_mode';
  static const String _keyUpdateUrlAndroid = 'update_url_android';
  static const String _keyUpdateFeaturesList = 'update_features_list';
  static const String _keySpecialEvent = 'special_event_data';
  static const String _keyPromotionalBanners = 'promotional_banners'; // ✅ جديد

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
      _cachedFeaturesList = _parseFeaturesList();
      _cachedSpecialEvent = _parseSpecialEvent();
      _cachedPromotionalBanners = _parsePromotionalBanners(); // ✅ جديد
      
      debugPrint('✅ Cache updated:');
      debugPrint('  - Promotional Banners: ${_cachedPromotionalBanners?.length ?? 0}');
    } catch (e) {
      debugPrint('⚠️ Error updating cache: $e');
    }
  }

  /// ✅ تحليل البانرات الترويجية
  List<dynamic> _parsePromotionalBanners() {
    try {
      final jsonString = _remoteConfig.getString(_keyPromotionalBanners);
      if (jsonString.isEmpty) {
        return [];
      }
      
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        debugPrint('✅ Found ${decoded.length} promotional banners');
        return decoded;
      }
      
      return [];
    } catch (e) {
      debugPrint('⚠️ Error parsing promotional banners: $e');
      return [];
    }
  }

  /// تحليل قائمة الميزات
  List<String> _parseFeaturesList() {
    try {
      final jsonString = _remoteConfig.getString(_keyUpdateFeaturesList);
      if (jsonString.isEmpty) {
        return _getDefaultFeaturesList();
      }
      
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

  /// تحليل بيانات المناسبة الخاصة
  Map<String, dynamic>? _parseSpecialEvent() {
    try {
      final jsonString = _remoteConfig.getString(_keySpecialEvent);
      if (jsonString.isEmpty) {
        return null;
      }
      
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
          } catch (e) {
            debugPrint('⚠️ Error parsing event dates: $e');
          }
        }
        
        return decoded;
      }
      
      return null;
    } catch (e) {
      debugPrint('⚠️ Error parsing special event data: $e');
      return null;
    }
  }

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
        'action_text': '',
        'action_url': '',
        'start_date': null,
        'end_date': null,
        'background_image': '',
      }),
      // ✅ قيم افتراضية للبانرات
      _keyPromotionalBanners: jsonEncode([]),
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

  // ==================== Getters ====================

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

  bool get isForceUpdateRequired {
    if (_cachedForceUpdate != null) {
      return _cachedForceUpdate!;
    }
    
    try {
      return _remoteConfig.getBool(_keyForceUpdate);
    } catch (e) {
      return false;
    }
  }

  bool get isMaintenanceModeEnabled {
    if (_cachedMaintenanceMode != null) {
      return _cachedMaintenanceMode!;
    }
    
    try {
      return _remoteConfig.getBool(_keyMaintenanceMode);
    } catch (e) {
      return false;
    }
  }

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

  List<String> get updateFeaturesList {
    if (_cachedFeaturesList != null && _cachedFeaturesList!.isNotEmpty) {
      return _cachedFeaturesList!;
    }
    
    return _parseFeaturesList();
  }

  Map<String, dynamic>? get specialEventData {
    if (_cachedSpecialEvent != null) {
      return _cachedSpecialEvent;
    }
    
    return _parseSpecialEvent();
  }

  /// ✅ Getter للبانرات الترويجية
  List<dynamic> get promotionalBanners {
    if (_cachedPromotionalBanners != null) {
      return _cachedPromotionalBanners!;
    }
    
    return _parsePromotionalBanners();
  }

  String get updateUrlAndroid => updateUrl;

  RemoteConfigFetchStatus get lastFetchStatus => _remoteConfig.lastFetchStatus;
  DateTime get lastFetchTime => _remoteConfig.lastFetchTime;
  bool get isInitialized => _isInitialized;

  Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'last_fetch_status': lastFetchStatus.toString(),
    'last_fetch_time': lastFetchTime.toIso8601String(),
    'cached_values': {
      'force_update': _cachedForceUpdate,
      'maintenance_mode': _cachedMaintenanceMode,
      'app_version': _cachedAppVersion,
      'features_count': _cachedFeaturesList?.length,
      'special_event_active': _cachedSpecialEvent?['is_active'] ?? false,
      'promotional_banners_count': _cachedPromotionalBanners?.length ?? 0, // ✅ جديد
    },
  };

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
      debugPrint('Promotional Banners: ${_cachedPromotionalBanners?.length ?? 0}'); // ✅ جديد
      if (_cachedSpecialEvent != null) {
        debugPrint('Special Event:');
        debugPrint('  - Active: ${_cachedSpecialEvent!['is_active']}');
        debugPrint('  - Title: ${_cachedSpecialEvent!['title']}');
      }
      debugPrint('========================================');
    } catch (e) {
      debugPrint('⚠️ Error printing debug info: $e');
    }
  }

  Future<void> forceRefreshForTesting() async {
    if (!_isInitialized) return;
    
    try {
      debugPrint('🧪 FORCE REFRESH FOR TESTING...');
      
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: Duration.zero,
      ));
      
      final result = await _remoteConfig.fetchAndActivate();
      _updateCache();
      
      debugPrint('🧪 Force refresh result: $result');
      _printDebugInfo();
      
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      
    } catch (e) {
      debugPrint('🧪 Error in force refresh: $e');
    }
  }

  Future<void> reinitialize() async {
    _isInitialized = false;
    _cachedForceUpdate = null;
    _cachedMaintenanceMode = null;
    _cachedAppVersion = null;
    _cachedUpdateUrl = null;
    _cachedFeaturesList = null;
    _cachedSpecialEvent = null;
    _cachedPromotionalBanners = null;
    await initialize();
  }

  void dispose() {
    _isInitialized = false;
    _cachedForceUpdate = null;
    _cachedMaintenanceMode = null;
    _cachedAppVersion = null;
    _cachedUpdateUrl = null;
    _cachedFeaturesList = null;
    _cachedSpecialEvent = null;
    _cachedPromotionalBanners = null;
    debugPrint('FirebaseRemoteConfigService disposed');
  }
}