// lib/core/infrastructure/services/notifications/notification_tap_handler.dart

import 'package:flutter/material.dart';
import 'models/notification_models.dart';

/// معالج النقر على الإشعارات
class NotificationTapHandler {
  final GlobalKey<NavigatorState> navigatorKey;
  
  NotificationTapHandler({required this.navigatorKey});
  
  /// معالجة حدث النقر على الإشعار
  Future<void> handleNotificationTap(NotificationTapEvent event) async {
    debugPrint('[NotificationTapHandler] ========================================');
    debugPrint('[NotificationTapHandler] تم الضغط على إشعار:');
    debugPrint('  - ID: ${event.notificationId}');
    debugPrint('  - Category: ${event.category}');
    debugPrint('  - Payload: ${event.payload}');
    debugPrint('[NotificationTapHandler] ========================================');
    
    // الانتظار للتأكد من جاهزية التطبيق
    await Future.delayed(const Duration(milliseconds: 500));
    
    // التحقق من جاهزية Navigator
    if (!_isNavigatorReady()) {
      debugPrint('[NotificationTapHandler] ⚠️ Navigator غير جاهز، إعادة المحاولة...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!_isNavigatorReady()) {
        debugPrint('[NotificationTapHandler] ❌ Navigator لا يزال غير جاهز، إلغاء');
        return;
      }
    }
    
    debugPrint('[NotificationTapHandler] ✅ Navigator جاهز، بدء التنقل');
    
    // توجيه المستخدم حسب نوع الإشعار
    switch (event.category) {
      case NotificationCategory.prayer:
        await _handlePrayerNotification(event);
        break;
        
      case NotificationCategory.athkar:
        await _handleAthkarNotification(event);
        break;
        
      case NotificationCategory.quran:
        await _handleQuranNotification(event);
        break;
        
      case NotificationCategory.reminder:
        await _handleReminderNotification(event);
        break;
        
      case NotificationCategory.system:
        await _handleSystemNotification(event);
        break;
    }
  }
  
  /// التحقق من جاهزية Navigator
  bool _isNavigatorReady() {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) return false;
      if (!context.mounted) return false;
      
      final navigator = navigatorKey.currentState;
      if (navigator == null) return false;
      
