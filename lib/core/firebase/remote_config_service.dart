// lib/core/infrastructure/firebase/remote_config_service.dart
// ✅ نسخة محسّنة لجلب البيانات بشكل أسرع

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
  
  // Cache محسّن
  Map<String, dynamic> _cachedValues = {};
  
  // مفاتيح الإعدادات
  static const String _keyAppVersion = 'app_version';
  static const String _keyForceUpdate = 'force_update';
  static const String _keyMaintenanceMode = 'maintenance_mode';
  static const String _keyUpdateUrlAndroid = 'update_url_android';
  static const String _keyUpdateFeaturesList = 'update_features_list';
  static const String _keySpecialEvent = 'special_event_data';
  static const String _keyPromotionalBanners = 'promotional_banners';

  /// تهيئة الخدمة - محسّنة للسرعة
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ FirebaseRemoteConfigService already initialized');
      return;
    }
    
    try {
      debugPrint('🔄 Initializing FirebaseRemoteConfigService...');
      final stopwatch = Stopwatch()..start();
      
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // ✅ إعدادات محسّنة للسرعة
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10), // تقليل من 60 إلى 10 ثواني
        minimumFetchInterval: kDebugMode 
          ? Duration.zero  // في وضع التطوير: بدون انتظار
          : const Duration(minutes: 5), // في الإنتاج: 5 دقائق فقط
      ));
      
      // تعيين القيم الافتراضية
      await _setDefaults();
      
      // ✅ جلب وتفعيل بشكل متزامن
      final fetchResult = await _fetchAndActivateWithRetry();
      
      // تحديث Cache
      _updateAllCache();
      
      _isInitialized = true;
      _lastFetchTime = DateTime.now();
      
      stopwatch.stop();
      debugPrint('✅ FirebaseRemoteConfigService initialized in ${stopwatch.elapsedMilliseconds}ms');
      _printDebugInfo();
      
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Remote Config: $e');
      _isInitialized = false;
      
      // استخدام القيم الافتراضية في حالة الفشل
      _loadDefaultValues();
    }
  }

  /// جلب وتفعيل مع إعادة المحاولة
  Future<bool> _fetchAndActivateWithRetry() async {
    try {
      // المحاولة الأولى
      debugPrint('🔄 Fetching remote config (attempt 1)...');
      bool result = await _remoteConfig.fetchAndActivate();
      
      if (result) {
        debugPrint('✅ Remote config fetched successfully on first attempt');
        return true;
      }
      
      // إذا فشلت المحاولة الأولى، جرب مرة أخرى
      debugPrint('🔄 Retrying fetch (attempt 2)...');
      await Future.delayed(const Duration(milliseconds: 500));
      result = await _remoteConfig.fetchAndActivate();
      
      debugPrint(result 
        ? '✅ Remote config fetched on retry' 
        : '⚠️ Using cached/default values');
      
      return result;
      
    } catch (e) {
      debugPrint('❌ Error fetching remote config: $e');
      
      // في حالة الخطأ، حاول تفعيل القيم المخزنة
      try {
        await _remoteConfig.activate();
        debugPrint('✅ Activated cached values');
        return false;
      } catch (_) {
        return false;
      }
    }
  }

  /// تحديث كل Cache دفعة واحدة
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
      
      debugPrint('✅ Cache updated successfully');
    } catch (e) {
      debugPrint('⚠️ Error updating cache: $e');
    }
  }

  /// تحميل القيم الافتراضية في حالة الفشل
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
    
    debugPrint('⚠️ Using default values due to fetch failure');
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
      }),
      _keyPromotionalBanners: jsonEncode([]),
    });
  }

  /// تحديث الإعدادات يدوياً - محسّن
  Future<bool> refresh() async {
    if (!_isInitialized) {
      await initialize();
      return _isInitialized;
    }
    
    try {
      debugPrint('🔄 Refreshing remote config...');
      
      // فحص إذا كان يمكن التحديث (تجنب التحديثات المتكررة)
      if (_lastFetchTime != null) {
        final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
        if (timeSinceLastFetch.inSeconds < 30 && !kDebugMode) {
          debugPrint('⚠️ Too soon to refresh (${timeSinceLastFetch.inSeconds}s since last fetch)');
          return false;
        }
      }
      
      final result = await _fetchAndActivateWithRetry();
      
      if (result) {
        _updateAllCache();
        _lastFetchTime = DateTime.now();
        _printDebugInfo();
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ Error refreshing config: $e');
      return false;
    }
  }

  // ==================== Optimized Getters ====================

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

  // ==================== Parsing Methods ====================

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
        // فحص التواريخ
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
      if (jsonString.isEmpty) return [];
      
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is List) {
        debugPrint('✅ Found ${decoded.length} promotional banners');
        return decoded;
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing promotional banners: $e');
    }
    return [];
  }

  List<String> _getDefaultFeaturesList() {
    return ['تحسينات الأداء', 'إصلاح الأخطاء', 'ميزات جديدة'];
  }

  // ==================== Status & Debug ====================

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

  /// فرض التحديث للاختبار - محسّن
  Future<void> forceRefreshForTesting() async {
    if (!_isInitialized) {
      await initialize();
      return;
    }
    
    try {
      debugPrint('🧪 FORCE REFRESH FOR TESTING...');
      
      // تغيير الإعدادات مؤقتاً للاختبار
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: Duration.zero,
      ));
      
      // جلب وتفعيل
      final result = await _remoteConfig.fetchAndActivate();
      _updateAllCache();
      _lastFetchTime = DateTime.now();
      
      debugPrint('🧪 Force refresh result: $result');
      _printDebugInfo();
      
      // إعادة الإعدادات الأصلية
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
      
    } catch (e) {
      debugPrint('🧪 Error in force refresh: $e');
    }
  }

  /// إعادة التهيئة الكاملة
  Future<void> reinitialize() async {
    debugPrint('🔄 Reinitializing FirebaseRemoteConfigService...');
    _isInitialized = false;
    _cachedValues.clear();
    _lastFetchTime = null;
    await initialize();
  }

  /// تنظيف الموارد
  void dispose() {
    _isInitialized = false;
    _cachedValues.clear();
    _lastFetchTime = null;
    debugPrint('🧹 FirebaseRemoteConfigService disposed');
  }
}