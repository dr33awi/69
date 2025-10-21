// lib/core/infrastructure/firebase/remote_config_manager.dart - مع فحص التحديث

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../infrastructure/services/storage/storage_service.dart';
import 'remote_config_service.dart';

/// مدير الإعدادات عن بعد - مع فحص التحديث المحسن
class RemoteConfigManager {
  static final RemoteConfigManager _instance = RemoteConfigManager._internal();
  factory RemoteConfigManager() => _instance;
  RemoteConfigManager._internal();

  late FirebaseRemoteConfigService _remoteConfig;
  late StorageService _storage;
  
  bool _isInitialized = false;
  Timer? _periodicRefreshTimer;
  
  // ValueNotifiers للحالات الأساسية فقط
  final ValueNotifier<bool> _maintenanceMode = ValueNotifier(false);
  final ValueNotifier<bool> _forceUpdate = ValueNotifier(false);
  final ValueNotifier<String> _requiredVersion = ValueNotifier('1.0.0');

  // مفاتيح التخزين
  static const String _keyLastInstalledVersion = 'last_installed_version';
  static const String _keyUpdateAcknowledged = 'update_acknowledged_version';
  static const String _keyLastConfigRefresh = 'last_config_refresh';

  // Getters للاستماع للتغييرات
  ValueListenable<bool> get maintenanceMode => _maintenanceMode;
  ValueListenable<bool> get forceUpdate => _forceUpdate;
  ValueListenable<String> get requiredVersion => _requiredVersion;

  /// تهيئة المدير
  Future<void> initialize({
    required FirebaseRemoteConfigService remoteConfig,
    required StorageService storage,
  }) async {
    if (_isInitialized) {
      return;
    }
    
    _remoteConfig = remoteConfig;
    _storage = storage;
    
    try {
      // فحص وحفظ نسخة التطبيق الحالية
      await _checkAndSaveCurrentVersion();
      
      // تحديث القيم الأولية
      await _updateValues();
      
      // بدء التحديث الدوري (كل ساعة)
      _startPeriodicRefresh();
      
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  /// فحص وحفظ نسخة التطبيق الحالية
  Future<void> _checkAndSaveCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // جلب آخر نسخة محفوظة
      final lastSavedVersion = _storage.getString(_keyLastInstalledVersion);
      
      // إذا تغيرت النسخة (تم التحديث)
      if (lastSavedVersion != null && lastSavedVersion != currentVersion) {
        // حفظ النسخة الجديدة
        await _storage.setString(_keyLastInstalledVersion, currentVersion);
        
        // مسح علامة الإقرار بالتحديث القديمة
        await _storage.remove(_keyUpdateAcknowledged);
      } else if (lastSavedVersion == null) {
        // أول مرة - حفظ النسخة الحالية
        await _storage.setString(_keyLastInstalledVersion, currentVersion);
      }
      
    } catch (e) {
    }
  }

  /// تحديث القيم من Remote Config
  Future<void> _updateValues() async {
    try {
      // تحديث حالات النظام
      _maintenanceMode.value = _remoteConfig.isMaintenanceModeEnabled;
      
      final requiredVersion = _remoteConfig.requiredAppVersion;
      _requiredVersion.value = requiredVersion;
      
      // فحص التحديث الإجباري مع مراعاة النسخة المثبتة
      final shouldShowForceUpdate = await _shouldShowForceUpdate(requiredVersion);
      _forceUpdate.value = shouldShowForceUpdate;
      // حفظ آخر وقت تحديث
      await _storage.setString(_keyLastConfigRefresh, DateTime.now().toIso8601String());
      
    } catch (e) {
    }
  }

  /// فحص ما إذا كان يجب عرض التحديث الإجباري
  Future<bool> _shouldShowForceUpdate(String requiredVersion) async {
    try {
      // 1. التحقق من تفعيل Force Update في Firebase
      final isForceUpdateEnabled = _remoteConfig.isForceUpdateRequired;
      if (!isForceUpdateEnabled) {
        return false;
      }
      
      // 2. الحصول على نسخة التطبيق الحالية
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // 3. مقارنة النسخ
      final isVersionOutdated = _compareVersions(currentVersion, requiredVersion) < 0;
      
      if (!isVersionOutdated) {
        return false;
      }
      
      // 4. التحقق من عدم الإقرار بالتحديث مسبقاً
      final acknowledgedVersion = _storage.getString(_keyUpdateAcknowledged);
      
      if (acknowledgedVersion == currentVersion) {
        return false;
      }
      return true;
      
    } catch (e) {
      return false;
    }
  }

