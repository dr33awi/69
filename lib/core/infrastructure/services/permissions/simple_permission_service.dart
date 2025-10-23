// lib/core/infrastructure/services/permissions/simple_permission_service.dart
// خدمة أذونات مبسطة باستخدام smart_permission

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_permission/smart_permission.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

/// خدمة أذونات مبسطة ونظيفة
class SimplePermissionService {
  static final SimplePermissionService _instance = SimplePermissionService._internal();
  factory SimplePermissionService() => _instance;
  SimplePermissionService._internal() {
    _setupSmartPermissionConfig();
  }

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

  /// إعداد SmartPermission بالتكوين المناسب
  void _setupSmartPermissionConfig() {
    SmartPermission.config
      ..titleProvider = (permission) {
        if (permission == Permission.notification) return 'أذونات الإشعارات';
        if (permission == Permission.locationWhenInUse) return 'أذونات الموقع';
        return null;
      }
      ..descriptionProvider = (permission) {
        if (permission == Permission.notification) {
          return 'نحتاج إذن الإشعارات لتذكيرك بمواقيت الصلاة والأذكار اليومية';
        }
        if (permission == Permission.locationWhenInUse) {
          return 'نحتاج إذن الموقع لحساب مواقيت الصلاة بدقة وتحديد اتجاه القبلة';
        }
        return null;
      };
  }

  /// طلب إذن الإشعارات مع context
  Future<bool> requestNotificationPermission(BuildContext context) async {
    try {
      debugPrint('📱 Requesting notification permission...');
      
      final result = await SmartPermission.request(
        context,
        permission: Permission.notification,
        style: PermissionDialogStyle.adaptive,
      );
      
      _updateCache(PermissionType.notification, result);
      _notifyChange(PermissionType.notification, result);
      
      debugPrint('📱 Notification permission result: $result');
      return result;
      
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// طلب إذن الموقع مع context
  Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      debugPrint('📍 Requesting location permission...');
      
      final result = await SmartPermission.request(
        context,
        permission: Permission.locationWhenInUse,
        style: PermissionDialogStyle.adaptive,
      );
      
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

  /// طلب جميع الأذونات الضرورية مع context
  Future<PermissionResults> requestAllPermissions(BuildContext context) async {
    debugPrint('🔐 Requesting all critical permissions...');
    
    final notificationGranted = await requestNotificationPermission(context);
    final locationGranted = await requestLocationPermission(context);
    
    final results = PermissionResults(
      notification: notificationGranted,
      location: locationGranted,
    );
    
    debugPrint('🔐 All permissions result: ${results.allGranted}');
    return results;
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

  /// طلب أذونات متعددة بطريقة مجمعة
  Future<PermissionResults> requestMultiplePermissions(BuildContext context) async {
    try {
      debugPrint('🔐 Requesting multiple permissions...');
      
      final result = await SmartPermission.requestMultiple(
        context,
        permissions: [
          Permission.notification,
          Permission.locationWhenInUse,
        ],
      );
      
      final notificationGranted = result[Permission.notification] ?? false;
      final locationGranted = result[Permission.locationWhenInUse] ?? false;
      
      // Update cache
      _updateCache(PermissionType.notification, notificationGranted);
      _updateCache(PermissionType.location, locationGranted);
      
      // Notify changes
      _notifyChange(PermissionType.notification, notificationGranted);
      _notifyChange(PermissionType.location, locationGranted);
      
      final results = PermissionResults(
        notification: notificationGranted,
        location: locationGranted,
      );
      
      debugPrint('🔐 Multiple permissions result: ${results.allGranted}');
      return results;
      
    } catch (e) {
      debugPrint('❌ Error requesting multiple permissions: $e');
      return const PermissionResults(notification: false, location: false);
    }
  }

  /// فتح إعدادات التطبيق 
  Future<bool> openAppSettings() async {
    try {
      // استخدام permission_handler مباشرة لفتح الإعدادات
      return await handler.openAppSettings();
    } catch (e) {
      debugPrint('❌ Error opening app settings: $e');
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
}

// ==================== Models ====================

/// نوع الإذن
enum PermissionType {
  notification,
  location,
}

/// نتائج فحص الأذونات
class PermissionResults {
  final bool notification;
  final bool location;

  const PermissionResults({
    required this.notification,
    required this.location,
  });

  /// هل جميع الأذونات مُمنوحة؟
  bool get allGranted => notification && location;

  /// هل أي إذن مُمنوح؟
  bool get anyGranted => notification || location;

  /// عدد الأذونات الممنوحة
  int get grantedCount {
    int count = 0;
    if (notification) count++;
    if (location) count++;
    return count;
  }

  /// قائمة الأذونات المرفوضة
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

/// تغيير في حالة الإذن
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

// ==================== Extensions ====================

/// توسيعات مفيدة لـ PermissionType
extension PermissionTypeExtension on PermissionType {
  /// اسم الإذن بالعربية
  String get arabicName {
    switch (this) {
      case PermissionType.notification:
        return 'الإشعارات';
      case PermissionType.location:
        return 'الموقع';
    }
  }

  /// وصف الإذن
  String get description {
    switch (this) {
      case PermissionType.notification:
        return 'لتذكيرك بمواقيت الصلاة والأذكار اليومية';
      case PermissionType.location:
        return 'لحساب مواقيت الصلاة بدقة وتحديد اتجاه القبلة';
    }
  }

  /// هل الإذن مهم؟
  bool get isCritical => true; // كل الأذونات الحالية مهمة
}