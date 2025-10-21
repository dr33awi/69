// lib/core/infrastructure/firebase/widgets/app_status_monitor.dart
// نسخة محدثة لحل مشكلة setState during build

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import '../remote_config_manager.dart';
import '../remote_config_service.dart';
import 'maintenance_screen.dart';
import 'force_update_screen.dart';

final GetIt _getIt = GetIt.instance;

/// مراقب حالة التطبيق (الصيانة والتحديث الإجباري)
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
  bool _hasShownDialog = false; // منع عرض الـ Dialog أكثر من مرة
  
  @override
  void initState() {
    super.initState();
    // تأجيل التهيئة لما بعد البناء الأول
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeManagers();
      }
    });
  }
  
  /// تهيئة المديرين والخدمات
  void _initializeManagers() {
    _configManager = widget.configManager ?? _tryGetConfigManager();
    _remoteConfigService = _tryGetRemoteConfigService();
    
    if (_configManager != null) {
      _setupListeners();
      _checkInitialStatus();
    } else {
      _retryInitialization();
    }
  }
  
  /// محاولة الحصول على ConfigManager من GetIt
  RemoteConfigManager? _tryGetConfigManager() {
    try {
      if (_getIt.isRegistered<RemoteConfigManager>()) {
        final manager = _getIt<RemoteConfigManager>();
        if (manager.isInitialized) {
          return manager;
        }
      }
    } catch (e) {
    }
    return null;
  }
  
  /// محاولة الحصول على FirebaseRemoteConfigService
  FirebaseRemoteConfigService? _tryGetRemoteConfigService() {
    try {
      if (_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final service = _getIt<FirebaseRemoteConfigService>();
        return service;
      }
    } catch (e) {
    }
    return null;
  }
  
  /// إعادة محاولة التهيئة بعد تأخير
  void _retryInitialization() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _configManager == null) {
        _initializeManagers();
      }
    });
  }
  
  /// إعداد المستمعين للتغييرات
  void _setupListeners() {
    if (_configManager == null) return;
    
    _configManager!.maintenanceMode.addListener(_onMaintenanceModeChanged);
    _configManager!.forceUpdate.addListener(_onForceUpdateChanged);
  }
  
  /// فحص الحالة الأولية
  void _checkInitialStatus() {
    if (_configManager == null || !mounted) return;
    
    final maintenanceMode = _configManager!.isMaintenanceModeActive;
    final forceUpdate = _configManager!.isForceUpdateRequired;
    
    // استخدم postFrameCallback لتحديث الحالة بأمان
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isMaintenanceMode = maintenanceMode;
          _isForceUpdateRequired = forceUpdate;
        });
        // عرض Dialog إذا لزم الأمر
        if (_isMaintenanceMode || _isForceUpdateRequired) {
          _showAppropriateDialog();
        }
      }
    });
  }
  
  /// معالج تغيير وضع الصيانة
  void _onMaintenanceModeChanged() {
    if (!mounted) return;
    
    final newValue = _configManager!.isMaintenanceModeActive;
    if (_isMaintenanceMode != newValue) {
      // استخدم postFrameCallback لضمان عدم التحديث أثناء البناء
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isMaintenanceMode = newValue;
            _hasShownDialog = false; // السماح بعرض Dialog جديد
          });
          if (_isMaintenanceMode) {
            _showAppropriateDialog();
          }
        }
      });
    }
  }
  
  /// معالج تغيير التحديث الإجباري
  void _onForceUpdateChanged() {
    if (!mounted) return;
    
    final newValue = _configManager!.isForceUpdateRequired;
    if (_isForceUpdateRequired != newValue) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isForceUpdateRequired = newValue;
            _hasShownDialog = false;
          });
          if (_isForceUpdateRequired) {
            _showAppropriateDialog();
          }
        }
      });
    }
  }
  
  /// عرض Dialog المناسب حسب الحالة
  void _showAppropriateDialog() {
    if (_hasShownDialog || !mounted) return;
    
    _hasShownDialog = true;
    
    // تأجيل عرض الـ Dialog لتجنب الخطأ
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      if (_isMaintenanceMode) {
        _showMaintenanceDialog();
      } else if (_isForceUpdateRequired) {
        _showForceUpdateDialog();
      }
    });
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
    if (_configManager != null) {
      _configManager!.maintenanceMode.removeListener(_onMaintenanceModeChanged);
      _configManager!.forceUpdate.removeListener(_onForceUpdateChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إذا لم يتم تهيئة ConfigManager بعد
    if (_configManager == null) {
      return widget.child; // عرض المحتوى العادي مباشرة
    }
    
    // إذا كان وضع الصيانة مفعل
    if (_isMaintenanceMode) {
      return const MaintenanceScreen();
    }
    
    // إذا كان التحديث الإجباري مطلوب
    if (_isForceUpdateRequired) {
      return ForceUpdateScreen(
        remoteConfig: _remoteConfigService,
      );
    }
    
    // عرض المحتوى العادي
    return widget.child;
  }
}

/// Extension للوصول السريع من Context
extension AppStatusMonitorExtension on BuildContext {
  bool get isInMaintenanceMode {
    try {
      if (_getIt.isRegistered<RemoteConfigManager>()) {
        final manager = _getIt<RemoteConfigManager>();
        return manager.isMaintenanceModeActive;
      }
    } catch (_) {}
    return false;
  }
  
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