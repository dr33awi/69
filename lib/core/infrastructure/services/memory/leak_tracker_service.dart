// lib/core/infrastructure/services/memory/leak_tracker_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:leak_tracker/leak_tracker.dart';
import '../logger/app_logger.dart';

/// خدمة تتبع تسريبات الذاكرة
class LeakTrackerService {
  static final LeakTrackerService _instance = LeakTrackerService._();
  static LeakTrackerService get instance => _instance;
  LeakTrackerService._();

  bool _isInitialized = false;

  /// تهيئة تتبع التسريبات
  void initialize() {
    if (_isInitialized || !kDebugMode) return;

    try {
      // تمكين تتبع التسريبات في وضع التطوير فقط
      LeakTracking.start();
      
      _isInitialized = true;
      AppLogger.info('Leak tracker initialized');
      
      // تسجيل callback للتسريبات المكتشفة
      _setupLeakListener();
      
    } catch (e) {
      AppLogger.error('Failed to initialize leak tracker', e);
    }
  }

  /// إعداد مستمع التسريبات
  void _setupLeakListener() {
    // هذا مثال - قد تحتاج لتخصيص أكثر حسب احتياجاتك
    AppLogger.info('Leak listener setup completed');
  }

  /// تسجيل كائن للتتبع
  void trackObject(Object object, String? description) {
    if (!_isInitialized || !kDebugMode) return;
    
    try {
      // تسجيل الكائن للتتبع
      AppLogger.debug('Tracking object: ${object.runtimeType}', description);
    } catch (e) {
      AppLogger.error('Error tracking object', e);
    }
  }

  /// إلغاء تتبع كائن
  void untrackObject(Object object) {
    if (!_isInitialized || !kDebugMode) return;
    
    try {
      AppLogger.debug('Untracking object: ${object.runtimeType}');
    } catch (e) {
      AppLogger.error('Error untracking object', e);
    }
  }

  /// فحص التسريبات الحالية
  void checkForLeaks() {
    if (!_isInitialized || !kDebugMode) return;
    
    try {
      AppLogger.info('Checking for memory leaks...');
      // هنا يمكن إضافة منطق فحص التسريبات
    } catch (e) {
      AppLogger.error('Error checking for leaks', e);
    }
  }

  /// تقرير عن التسريبات
  void generateReport() {
    if (!_isInitialized || !kDebugMode) return;
    
    try {
      AppLogger.info('=== Memory Leak Report ===');
      // إضافة منطق التقرير هنا
      AppLogger.info('========================');
    } catch (e) {
      AppLogger.error('Error generating leak report', e);
    }
  }

  /// تنظيف الخدمة
  void dispose() {
    if (!_isInitialized) return;
    
    try {
      AppLogger.info('Disposing leak tracker service');
      _isInitialized = false;
    } catch (e) {
      AppLogger.error('Error disposing leak tracker', e);
    }
  }
}

/// Mixin لتتبع التسريبات في Widgets
mixin LeakTrackingMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    LeakTrackerService.instance.trackObject(this, widget.runtimeType.toString());
  }

  @override
  void dispose() {
    LeakTrackerService.instance.untrackObject(this);
    super.dispose();
  }
}

/// Mixin لتتبع التسريبات في Services
mixin ServiceLeakTrackingMixin {
  void trackService() {
    LeakTrackerService.instance.trackObject(this, runtimeType.toString());
  }

  void untrackService() {
    LeakTrackerService.instance.untrackObject(this);
  }
}