// lib/core/infrastructure/services/permissions/permission_service_impl.dart 

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import '../storage/storage_service.dart';
import 'permission_service.dart';
import 'permission_constants.dart';
import 'permission_coordinator.dart'; // إضافة هذا
import 'widgets/permission_dialogs.dart';
import 'handlers/permission_handler_factory.dart';

/// تنفيذ مبسط لخدمة الأذونات مع استخدام PermissionCoordinator
class PermissionServiceImpl implements PermissionService {
  final StorageService _storage;
  final BuildContext? _context;
  
  // إضافة reference للـ coordinator
  late final PermissionCoordinator _coordinator;
  
  // Cache
  final Map<AppPermissionType, AppPermissionStatus> _statusCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiration = Duration(seconds: 30);
  
  // Stream controller
  final StreamController<PermissionChange> _permissionChangeController = 
      StreamController<PermissionChange>.broadcast();
  
  PermissionServiceImpl({
    required StorageService storage,
    BuildContext? context,
  }) : _storage = storage,
       _context = context {
    _coordinator = PermissionCoordinator(); // استخدام singleton
    _initializeService();
  }
  
  void _initializeService() {
    _log('Initializing with PermissionCoordinator');
    _loadCachedStatuses();
  }
  
  @override
  Future<bool> checkNotificationPermission() async {
    final status = await checkPermissionStatus(AppPermissionType.notification);
    return status == AppPermissionStatus.granted;
  }
  
  @override
  Future<bool> requestNotificationPermission() async {
    final status = await requestPermission(AppPermissionType.notification);
    return status == AppPermissionStatus.granted;
  }
  
