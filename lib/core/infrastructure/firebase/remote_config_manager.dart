// lib/core/infrastructure/firebase/remote_config_manager.dart - محدث ومبسط

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/storage/storage_service.dart';
import 'remote_config_service.dart';

/// مدير الإعدادات عن بعد - مبسط للإعدادات الأساسية فقط
class RemoteConfigManager {
  static final RemoteConfigManager _instance = RemoteConfigManager._internal();
  factory RemoteConfigManager() => _instance;
  RemoteConfigManager._internal();

  late FirebaseRemoteConfigService _remoteConfig;
  late StorageService _storage;
  
  bool _isInitialized = false;
  Timer? _periodicRefreshTimer;
  
  // ValueNotifiers للميزات الرئيسية فقط
  final ValueNotifier<bool> _prayerTimesEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _qiblaEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _athkarEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _notificationsEnabled = ValueNotifier(true);
  final ValueNotifier<bool> _maintenanceMode = ValueNotifier(false);
  final ValueNotifier<bool> _forceUpdate = ValueNotifier(false);

  // Getters للاستماع للتغييرات
  ValueListenable<bool> get prayerTimesEnabled => _prayerTimesEnabled;
  ValueListenable<bool> get qiblaEnabled => _qiblaEnabled;
  ValueListenable<bool> get athkarEnabled => _athkarEnabled;
  ValueListenable<bool> get notificationsEnabled => _notificationsEnabled;
  ValueListenable<bool> get maintenanceMode => _maintenanceMode;
  ValueListenable<bool> get forceUpdate => _forceUpdate;

  /// تهيئة المدير
  Future<void> initialize({
    required FirebaseRemoteConfigService remoteConfig,
    required StorageService storage,
  }) async {
    if (_isInitialized) return;
    
    _remoteConfig = remoteConfig;
    _storage = storage;
    
    try {
      // تحديث القيم الأولية
      await _updateAllValues();
      
      // بدء التحديث الدوري (كل ساعة)
      _startPeriodicRefresh();
      
      _isInitialized = true;
      debugPrint('RemoteConfigManager initialized successfully');
      
    } catch (e) {
      debugPrint('Error initializing RemoteConfigManager: $e');
    }
  }

  /// تحديث جميع القيم
  Future<void> _updateAllValues() async {
    try {
      // تحديث الميزات
      final features = _remoteConfig.featuresConfig;
      _prayerTimesEnabled.value = features['prayer_times_enabled'] ?? true;
      _qiblaEnabled.value = features['qibla_enabled'] ?? true;
      _athkarEnabled.value = features['athkar_enabled'] ?? true;
      _notificationsEnabled.value = features['notifications_enabled'] ?? true;
      
      // تحديث حالات النظام
      _maintenanceMode.value = _remoteConfig.isMaintenanceModeEnabled;
      _forceUpdate.value = _remoteConfig.isForceUpdateRequired;
      
      debugPrint('All remote config values updated');
      debugPrint('  - Prayer Times: ${_prayerTimesEnabled.value}');
      debugPrint('  - Qibla: ${_qiblaEnabled.value}');
      debugPrint('  - Athkar: ${_athkarEnabled.value}');
      debugPrint('  - Notifications: ${_notificationsEnabled.value}');
      debugPrint('  - Maintenance Mode: ${_maintenanceMode.value}');
      debugPrint('  - Force Update: ${_forceUpdate.value}');
      
    } catch (e) {
      debugPrint('Error updating remote config values: $e');
    }
  }

