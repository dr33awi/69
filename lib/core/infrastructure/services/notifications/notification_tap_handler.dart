// lib/core/infrastructure/services/notifications/notification_tap_handler.dart

import 'package:flutter/material.dart';
import 'models/notification_models.dart';

/// معالج النقر على الإشعارات - محسّن للعمل مع Cold Start
class NotificationTapHandler {
  final GlobalKey<NavigatorState> navigatorKey;
  
  // متغير لتخزين الإشعار إذا لم يكن Navigator جاهزاً
  static NotificationTapEvent? _pendingEvent;
  static bool _isProcessing = false;
  
  NotificationTapHandler({required this.navigatorKey});
  
  /// معالجة حدث النقر على الإشعار
  Future<void> handleNotificationTap(NotificationTapEvent event) async {
    // منع المعالجة المتعددة
    if (_isProcessing) {
      return;
    }
    
    _isProcessing = true;
    
    try {
      // محاولة المعالجة الفورية
      bool processed = await _tryProcessEvent(event);
      
      if (!processed) {
        _pendingEvent = event;
        
        // المحاولة عدة مرات مع فترات انتظار متزايدة
        for (int attempt = 1; attempt <= 10; attempt++) {
          await Future.delayed(Duration(milliseconds: 300 * attempt));
          
          if (await _tryProcessEvent(event)) {
            _pendingEvent = null;
            break;
          }
        }
        
        if (_pendingEvent != null) {
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
  
  /// محاولة معالجة الحدث
  Future<bool> _tryProcessEvent(NotificationTapEvent event) async {
    // فحص جاهزية Navigator
    final context = navigatorKey.currentContext;
    
    if (context == null || !context.mounted) {
      return false;
    }
    
    // فحص إذا كان Navigator جاهزاً للتنقل
    try {
      // اختبار بسيط للتأكد من جاهزية Navigator
      final canPop = Navigator.of(context).canPop();
    } catch (e) {
      return false;
    }
    
    // معالجة الإشعار حسب نوعه
    try {
      await _processEventByCategory(context, event);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// معالجة الحدث حسب الفئة
  Future<void> _processEventByCategory(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    // الانتظار قليلاً للتأكد من استقرار الواجهة
    await Future.delayed(const Duration(milliseconds: 100));
    
    switch (event.category) {
      case NotificationCategory.prayer:
        await _handlePrayerNotification(context, event);
        break;
        
      case NotificationCategory.athkar:
        await _handleAthkarNotification(context, event);
        break;
        
      case NotificationCategory.quran:
        await _handleQuranNotification(context, event);
        break;
        
      case NotificationCategory.reminder:
        await _handleReminderNotification(context, event);
        break;
        
      case NotificationCategory.system:
        await _handleSystemNotification(context, event);
        break;
    }
  }
  
  // ==================== معالجات الإشعارات المختلفة ====================
  
  /// معالجة إشعارات الصلاة
  Future<void> _handlePrayerNotification(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    try {
      final prayerName = event.payload['prayer'] as String?;
      final arabicName = event.payload['arabicName'] as String?;
      // التنقل لصفحة مواقيت الصلاة
      await _safeNavigate(
        context,
        '/prayer-times',
        clearStack: true,
      );
      
    } catch (e) {
      _navigateToHome(context);
    }
  }
  
  /// معالجة إشعارات الأذكار
  Future<void> _handleAthkarNotification(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    try {
      final categoryId = event.payload['categoryId'] as String?;
      final categoryName = event.payload['categoryName'] as String?;
      if (categoryId != null) {
        // الانتقال مباشرة لصفحة قراءة الأذكار
        await _safeNavigate(
          context,
          '/athkar-details',
          arguments: categoryId,
          clearStack: true,
        );
      } else {
        // الانتقال لصفحة الأذكار الرئيسية
        await _safeNavigate(
          context,
          '/athkar',
          clearStack: true,
        );
      }
      
    } catch (e) {
      _navigateToHome(context);
    }
  }
  
  /// معالجة إشعارات القرآن
  Future<void> _handleQuranNotification(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    await _safeNavigate(
      context,
      '/quran',
      clearStack: true,
    );
  }
  
  /// معالجة التذكيرات العامة
  Future<void> _handleReminderNotification(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    // الانتقال للصفحة الرئيسية
    _navigateToHome(context);
  }
  
  /// معالجة إشعارات النظام
  Future<void> _handleSystemNotification(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    final type = event.payload['type'] as String?;
    
    switch (type) {
      case 'achievement':
        await _safeNavigate(context, '/achievements');
        break;
        
      case 'daily_tip':
        await _safeNavigate(context, '/settings');
        break;
        
      default:
        _navigateToHome(context);
        break;
    }
  }
  
  // ==================== دوال التنقل الآمنة ====================
  
  /// تنقل آمن مع معالجة الأخطاء
  Future<void> _safeNavigate(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool clearStack = false,
  }) async {
    try {
      if (!context.mounted) {
        return;
      }
      
      if (clearStack) {
        // مسح الـ stack والانتقال للصفحة الجديدة
        await Navigator.of(context).pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      } else {
        // تنقل عادي
        await Navigator.of(context).pushNamed(
          routeName,
          arguments: arguments,
        );
      }
    } catch (e) {
      // في حالة الفشل، حاول الانتقال للصفحة الرئيسية
      try {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      } catch (homeError) {
      }
    }
  }
  
  /// الانتقال للصفحة الرئيسية
  void _navigateToHome(BuildContext context) {
    _safeNavigate(context, '/home', clearStack: true);
  }
  
  // ==================== دوال مساعدة ====================
  
  /// فحص إذا كان هناك حدث معلق
  static bool get hasPendingEvent => _pendingEvent != null;
  
  /// الحصول على الحدث المعلق
  static NotificationTapEvent? get pendingEvent => _pendingEvent;
  
  /// مسح الحدث المعلق
  static void clearPendingEvent() {
    _pendingEvent = null;
  }
  
  /// معالجة الحدث المعلق إن وجد
  Future<void> processPendingEvent() async {
    if (_pendingEvent != null) {
      final event = _pendingEvent!;
      _pendingEvent = null; // مسحه قبل المعالجة
      await handleNotificationTap(event);
    }
  }
  
  /// عرض dialog بمعلومات الإشعار (للتطوير/التصحيح)
  Future<void> _showNotificationDebugDialog(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    if (!context.mounted) return;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 معلومات الإشعار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('النوع: ${event.category}'),
            const SizedBox(height: 8),
            Text('المعرف: ${event.notificationId}'),
            const SizedBox(height: 8),
            Text('البيانات: ${event.payload}'),
            const SizedBox(height: 8),
            Text('الوقت: ${event.timestamp}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}