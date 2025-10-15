// lib/core/infrastructure/services/permissions/permission_coordinator.dart
// منسق مركزي لمنع تضارب وتكرار طلبات الأذونات - محدث لحل مشكلة الطلبات

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'permission_service.dart';
import 'permission_constants.dart';

/// منسق مركزي لمنع تضارب طلبات الأذونات
/// يضمن عدم تكرار الطلبات ويدير التزامن بين المكونات المختلفة
class PermissionCoordinator {
  // Singleton pattern
  static final PermissionCoordinator _instance = PermissionCoordinator._internal();
  factory PermissionCoordinator() => _instance;
  PermissionCoordinator._internal() {
    _log('✅ Coordinator initialized');
  }
  
  // قائمة انتظار الطلبات المعلقة
  final Map<AppPermissionType, Completer<AppPermissionStatus>> _pendingRequests = {};
  
  // قائمة انتظار الفحوصات المعلقة
  final Map<AppPermissionType, Completer<AppPermissionStatus>> _pendingChecks = {};
  
  // تتبع آخر وقت طلب لكل إذن
  final Map<AppPermissionType, DateTime> _lastRequestTime = {};
  final Map<AppPermissionType, DateTime> _lastCheckTime = {};
  
  // تتبع آخر حالة لكل إذن
  final Map<AppPermissionType, AppPermissionStatus> _lastKnownStatus = {};
  
  // عداد للطلبات النشطة
  int _activeRequestsCount = 0;
  int _activeChecksCount = 0;
  
  // الحد الأقصى للطلبات المتزامنة
  static const int _maxConcurrentRequests = 1;
  static const int _maxConcurrentChecks = 3;
  
  // ==================== الدوال الرئيسية ====================
  
