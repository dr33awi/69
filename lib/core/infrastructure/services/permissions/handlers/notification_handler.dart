// lib/core/infrastructure/services/permissions/handlers/notification_handler.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import '../permission_service.dart';
import 'permission_handler_base.dart';

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
      // طلب الإذن مباشرة
      final status = await nativePermission!.request();
      // معالجة خاصة لـ Android
      if (Platform.isAndroid) {
        // إذا كانت الحالة granted أو limited أو provisional، نعتبرها مفعلة
        if (status.isGranted || status.isLimited || status.isProvisional) {
          return AppPermissionStatus.granted;
        }
        
        // إذا كانت permanentlyDenied
        if (status.isPermanentlyDenied) {
          return AppPermissionStatus.permanentlyDenied;
        }
        
        // إذا كانت denied
        if (status.isDenied) {
          return AppPermissionStatus.denied;
        }
        
        // إذا كانت restricted
        if (status.isRestricted) {
          return AppPermissionStatus.restricted;
        }
      }
      
      // للمنصات الأخرى أو الحالات العامة
      return mapFromNativeStatus(status);
      
    } catch (e) {
      // في حالة الخطأ على Android، قد يكون الجهاز لا يدعم runtime permissions
      if (Platform.isAndroid) {
        try {
          // محاولة فحص الحالة مباشرة
          final checkStatus = await nativePermission!.status;
          
          // على أجهزة Android القديمة، الإشعارات مفعلة افتراضياً
          if (checkStatus == handler.PermissionStatus.granted) {
            return AppPermissionStatus.granted;
          }
          
          return mapFromNativeStatus(checkStatus);
        } catch (e2) {
          // على Android القديم جداً، نفترض أن الإشعارات مفعلة
          return AppPermissionStatus.granted;
        }
      }
      
      return AppPermissionStatus.unknown;
    }
  }
  
  @override
  Future<AppPermissionStatus> check() async {
    try {
      final status = await nativePermission!.status;
      // معالجة خاصة لـ Android
      if (Platform.isAndroid) {
        // إذا كانت الحالة granted أو limited أو provisional، نعتبرها مفعلة
        if (status.isGranted || status.isLimited || status.isProvisional) {
          return AppPermissionStatus.granted;
        }
        
        // إذا كانت permanentlyDenied
        if (status.isPermanentlyDenied) {
          return AppPermissionStatus.permanentlyDenied;
        }
        
        // إذا كانت denied
        if (status.isDenied) {
          // على Android، قد تكون هذه أول مرة أو رفض مؤقت
          return AppPermissionStatus.denied;
        }
        
        // إذا كانت restricted
        if (status.isRestricted) {
          return AppPermissionStatus.restricted;
        }
      }
      
      // للمنصات الأخرى أو الحالات العامة
      return mapFromNativeStatus(status);
      
    } catch (e) {
      // في حالة الخطأ على Android القديم
      if (Platform.isAndroid) {
        // نفترض أن الإشعارات مفعلة على Android القديم
        return AppPermissionStatus.granted;
      }
      
      return AppPermissionStatus.unknown;
    }
  }
}