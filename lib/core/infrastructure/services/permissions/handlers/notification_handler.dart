// lib/core/infrastructure/services/permissions/handlers/notification_handler.dart
// ✅ Handler محسّن للإشعارات فقط

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import '../permission_service.dart';
import 'permission_handler_base.dart';

/// Handler محسّن للإشعارات
class NotificationPermissionHandler extends PermissionHandlerBase {
  @override
  handler.Permission? get nativePermission => handler.Permission.notification;
  
  @override
  AppPermissionType get permissionType => AppPermissionType.notification;
  
  @override
  bool get isAvailable => true;
  
  @override
  Future<AppPermissionStatus> request() async {
    try {
      debugPrint('🔔 [NotificationHandler] Requesting notification permission...');
      
      // فحص الحالة الحالية أولاً
      final currentStatus = await nativePermission!.status;
      if (currentStatus.isGranted || currentStatus.isLimited || currentStatus.isProvisional) {
        debugPrint('✅ [NotificationHandler] Permission already granted');
        return AppPermissionStatus.granted;
      }
      
      // طلب الإذن
      final status = await nativePermission!.request();
      
      debugPrint('🔔 [NotificationHandler] Permission status: ${status.toString()}');
      
      // معالجة خاصة لـ Android
      if (Platform.isAndroid) {
        // على Android 13+ (API 33+)
        if (status.isGranted || status.isLimited || status.isProvisional) {
          return AppPermissionStatus.granted;
        }
        
        if (status.isPermanentlyDenied) {
          return AppPermissionStatus.permanentlyDenied;
        }
        
        if (status.isDenied) {
          return AppPermissionStatus.denied;
        }
        
        if (status.isRestricted) {
          return AppPermissionStatus.restricted;
        }
        
        // على Android القديم (< API 33)، الإشعارات مفعلة افتراضياً
        return AppPermissionStatus.granted;
      }
      
      // للمنصات الأخرى
      return mapFromNativeStatus(status);
      
    } catch (e) {
      debugPrint('❌ [NotificationHandler] Error requesting permission: $e');
      
      // في حالة الخطأ على Android القديم، نفترض أن الإشعارات مفعلة
      if (Platform.isAndroid) {
        return AppPermissionStatus.granted;
      }
      
      return AppPermissionStatus.unknown;
    }
  }
  
  @override
  Future<AppPermissionStatus> check() async {
    try {
      debugPrint('🔍 [NotificationHandler] Checking notification permission...');
      
      final status = await nativePermission!.status;
      
      debugPrint('🔍 [NotificationHandler] Current status: ${status.toString()}');
      
      // معالجة خاصة لـ Android
      if (Platform.isAndroid) {
        if (status.isGranted || status.isLimited || status.isProvisional) {
          return AppPermissionStatus.granted;
        }
        
        if (status.isPermanentlyDenied) {
          return AppPermissionStatus.permanentlyDenied;
        }
        
        if (status.isDenied) {
          // التحقق من إصدار Android
          // على Android القديم، قد تكون الإشعارات مفعلة رغم حالة denied
          return AppPermissionStatus.denied;
        }
        
        if (status.isRestricted) {
          return AppPermissionStatus.restricted;
        }
        
        // افتراضياً على Android القديم
        return AppPermissionStatus.granted;
      }
      
      // للمنصات الأخرى
      return mapFromNativeStatus(status);
      
    } catch (e) {
      debugPrint('❌ [NotificationHandler] Error checking permission: $e');
      
      // في حالة الخطأ على Android القديم
      if (Platform.isAndroid) {
        return AppPermissionStatus.granted;
      }
      
      return AppPermissionStatus.unknown;
    }
  }
}