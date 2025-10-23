// lib/core/infrastructure/services/permissions/legacy_permission_stub.dart
// Stub بسيط للتوافق مع الخدمات القديمة

import 'dart:async';
import 'permission_service.dart';

/// Stub بسيط للتوافق مع الخدمات التي تحتاج PermissionService القديم
class LegacyPermissionStub implements PermissionService {
  
  @override
  Future<AppPermissionStatus> requestPermission(AppPermissionType permission) async {
    // نرجع granted دائماً لأن النظام الجديد سيتولى الأمر
    return AppPermissionStatus.granted;
  }

  @override
  Future<AppPermissionStatus> checkPermissionStatus(AppPermissionType permission) async {
    // نرجع granted دائماً لأن النظام الجديد سيتولى الأمر
    return AppPermissionStatus.granted;
  }

  @override
  Future<PermissionBatchResult> requestMultiplePermissions({
    required List<AppPermissionType> permissions,
    Function(PermissionProgress)? onProgress,
    bool showExplanationDialog = true,
  }) async {
    final results = <AppPermissionType, AppPermissionStatus>{};
    for (final permission in permissions) {
      results[permission] = AppPermissionStatus.granted;
    }
    
    return PermissionBatchResult(
      results: results,
      allGranted: true,
      deniedPermissions: [],
    );
  }

  @override
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllPermissions() async {
    return {
      AppPermissionType.notification: AppPermissionStatus.granted,
      AppPermissionType.location: AppPermissionStatus.granted,
    };
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  String getPermissionDescription(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.notification:
        return 'الإشعارات';
      case AppPermissionType.location:
        return 'الموقع';
    }
  }

  @override
  String getPermissionName(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.notification:
        return 'الإشعارات';
      case AppPermissionType.location:
        return 'الموقع';
    }
  }

  @override
  Future<bool> checkNotificationPermission() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Stream<PermissionChange> get permissionChanges => const Stream.empty();

  @override
  void clearPermissionCache() {}

  @override
  Future<void> dispose() async {}
}