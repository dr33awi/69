// lib/core/infrastructure/services/permissions/permission_service.dart
// الخدمة الأساسية للتعامل مع أذونات النظام

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'permission_constants.dart';

/// الخدمة الأساسية للتعامل مع أذونات Android/iOS
/// 
/// توفر:
/// - فحص حالة الأذونات
/// - طلب الأذونات
/// - فتح إعدادات التطبيق
/// - معالجة الأذونات الخاصة
class PermissionService {
  int? _androidVersion;
  bool _isInitialized = false;

  PermissionService() {
    _initialize();
  }

  /// تهيئة الخدمة
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        _androidVersion = androidInfo.version.sdkInt;
        debugPrint('[PermissionService] Android SDK: $_androidVersion');
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('[PermissionService] Init error: $e');
    }
  }

  // ============== فحص الأذونات ==============

  /// فحص حالة إذن معين
  Future<AppPermissionStatus> checkPermissionStatus(
    AppPermissionType type,
  ) async {
    await _initialize();
    
    try {
      switch (type) {
        case AppPermissionType.location:
          return await _checkLocationPermission();
          
        case AppPermissionType.backgroundLocation:
          return await _checkBackgroundLocationPermission();
          
        case AppPermissionType.notification:
          return await _checkNotificationPermission();
          
        case AppPermissionType.exactAlarm:
          return await _checkExactAlarmPermission();
          
        case AppPermissionType.batteryOptimization:
          return await _checkBatteryOptimizationPermission();
          
        case AppPermissionType.systemAlertWindow:
          return await _checkSystemAlertWindowPermission();
      }
    } catch (e) {
      debugPrint('[PermissionService] Error checking ${type.name}: $e');
      return AppPermissionStatus.denied;
    }
  }

  /// فحص إذن الموقع
  Future<AppPermissionStatus> _checkLocationPermission() async {
    final status = await Permission.location.status;
    return _mapPermissionStatus(status);
  }

  /// فحص إذن الموقع في الخلفية
  Future<AppPermissionStatus> _checkBackgroundLocationPermission() async {
    if (!Platform.isAndroid || (_androidVersion != null && _androidVersion! < 29)) {
      return AppPermissionStatus.granted; // غير مطلوب في الإصدارات القديمة
    }
    
    final status = await Permission.locationAlways.status;
    return _mapPermissionStatus(status);
  }

  /// فحص إذن الإشعارات
  Future<AppPermissionStatus> _checkNotificationPermission() async {
    if (!Platform.isAndroid || (_androidVersion != null && _androidVersion! < 33)) {
      return AppPermissionStatus.granted; // غير مطلوب قبل Android 13
    }
    
    final status = await Permission.notification.status;
    return _mapPermissionStatus(status);
  }

  /// فحص إذن التنبيهات الدقيقة
  Future<AppPermissionStatus> _checkExactAlarmPermission() async {
    if (!Platform.isAndroid || (_androidVersion != null && _androidVersion! < 31)) {
      return AppPermissionStatus.granted; // غير مطلوب قبل Android 12
    }
    
    final status = await Permission.scheduleExactAlarm.status;
    return _mapPermissionStatus(status);
  }

  /// فحص إذن تحسين البطارية
  Future<AppPermissionStatus> _checkBatteryOptimizationPermission() async {
    if (!Platform.isAndroid) {
      return AppPermissionStatus.granted;
    }
    
    final status = await Permission.ignoreBatteryOptimizations.status;
    return _mapPermissionStatus(status);
  }

  /// فحص إذن النوافذ الطافية
  Future<AppPermissionStatus> _checkSystemAlertWindowPermission() async {
    if (!Platform.isAndroid) {
      return AppPermissionStatus.granted;
    }
    
    final status = await Permission.systemAlertWindow.status;
    return _mapPermissionStatus(status);
  }

  // ============== طلب الأذونات ==============

  /// طلب إذن معين
  Future<bool> requestPermission(AppPermissionType type) async {
    await _initialize();
    
    try {
      // فحص الحالة الحالية أولاً
      final currentStatus = await checkPermissionStatus(type);
      
      // إذا كان ممنوحاً بالفعل
      if (currentStatus == AppPermissionStatus.granted) {
        return true;
      }
      
      // إذا كان مرفوضاً بشكل دائم، افتح الإعدادات
      if (currentStatus == AppPermissionStatus.permanentlyDenied) {
        return await openAppSettings();
      }
      
      // طلب الإذن حسب النوع
      switch (type) {
        case AppPermissionType.location:
          return await _requestLocationPermission();
          
        case AppPermissionType.backgroundLocation:
          return await _requestBackgroundLocationPermission();
          
        case AppPermissionType.notification:
          return await _requestNotificationPermission();
          
        case AppPermissionType.exactAlarm:
          return await _requestExactAlarmPermission();
          
        case AppPermissionType.batteryOptimization:
          return await _requestBatteryOptimizationPermission();
          
        case AppPermissionType.systemAlertWindow:
          return await _requestSystemAlertWindowPermission();
      }
    } catch (e) {
      debugPrint('[PermissionService] Error requesting ${type.name}: $e');
      return false;
    }
  }

  /// طلب إذن الموقع
  Future<bool> _requestLocationPermission() async {
    final result = await Permission.location.request();
    debugPrint('[PermissionService] Location permission: $result');
    return result.isGranted;
  }

  /// طلب إذن الموقع في الخلفية
  Future<bool> _requestBackgroundLocationPermission() async {
    if (!Platform.isAndroid || (_androidVersion != null && _androidVersion! < 29)) {
      return true;
    }
    
    // يجب طلب إذن الموقع الأساسي أولاً
    final locationGranted = await _requestLocationPermission();
    if (!locationGranted) {
      debugPrint('[PermissionService] Basic location not granted, skipping background');
      return false;
    }
    
    // ثم طلب الموقع في الخلفية
    final result = await Permission.locationAlways.request();
    debugPrint('[PermissionService] Background location permission: $result');
    return result.isGranted;
  }

  /// طلب إذن الإشعارات
  Future<bool> _requestNotificationPermission() async {
    if (!Platform.isAndroid || (_androidVersion != null && _androidVersion! < 33)) {
      return true; // غير مطلوب في الإصدارات القديمة
    }
    
    final result = await Permission.notification.request();
    debugPrint('[PermissionService] Notification permission: $result');
    return result.isGranted;
  }

  /// طلب إذن التنبيهات الدقيقة
  Future<bool> _requestExactAlarmPermission() async {
    if (!Platform.isAndroid || (_androidVersion != null && _androidVersion! < 31)) {
      return true;
    }
    
    // هذا الإذن يحتاج فتح نافذة إعدادات خاصة
    final status = await Permission.scheduleExactAlarm.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // طلب الإذن (سيفتح نافذة الإعدادات)
    final result = await Permission.scheduleExactAlarm.request();
    debugPrint('[PermissionService] Exact alarm permission: $result');
    
    return result.isGranted;
  }

  /// طلب إذن تحسين البطارية
  Future<bool> _requestBatteryOptimizationPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    
    final result = await Permission.ignoreBatteryOptimizations.request();
    debugPrint('[PermissionService] Battery optimization permission: $result');
    return result.isGranted;
  }

  /// طلب إذن النوافذ الطافية
  Future<bool> _requestSystemAlertWindowPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    
    final result = await Permission.systemAlertWindow.request();
    debugPrint('[PermissionService] System alert window permission: $result');
    return result.isGranted;
  }

  // ============== الإعدادات ==============

  /// فتح إعدادات التطبيق
  Future<bool> openAppSettings() async {
    debugPrint('[PermissionService] Opening app settings');
    return await openAppSettings();
  }

  /// فتح إعدادات الموقع
  Future<bool> openLocationSettings() async {
    debugPrint('[PermissionService] Opening location settings');
    return await Permission.location.request().isGranted;
  }

  // ============== مساعدات ==============

  /// تحويل حالة الإذن من permission_handler إلى حالتنا المخصصة
  AppPermissionStatus _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return AppPermissionStatus.granted;
        
      case PermissionStatus.denied:
        return AppPermissionStatus.denied;
        
      case PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
        
      case PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
        
      case PermissionStatus.provisional:
        return AppPermissionStatus.provisional;
    }
  }

  /// فحص إذا كان الإذن مدعوماً
  bool isPermissionSupported(AppPermissionType type) {
    if (!Platform.isAndroid) return false;
    if (_androidVersion == null) return true;
    
    switch (type) {
      case AppPermissionType.notification:
        return _androidVersion! >= 33;
        
      case AppPermissionType.exactAlarm:
        return _androidVersion! >= 31;
        
      case AppPermissionType.backgroundLocation:
        return _androidVersion! >= 29;
        
      default:
        return true;
    }
  }

  /// الحصول على قائمة بجميع الأذونات المدعومة
  List<AppPermissionType> getSupportedPermissions() {
    return AppPermissionType.values.where((type) {
      return isPermissionSupported(type);
    }).toList();
  }

  /// فحص جميع الأذونات دفعة واحدة
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions(
    List<AppPermissionType> permissions,
  ) async {
    final results = <AppPermissionType, AppPermissionStatus>{};
    
    for (final permission in permissions) {
      results[permission] = await checkPermissionStatus(permission);
    }
    
    return results;
  }

  /// طلب عدة أذونات دفعة واحدة
  Future<Map<AppPermissionType, bool>> requestMultiplePermissions(
    List<AppPermissionType> permissions,
  ) async {
    final results = <AppPermissionType, bool>{};
    
    for (final permission in permissions) {
      results[permission] = await requestPermission(permission);
      
      // تأخير صغير بين الطلبات لتجنب إرباك المستخدم
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    return results;
  }

  // ============== الأذونات الخاصة ==============

  /// فحص إذا كان التطبيق لديه إذن رسم فوق التطبيقات (deprecated method)
  Future<bool> canDrawOverlays() async {
    if (!Platform.isAndroid) return true;
    
    final status = await Permission.systemAlertWindow.status;
    return status.isGranted;
  }

  /// فحص إذا كان التطبيق معفى من تحسين البطارية
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  /// فحص إذا كان يمكن جدولة تنبيهات دقيقة
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid || (_androidVersion != null && _androidVersion! < 31)) {
      return true;
    }
    
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  // ============== التشخيص ==============

  /// طباعة تقرير حالة جميع الأذونات
  Future<void> printPermissionsReport() async {
    debugPrint('');
    debugPrint('========== Permissions Status Report ==========');
    debugPrint('Platform: ${Platform.operatingSystem}');
    debugPrint('Android SDK: $_androidVersion');
    debugPrint('');
    
    for (final type in AppPermissionType.values) {
      if (isPermissionSupported(type)) {
        final status = await checkPermissionStatus(type);
        final emoji = status == AppPermissionStatus.granted ? '✅' : '❌';
        debugPrint('$emoji ${type.name}: $status');
      } else {
        debugPrint('⚪ ${type.name}: Not supported');
      }
    }
    
    debugPrint('===============================================');
    debugPrint('');
  }

  /// الحصول على ملخص الأذونات
  Future<Map<String, dynamic>> getPermissionsSummary() async {
    final summary = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'android_version': _androidVersion,
      'is_initialized': _isInitialized,
      'permissions': <String, dynamic>{},
    };
    
    for (final type in AppPermissionType.values) {
      if (isPermissionSupported(type)) {
        final status = await checkPermissionStatus(type);
        summary['permissions'][type.name] = {
          'status': status.toString(),
          'is_granted': status == AppPermissionStatus.granted,
          'supported': true,
        };
      } else {
        summary['permissions'][type.name] = {
          'status': 'not_supported',
          'is_granted': null,
          'supported': false,
        };
      }
    }
    
    return summary;
  }
}

