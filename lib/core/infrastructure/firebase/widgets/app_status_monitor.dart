// lib/core/infrastructure/firebase/widgets/app_status_monitor.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../remote_config_manager.dart';
import '../remote_config_service.dart';
import 'maintenance_screen.dart';
import 'force_update_screen.dart';

// الحصول على GetIt instance
final GetIt _getIt = GetIt.instance;

/// مراقب حالة التطبيق (الصيانة والتحديث الإجباري)
/// يراقب التغييرات في Remote Config ويعرض الشاشات المناسبة
class AppStatusMonitor extends StatefulWidget {
  final Widget child;
  final RemoteConfigManager? configManager;
  
  const AppStatusMonitor({
    super.key,
    required this.child,
    this.configManager,
  });

  @override
  State<AppStatusMonitor> createState() => _AppStatusMonitorState();
}

class _AppStatusMonitorState extends State<AppStatusMonitor> {
  RemoteConfigManager? _configManager;
  FirebaseRemoteConfigService? _remoteConfigService;
  bool _isMaintenanceMode = false;
  bool _isForceUpdateRequired = false;
  
  @override
  void initState() {
    super.initState();
    _initializeManagers();
  }
  
  /// تهيئة المديرين والخدمات
  void _initializeManagers() {
    // استخدم ConfigManager الممرر أو احصل عليه من GetIt
    _configManager = widget.configManager ?? _tryGetConfigManager();
    
    // محاولة الحصول على FirebaseRemoteConfigService
    _remoteConfigService = _tryGetRemoteConfigService();
    
    // إعداد المستمعين وفحص الحالة
    if (_configManager != null) {
      _setupListeners();
      _checkInitialStatus();
      debugPrint('✅ AppStatusMonitor initialized with ConfigManager');
    } else {
      debugPrint('⚠️ AppStatusMonitor: No ConfigManager available');
      // محاولة مرة أخرى بعد تأخير
      _retryInitialization();
    }
  }
  
