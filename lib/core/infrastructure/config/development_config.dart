// lib/core/infrastructure/config/development_config.dart
import 'package:flutter/foundation.dart';
import '../services/logger/app_logger.dart';
import '../services/performance/performance_monitor.dart';
import '../services/memory/leak_tracker_service.dart';

/// تكوين شامل لأدوات التطوير
class DevelopmentConfig {
  static bool get isEnabled => kDebugMode;

  /// تهيئة جميع أدوات التطوير
  static void initialize() {
    if (!isEnabled) {
      return;
    }

    AppLogger.info('🚀 Development tools initialization started');

    try {
      // تهيئة Logger
      _initializeLogger();

      // تهيئة Performance Monitor
      _initializePerformanceMonitor();

      // تهيئة Leak Tracker
      _initializeLeakTracker();

      AppLogger.info('✅ All development tools initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing development tools: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// تهيئة Logger
  static void _initializeLogger() {
    AppLogger.info('📝 Logger initialized');
    
    // تسجيل معلومات النظام
    AppLogger.info('🎯 App running in ${kDebugMode ? 'DEBUG' : 'RELEASE'} mode');
    AppLogger.info('📱 Platform: ${defaultTargetPlatform.name}');
  }

  /// تهيئة Performance Monitor
  static void _initializePerformanceMonitor() {
    final monitor = PerformanceMonitor.instance;
    
    AppLogger.info('⚡ Performance Monitor initialized');
    
    // بدء قياس الأداء الأولي
    monitor.startMeasurement('app_startup');
  }

  /// تهيئة Leak Tracker
  static void _initializeLeakTracker() {
    LeakTrackerService.instance.initialize();
    AppLogger.info('🔍 Leak Tracker initialized');
  }

  /// تنظيف أدوات التطوير
  static void dispose() {
    if (!isEnabled) return;

    try {
      // إنهاء قياس الأداء
      PerformanceMonitor.instance.endMeasurement('app_startup');
      PerformanceMonitor.instance.printReport();

      // تنظيف Leak Tracker
      LeakTrackerService.instance.dispose();

      AppLogger.info('🧹 Development tools disposed');
    } catch (e) {
      AppLogger.error('Error disposing development tools', e);
    }
  }

  /// طباعة تقرير الأداء
  static void printPerformanceReport() {
    if (!isEnabled) return;
    PerformanceMonitor.instance.printReport();
  }

  /// فحص تسريبات الذاكرة
  static void checkMemoryLeaks() {
    if (!isEnabled) return;
    LeakTrackerService.instance.checkForLeaks();
  }

  /// تسجيل حدث مخصص
  static void logCustomEvent(String event, [Object? data]) {
    if (!isEnabled) return;
    AppLogger.userAction(event, data);
  }
}

/// Extensions للاستخدام السهل في التطبيق
extension DevelopmentExtensions on Object {
  /// تسجيل سريع للأحداث
  void logEvent(String event) {
    DevelopmentConfig.logCustomEvent('${runtimeType}: $event', this);
  }

  /// قياس أداء عملية
  Future<T> measurePerformance<T>(String name, Future<T> Function() operation) async {
    return PerformanceMonitor.instance.measureAsync('${runtimeType}_$name', operation);
  }
}