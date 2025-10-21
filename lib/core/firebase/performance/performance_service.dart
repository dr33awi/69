// lib/core/infrastructure/firebase/performance/performance_service.dart

import 'dart:async';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';

/// خدمة مراقبة الأداء باستخدام Firebase Performance
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();
  
  FirebasePerformance? _performance;
  bool _isInitialized = false;
  
  // تخزين الـ Traces النشطة
  final Map<String, Trace> _activeTraces = {};
  final Map<String, HttpMetric> _activeHttpMetrics = {};
  
  // معلومات الأداء
  final Map<String, PerformanceMetric> _metrics = {};
  
  /// تهيئة خدمة الأداء
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _performance = FirebasePerformance.instance;
      
      // تفعيل جمع بيانات الأداء
      await _performance!.setPerformanceCollectionEnabled(true);
      
      _isInitialized = true;
      // بدء تتبع أداء التطبيق الأساسي
      await _startAppLifecycleTrace();
      
    } catch (e) {
    }
  }
  
  /// بدء تتبع دورة حياة التطبيق
  Future<void> _startAppLifecycleTrace() async {
    startTrace('app_lifecycle');
  }
  
  // ==================== Custom Traces ====================
  
  /// بدء تتبع أداء مخصص
  void startTrace(String traceName) {
    if (_performance == null || !_isInitialized) return;
    
    try {
      // التحقق من عدم وجود trace نشط بنفس الاسم
      if (_activeTraces.containsKey(traceName)) {
        return;
      }
      
      final trace = _performance!.newTrace(traceName);
      trace.start();
      
      _activeTraces[traceName] = trace;
      
      // حفظ بداية القياس
      _metrics[traceName] = PerformanceMetric(
        name: traceName,
        startTime: DateTime.now(),
      );
    } catch (e) {
    }
  }
  
  /// إيقاف تتبع الأداء
  Future<void> stopTrace(String traceName, {Map<String, dynamic>? attributes}) async {
    if (!_activeTraces.containsKey(traceName)) {
      return;
    }
    
    try {
      final trace = _activeTraces[traceName]!;
      
      // إضافة attributes إذا وجدت
      if (attributes != null) {
        attributes.forEach((key, value) {
          if (value is String) {
            trace.putAttribute(key, value);
          } else if (value is int) {
            trace.setMetric(key, value);
          }
        });
      }
      
      await trace.stop();
      _activeTraces.remove(traceName);
      
      // تحديث المعلومات
      if (_metrics.containsKey(traceName)) {
        final metric = _metrics[traceName]!;
        metric.endTime = DateTime.now();
        metric.duration = metric.endTime!.difference(metric.startTime);
      }
      
    } catch (e) {
    }
  }
  
  /// إضافة metric لـ trace نشط
  void addTraceMetric(String traceName, String metricName, int value) {
    if (!_activeTraces.containsKey(traceName)) return;
    
    try {
      _activeTraces[traceName]!.setMetric(metricName, value);
    } catch (e) {
    }
  }
  
  /// إضافة attribute لـ trace نشط
  void addTraceAttribute(String traceName, String key, String value) {
    if (!_activeTraces.containsKey(traceName)) return;
    
    try {
      _activeTraces[traceName]!.putAttribute(key, value);
    } catch (e) {
    }
  }
  
  // ==================== Screen Rendering Performance ====================
  
  /// تتبع أداء رسم الشاشة
  void startScreenRenderTrace(String screenName) {
    final traceName = 'screen_render_$screenName';
    startTrace(traceName);
    addTraceAttribute(traceName, 'screen_name', screenName);
  }
  
  /// إنهاء تتبع رسم الشاشة
  Future<void> stopScreenRenderTrace(String screenName, {int? widgetCount}) async {
    final traceName = 'screen_render_$screenName';
    
    final attributes = <String, dynamic>{};
    if (widgetCount != null) {
      attributes['widget_count'] = widgetCount;
    }
    
    await stopTrace(traceName, attributes: attributes);
  }
  
  // ==================== API/Network Performance ====================
  
  /// بدء تتبع طلب HTTP
  void startHttpMetric(String url, HttpMethod method, {String? requestId}) {
    if (_performance == null || !_isInitialized) return;
    
    try {
      final metricKey = requestId ?? '${method.name}_${url.hashCode}';
      
      // التحقق من عدم وجود metric نشط
      if (_activeHttpMetrics.containsKey(metricKey)) {
        return;
      }
      
      final metric = _performance!.newHttpMetric(url, method);
      metric.start();
      
      _activeHttpMetrics[metricKey] = metric;
    } catch (e) {
    }
  }
  
  /// إيقاف تتبع طلب HTTP
  Future<void> stopHttpMetric({
    required String url,
    required HttpMethod method,
    String? requestId,
    int? httpResponseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
    String? responseContentType,
  }) async {
    final metricKey = requestId ?? '${method.name}_${url.hashCode}';
    
    if (!_activeHttpMetrics.containsKey(metricKey)) {
      return;
    }
    
    try {
      final metric = _activeHttpMetrics[metricKey]!;
      
      // إضافة المعلومات
      if (httpResponseCode != null) {
        metric.httpResponseCode = httpResponseCode;
      }
      if (requestPayloadSize != null) {
        metric.requestPayloadSize = requestPayloadSize;
      }
      if (responsePayloadSize != null) {
        metric.responsePayloadSize = responsePayloadSize;
      }
      if (responseContentType != null) {
        metric.responseContentType = responseContentType;
      }
      
      await metric.stop();
      _activeHttpMetrics.remove(metricKey);
    } catch (e) {
    }
  }
  
  // ==================== Database Performance ====================
  
  /// تتبع أداء قاعدة البيانات
  void startDatabaseTrace(String operation, String table) {
    final traceName = 'db_${operation}_$table';
    startTrace(traceName);
    addTraceAttribute(traceName, 'operation', operation);
    addTraceAttribute(traceName, 'table', table);
  }
  
  /// إنهاء تتبع قاعدة البيانات
  Future<void> stopDatabaseTrace(String operation, String table, {int? recordCount}) async {
    final traceName = 'db_${operation}_$table';
    
    final attributes = <String, dynamic>{};
    if (recordCount != null) {
      attributes['record_count'] = recordCount;
    }
    
    await stopTrace(traceName, attributes: attributes);
  }
  
  // ==================== App-Specific Performance ====================
  
  /// تتبع أداء تحميل الأذكار
  void startAthkarLoadTrace(String category) {
    final traceName = 'athkar_load_$category';
    startTrace(traceName);
    addTraceAttribute(traceName, 'category', category);
  }
  
  /// إنهاء تتبع تحميل الأذكار
  Future<void> stopAthkarLoadTrace(String category, int itemCount) async {
    final traceName = 'athkar_load_$category';
    await stopTrace(traceName, attributes: {'item_count': itemCount});
  }
  
  /// تتبع أداء حساب القبلة
  void startQiblaCalculationTrace() {
    startTrace('qibla_calculation');
  }
  
  /// إنهاء تتبع حساب القبلة
  Future<void> stopQiblaCalculationTrace({double? accuracy}) async {
    final attributes = <String, dynamic>{};
    if (accuracy != null) {
      attributes['accuracy'] = (accuracy * 100).toInt();
    }
    await stopTrace('qibla_calculation', attributes: attributes);
  }
  
  /// تتبع أداء حساب أوقات الصلاة
  void startPrayerTimesCalculationTrace() {
    startTrace('prayer_times_calculation');
  }
  
  /// إنهاء تتبع حساب أوقات الصلاة
  Future<void> stopPrayerTimesCalculationTrace({String? method}) async {
    final attributes = <String, dynamic>{};
    if (method != null) {
      attributes['calculation_method'] = method;
    }
    await stopTrace('prayer_times_calculation', attributes: attributes);
  }
  
  // ==================== Performance Monitoring ====================
  
  /// الحصول على معلومات الأداء الحالية
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    // الـ traces النشطة
    stats['active_traces'] = _activeTraces.keys.toList();
    stats['active_http_metrics'] = _activeHttpMetrics.keys.toList();
    
    // المقاييس المكتملة
    final completedMetrics = _metrics.values
        .where((m) => m.duration != null)
        .map((m) => {
          'name': m.name,
          'duration_ms': m.duration!.inMilliseconds,
          'start_time': m.startTime.toIso8601String(),
        })
        .toList();
    
    stats['completed_metrics'] = completedMetrics;
    
    // متوسط الأداء
    if (completedMetrics.isNotEmpty) {
      final totalDuration = completedMetrics
          .fold<int>(0, (sum, m) => sum + (m['duration_ms'] as int));
      stats['average_duration_ms'] = totalDuration ~/ completedMetrics.length;
    }
    
    return stats;
  }
  
  /// مسح المقاييس المحفوظة
  void clearMetrics() {
    _metrics.clear();
  }
  
  // ==================== Automatic Performance Tracking ====================
  
  /// Wrapper لتتبع أداء دالة
  Future<T> trackPerformance<T>(
    String traceName,
    Future<T> Function() operation, {
    Map<String, dynamic>? attributes,
  }) async {
    startTrace(traceName);
    
    try {
      final result = await operation();
      await stopTrace(traceName, attributes: attributes);
      return result;
      
    } catch (e) {
      await stopTrace(traceName, attributes: {
        ...?attributes,
        'error': e.toString(),
      });
      rethrow;
    }
  }
  
  /// Wrapper لتتبع أداء دالة متزامنة
  T trackSyncPerformance<T>(
    String traceName,
    T Function() operation, {
    Map<String, dynamic>? attributes,
  }) {
    startTrace(traceName);
    
    try {
      final result = operation();
      stopTrace(traceName, attributes: attributes);
      return result;
      
    } catch (e) {
      stopTrace(traceName, attributes: {
        ...?attributes,
        'error': e.toString(),
      });
      rethrow;
    }
  }
  
  // ==================== Cleanup ====================
  
  /// تنظيف الموارد
  Future<void> dispose() async {
    // إيقاف جميع الـ traces النشطة
    for (final traceName in _activeTraces.keys.toList()) {
      await stopTrace(traceName);
    }
    
    // إيقاف جميع HTTP metrics النشطة
    for (final metric in _activeHttpMetrics.values) {
      await metric.stop();
    }
    
    _activeTraces.clear();
    _activeHttpMetrics.clear();
    _metrics.clear();
    
    _isInitialized = false;
  }
  
  // ==================== Getters ====================
  
  bool get isInitialized => _isInitialized;
  int get activeTraceCount => _activeTraces.length;
  int get activeHttpMetricCount => _activeHttpMetrics.length;
}

/// معلومات مقياس الأداء
class PerformanceMetric {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;
  
  PerformanceMetric({
    required this.name,
    required this.startTime,
    this.endTime,
    this.duration,
  });
}

/// Extension للاستخدام السريع
extension PerformanceExtension on BuildContext {
  /// تتبع أداء عملية
  Future<T> trackPerformance<T>(
    String traceName,
    Future<T> Function() operation,
  ) async {
    return PerformanceService().trackPerformance(traceName, operation);
  }
}