  /// مقارنة نسختين (SemVer)
  /// Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map(int.parse).toList();
      final parts2 = v2.split('.').map(int.parse).toList();
      
      for (int i = 0; i < 3; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;
        
        if (p1 < p2) return -1;
        if (p1 > p2) return 1;
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// تسجيل أن المستخدم شاهد شاشة التحديث
  Future<void> acknowledgeUpdateShown() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await _storage.setString(_keyUpdateAcknowledged, packageInfo.version);
    } catch (e) {
    }
  }

  /// بدء التحديث الدوري
  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    
    // تحديث كل ساعة
    _periodicRefreshTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) async {
        await refreshConfig();
      },
    );
  }

  /// تحديث الإعدادات يدوياً
  Future<bool> refreshConfig() async {
    if (!_isInitialized) {
      return false;
    }
    
    try {
      final success = await _remoteConfig.refresh();
      if (success) {
        await _checkAndSaveCurrentVersion();
        await _updateValues();
      } else {
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // ==================== التحقق من الحالات ====================

  /// فحص وضع الصيانة
  bool get isMaintenanceModeActive => _maintenanceMode.value;

  /// فحص الحاجة لتحديث إجباري
  bool get isForceUpdateRequired => _forceUpdate.value;

  /// الحصول على إصدار التطبيق المطلوب
  String get requiredAppVersion => _requiredVersion.value;

  /// الحصول على رابط التحديث
  String get updateUrl => _remoteConfig.updateUrl;

  // ==================== متابعة التغييرات ====================

  void addMaintenanceListener(VoidCallback callback) {
    _maintenanceMode.addListener(callback);
  }

  void removeMaintenanceListener(VoidCallback callback) {
    _maintenanceMode.removeListener(callback);
  }

  void addForceUpdateListener(VoidCallback callback) {
    _forceUpdate.addListener(callback);
  }

  void removeForceUpdateListener(VoidCallback callback) {
    _forceUpdate.removeListener(callback);
  }

  // ==================== معلومات الحالة ====================

  bool get isInitialized => _isInitialized;

  DateTime? get lastRefreshTime {
    final timeString = _storage.getString(_keyLastConfigRefresh);
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }

  Map<String, dynamic> get configStatus => {
    'is_initialized': _isInitialized,
    'has_timer': _periodicRefreshTimer != null,
    'last_refresh': lastRefreshTime?.toIso8601String(),
    'last_installed_version': _storage.getString(_keyLastInstalledVersion),
    'update_acknowledged_version': _storage.getString(_keyUpdateAcknowledged),
    'current_values': {
      'maintenance_mode': _maintenanceMode.value,
      'force_update': _forceUpdate.value,
      'required_version': _requiredVersion.value,
      'update_url': updateUrl,
    },
    'remote_config_status': _remoteConfig.debugInfo,
  };

  Map<String, dynamic> get debugInfo => configStatus;

  void printStatus() {
  }

  // ==================== للاختبار ====================

  Future<void> forceRefreshForTesting() async {
    if (!_isInitialized) {
      return;
    }
    await _remoteConfig.forceRefreshForTesting();
    await _checkAndSaveCurrentVersion();
    await _updateValues();
    printStatus();
  }

  void setTestValues({
    bool? maintenanceMode,
    bool? forceUpdate,
    String? requiredVersion,
  }) {
    if (maintenanceMode != null) {
      _maintenanceMode.value = maintenanceMode;
    }
    
    if (forceUpdate != null) {
      _forceUpdate.value = forceUpdate;
    }
    
    if (requiredVersion != null) {
      _requiredVersion.value = requiredVersion;
    }
  }

  /// مسح بيانات التحديث (للاختبار)
  Future<void> clearUpdateData() async {
    await _storage.remove(_keyUpdateAcknowledged);
    await _storage.remove(_keyLastInstalledVersion);
  }

  // ==================== تنظيف الموارد ====================

  void dispose() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
    
    _maintenanceMode.dispose();
    _forceUpdate.dispose();
    _requiredVersion.dispose();
    
    _isInitialized = false;
  }

  Future<void> reinitialize({
    required FirebaseRemoteConfigService remoteConfig,
    required StorageService storage,
  }) async {
    dispose();
    _isInitialized = false;
    
    await initialize(
      remoteConfig: remoteConfig,
      storage: storage,
    );
  }
}