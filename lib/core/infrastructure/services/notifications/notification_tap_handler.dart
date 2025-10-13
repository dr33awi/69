// lib/core/infrastructure/services/notifications/notification_tap_handler.dart

import 'package:flutter/material.dart';
import 'models/notification_models.dart';

/// معالج النقر على الإشعارات
/// يقوم بتوجيه المستخدم للصفحة المناسبة حسب نوع الإشعار
class NotificationTapHandler {
  final GlobalKey<NavigatorState> navigatorKey;
  
  NotificationTapHandler({required this.navigatorKey});
  
  /// معالجة حدث النقر على الإشعار
  Future<void> handleNotificationTap(NotificationTapEvent event) async {
    debugPrint('[NotificationTapHandler] تم الضغط على إشعار:');
    debugPrint('  - ID: ${event.notificationId}');
    debugPrint('  - Category: ${event.category}');
    debugPrint('  - Payload: ${event.payload}');
    
    // الانتظار قليلاً للتأكد من جاهزية التطبيق
    await Future.delayed(const Duration(milliseconds: 300));
    
    // التحقق من جاهزية Navigator
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      debugPrint('[NotificationTapHandler] Context غير متاح، إعادة المحاولة...');
      await Future.delayed(const Duration(milliseconds: 500));
      return handleNotificationTap(event);
    }
    
    // توجيه المستخدم حسب نوع الإشعار
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
    debugPrint('[NotificationTapHandler] معالجة إشعار صلاة');
    
    try {
      // استخراج معلومات الصلاة من payload
      final prayerName = event.payload['prayer'] as String?;
      final arabicName = event.payload['arabicName'] as String?;
      
      if (prayerName == null) {
        debugPrint('[NotificationTapHandler] لا توجد معلومات صلاة في payload');
        _navigateToPrayerTimesHome(context);
        return;
      }
      
      // الانتقال لصفحة مواقيت الصلاة
      _navigateToPrayerTimesHome(context);
      
      // يمكنك إضافة المزيد من المنطق هنا:
      // - عرض تفاصيل الصلاة
      // - عرض dialog بمعلومات إضافية
      // - تسجيل أداء الصلاة
      
    } catch (e) {
      debugPrint('[NotificationTapHandler] خطأ في معالجة إشعار الصلاة: $e');
      _navigateToPrayerTimesHome(context);
    }
  }
  
  /// معالجة إشعارات الأذكار
  Future<void> _handleAthkarNotification(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    debugPrint('[NotificationTapHandler] معالجة إشعار أذكار');
    
    try {
      // استخراج معلومات الأذكار من payload
      final categoryId = event.payload['categoryId'] as String?;
      final categoryName = event.payload['categoryName'] as String?;
      
      if (categoryId == null) {
        debugPrint('[NotificationTapHandler] لا توجد معلومات فئة في payload');
        _navigateToAthkarHome(context);
        return;
      }
      
      // الانتقال لصفحة قراءة الأذكار مباشرة
      _navigateToAthkarReading(context, categoryId);
      
    } catch (e) {
      debugPrint('[NotificationTapHandler] خطأ في معالجة إشعار الأذكار: $e');
      _navigateToAthkarHome(context);
    }
  }
  
  /// معالجة إشعارات القرآن
  Future<void> _handleQuranNotification(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    debugPrint('[NotificationTapHandler] معالجة إشعار قرآن');
    
    // الانتقال لصفحة القرآن
    _navigateToQuran(context);
  }
  
  /// معالجة التذكيرات العامة
  Future<void> _handleReminderNotification(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    debugPrint('[NotificationTapHandler] معالجة تذكير عام');
    
    // يمكنك إضافة منطق مخصص هنا
    // مثلاً: عرض الصفحة الرئيسية
  }
  
  /// معالجة إشعارات النظام
  Future<void> _handleSystemNotification(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    debugPrint('[NotificationTapHandler] معالجة إشعار نظام');
    
    final type = event.payload['type'] as String?;
    
    switch (type) {
      case 'achievement':
        // عرض صفحة الإنجازات
        break;
        
      case 'motivational':
        // عرض الصفحة الرئيسية
        break;
        
      case 'daily_tip':
        // عرض صفحة النصائح أو الإعدادات
        _navigateToSettings(context);
        break;
        
      default:
        // عرض الصفحة الرئيسية
        break;
    }
  }
  
  // ==================== دوال التنقل ====================
  
  /// الانتقال لصفحة مواقيت الصلاة الرئيسية
  void _navigateToPrayerTimesHome(BuildContext context) {
    try {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/prayer-times', // AppRouter.prayerTimes
        (route) => route.settings.name == '/home',
      );
    } catch (e) {
      debugPrint('[NotificationTapHandler] خطأ في التنقل لصفحة الصلاة: $e');
    }
  }
  
  /// الانتقال لصفحة الأذكار الرئيسية
  void _navigateToAthkarHome(BuildContext context) {
    try {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/athkar', // AppRouter.athkar
        (route) => route.settings.name == '/home',
      );
    } catch (e) {
      debugPrint('[NotificationTapHandler] خطأ في التنقل لصفحة الأذكار: $e');
    }
  }
  
  /// الانتقال لصفحة قراءة أذكار معينة
  void _navigateToAthkarReading(BuildContext context, String categoryId) {
    try {
      // استخدام named route '/athkar-details' مع arguments
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/athkar-details', // AppRouter.athkarDetails
        (route) => route.settings.name == '/home',
        arguments: categoryId, // يمرر categoryId مباشرة
      );
    } catch (e) {
      debugPrint('[NotificationTapHandler] خطأ في التنقل لقراءة الأذكار: $e');
      _navigateToAthkarHome(context);
    }
  }
  
  /// الانتقال لصفحة القرآن
  void _navigateToQuran(BuildContext context) {
    try {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/quran', // AppRouter.quran
        (route) => route.settings.name == '/home',
      );
    } catch (e) {
      debugPrint('[NotificationTapHandler] خطأ في التنقل لصفحة القرآن: $e');
    }
  }
  
  /// الانتقال لصفحة الإعدادات
  void _navigateToSettings(BuildContext context) {
    try {
      Navigator.of(context).pushNamed('/settings'); // AppRouter.settings
    } catch (e) {
      debugPrint('[NotificationTapHandler] خطأ في التنقل لصفحة الإعدادات: $e');
    }
  }
  
  /// الانتقال للصفحة الرئيسية
  void _navigateToHome(BuildContext context) {
    try {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home', // AppRouter.home
        (route) => false,
      );
    } catch (e) {
      debugPrint('[NotificationTapHandler] خطأ في التنقل للصفحة الرئيسية: $e');
    }
  }
  
  // ==================== دوال مساعدة ====================
  
  /// عرض dialog بمعلومات الإشعار (للتطوير/التصحيح)
  Future<void> _showNotificationDialog(
    BuildContext context,
    NotificationTapEvent event,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات الإشعار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('النوع: ${event.category}'),
            const SizedBox(height: 8),
            Text('المعرف: ${event.notificationId}'),
            const SizedBox(height: 8),
            Text('البيانات: ${event.payload}'),
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