// lib/core/infrastructure/services/notifications/pending_notification_handler.dart

import 'package:flutter/material.dart';
import 'models/notification_models.dart';
import 'notification_tap_handler.dart';
import '../../../../app/routes/app_router.dart';

/// معالج الإشعارات المعلقة عند فتح التطبيق
class PendingNotificationHandler {
  static final PendingNotificationHandler _instance = PendingNotificationHandler._internal();
  factory PendingNotificationHandler() => _instance;
  PendingNotificationHandler._internal();

  NotificationTapEvent? _pendingNotification;
  bool _isHandled = false;

  /// حفظ إشعار معلق للمعالجة لاحقاً
  void setPendingNotification(NotificationTapEvent event) {
    debugPrint('📥 [PendingNotificationHandler] حفظ إشعار معلق');
    debugPrint('   - Category: ${event.category}');
    debugPrint('   - Payload: ${event.payload}');
    _pendingNotification = event;
    _isHandled = false;
  }

  /// التحقق من وجود إشعار معلق
  bool hasPendingNotification() {
    return _pendingNotification != null && !_isHandled;
  }

  /// معالجة الإشعار المعلق
  Future<void> handlePendingNotification() async {
    if (_pendingNotification == null || _isHandled) {
      debugPrint('📭 [PendingNotificationHandler] لا يوجد إشعار معلق');
      return;
    }

    try {
      debugPrint('📤 [PendingNotificationHandler] معالجة الإشعار المعلق...');
      
      // الانتظار للتأكد من جاهزية التطبيق
      await Future.delayed(const Duration(milliseconds: 1000));

      // التحقق من جاهزية Navigator
      if (!_isNavigatorReady()) {
        debugPrint('⚠️ [PendingNotificationHandler] Navigator غير جاهز بعد');
        // سنحاول مرة أخرى
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!_isNavigatorReady()) {
          debugPrint('❌ [PendingNotificationHandler] فشل: Navigator غير جاهز');
          return;
        }
      }

      // إنشاء معالج وتنفيذ التنقل
      final handler = NotificationTapHandler(
        navigatorKey: AppRouter.navigatorKey,
      );

      await handler.handleNotificationTap(_pendingNotification!);
      
      // تعيين كمعالج
      _isHandled = true;
      debugPrint('✅ [PendingNotificationHandler] تم معالجة الإشعار بنجاح');

    } catch (e, stackTrace) {
      debugPrint('❌ [PendingNotificationHandler] خطأ في المعالجة: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// التحقق من جاهزية Navigator
  bool _isNavigatorReady() {
    try {
      final context = AppRouter.navigatorKey.currentContext;
      if (context == null) return false;
      if (!context.mounted) return false;
      
      final navigator = AppRouter.navigatorKey.currentState;
      if (navigator == null) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// مسح الإشعار المعلق
  void clearPendingNotification() {
    debugPrint('🗑️ [PendingNotificationHandler] مسح الإشعار المعلق');
    _pendingNotification = null;
    _isHandled = false;
  }

  /// الحصول على الإشعار المعلق
  NotificationTapEvent? getPendingNotification() {
    return _pendingNotification;
  }
}