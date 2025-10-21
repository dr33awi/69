// lib/core/infrastructure/services/notifications/notification_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'models/notification_models.dart';
import 'constants/notification_messages.dart';

/// مدير مركزي للإشعارات
class NotificationManager {
  final NotificationService _service;
  
  // Singleton pattern
  static NotificationManager? _instance;
  
  NotificationManager._(this._service);
  
  /// الحصول على instance واحد
  static NotificationManager get instance {
    if (_instance == null) {
      throw StateError('NotificationManager not initialized');
    }
    return _instance!;
  }
  
  /// تهيئة المدير
  static Future<void> initialize(NotificationService service) async {
    _instance = NotificationManager._(service);
    await _instance!._service.initialize();
  }
  
  /// طلب الأذونات
  Future<bool> requestPermission() => _service.requestPermission();
  
  /// التحقق من الأذونات
  Future<bool> hasPermission() => _service.hasPermission();
  
  /// الاستماع للنقرات
  Stream<NotificationTapEvent> get onTap => _service.onNotificationTap;
  
  // ========== إشعارات الصلاة ==========
  
  /// جدولة إشعار الصلاة
  Future<void> schedulePrayerNotification({
    required String prayerName,
    required String arabicName,
    required DateTime time,
    int minutesBefore = 0,
  }) async {
    final scheduledTime = time.subtract(Duration(minutes: minutesBefore));
    final id = 'prayer_${prayerName}_${minutesBefore}_${time.millisecondsSinceEpoch}';
    
    String title;
    String body;
    
    if (minutesBefore > 0) {
      // إشعار قبل الصلاة
      title = NotificationMessages.getPrayerReminderTitle(arabicName, minutesBefore);
      body = NotificationMessages.getPrayerReminderBody(arabicName);
    } else {
      // إشعار وقت الصلاة
      title = NotificationMessages.getPrayerTimeTitle(arabicName);
      body = NotificationMessages.getPrayerTimeBody(arabicName);
    }
    
    final notification = NotificationData(
      id: id,
      title: title,
      body: body,
      category: NotificationCategory.prayer,
      priority: NotificationPriority.high,
      scheduledTime: scheduledTime,
      repeatType: NotificationRepeat.daily,
      payload: {
        'prayer': prayerName,
        'arabicName': arabicName,
        'time': time.toIso8601String(),
        'minutesBefore': minutesBefore,
      },
    );
    
    await _service.scheduleNotification(notification);
  }
  
  /// إلغاء جميع إشعارات الصلاة
  Future<void> cancelAllPrayerNotifications() async {
    await _service.cancelCategoryNotifications(NotificationCategory.prayer);
  }
  
  // ========== إشعارات الأذكار ==========
  
