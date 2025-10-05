// lib/core/infrastructure/firebase/remote_config_manager.dart - مبسط للغاية

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
  
  // ValueNotifiers للحالات الأساسية فقط
  final ValueNotifier<bool> _maintenanceMode = ValueNotifier(false);
  final ValueNotifier<bool> _forceUpdate = ValueNotifier(false);
  final ValueNotifier<String> _requiredVersion = ValueNotifier('1.0.0');

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
      debugPrint('RemoteConfigManager already initialized');
      return;
    }
    
    _remoteConfig = remoteConfig;
    _storage = storage;
    
    try {
      // تحديث القيم الأولية
      await _updateValues();
      
      // بدء التحديث الدوري (كل ساعة)
      _startPeriodicRefresh();
      
      _isInitialized = true;
      debugPrint('✅ RemoteConfigManager initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Error initializing RemoteConfigManager: $e');
      _isInitialized = false;
    }
  }

  /// تحديث القيم من Remote Config
  Future<void> _updateValues() async {
    try {
      // تحديث حالات النظام
      _maintenanceMode.value = _remoteConfig.isMaintenanceModeEnabled;
      _forceUpdate.value = _remoteConfig.isForceUpdateRequired;
      _requiredVersion.value = _remoteConfig.requiredAppVersion;
      
      debugPrint('📊 Remote config values updated:');
      debugPrint('  - Maintenance Mode: ${_maintenanceMode.value}');
      debugPrint('  - Force Update: ${_forceUpdate.value}');
      debugPrint('  - Required Version: ${_requiredVersion.value}');
      
      // حفظ آخر وقت تحديث
      await _storage.setString('last_config_refresh', DateTime.now().toIso8601String());
      
    } catch (e) {
      debugPrint('❌ Error updating remote config values: $e');
    }
  }

  /// بدء التحديث الدوري
  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    
    // تحديث كل ساعة
    _periodicRefreshTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) async {
        debugPrint('⏰ Periodic remote config refresh...');
        await refreshConfig();
      },
    );
    
    debugPrint('🔄 Periodic refresh timer started (every hour)');
  }

  /// تحديث الإعدادات يدوياً
  Future<bool> refreshConfig() async {
    if (!_isInitialized) {
      debugPrint('⚠️ RemoteConfigManager not initialized');
      return false;
    }
    
    try {
      debugPrint('🔄 Refreshing remote config...');
      
      final success = await _remoteConfig.refresh();
      if (success) {
        await _updateValues();
        debugPrint('✅ Remote config refreshed successfully');
      } else {
        debugPrint('⚠️ Remote config refresh returned false');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error refreshing config: $e');
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

  /// إضافة مستمع لوضع الصيانة
  void addMaintenanceListener(VoidCallback callback) {
    _maintenanceMode.addListener(callback);
  }

  /// إزالة مستمع وضع الصيانة
  void removeMaintenanceListener(VoidCallback callback) {
    _maintenanceMode.removeListener(callback);
  }

  /// إضافة مستمع للتحديث الإجباري
  void addForceUpdateListener(VoidCallback callback) {
    _forceUpdate.addListener(callback);
  }

  /// إزالة مستمع التحديث الإجباري
  void removeForceUpdateListener(VoidCallback callback) {
    _forceUpdate.removeListener(callback);
  }

  // ==================== معلومات الحالة ====================

  /// هل المدير مهيأ؟
  bool get isInitialized => _isInitialized;

  /// آخر وقت تحديث
  DateTime? get lastRefreshTime {
    final timeString = _storage.getString('last_config_refresh');
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }

  /// معلومات حالة الإعدادات
  Map<String, dynamic> get configStatus => {
    'is_initialized': _isInitialized,
    'has_timer': _periodicRefreshTimer != null,
    'last_refresh': lastRefreshTime?.toIso8601String(),
    'current_values': {
      'maintenance_mode': _maintenanceMode.value,
      'force_update': _forceUpdate.value,
      'required_version': _requiredVersion.value,
      'update_url': updateUrl,
    },
    'remote_config_status': _remoteConfig.debugInfo,
  };

  /// معلومات التصحيح
  Map<String, dynamic> get debugInfo => configStatus;

  /// طباعة معلومات الحالة
  void printStatus() {
    debugPrint('========== RemoteConfigManager Status ==========');
    debugPrint('Initialized: $_isInitialized');
    debugPrint('Last Refresh: ${lastRefreshTime?.toString() ?? "Never"}');
    debugPrint('--- Current Values ---');
    debugPrint('Maintenance Mode: ${_maintenanceMode.value}');
    debugPrint('Force Update: ${_forceUpdate.value}');
    debugPrint('Required Version: ${_requiredVersion.value}');
    debugPrint('Update URL: $updateUrl');
    debugPrint('===============================================');
  }

  // ==================== للاختبار ====================

  /// فرض التحديث للاختبار
  Future<void> forceRefreshForTesting() async {
    if (!_isInitialized) {
      debugPrint('⚠️ Cannot test - manager not initialized');
      return;
    }
    
    debugPrint('🧪 Testing force refresh...');
    await _remoteConfig.forceRefreshForTesting();
    await _updateValues();
    printStatus();
  }

  /// تغيير القيم محلياً للاختبار
  void setTestValues({
    bool? maintenanceMode,
    bool? forceUpdate,
    String? requiredVersion,
  }) {
    debugPrint('🧪 Setting test values...');
    
    if (maintenanceMode != null) {
      _maintenanceMode.value = maintenanceMode;
      debugPrint('  - Test Maintenance Mode: $maintenanceMode');
    }
    
    if (forceUpdate != null) {
      _forceUpdate.value = forceUpdate;
      debugPrint('  - Test Force Update: $forceUpdate');
    }
    
    if (requiredVersion != null) {
      _requiredVersion.value = requiredVersion;
      debugPrint('  - Test Required Version: $requiredVersion');
    }
  }

  // ==================== تنظيف الموارد ====================

  /// تنظيف الموارد
  void dispose() {
    debugPrint('🧹 Disposing RemoteConfigManager...');
    
    // إيقاف التحديث الدوري
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
    
    // تنظيف ValueNotifiers
    _maintenanceMode.dispose();
    _forceUpdate.dispose();
    _requiredVersion.dispose();
    
    _isInitialized = false;
    
    debugPrint('✅ RemoteConfigManager disposed');
  }

  /// إعادة التهيئة
  Future<void> reinitialize({
    required FirebaseRemoteConfigService remoteConfig,
    required StorageService storage,
  }) async {
    debugPrint('🔄 Reinitializing RemoteConfigManager...');
    
    dispose();
    _isInitialized = false;
    
    await initialize(
      remoteConfig: remoteConfig,
      storage: storage,
    );
  }
}