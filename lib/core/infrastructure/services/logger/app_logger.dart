// lib/core/infrastructure/services/logger/app_logger.dart
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// خدمة اللوقر المخصصة للتطبيق
class AppLogger {
  static final Logger _logger = Logger(
    filter: kDebugMode ? DevelopmentFilter() : ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    output: kDebugMode ? ConsoleOutput() : null,
  );

  // Singleton instance
  static AppLogger? _instance;
  static AppLogger get instance => _instance ??= AppLogger._();
  AppLogger._();

  /// تسجيل معلومات عامة
  static void info(String message, [Object? data]) {
    if (data != null) {
      _logger.i('ℹ️ $message\nData: $data');
    } else {
      _logger.i('ℹ️ $message');
    }
  }

  /// تسجيل تحذيرات
  static void warning(String message, [Object? data]) {
    if (data != null) {
      _logger.w('⚠️ $message\nData: $data');
    } else {
      _logger.w('⚠️ $message');
    }
  }

  /// تسجيل أخطاء
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (error != null || stackTrace != null) {
      _logger.e('❌ $message', error: error, stackTrace: stackTrace);
    } else {
      _logger.e('❌ $message');
    }
  }

  /// تسجيل تصحيح أخطاء
  static void debug(String message, [Object? data]) {
    if (data != null) {
      _logger.d('🐛 $message\nData: $data');
    } else {
      _logger.d('🐛 $message');
    }
  }

  /// تسجيل أخطاء خطيرة
  static void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    if (error != null || stackTrace != null) {
      _logger.f('💀 $message', error: error, stackTrace: stackTrace);
    } else {
      _logger.f('💀 $message');
    }
  }

  /// تسجيل تتبع
  static void trace(String message, [Object? data]) {
    if (data != null) {
      _logger.t('🔍 $message\nData: $data');
    } else {
      _logger.t('🔍 $message');
    }
  }

  // خدمات متخصصة للتطبيق
  
  /// تسجيل عمليات التطبيق
  static void operation(String operation, [Object? data]) {
    info('🔄 Operation: $operation', data);
  }

  /// تسجيل أحداث المستخدم
  static void userAction(String action, [Object? data]) {
    info('👤 User Action: $action', data);
  }

  /// تسجيل أحداث الشبكة
  static void network(String event, [Object? data]) {
    debug('🌐 Network: $event', data);
  }

  /// تسجيل أحداث قاعدة البيانات
  static void database(String event, [Object? data]) {
    debug('💾 Database: $event', data);
  }

  /// تسجيل أحداث الأذونات
  static void permission(String event, [Object? data]) {
    info('🔐 Permission: $event', data);
  }

  /// تسجيل أحداث الإشعارات
  static void notification(String event, [Object? data]) {
    info('🔔 Notification: $event', data);
  }

  /// تسجيل أحداث Firebase
  static void firebase(String event, [Object? data]) {
    debug('🔥 Firebase: $event', data);
  }

  /// تسجيل أداء التطبيق
  static void performance(String metric, [Object? data]) {
    debug('⚡ Performance: $metric', data);
  }
}

/// Filter مخصص للإنتاج
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // في الإنتاج، نسجل فقط التحذيرات والأخطاء
    return event.level.index >= Level.warning.index;
  }
}

/// Extensions للاستخدام السهل
extension LoggerExtension on Object {
  void logInfo([String? message]) {
    AppLogger.info(message ?? toString(), this);
  }

  void logError([String? message, StackTrace? stackTrace]) {
    AppLogger.error(message ?? toString(), this, stackTrace);
  }

  void logDebug([String? message]) {
    AppLogger.debug(message ?? toString(), this);
  }
}