  /// جدولة تذكير الأذكار
  Future<void> scheduleAthkarReminder({
    required String categoryId,
    required String categoryName,
    required TimeOfDay time,
    NotificationRepeat repeat = NotificationRepeat.daily,
    bool useMotivationalMessage = false,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // إذا مر الوقت اليوم، جدولة لليوم التالي
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    final message = NotificationMessages.getAthkarMessage(categoryId, categoryName);
    
    // إذا أردنا استخدام رسالة تحفيزية عشوائية
    final body = useMotivationalMessage 
        ? NotificationMessages.getRandomMotivation()
        : message['body']!;
    
    final notification = NotificationData(
      id: 'athkar_$categoryId',
      title: message['title']!,
      body: body,
      category: NotificationCategory.athkar,
      priority: NotificationPriority.normal,
      scheduledTime: scheduledDate,
      repeatType: repeat,
      payload: {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'type': 'athkar_reminder',
      },
    );
    
    await _service.scheduleNotification(notification);
  }
  
  /// إلغاء تذكير أذكار محدد
  Future<void> cancelAthkarReminder(String categoryId) async {
    await _service.cancelNotification('athkar_$categoryId');
  }
  
  /// إلغاء جميع تذكيرات الأذكار
  Future<void> cancelAllAthkarReminders() async {
    await _service.cancelCategoryNotifications(NotificationCategory.athkar);
  }
  
  // ========== إشعارات بسيطة ==========
  
  /// عرض إشعار فوري
  Future<void> showInstantNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    NotificationPriority priority = NotificationPriority.normal,
    String? emoji,
  }) async {
    // إضافة رمز تعبيري اختياري للعنوان
    final finalTitle = emoji != null ? '$emoji $title' : title;
    
    final notification = NotificationData(
      id: 'instant_${DateTime.now().millisecondsSinceEpoch}',
      title: finalTitle,
      body: body,
      category: NotificationCategory.system,
      priority: priority,
      payload: payload,
    );
    
    await _service.showNotification(notification);
  }
  
  /// إشعار نجاح العملية
  Future<void> showSuccessNotification(String message) async {
    await showInstantNotification(
      title: 'نجحت العملية',
      body: message,
      emoji: '✅',
      priority: NotificationPriority.normal,
    );
  }
  
  /// إشعار خطأ
  Future<void> showErrorNotification(String message) async {
    await showInstantNotification(
      title: 'حدث خطأ',
      body: message,
      emoji: '❌',
      priority: NotificationPriority.high,
    );
  }
  
  /// إشعار تحذير
  Future<void> showWarningNotification(String message) async {
    await showInstantNotification(
      title: 'تنبيه',
      body: message,
      emoji: '⚠️',
      priority: NotificationPriority.normal,
    );
  }
  
  /// إشعار معلومات
  Future<void> showInfoNotification(String message) async {
    await showInstantNotification(
      title: 'معلومة',
      body: message,
      emoji: 'ℹ️',
      priority: NotificationPriority.low,
    );
  }
  
  // ========== الإعدادات الأساسية ==========
  
  /// تحديث إعدادات الإشعارات
  Future<void> updateSettings(NotificationSettings settings) async {
    await _service.updateSettings(settings);
  }
  
  /// الحصول على الإعدادات الحالية
  Future<NotificationSettings> getSettings() => _service.getSettings();
  
  // ========== إدارة بسيطة ==========
  
  /// إلغاء إشعار محدد
  Future<void> cancelNotification(String id) {
    return _service.cancelNotification(id);
  }
  
  /// إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() {
    return _service.cancelAllNotifications();
  }
  
  /// الحصول على الإشعارات المجدولة
  Future<List<NotificationData>> getScheduledNotifications() {
    return _service.getScheduledNotifications();
  }
  
  /// الحصول على عدد الإشعارات المجدولة
  Future<int> getScheduledNotificationsCount() async {
    final notifications = await getScheduledNotifications();
    return notifications.length;
  }
  
  /// الحصول على إشعارات الصلاة المجدولة فقط
  Future<List<NotificationData>> getScheduledPrayerNotifications() async {
    final all = await getScheduledNotifications();
    return all.where((n) => n.category == NotificationCategory.prayer).toList();
  }
  
  /// الحصول على إشعارات الأذكار المجدولة فقط
  Future<List<NotificationData>> getScheduledAthkarNotifications() async {
    final all = await getScheduledNotifications();
    return all.where((n) => n.category == NotificationCategory.athkar).toList();
  }
  
  /// التنظيف
  Future<void> dispose() {
    return _service.dispose();
  }
  
  // ========== دوال مساعدة للتصحيح ==========
  
  /// طباعة معلومات الإشعارات المجدولة (للتطوير)
  Future<void> debugPrintScheduledNotifications() async {
    final notifications = await getScheduledNotifications();
    if (notifications.isEmpty) {
      return;
    }
    
    // تصنيف الإشعارات
    final byCategory = <NotificationCategory, List<NotificationData>>{};
    
    for (final notif in notifications) {
      byCategory.putIfAbsent(notif.category, () => []).add(notif);
    }
    
    // طباعة كل فئة
    byCategory.forEach((category, list) {
      for (final notif in list) {
        if (notif.scheduledTime != null) {
        }
      }
    });
  }
  
  /// الحصول على اسم الفئة بالعربية
  String _getCategoryName(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.prayer:
        return 'إشعارات الصلاة';
      case NotificationCategory.athkar:
        return 'إشعارات الأذكار';
      case NotificationCategory.quran:
        return 'إشعارات القرآن';
      case NotificationCategory.reminder:
        return 'تذكيرات عامة';
      case NotificationCategory.system:
        return 'إشعارات النظام';
    }
  }
}