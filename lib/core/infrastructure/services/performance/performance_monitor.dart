// lib/core/infrastructure/services/performance/performance_monitor.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../logger/app_logger.dart';

/// خدمة مراقبة الأداء
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._();
  static PerformanceMonitor get instance => _instance;
  PerformanceMonitor._();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<Duration>> _measurements = {};

  /// بدء قياس الأداء
  void startMeasurement(String name) {
    _startTimes[name] = DateTime.now();
    AppLogger.performance('Started measuring: $name');
  }

  /// إنهاء قياس الأداء
  Duration? endMeasurement(String name) {
    final startTime = _startTimes.remove(name);
    if (startTime == null) {
      AppLogger.warning('No start time found for measurement: $name');
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    
    // تخزين القياس
    _measurements.putIfAbsent(name, () => []).add(duration);
    
    AppLogger.performance(
      'Measurement completed: $name', 
      'Duration: ${duration.inMilliseconds}ms'
    );
    
    return duration;
  }

  /// قياس عملية مع callback
  Future<T> measureAsync<T>(String name, Future<T> Function() operation) async {
    startMeasurement(name);
    try {
      final result = await operation();
      endMeasurement(name);
      return result;
    } catch (e) {
      endMeasurement(name);
      AppLogger.error('Error during measured operation: $name', e);
      rethrow;
    }
  }

  /// قياس عملية متزامنة
  T measure<T>(String name, T Function() operation) {
    startMeasurement(name);
    try {
      final result = operation();
      endMeasurement(name);
      return result;
    } catch (e) {
      endMeasurement(name);
      AppLogger.error('Error during measured operation: $name', e);
      rethrow;
    }
  }

  /// الحصول على إحصائيات القياس
  PerformanceStats? getStats(String name) {
    final measurements = _measurements[name];
    if (measurements == null || measurements.isEmpty) return null;

    final durations = measurements.map((d) => d.inMilliseconds).toList();
    durations.sort();

    return PerformanceStats(
      name: name,
      count: measurements.length,
      totalMs: durations.reduce((a, b) => a + b),
      averageMs: durations.reduce((a, b) => a + b) / durations.length,
      minMs: durations.first,
      maxMs: durations.last,
      medianMs: durations[durations.length ~/ 2],
    );
  }

  /// طباعة تقرير الأداء
  void printReport() {
    if (!kDebugMode) return;

    AppLogger.info('=== Performance Report ===');
    for (final name in _measurements.keys) {
      final stats = getStats(name);
      if (stats != null) {
        AppLogger.info(stats.toString());
      }
    }
    AppLogger.info('========================');
  }

  /// مسح القياسات
  void clear() {
    _startTimes.clear();
    _measurements.clear();
    AppLogger.debug('Performance measurements cleared');
  }

  /// قياس استخدام الذاكرة
  Future<MemoryInfo> getMemoryInfo() async {
    if (!kDebugMode) return MemoryInfo.empty();

    try {
      await MethodChannel('flutter/system')
          .invokeMethod('SystemChrome.getSystemGestureInsets');
      
      // هذا مثال بسيط - في التطبيق الحقيقي قد تحتاج لمكتبة أخرى
      return MemoryInfo(
        usedMB: 0, // سيتم حسابها لاحقاً
        totalMB: 0,
        freeMB: 0,
      );
    } catch (e) {
      AppLogger.error('Error getting memory info', e);
      return MemoryInfo.empty();
    }
  }

  /// تسجيل استخدام الذاكرة
  void logMemoryUsage(String context) async {
    if (!kDebugMode) return;
    
    final memInfo = await getMemoryInfo();
    AppLogger.performance(
      'Memory usage at $context',
      'Used: ${memInfo.usedMB}MB, Free: ${memInfo.freeMB}MB'
    );
  }
}

/// فئة إحصائيات الأداء
class PerformanceStats {
  final String name;
  final int count;
  final int totalMs;
  final double averageMs;
  final int minMs;
  final int maxMs;
  final int medianMs;

  PerformanceStats({
    required this.name,
    required this.count,
    required this.totalMs,
    required this.averageMs,
    required this.minMs,
    required this.maxMs,
    required this.medianMs,
  });

  @override
  String toString() {
    return '$name: Count=$count, Avg=${averageMs.toStringAsFixed(1)}ms, '
           'Min=${minMs}ms, Max=${maxMs}ms, Median=${medianMs}ms';
  }
}

/// معلومات الذاكرة
class MemoryInfo {
  final double usedMB;
  final double totalMB;
  final double freeMB;

  MemoryInfo({
    required this.usedMB,
    required this.totalMB,
    required this.freeMB,
  });

  factory MemoryInfo.empty() => MemoryInfo(usedMB: 0, totalMB: 0, freeMB: 0);

  double get usagePercentage => totalMB > 0 ? (usedMB / totalMB) * 100 : 0;
}

/// Extensions للاستخدام السهل
extension PerformanceExtension on Future {
  Future<T> measurePerformance<T>(String name) async {
    return PerformanceMonitor.instance.measureAsync(name, () async => await this as T);
  }
}