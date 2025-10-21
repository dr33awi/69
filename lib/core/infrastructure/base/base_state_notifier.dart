// lib/core/infrastructure/base/base_state_notifier.dart
import 'package:flutter/material.dart';

/// Base class موحدة لجميع State Notifiers في التطبيق
///
/// توفر:
/// - حماية من memory leaks
/// - معالجة dispose آمنة
/// - notify آمن
/// - تتبع حالة dispose
abstract class BaseStateNotifier extends ChangeNotifier {
  bool _isDisposed = false;

  /// التحقق من حالة dispose
  bool get isDisposed => _isDisposed;

  /// التحقق من حالة active
  bool get isActive => !_isDisposed;

  @override
  void dispose() {
    if (_isDisposed) {
      debugPrint('[BaseStateNotifier] Warning: dispose() called multiple times on ${runtimeType}');
      return;
    }

    debugPrint('[BaseStateNotifier] Disposing ${runtimeType}');
    _isDisposed = true;

    // استدعاء cleanup المخصص
    onDispose();

    // استدعاء dispose الأصلي
    super.dispose();
  }

  /// دالة للتنظيف المخصص - يمكن override في الـ subclasses
  @protected
  void onDispose() {
    // للتخصيص في الـ subclasses
  }

  /// notify آمن - يتحقق من dispose قبل notify
  @protected
  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    } else {
      debugPrint('[BaseStateNotifier] Warning: safeNotify() called on disposed ${runtimeType}');
    }
  }

  /// تحديث الحالة بشكل آمن
  @protected
  void updateState(VoidCallback updateFn) {
    if (_isDisposed) {
      debugPrint('[BaseStateNotifier] Warning: updateState() called on disposed ${runtimeType}');
      return;
    }

    updateFn();
    safeNotify();
  }

  /// معلومات debug
  @override
  String toString() {
    return '${runtimeType}(isDisposed: $_isDisposed, hasListeners: $hasListeners)';
  }
}

/// Base class موحدة للخدمات التي تدير البيانات
abstract class BaseDataService extends BaseStateNotifier {
  bool _isLoading = false;
  String? _error;

  /// حالة التحميل
  bool get isLoading => _isLoading;

  /// رسالة الخطأ
  String? get error => _error;

  /// هل يوجد خطأ
  bool get hasError => _error != null;

  /// تعيين حالة التحميل
  @protected
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (_isLoading) {
        _error = null; // مسح الخطأ عند بدء التحميل
      }
      safeNotify();
    }
  }

  /// تعيين رسالة خطأ
  @protected
  void setError(String? error) {
    _error = error;
    _isLoading = false;
    safeNotify();
  }

  /// مسح الخطأ
  @protected
  void clearError() {
    if (_error != null) {
      _error = null;
      safeNotify();
    }
  }

  /// تنفيذ عملية مع معالجة Loading و Errors
  @protected
  Future<T?> execute<T>({
    required Future<T> Function() operation,
    String? errorMessage,
    void Function(T result)? onSuccess,
    void Function(String error)? onError,
  }) async {
    try {
      setLoading(true);
      final result = await operation();
      setLoading(false);
      onSuccess?.call(result);
      return result;
    } catch (e, stack) {
      final error = errorMessage ?? e.toString();
      debugPrint('[${runtimeType}] Error: $error');
      debugPrint('Stack: $stack');
      setError(error);
      onError?.call(error);
      return null;
    }
  }

  @override
  void onDispose() {
    _error = null;
    _isLoading = false;
    super.onDispose();
  }
}
