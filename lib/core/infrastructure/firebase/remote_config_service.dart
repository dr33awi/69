// lib/core/infrastructure/firebase/enhanced_remote_config_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// إعدادات التحديث الإجباري
class ForceUpdateConfig {
  final bool enabled;
  final String minVersion;
  final String currentVersion;
  final String title;
  final String message;
  final String updateUrlAndroid;
  final String updateUrlIos;
  final bool dismissible;
  final List<String> features;

  const ForceUpdateConfig({
    required this.enabled,
    required this.minVersion,
    required this.currentVersion,
    required this.title,
    required this.message,
    required this.updateUrlAndroid,
    required this.updateUrlIos,
    required this.dismissible,
    required this.features,
  });

  factory ForceUpdateConfig.fromJson(Map<String, dynamic> json) {
    return ForceUpdateConfig(
      enabled: json['enabled'] as bool? ?? false,
      minVersion: json['min_version'] as String? ?? '1.0.0',
      currentVersion: json['current_version'] as String? ?? '1.0.0',
      title: json['title'] as String? ?? 'تحديث مطلوب',
      message: json['message'] as String? ?? 'يجب تحديث التطبيق',
      updateUrlAndroid: json['update_url_android'] as String? ?? '',
      updateUrlIos: json['update_url_ios'] as String? ?? '',
      dismissible: json['dismissible'] as bool? ?? false,
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  factory ForceUpdateConfig.defaultConfig() {
    return const ForceUpdateConfig(
      enabled: false,
      minVersion: '1.0.0',
      currentVersion: '1.0.0',
      title: 'تحديث مطلوب',
      message: 'يجب تحديث التطبيق للإصدار الأحدث',
      updateUrlAndroid: '',
      updateUrlIos: '',
      dismissible: false,
      features: [],
    );
  }
}

/// خدمة Remote Config محسنة
class EnhancedRemoteConfigService {
  static final EnhancedRemoteConfigService _instance = EnhancedRemoteConfigService._internal();
  factory EnhancedRemoteConfigService() => _instance;
  EnhancedRemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;
  String? _currentAppVersion;
  
  // مفاتيح الإعدادات
  static const String _keyForceUpdate = 'force_update';
  static const String _keyAppVersion = 'app_version';
  static const String _keyForceUpdateConfig = 'force_update_config';
  static const String _keyMaintenanceMode = 'maintenance_mode';

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // الحصول على إصدار التطبيق الحالي
      await _loadCurrentAppVersion();
      
      // إعداد التحديث التلقائي
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 10), // تحديث كل 10 دقائق للتحديث الإجباري
      ));
      
      // تعيين القيم الافتراضية
      await _setDefaults();
      
      // جلب الإعدادات الأولية
      await _fetchAndActivate();
      
      _isInitialized = true;
      debugPrint('EnhancedRemoteConfigService initialized successfully');
      
    } catch (e) {
      debugPrint('Error initializing Enhanced Remote Config: $e');
      throw Exception('Failed to initialize Enhanced Remote Config: $e');
    }
  }

  /// تحميل إصدار التطبيق الحالي
  Future<void> _loadCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentAppVersion = packageInfo.version;
      debugPrint('Current app version: $_currentAppVersion');
    } catch (e) {
      debugPrint('Error loading app version: $e');
      _currentAppVersion = '1.0.0';
    }
  }

  /// تعيين القيم الافتراضية
  Future<void> _setDefaults() async {
    await _remoteConfig.setDefaults({
      _keyForceUpdate: false,
      _keyAppVersion: _currentAppVersion ?? '1.0.0',
      _keyMaintenanceMode: false,
      _keyForceUpdateConfig: jsonEncode({
        'enabled': false,
        'min_version': '1.0.0',
        'current_version': '1.1.0',
        'title': 'تحديث مطلوب',
        'message': 'يجب تحديث التطبيق للإصدار الأحدث للاستمرار في الاستخدام',
        'update_url_android': 'https://play.google.com/store/apps/details?id=com.example.test_athkar_app',
        'update_url_ios': 'https://apps.apple.com/app/id1234567890',
        'dismissible': false,
        'features': [
          'تحسينات الأداء',
          'إصلاح الأخطاء',
          'ميزات جديدة'
        ],
      }),
    });
  }

  /// جلب وتفعيل الإعدادات
  Future<bool> _fetchAndActivate() async {
    try {
      final fetchResult = await _remoteConfig.fetchAndActivate();
      debugPrint('Remote config fetch result: $fetchResult');
      
      // فحص التحديث الإجباري فور التحديث
      _checkForceUpdateStatus();
      
      return fetchResult;
    } catch (e) {
      debugPrint('Error fetching remote config: $e');
      return false;
    }
  }

  /// فحص حالة التحديث الإجباري
  void _checkForceUpdateStatus() {
    try {
      final forceUpdateRequired = isForceUpdateRequired();
      debugPrint('Force update required: $forceUpdateRequired');
      
      if (forceUpdateRequired) {
        final config = getForceUpdateConfig();
        debugPrint('Force update config: enabled=${config.enabled}, minVersion=${config.minVersion}, currentAppVersion=$_currentAppVersion');
      }
    } catch (e) {
      debugPrint('Error checking force update status: $e');
    }
  }

  /// فحص الحاجة للتحديث الإجباري
  bool isForceUpdateRequired() {
    try {
      // الطريقة الأولى: الفحص البسيط
      final simpleForceUpdate = _remoteConfig.getBool(_keyForceUpdate);
      if (simpleForceUpdate) return true;
      
      // الطريقة الثانية: الفحص المتقدم
      final config = getForceUpdateConfig();
      if (!config.enabled) return false;
      
      // مقارنة الإصدارات
      return _isVersionOutdated(_currentAppVersion ?? '1.0.0', config.minVersion);
      
    } catch (e) {
      debugPrint('Error checking force update: $e');
      return false;
    }
  }

  /// مقارنة الإصدارات
  bool _isVersionOutdated(String currentVersion, String minVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final minimum = _parseVersion(minVersion);
      
      // مقارنة major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (current[i] < minimum[i]) return true;
        if (current[i] > minimum[i]) return false;
      }
      
      return false; // نفس الإصدار
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  /// تحليل رقم الإصدار
  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return [
      int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }

  /// الحصول على إعدادات التحديث الإجباري
  ForceUpdateConfig getForceUpdateConfig() {
    try {
      final jsonString = _remoteConfig.getString(_keyForceUpdateConfig);
      if (jsonString.isEmpty) return ForceUpdateConfig.defaultConfig();
      
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return ForceUpdateConfig.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error parsing force update config: $e');
      return ForceUpdateConfig.defaultConfig();
    }
  }

  /// فحص وضع الصيانة
  bool get isMaintenanceModeEnabled => _remoteConfig.getBool(_keyMaintenanceMode);

  /// الإصدار المطلوب
  String get requiredAppVersion => _remoteConfig.getString(_keyAppVersion);

  /// الإصدار الحالي
  String get currentAppVersion => _currentAppVersion ?? '1.0.0';

  /// جلب الإعدادات يدوياً
  Future<bool> refresh() async {
    if (!_isInitialized) return false;
    return await _fetchAndActivate();
  }

  /// هل الخدمة مهيأة
  bool get isInitialized => _isInitialized;

  /// معلومات التشخيص
  Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'current_app_version': _currentAppVersion,
    'required_app_version': requiredAppVersion,
    'force_update_required': isForceUpdateRequired(),
    'maintenance_mode': isMaintenanceModeEnabled,
    'last_fetch_status': _remoteConfig.lastFetchStatus.toString(),
    'last_fetch_time': _remoteConfig.lastFetchTime.toIso8601String(),
  };

  /// تنظيف الموارد
  void dispose() {
    _isInitialized = false;
    debugPrint('EnhancedRemoteConfigService disposed');
  }
}