  /// طلب إذن مع منع التكرار والتضارب
  Future<AppPermissionStatus> requestPermission(
    AppPermissionType permission,
    Future<AppPermissionStatus> Function() requestFunction,
  ) async {
    // التحقق من Throttling - محسّن للسماح بالطلبات الضرورية
    if (_shouldThrottleRequest(permission)) {
      _log('⏱️ Request throttled for $permission');
      
      // إذا كان الإذن مرفوض، السماح بإعادة المحاولة بعد فترة قصيرة
      final lastStatus = _lastKnownStatus[permission];
      if (lastStatus != null && lastStatus != AppPermissionStatus.granted) {
        // إعادة تعيين وقت الطلب للسماح بمحاولة جديدة
        _lastRequestTime.remove(permission);
        _log('🔄 Resetting throttle for denied permission: $permission');
        // المتابعة مع الطلب
      } else {
        // إرجاع الحالة الأخيرة المعروفة
        return lastStatus ?? AppPermissionStatus.denied;
      }
    }
    
    // إذا كان هناك طلب معلق، انتظر نتيجته
    if (_pendingRequests.containsKey(permission)) {
      _log('⏳ Request already pending for $permission, waiting...');
      try {
        return await _pendingRequests[permission]!.future;
      } catch (e) {
        _log('❌ Pending request failed: $e');
        return AppPermissionStatus.unknown;
      }
    }
    
    // انتظار إذا تجاوزنا الحد الأقصى للطلبات المتزامنة
    while (_activeRequestsCount >= _maxConcurrentRequests) {
      _log('⏸️ Waiting for active requests to complete...');
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // إنشاء طلب جديد
    final completer = Completer<AppPermissionStatus>();
    _pendingRequests[permission] = completer;
    _activeRequestsCount++;
    
    try {
      _log('🚀 Starting new request for $permission');
      _lastRequestTime[permission] = DateTime.now();
      
      final result = await requestFunction();
      
      // حفظ آخر حالة معروفة
      _lastKnownStatus[permission] = result;
      
      _log('✅ Request completed for $permission: ${result.toString().split('.').last}');
      completer.complete(result);
      
      return result;
      
    } catch (e, stackTrace) {
      _log('❌ Request failed for $permission: $e');
      completer.completeError(e, stackTrace);
      rethrow;
      
    } finally {
      _pendingRequests.remove(permission);
      _activeRequestsCount--;
      _log('📊 Active requests count: $_activeRequestsCount');
    }
  }
  
  /// فحص حالة إذن مع منع التكرار
  Future<AppPermissionStatus> checkPermission(
    AppPermissionType permission,
    Future<AppPermissionStatus> Function() checkFunction,
  ) async {
    // التحقق من Throttling للفحص - أكثر تساهلاً من الطلبات
    if (_shouldThrottleCheck(permission)) {
      _log('⏱️ Check throttled for $permission');
      // إرجاع آخر حالة معروفة أو unknown
      return _lastKnownStatus[permission] ?? AppPermissionStatus.unknown;
    }
    
    // إذا كان هناك فحص معلق، انتظر نتيجته
    if (_pendingChecks.containsKey(permission)) {
      _log('⏳ Check already pending for $permission, waiting...');
      try {
        return await _pendingChecks[permission]!.future;
      } catch (e) {
        _log('❌ Pending check failed: $e');
        return AppPermissionStatus.unknown;
      }
    }
    
    // انتظار إذا تجاوزنا الحد الأقصى للفحوصات المتزامنة
    while (_activeChecksCount >= _maxConcurrentChecks) {
      _log('⏸️ Waiting for active checks to complete...');
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    // إنشاء فحص جديد
    final completer = Completer<AppPermissionStatus>();
    _pendingChecks[permission] = completer;
    _activeChecksCount++;
    
    try {
      _log('🔍 Starting check for $permission');
      _lastCheckTime[permission] = DateTime.now();
      
      final result = await checkFunction();
      
      // حفظ آخر حالة معروفة
      _lastKnownStatus[permission] = result;
      
      _log('✅ Check completed for $permission: ${result.toString().split('.').last}');
      completer.complete(result);
      
      return result;
      
    } catch (e, stackTrace) {
      _log('❌ Check failed for $permission: $e');
      completer.completeError(e, stackTrace);
      rethrow;
      
    } finally {
      _pendingChecks.remove(permission);
      _activeChecksCount--;
    }
  }
  
  /// طلب أذونات متعددة بالتتابع المنظم
  Future<Map<AppPermissionType, AppPermissionStatus>> requestMultiplePermissions(
    List<AppPermissionType> permissions,
    Future<AppPermissionStatus> Function(AppPermissionType) requestFunction,
  ) async {
    _log('📱 Requesting ${permissions.length} permissions sequentially');
    
    final results = <AppPermissionType, AppPermissionStatus>{};
    
    // ترتيب الأذونات حسب الأولوية
    final sortedPermissions = PermissionConstants.sortByPriority(permissions);
    
    for (final permission in sortedPermissions) {
      try {
        // إعادة تعيين throttle للطلبات المتعددة
        _lastRequestTime.remove(permission);
        
        final result = await requestPermission(
          permission,
          () => requestFunction(permission),
        );
        results[permission] = result;
        
        // تأخير بسيط بين الطلبات
        if (sortedPermissions.last != permission) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
      } catch (e) {
        _log('❌ Failed to request $permission: $e');
        results[permission] = AppPermissionStatus.unknown;
      }
    }
    
    _log('✅ Batch request completed: ${results.length} permissions processed');
    return results;
  }
  
  /// فحص أذونات متعددة بالتوازي المحكم
  Future<Map<AppPermissionType, AppPermissionStatus>> checkMultiplePermissions(
    List<AppPermissionType> permissions,
    Future<AppPermissionStatus> Function(AppPermissionType) checkFunction,
  ) async {
    _log('🔍 Checking ${permissions.length} permissions in parallel');
    
    final futures = <Future<MapEntry<AppPermissionType, AppPermissionStatus>>>[];
    
    for (final permission in permissions) {
      futures.add(
        checkPermission(
          permission,
          () => checkFunction(permission),
        ).then((status) => MapEntry(permission, status))
        .catchError((error) {
          _log('❌ Error checking $permission: $error');
          return MapEntry(permission, AppPermissionStatus.unknown);
        }),
      );
    }
    
    final entries = await Future.wait(futures);
    final results = Map.fromEntries(entries);
    
    _log('✅ Batch check completed: ${results.length} permissions checked');
    return results;
  }
  
  // ==================== دوال مساعدة ====================
  
  /// التحقق من Throttling للطلب - محسّن
  bool _shouldThrottleRequest(AppPermissionType permission) {
    final lastRequest = _lastRequestTime[permission];
    if (lastRequest == null) return false;
    
    final timeSince = DateTime.now().difference(lastRequest);
    
    // إذا كان الإذن مرفوض، استخدم فترة أقصر للسماح بإعادة المحاولة
    final lastStatus = _lastKnownStatus[permission];
    if (lastStatus != null && lastStatus != AppPermissionStatus.granted) {
      // السماح بإعادة المحاولة بعد ثانيتين فقط للأذونات المرفوضة
      return timeSince < const Duration(seconds: 2);
    }
    
    // للأذونات الممنوحة أو غير المعروفة، استخدم الفترة العادية
    return timeSince < PermissionConstants.minRequestInterval;
  }
  
  /// التحقق من Throttling للفحص
  bool _shouldThrottleCheck(AppPermissionType permission) {
    final lastCheck = _lastCheckTime[permission];
    if (lastCheck == null) return false;
    
    final timeSince = DateTime.now().difference(lastCheck);
    return timeSince < PermissionConstants.minCheckInterval;
  }
  
  /// إلغاء جميع الطلبات المعلقة
  void cancelAllPendingRequests() {
    _log('🚫 Cancelling all pending requests');
    
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('Request cancelled');
      }
    }
    _pendingRequests.clear();
    
    for (final completer in _pendingChecks.values) {
      if (!completer.isCompleted) {
        completer.completeError('Check cancelled');
      }
    }
    _pendingChecks.clear();
    
    _activeRequestsCount = 0;
    _activeChecksCount = 0;
  }
  
  /// إعادة تعيين throttle لإذن محدد (للاستخدام عند الضرورة)
  void resetThrottleForPermission(AppPermissionType permission) {
    _log('🔄 Resetting throttle for $permission');
    _lastRequestTime.remove(permission);
    _lastCheckTime.remove(permission);
  }
  
  /// إعادة تعيين المنسق
  void reset() {
    _log('🔄 Resetting coordinator');
    
    cancelAllPendingRequests();
    _lastRequestTime.clear();
    _lastCheckTime.clear();
    _lastKnownStatus.clear();
  }
  
  /// الحصول على معلومات الحالة
  Map<String, dynamic> getStatus() {
    return {
      'pendingRequests': _pendingRequests.keys.map((p) => p.toString()).toList(),
      'pendingChecks': _pendingChecks.keys.map((p) => p.toString()).toList(),
      'activeRequests': _activeRequestsCount,
      'activeChecks': _activeChecksCount,
      'lastKnownStatuses': _lastKnownStatus.map((k, v) => MapEntry(k.toString(), v.toString())),
    };
  }
  
  // ==================== Logging ====================
  
  void _log(String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      debugPrint('🎯 [$timestamp] [PermissionCoordinator] $message');
    }
  }
}