  /// محاولة الحصول على ConfigManager من GetIt
  RemoteConfigManager? _tryGetConfigManager() {
    try {
      if (_getIt.isRegistered<RemoteConfigManager>()) {
        final manager = _getIt<RemoteConfigManager>();
        if (manager.isInitialized) {
          debugPrint('✅ Got RemoteConfigManager from GetIt');
          return manager;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not get RemoteConfigManager: $e');
    }
    return null;
  }
  
  /// محاولة الحصول على FirebaseRemoteConfigService
  FirebaseRemoteConfigService? _tryGetRemoteConfigService() {
    try {
      if (_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final service = _getIt<FirebaseRemoteConfigService>();
        debugPrint('✅ Got FirebaseRemoteConfigService for screens');
        return service;
      }
    } catch (e) {
      debugPrint('⚠️ Could not get FirebaseRemoteConfigService: $e');
    }
    return null;
  }
  
  /// إعادة محاولة التهيئة بعد تأخير
  void _retryInitialization() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _configManager == null) {
        debugPrint('🔄 Retrying to get ConfigManager...');
        setState(() {
          _initializeManagers();
        });
      }
    });
  }
  
  /// إعداد المستمعين للتغييرات
  void _setupListeners() {
    if (_configManager == null) return;
    
    // مراقبة وضع الصيانة
    _configManager!.maintenanceMode.addListener(_onMaintenanceModeChanged);
    
    // مراقبة التحديث الإجباري
    _configManager!.forceUpdate.addListener(_onForceUpdateChanged);
    
    debugPrint('🔔 Listeners setup for Remote Config changes');
  }
  
  /// فحص الحالة الأولية
  void _checkInitialStatus() {
    if (_configManager == null) return;
    
    final maintenanceMode = _configManager!.isMaintenanceModeActive;
    final forceUpdate = _configManager!.isForceUpdateRequired;
    
    setState(() {
      _isMaintenanceMode = maintenanceMode;
      _isForceUpdateRequired = forceUpdate;
    });
    
    debugPrint('📊 Initial App Status:');
    debugPrint('  - Maintenance Mode: $_isMaintenanceMode');
    debugPrint('  - Force Update: $_isForceUpdateRequired');
    debugPrint('  - Required Version: ${_configManager!.requiredAppVersion}');
    
    // إذا كانت أي من الحالات مفعلة عند البداية
    if (_isMaintenanceMode || _isForceUpdateRequired) {
      debugPrint('⚠️ App status requires action on startup');
    }
  }
  
  /// معالج تغيير وضع الصيانة
  void _onMaintenanceModeChanged() {
    if (!mounted) return;
    
    final newValue = _configManager!.isMaintenanceModeActive;
    if (_isMaintenanceMode != newValue) {
      setState(() {
        _isMaintenanceMode = newValue;
      });
      
      debugPrint('🔧 Maintenance mode changed to: $_isMaintenanceMode');
      
      if (_isMaintenanceMode) {
        _showMaintenanceDialog();
      }
    }
  }
  
  /// معالج تغيير التحديث الإجباري
  void _onForceUpdateChanged() {
    if (!mounted) return;
    
    final newValue = _configManager!.isForceUpdateRequired;
    if (_isForceUpdateRequired != newValue) {
      setState(() {
        _isForceUpdateRequired = newValue;
      });
      
      debugPrint('🚨 Force update changed to: $_isForceUpdateRequired');
      debugPrint('  - Required version: ${_configManager!.requiredAppVersion}');
      
      if (_isForceUpdateRequired) {
        _showForceUpdateDialog();
      }
    }
  }
  
  /// عرض شاشة الصيانة كـ Dialog
  void _showMaintenanceDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: const MaintenanceScreen(),
      ),
    );
  }
  
  /// عرض شاشة التحديث الإجباري كـ Dialog
  void _showForceUpdateDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: ForceUpdateScreen(
          remoteConfig: _remoteConfigService,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    // إزالة المستمعين
    if (_configManager != null) {
      _configManager!.maintenanceMode.removeListener(_onMaintenanceModeChanged);
      _configManager!.forceUpdate.removeListener(_onForceUpdateChanged);
    }
    
    debugPrint('🧹 AppStatusMonitor disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إذا لم يتم تهيئة ConfigManager بعد
    if (_configManager == null) {
      debugPrint('⏳ AppStatusMonitor: Waiting for ConfigManager...');
      // عرض المحتوى العادي مع مؤشر تحميل صغير
      return Stack(
        children: [
          widget.child,
          // مؤشر صغير في الأعلى للتطوير فقط
          if (const bool.fromEnvironment('dart.vm.product') == false)
            const Positioned(
              top: 50,
              right: 20,
              child: Card(
                color: Colors.orange,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Loading Config...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    }
    
    // إذا كان وضع الصيانة مفعل، عرض شاشة الصيانة
    if (_isMaintenanceMode) {
      debugPrint('🔧 Rendering MaintenanceScreen');
      return const MaintenanceScreen();
    }
    
    // إذا كان التحديث الإجباري مطلوب، عرض شاشة التحديث
    if (_isForceUpdateRequired) {
      debugPrint('🚨 Rendering ForceUpdateScreen');
      return ForceUpdateScreen(
        remoteConfig: _remoteConfigService,
      );
    }
    
    // عرض المحتوى العادي
    return widget.child;
  }
  
  /// طريقة للتحديث اليدوي (للاختبار)
  @visibleForTesting
  Future<void> refreshStatus() async {
    if (_configManager != null) {
      await _configManager!.refreshConfig();
      _checkInitialStatus();
    }
  }
}

/// Extension للوصول السريع من Context
extension AppStatusMonitorExtension on BuildContext {
  /// فحص وضع الصيانة
  bool get isInMaintenanceMode {
    try {
      if (_getIt.isRegistered<RemoteConfigManager>()) {
        final manager = _getIt<RemoteConfigManager>();
        return manager.isMaintenanceModeActive;
      }
    } catch (_) {}
    return false;
  }
  
  /// فحص التحديث الإجباري
  bool get needsForceUpdate {
    try {
      if (_getIt.isRegistered<RemoteConfigManager>()) {
        final manager = _getIt<RemoteConfigManager>();
        return manager.isForceUpdateRequired;
      }
    } catch (_) {}
    return false;
  }
}