  /// بدء التحديث الدوري
  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) async {
        await refreshConfig();
      },
    );
  }

  /// تحديث الإعدادات يدوياً
  Future<bool> refreshConfig() async {
    try {
      debugPrint('Refreshing remote config...');
      
      final success = await _remoteConfig.refresh();
      if (success) {
        await _updateAllValues();
        await _storage.setString('last_config_refresh', DateTime.now().toIso8601String());
      }
      
      return success;
    } catch (e) {
      debugPrint('Error refreshing config: $e');
      return false;
    }
  }

  // ==================== التحقق من الميزات ====================

  /// فحص تفعيل مواقيت الصلاة
  bool get isPrayerTimesFeatureEnabled => _prayerTimesEnabled.value;

  /// فحص تفعيل القبلة
  bool get isQiblaFeatureEnabled => _qiblaEnabled.value;

  /// فحص تفعيل الأذكار
  bool get isAthkarFeatureEnabled => _athkarEnabled.value;

  /// فحص تفعيل الإشعارات
  bool get isNotificationsFeatureEnabled => _notificationsEnabled.value;

  /// فحص وضع الصيانة
  bool get isMaintenanceModeActive => _maintenanceMode.value;

  /// فحص الحاجة لتحديث إجباري
  bool get isForceUpdateRequired => _forceUpdate.value;

  /// الحصول على إصدار التطبيق المطلوب
  String get requiredAppVersion => _remoteConfig.requiredAppVersion;

  /// الحصول على رابط التحديث
  String get updateUrl => _remoteConfig.updateUrl;

  // ==================== إعدادات مخصصة ====================

  /// الحصول على قيمة مخصصة
  T? getCustomValue<T>(String key, {T? defaultValue}) {
    try {
      if (T == String) {
        return _remoteConfig.getCustomString(key, defaultValue: defaultValue as String? ?? '') as T?;
      } else if (T == bool) {
        return _remoteConfig.getCustomBool(key, defaultValue: defaultValue as bool? ?? false) as T?;
      } else if (T == int) {
        return _remoteConfig.getCustomInt(key, defaultValue: defaultValue as int? ?? 0) as T?;
      } else {
        return defaultValue;
      }
    } catch (e) {
      debugPrint('Error getting custom value for key $key: $e');
      return defaultValue;
    }
  }

  /// الحصول على JSON مخصص
  Map<String, dynamic>? getCustomJson(String key) {
    return _remoteConfig.getCustomJson(key);
  }

  // ==================== متابعة التغييرات ====================

  /// إضافة مستمع لتغييرات ميزة معينة
  void addFeatureListener(String feature, VoidCallback callback) {
    switch (feature.toLowerCase()) {
      case 'prayer_times':
        _prayerTimesEnabled.addListener(callback);
        break;
      case 'qibla':
        _qiblaEnabled.addListener(callback);
        break;
      case 'athkar':
        _athkarEnabled.addListener(callback);
        break;
      case 'notifications':
        _notificationsEnabled.addListener(callback);
        break;
      case 'maintenance':
        _maintenanceMode.addListener(callback);
        break;
      case 'force_update':
        _forceUpdate.addListener(callback);
        break;
    }
  }

  /// إزالة مستمع لتغييرات ميزة معينة
  void removeFeatureListener(String feature, VoidCallback callback) {
    switch (feature.toLowerCase()) {
      case 'prayer_times':
        _prayerTimesEnabled.removeListener(callback);
        break;
      case 'qibla':
        _qiblaEnabled.removeListener(callback);
        break;
      case 'athkar':
        _athkarEnabled.removeListener(callback);
        break;
      case 'notifications':
        _notificationsEnabled.removeListener(callback);
        break;
      case 'maintenance':
        _maintenanceMode.removeListener(callback);
        break;
      case 'force_update':
        _forceUpdate.removeListener(callback);
        break;
    }
  }

  // ==================== معلومات الحالة ====================

  /// هل المدير مهيأ
  bool get isInitialized => _isInitialized;

  /// آخر وقت تحديث
  DateTime? get lastRefreshTime {
    final timeString = _storage.getString('last_config_refresh');
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }

  /// معلومات حالة Firebase Remote Config
  Map<String, dynamic> get configStatus => {
    'is_initialized': _remoteConfig.isInitialized,
    'last_fetch_status': _remoteConfig.lastFetchStatus.toString(),
    'last_fetch_time': _remoteConfig.lastFetchTime.toIso8601String(),
    'last_manager_refresh': lastRefreshTime?.toIso8601String(),
    'features_status': {
      'prayer_times': _prayerTimesEnabled.value,
      'qibla': _qiblaEnabled.value,
      'athkar': _athkarEnabled.value,
      'notifications': _notificationsEnabled.value,
    },
    'system_status': {
      'maintenance_mode': _maintenanceMode.value,
      'force_update': _forceUpdate.value,
      'required_version': requiredAppVersion,
    }
  };

  /// معلومات التصحيح
  Map<String, dynamic> get debugInfo => {
    'initialized': _isInitialized,
    'has_refresh_timer': _periodicRefreshTimer != null,
    'last_refresh': lastRefreshTime?.toString(),
    'current_features': {
      'prayer_times': _prayerTimesEnabled.value,
      'qibla': _qiblaEnabled.value,
      'athkar': _athkarEnabled.value,
      'notifications': _notificationsEnabled.value,
    },
    'current_system': {
      'maintenance': _maintenanceMode.value,
      'force_update': _forceUpdate.value,
      'app_version': requiredAppVersion,
    }
  };

  // ==================== تنظيف الموارد ====================

  /// تنظيف الموارد
  void dispose() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
    
    _prayerTimesEnabled.dispose();
    _qiblaEnabled.dispose();
    _athkarEnabled.dispose();
    _notificationsEnabled.dispose();
    _maintenanceMode.dispose();
    _forceUpdate.dispose();
    
    _isInitialized = false;
    debugPrint('RemoteConfigManager disposed');
  }
}