  @override
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission) async {
    _log('Requesting permission via coordinator', {'type': permission.toString()});
    
    // Check cache first
    final cachedStatus = _getCachedStatus(permission);
    if (cachedStatus != null && cachedStatus == AppPermissionStatus.granted) {
      _log('Permission already granted (cached)');
      return cachedStatus;
    }
    
    // استخدام Coordinator بدلاً من الإدارة المحلية
    return await _coordinator.requestPermission(
      permission,
      () async {
        final handler = PermissionHandlerFactory.getHandler(permission);
        if (handler == null) {
          _logWarning('Unsupported permission type');
          return AppPermissionStatus.unknown;
        }
        
        try {
          // Check availability
          if (!handler.isAvailable) {
            _logWarning('Permission not available on this platform');
            return AppPermissionStatus.unknown;
          }
          
          // Request permission
          final status = await handler.request();
          
          // Update cache
          _updateCache(permission, status);
          
          // Notify listeners
          _notifyPermissionChange(
            permission, 
            cachedStatus ?? AppPermissionStatus.unknown,
            status
          );
          
          _log('Permission request result via coordinator', {
            'type': permission.toString(),
            'status': status.toString(),
          });
          
          return status;
        } catch (e) {
          _logError('Error in permission request', e);
          return AppPermissionStatus.unknown;
        }
      },
    );
  }
  
  @override
  Future<PermissionBatchResult> requestMultiplePermissions({
    required List<AppPermissionType> permissions,
    Function(PermissionProgress)? onProgress,
    bool showExplanationDialog = true,
  }) async {
    _log('Requesting multiple permissions via coordinator', {
      'permissions': permissions.map((p) => p.toString()).toList()
    });
    
    // Filter supported permissions
    final supportedPermissions = permissions.where((p) {
      final handler = PermissionHandlerFactory.getHandler(p);
      return handler != null && handler.isAvailable;
    }).toList();
    
    if (supportedPermissions.isEmpty) {
      _logWarning('No supported permissions');
      return PermissionBatchResult(
        results: {},
        allGranted: false,
        deniedPermissions: permissions,
      );
    }
    
    // Show explanation dialog if needed
    if (showExplanationDialog && _context != null) {
      final shouldContinue = await PermissionDialogs.showExplanation(
        context: _context!,
        permissions: supportedPermissions,
      );
      
      if (!shouldContinue) {
        _log('User cancelled permission request');
        return PermissionBatchResult.cancelled();
      }
    }
    
    // استخدام Coordinator للطلبات المتعددة
    final results = await _coordinator.requestMultiplePermissions(
      supportedPermissions,
      (permission) => requestPermission(permission),
    );
    
    // Send progress updates
    int i = 0;
    for (final permission in supportedPermissions) {
      i++;
      onProgress?.call(PermissionProgress(
        current: i,
        total: supportedPermissions.length,
        currentPermission: permission,
      ));
    }
    
    // Calculate results
    final deniedPermissions = results.entries
        .where((e) => e.value != AppPermissionStatus.granted)
        .map((e) => e.key)
        .toList();
    
    return PermissionBatchResult(
      results: results,
      allGranted: deniedPermissions.isEmpty,
      deniedPermissions: deniedPermissions,
    );
  }
  
  @override
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission) async {
    // Check cache first
    final cachedStatus = _getCachedStatus(permission);
    if (cachedStatus != null && _isCacheValid()) {
      return cachedStatus;
    }
    
    // استخدام Coordinator للفحص
    return await _coordinator.checkPermission(
      permission,
      () async {
        final handler = PermissionHandlerFactory.getHandler(permission);
        if (handler == null) {
          _logWarning('Unsupported permission type for check');
          return AppPermissionStatus.unknown;
        }
        
        try {
          // Check availability
          if (!handler.isAvailable) {
            return AppPermissionStatus.unknown;
          }
          
          // Check status
          final status = await handler.check();
          
          // Update cache
          _updateCache(permission, status);
          
          return status;
        } catch (e) {
          _logError('Error checking permission status', e);
          return AppPermissionStatus.unknown;
        }
      },
    );
  }
  
  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    // فحص الأذونات الحرجة فقط لتحسين الأداء
    final criticalPermissions = PermissionConstants.criticalPermissions;
    
    _log('Checking critical permissions via coordinator');
    
    // استخدام coordinator للفحص المتعدد
    return await _coordinator.checkMultiplePermissions(
      criticalPermissions,
      (permission) => checkPermissionStatus(permission),
    );
  }
  
  @override
  Future<bool> openAppSettings() async {
    _log('Opening app settings');
    
    try {
      return await handler.openAppSettings();
    } catch (e) {
      _logError('Error opening settings', e);
      return false;
    }
  }
  
  @override
  String getPermissionDescription(AppPermissionType permission) {
    return PermissionConstants.getDescription(permission);
  }
  
  @override
  String getPermissionName(AppPermissionType permission) {
    return PermissionConstants.getName(permission);
  }
  
  @override
  Stream<PermissionChange> get permissionChanges => _permissionChangeController.stream;
  
  @override
  void clearPermissionCache() {
    _statusCache.clear();
    _lastCacheUpdate = null;
    _coordinator.reset(); // إعادة تعيين Coordinator أيضاً
    _log('Permission cache and coordinator cleared');
  }
  
  @override
  Future<void> dispose() async {
    await _permissionChangeController.close();
    clearPermissionCache();
    _log('Permission service disposed');
  }
  
  // ==================== Private Methods ====================
  
  AppPermissionStatus? _getCachedStatus(AppPermissionType permission) {
    if (!_isCacheValid()) {
      clearPermissionCache();
      return null;
    }
    return _statusCache[permission];
  }
  
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiration;
  }
  
  void _updateCache(AppPermissionType permission, AppPermissionStatus status) {
    _statusCache[permission] = status;
    _lastCacheUpdate = DateTime.now();
    _saveCacheToStorage();
  }
  
  void _saveCacheToStorage() {
    try {
      final cacheData = <String, String>{};
      _statusCache.forEach((key, value) {
        cacheData[key.toString()] = value.toString();
      });
      _storage.setMap('permission_cache', cacheData);
    } catch (e) {
      _logWarning('Error saving permission cache');
    }
  }
  
  void _loadCachedStatuses() {
    try {
      final cached = _storage.getMap('permission_cache');
      if (cached != null) {
        cached.forEach((key, value) {
          try {
            final permission = AppPermissionType.values.firstWhere(
              (p) => p.toString() == key,
            );
            final status = AppPermissionStatus.values.firstWhere(
              (s) => s.toString() == value,
            );
            _statusCache[permission] = status;
          } catch (e) {
            // Ignore parsing errors
          }
        });
        _lastCacheUpdate = DateTime.now();
      }
    } catch (e) {
      _logWarning('Error loading permission cache');
    }
  }
  
  void _notifyPermissionChange(
    AppPermissionType permission,
    AppPermissionStatus oldStatus,
    AppPermissionStatus newStatus,
  ) {
    if (oldStatus != newStatus) {
      _permissionChangeController.add(PermissionChange(
        permission: permission,
        oldStatus: oldStatus,
        newStatus: newStatus,
        timestamp: DateTime.now(),
      ));
    }
  }

  // ==================== Simple Logging Methods ====================

  void _log(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
    }
  }

  void _logWarning(String message) {
    if (kDebugMode) {
    }
  }

  void _logError(String message, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      if (stackTrace != null) {
      }
    }
  }
}