// ============== Extensions ==============

/// امتدادات مفيدة لـ PermissionStatus
extension PermissionStatusExtension on PermissionStatus {
  bool get isAllowed => isGranted || isLimited;
  bool get isNotGranted => !isGranted;
  bool get needsManualSettings => isPermanentlyDenied;
}

/// امتدادات مفيدة لـ AppPermissionStatus
extension AppPermissionStatusExtension on AppPermissionStatus {
  bool get isAllowed => this == AppPermissionStatus.granted;
  bool get isNotGranted => this != AppPermissionStatus.granted;
  bool get needsManualSettings => this == AppPermissionStatus.permanentlyDenied;
  
  String get displayName {
    switch (this) {
      case AppPermissionStatus.granted:
        return 'ممنوح';
      case AppPermissionStatus.denied:
        return 'مرفوض';
      case AppPermissionStatus.permanentlyDenied:
        return 'مرفوض دائماً';
      case AppPermissionStatus.restricted:
        return 'محظور';
      case AppPermissionStatus.provisional:
        return 'مؤقت';
      case AppPermissionStatus.notDetermined:
        return 'غير محدد';
    }
  }
  
  IconData get icon {
    switch (this) {
      case AppPermissionStatus.granted:
        return Icons.check_circle;
      case AppPermissionStatus.denied:
        return Icons.cancel;
      case AppPermissionStatus.permanentlyDenied:
        return Icons.block;
      case AppPermissionStatus.restricted:
        return Icons.lock;
      case AppPermissionStatus.provisional:
        return Icons.schedule;
      case AppPermissionStatus.notDetermined:
        return Icons.help_outline;
    }
  }
  
  Color get color {
    switch (this) {
      case AppPermissionStatus.granted:
        return Colors.green;
      case AppPermissionStatus.denied:
        return Colors.orange;
      case AppPermissionStatus.permanentlyDenied:
        return Colors.red;
      case AppPermissionStatus.restricted:
        return Colors.grey;
      case AppPermissionStatus.provisional:
        return Colors.blue;
      case AppPermissionStatus.notDetermined:
        return Colors.grey;
    }
  }
}