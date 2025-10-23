// lib/core/infrastructure/services/permissions/simple_permission_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart' as app_settings;

/// خدمة أذونات مبسطة
class SimplePermissionService {
  static final SimplePermissionService _instance = SimplePermissionService._internal();
  factory SimplePermissionService() => _instance;
  SimplePermissionService._internal();

  // Stream controller للإشعار بالتغييرات
  final StreamController<PermissionChange> _changeController = 
      StreamController<PermissionChange>.broadcast();

  // Cache للحالات
  final Map<PermissionType, bool> _statusCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// الحصول على stream التغييرات
  Stream<PermissionChange> get permissionChanges => _changeController.stream;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    debugPrint('🔐 SimplePermissionService initialized');
  }

  /// فحص الأذونات عند العودة للتطبيق
  Future<PermissionResults> checkPermissionsOnResume() async {
    debugPrint('🔄 Checking permissions on resume');
    clearCache();
    
    try {
      final notificationStatus = await Permission.notification.status;
      final notificationGranted = notificationStatus.isGranted;
      _updateCache(PermissionType.notification, notificationGranted);
      _notifyChange(PermissionType.notification, notificationGranted);
      
      final locationStatus = await Permission.locationWhenInUse.status;
      final locationGranted = locationStatus.isGranted;
      _updateCache(PermissionType.location, locationGranted);
      _notifyChange(PermissionType.location, locationGranted);
      
      debugPrint('📱 Notification permission: $notificationGranted');
      debugPrint('📍 Location permission: $locationGranted');
      
      return PermissionResults(
        notification: notificationGranted,
        location: locationGranted,
      );
    } catch (e) {
      debugPrint('❌ Error checking permissions on resume: $e');
      return const PermissionResults(notification: false, location: false);
    }
  }

  /// طلب إذن الإشعارات
  Future<bool> requestNotificationPermission(BuildContext context) async {
    try {
      debugPrint('📱 Requesting notification permission...');
      
      final currentStatus = await Permission.notification.status;
      
      if (currentStatus.isGranted) {
        _updateCache(PermissionType.notification, true);
        return true;
      }
      
      if (currentStatus.isPermanentlyDenied) {
        if (context.mounted) {
          final shouldOpenSettings = await _showPermanentlyDeniedDialog(
            context,
            'الإشعارات',
            'تم رفض إذن الإشعارات نهائياً. يرجى تفعيله من إعدادات التطبيق.',
          );
          
          if (shouldOpenSettings) {
            await app_settings.AppSettings.openAppSettings();
            await Future.delayed(const Duration(seconds: 1));
            final newStatus = await Permission.notification.status;
            final result = newStatus.isGranted;
            _updateCache(PermissionType.notification, result);
            _notifyChange(PermissionType.notification, result);
            return result;
          }
        }
        return false;
      }
      
      final status = await Permission.notification.request();
      final result = status.isGranted;
      
      _updateCache(PermissionType.notification, result);
      _notifyChange(PermissionType.notification, result);
      
      debugPrint('📱 Notification permission result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// طلب إذن الموقع
  Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      debugPrint('📍 Requesting location permission...');
      
      final currentStatus = await Permission.locationWhenInUse.status;
      
      if (currentStatus.isGranted) {
        _updateCache(PermissionType.location, true);
        return true;
      }
      
      if (currentStatus.isPermanentlyDenied) {
        if (context.mounted) {
          final shouldOpenSettings = await _showPermanentlyDeniedDialog(
            context,
            'الموقع',
            'تم رفض إذن الموقع نهائياً. يرجى تفعيله من إعدادات التطبيق.',
          );
          
          if (shouldOpenSettings) {
            await app_settings.AppSettings.openAppSettings();
            await Future.delayed(const Duration(seconds: 1));
            final newStatus = await Permission.locationWhenInUse.status;
            final result = newStatus.isGranted;
            _updateCache(PermissionType.location, result);
            _notifyChange(PermissionType.location, result);
            return result;
          }
        }
        return false;
      }
      
      final serviceStatus = await Permission.location.serviceStatus;
      if (!serviceStatus.isEnabled) {
        if (context.mounted) {
          final shouldOpenSettings = await _showServiceDisabledDialog(
            context,
            'خدمة الموقع معطلة',
            'يرجى تفعيل خدمة الموقع في الجهاز للاستمرار.',
          );
          
          if (shouldOpenSettings) {
            await app_settings.AppSettings.openAppSettings();
            await Future.delayed(const Duration(seconds: 1));
          }
        }
        return false;
      }
      
      final status = await Permission.locationWhenInUse.request();
      final result = status.isGranted;
      
      _updateCache(PermissionType.location, result);
      _notifyChange(PermissionType.location, result);
      
      debugPrint('📍 Location permission result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      return false;
    }
  }

  /// فحص إذن الإشعارات
  Future<bool> checkNotificationPermission() async {
    final cached = _getCachedStatus(PermissionType.notification);
    if (cached != null) return cached;

    try {
      final status = await Permission.notification.status;
      final result = status.isGranted;
      _updateCache(PermissionType.notification, result);
      return result;
    } catch (e) {
      debugPrint('❌ Error checking notification permission: $e');
      return false;
    }
  }

  /// فحص إذن الموقع
  Future<bool> checkLocationPermission() async {
    final cached = _getCachedStatus(PermissionType.location);
    if (cached != null) return cached;

    try {
      final status = await Permission.locationWhenInUse.status;
      final result = status.isGranted;
      _updateCache(PermissionType.location, result);
      return result;
    } catch (e) {
      debugPrint('❌ Error checking location permission: $e');
      return false;
    }
  }

  /// فحص جميع الأذونات
  Future<PermissionResults> checkAllPermissions() async {
    final notificationGranted = await checkNotificationPermission();
    final locationGranted = await checkLocationPermission();
    
    return PermissionResults(
      notification: notificationGranted,
      location: locationGranted,
    );
  }

  /// طلب جميع الأذونات
  Future<PermissionResults> requestAllPermissions(BuildContext context) async {
    debugPrint('🔐 Requesting all critical permissions...');
    
    final notificationGranted = await requestNotificationPermission(context);
    await Future.delayed(const Duration(milliseconds: 500));
    final locationGranted = await requestLocationPermission(context);
    
    final results = PermissionResults(
      notification: notificationGranted,
      location: locationGranted,
    );
    
    debugPrint('🔐 All permissions result: ${results.allGranted}');
    return results;
  }

  /// فتح إعدادات التطبيق
  Future<bool> openAppSettings() async {
    try {
      await app_settings.AppSettings.openAppSettings();
      return true;
    } catch (e) {
      debugPrint('❌ Error opening app settings: $e');
      return false;
    }
  }

  /// فتح إعدادات الإشعارات
  Future<bool> openNotificationSettings() async {
    try {
      await app_settings.AppSettings.openAppSettings();
      return true;
    } catch (e) {
      debugPrint('❌ Error opening notification settings: $e');
      return false;
    }
  }

  /// فتح إعدادات الموقع
  Future<bool> openLocationSettings() async {
    try {
      await app_settings.AppSettings.openAppSettings();
      return true;
    } catch (e) {
      debugPrint('❌ Error opening location settings: $e');
      return false;
    }
  }

  /// تنظيف الـ cache
  void clearCache() {
    _statusCache.clear();
    _lastCacheUpdate = null;
    debugPrint('🧹 Permission cache cleared');
  }

  /// تنظيف الموارد
  void dispose() {
    _changeController.close();
    clearCache();
  }

  // ==================== Private Methods ====================

  bool? _getCachedStatus(PermissionType type) {
    if (!_isCacheValid()) {
      clearCache();
      return null;
    }
    return _statusCache[type];
  }

  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiration;
  }

  void _updateCache(PermissionType type, bool granted) {
    _statusCache[type] = granted;
    _lastCacheUpdate = DateTime.now();
  }

  void _notifyChange(PermissionType type, bool newStatus) {
    final change = PermissionChange(
      type: type,
      isGranted: newStatus,
      timestamp: DateTime.now(),
    );
    _changeController.add(change);
  }

  /// عرض dialog للأذونات المرفوضة نهائياً
  Future<bool> _showPermanentlyDeniedDialog(
    BuildContext context,
    String permissionName,
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text('إذن $permissionName مطلوب'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// عرض dialog لخدمة معطلة
  Future<bool> _showServiceDisabledDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    ) ?? false;
  }
}

// ==================== Models ====================

enum PermissionType {
  notification,
  location,
}

enum PermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  unknown,
}

class PermissionResults {
  final bool notification;
  final bool location;

  const PermissionResults({
    required this.notification,
    required this.location,
  });

  bool get allGranted => notification && location;
  bool get anyGranted => notification || location;
  
  int get grantedCount {
    int count = 0;
    if (notification) count++;
    if (location) count++;
    return count;
  }

  List<PermissionType> get deniedPermissions {
    final denied = <PermissionType>[];
    if (!notification) denied.add(PermissionType.notification);
    if (!location) denied.add(PermissionType.location);
    return denied;
  }

  @override
  String toString() {
    return 'PermissionResults(notification: $notification, location: $location)';
  }
}

class PermissionChange {
  final PermissionType type;
  final bool isGranted;
  final DateTime timestamp;

  const PermissionChange({
    required this.type,
    required this.isGranted,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PermissionChange(${type.name}: $isGranted at $timestamp)';
  }
}