      return true;
    } catch (e) {
      debugPrint('[NotificationTapHandler] خطأ في فحص Navigator: $e');
      return false;
    }
  }
  
  // ==================== معالجات الإشعارات المختلفة ====================
  
  /// معالجة إشعارات الصلاة
  Future<void> _handlePrayerNotification(NotificationTapEvent event) async {
    debugPrint('[NotificationTapHandler] 🕌 معالجة إشعار صلاة');
    
    try {
      final prayerName = event.payload['prayer'] as String?;
      final arabicName = event.payload['arabicName'] as String?;
      
      debugPrint('  - Prayer: $prayerName ($arabicName)');
      
      await _navigateToPrayerTimes();
      
    } catch (e) {
      debugPrint('[NotificationTapHandler] ❌ خطأ في معالجة إشعار الصلاة: $e');
      await _navigateToPrayerTimes();
    }
  }
  
  /// معالجة إشعارات الأذكار
  Future<void> _handleAthkarNotification(NotificationTapEvent event) async {
    debugPrint('[NotificationTapHandler] 📿 معالجة إشعار أذكار');
    
    try {
      final categoryId = event.payload['categoryId'] as String?;
      final categoryName = event.payload['categoryName'] as String?;
      
      debugPrint('  - Category ID: $categoryId');
      debugPrint('  - Category Name: $categoryName');
      
      if (categoryId != null && categoryId.isNotEmpty) {
        await _navigateToAthkarDetails(categoryId);
      } else {
        debugPrint('⚠️ Category ID is null, navigating to athkar home');
        await _navigateToAthkarHome();
      }
      
    } catch (e) {
      debugPrint('[NotificationTapHandler] ❌ خطأ في معالجة إشعار الأذكار: $e');
      await _navigateToAthkarHome();
    }
  }
  
  /// معالجة إشعارات القرآن
  Future<void> _handleQuranNotification(NotificationTapEvent event) async {
    debugPrint('[NotificationTapHandler] 📖 معالجة إشعار قرآن');
    await _navigateToQuran();
  }
  
  /// معالجة التذكيرات العامة
  Future<void> _handleReminderNotification(NotificationTapEvent event) async {
    debugPrint('[NotificationTapHandler] 🔔 معالجة تذكير عام');
    await _navigateToHome();
  }
  
  /// معالجة إشعارات النظام
  Future<void> _handleSystemNotification(NotificationTapEvent event) async {
    debugPrint('[NotificationTapHandler] ⚙️ معالجة إشعار نظام');
    
    final type = event.payload['type'] as String?;
    debugPrint('  - System Type: $type');
    
    switch (type) {
      case 'achievement':
        await _navigateToHome();
        break;
        
      case 'motivational':
        await _navigateToHome();
        break;
        
      case 'daily_tip':
        await _navigateToSettings();
        break;
        
      default:
        await _navigateToHome();
        break;
    }
  }
  
  // ==================== دوال التنقل ====================
  
  /// التنقل لصفحة مواقيت الصلاة
  Future<void> _navigateToPrayerTimes() async {
    try {
      debugPrint('[NotificationTapHandler] 📍 Navigating to: /prayer-times');
      
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('[NotificationTapHandler] ❌ Navigator is null');
        return;
      }
      
      // إزالة جميع الصفحات والانتقال لصفحة الصلاة
      await navigator.pushNamedAndRemoveUntil(
        '/prayer-times',
        (route) => false,
      );
      
      debugPrint('[NotificationTapHandler] ✅ Navigation completed');
      
    } catch (e) {
      debugPrint('[NotificationTapHandler] ❌ خطأ في التنقل لصفحة الصلاة: $e');
    }
  }
  
  /// التنقل لصفحة الأذكار الرئيسية
  Future<void> _navigateToAthkarHome() async {
    try {
      debugPrint('[NotificationTapHandler] 📍 Navigating to: /athkar');
      
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('[NotificationTapHandler] ❌ Navigator is null');
        return;
      }
      
      await navigator.pushNamedAndRemoveUntil(
        '/athkar',
        (route) => false,
      );
      
      debugPrint('[NotificationTapHandler] ✅ Navigation completed');
      
    } catch (e) {
      debugPrint('[NotificationTapHandler] ❌ خطأ في التنقل لصفحة الأذكار: $e');
    }
  }
  
  /// التنقل لصفحة قراءة أذكار معينة
  Future<void> _navigateToAthkarDetails(String categoryId) async {
    try {
      debugPrint('[NotificationTapHandler] 📍 Navigating to: /athkar-details');
      debugPrint('  - Category ID: $categoryId');
      
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('[NotificationTapHandler] ❌ Navigator is null');
        return;
      }
      
      // التحقق من صحة categoryId
      if (categoryId.isEmpty) {
        debugPrint('[NotificationTapHandler] ⚠️ Category ID is empty, navigating to athkar home');
        await _navigateToAthkarHome();
        return;
      }
      
      // محاولة التنقل للتفاصيل
      try {
        // أولاً: الانتقال للرئيسية
        await navigator.pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
        
        debugPrint('[NotificationTapHandler] ✓ Step 1: Navigated to home');
        
        // ثانياً: انتظار قصير
        await Future.delayed(const Duration(milliseconds: 400));
        
        // ثالثاً: الانتقال لصفحة الأذكار
        await navigator.pushNamed('/athkar');
        
        debugPrint('[NotificationTapHandler] ✓ Step 2: Navigated to athkar');
        
        // رابعاً: انتظار قصير
        await Future.delayed(const Duration(milliseconds: 400));
        
        // خامساً: الانتقال لتفاصيل الأذكار
        await navigator.pushNamed(
          '/athkar-details',
          arguments: categoryId,
        );
        
        debugPrint('[NotificationTapHandler] ✓ Step 3: Navigated to athkar details');
        debugPrint('[NotificationTapHandler] ✅ Navigation completed successfully');
        
      } catch (navError) {
        debugPrint('[NotificationTapHandler] ❌ Navigation error: $navError');
        debugPrint('  - Falling back to athkar home');
        await _navigateToAthkarHome();
      }
      
    } catch (e) {
      debugPrint('[NotificationTapHandler] ❌ خطأ عام في التنقل: $e');
      await _navigateToAthkarHome();
    }
  }
  
  /// التنقل لصفحة القرآن
  Future<void> _navigateToQuran() async {
    try {
      debugPrint('[NotificationTapHandler] 📍 Navigating to: /quran');
      
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('[NotificationTapHandler] ❌ Navigator is null');
        return;
      }
      
      await navigator.pushNamedAndRemoveUntil(
        '/quran',
        (route) => false,
      );
      
      debugPrint('[NotificationTapHandler] ✅ Navigation completed');
      
    } catch (e) {
      debugPrint('[NotificationTapHandler] ❌ خطأ في التنقل لصفحة القرآن: $e');
    }
  }
  
  /// التنقل لصفحة الإعدادات
  Future<void> _navigateToSettings() async {
    try {
      debugPrint('[NotificationTapHandler] 📍 Navigating to: /settings');
      
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('[NotificationTapHandler] ❌ Navigator is null');
        return;
      }
      
      // الانتقال للرئيسية أولاً ثم الإعدادات
      await navigator.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      await navigator.pushNamed('/settings');
      
      debugPrint('[NotificationTapHandler] ✅ Navigation completed');
      
    } catch (e) {
      debugPrint('[NotificationTapHandler] ❌ خطأ في التنقل لصفحة الإعدادات: $e');
    }
  }
  
  /// التنقل للصفحة الرئيسية
  Future<void> _navigateToHome() async {
    try {
      debugPrint('[NotificationTapHandler] 📍 Navigating to: /home');
      
      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('[NotificationTapHandler] ❌ Navigator is null');
        return;
      }
      
      await navigator.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
      
      debugPrint('[NotificationTapHandler] ✅ Navigation completed');
      
    } catch (e) {
      debugPrint('[NotificationTapHandler] ❌ خطأ في التنقل للصفحة الرئيسية: $e');
    }
  }
}