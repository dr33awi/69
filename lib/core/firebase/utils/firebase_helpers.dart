// lib/core/infrastructure/firebase/utils/firebase_helpers.dart

import 'package:flutter/foundation.dart';

/// Helper functions لـ Firebase
class FirebaseHelpers {
  
  /// تحويل Map<String, dynamic> إلى Map<String, Object> لـ Firebase Analytics
  /// Firebase Analytics يتطلب Map<String, Object> حيث القيم لا يمكن أن تكون null
  static Map<String, Object>? convertToFirebaseParams(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return null;
    
    final Map<String, Object> firebaseParams = {};
    
    params.forEach((key, value) {
      // تجاهل القيم null
      if (value == null) return;
      
      // التعامل مع الأنواع المختلفة
      if (value is String || 
          value is num || 
          value is bool) {
        firebaseParams[key] = value;
      } 
      // تحويل DateTime إلى String
      else if (value is DateTime) {
        firebaseParams[key] = value.toIso8601String();
      }
      // تحويل Lists (يجب أن تحتوي على أنواع بسيطة)
      else if (value is List) {
        final filteredList = value.where((item) => item != null).toList();
        if (filteredList.isNotEmpty) {
          firebaseParams[key] = filteredList.map((e) => e.toString()).join(',');
        }
      }
      // تحويل Maps المتداخلة إلى JSON string
      else if (value is Map) {
        firebaseParams[key] = value.toString();
      }
      // أي نوع آخر يتم تحويله إلى String
      else {
        firebaseParams[key] = value.toString();
      }
    });
    
    return firebaseParams.isEmpty ? null : firebaseParams;
  }
  
  /// إضافة معلومات افتراضية للأحداث
  static Map<String, Object> addDefaultEventParams(Map<String, Object>? params) {
    final defaultParams = <String, Object>{
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'platform': 'android',
      'is_debug': kDebugMode,
    };
    
    if (params != null) {
      defaultParams.addAll(params);
    }
    
    return defaultParams;
  }
  
  /// تنظيف اسم الحدث ليكون متوافق مع Firebase
  /// Firebase Analytics يتطلب أسماء أحداث بحروف صغيرة وشرطات سفلية
  static String sanitizeEventName(String name) {
    // إزالة المسافات واستبدالها بشرطة سفلية
    String sanitized = name.replaceAll(RegExp(r'\s+'), '_');
    
    // تحويل إلى حروف صغيرة
    sanitized = sanitized.toLowerCase();
    
    // إزالة الأحرف غير المسموحة
    sanitized = sanitized.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    
    // التأكد من أن الاسم لا يبدأ برقم
    if (sanitized.isNotEmpty && RegExp(r'^[0-9]').hasMatch(sanitized)) {
      sanitized = 'event_$sanitized';
    }
    
    // التأكد من ألا يتجاوز 40 حرف (حد Firebase)
    if (sanitized.length > 40) {
      sanitized = sanitized.substring(0, 40);
    }
    
    // التأكد من أن الاسم ليس فارغاً
    if (sanitized.isEmpty) {
      sanitized = 'unnamed_event';
    }
    
    return sanitized;
  }
  
  /// تنظيف اسم المعامل ليكون متوافق مع Firebase
  static String sanitizeParamName(String name) {
    String sanitized = name.replaceAll(RegExp(r'\s+'), '_');
    sanitized = sanitized.toLowerCase();
    sanitized = sanitized.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    
    if (sanitized.isNotEmpty && RegExp(r'^[0-9]').hasMatch(sanitized)) {
      sanitized = 'param_$sanitized';
    }
    
    // حد Firebase للمعاملات هو 40 حرف
    if (sanitized.length > 40) {
      sanitized = sanitized.substring(0, 40);
    }
    
    if (sanitized.isEmpty) {
      sanitized = 'unnamed_param';
    }
    
    return sanitized;
  }
  
  /// التحقق من صحة قيمة المعامل
  static bool isValidParamValue(dynamic value) {
    if (value == null) return false;
    
    // Firebase يدعم فقط: String, int, double, bool
    return value is String || 
           value is int || 
           value is double || 
           value is bool;
  }
  
  /// تحويل قيمة إلى نوع مدعوم من Firebase
  static Object? convertToSupportedType(dynamic value) {
    if (value == null) return null;
    
    // الأنواع المدعومة مباشرة
    if (value is String || value is num || value is bool) {
      return value;
    }
    
    // تحويل الأنواع الأخرى
    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }
    
    if (value is Duration) {
      return value.inMilliseconds;
    }
    
    if (value is List || value is Map) {
      return value.toString();
    }
    
    // أي شيء آخر يتم تحويله إلى String
    return value.toString();
  }
  
  /// إنشاء معاملات لحدث الخطأ
  static Map<String, Object> createErrorEventParams({
    required String errorType,
    required String errorMessage,
    String? screenName,
    String? functionName,
    Map<String, dynamic>? additionalInfo,
  }) {
    final params = <String, Object>{
      'error_type': errorType,
      'error_message': _truncateString(errorMessage, 100),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (screenName != null) {
      params['screen_name'] = screenName;
    }
    
    if (functionName != null) {
      params['function_name'] = functionName;
    }
    
    if (additionalInfo != null) {
      final converted = convertToFirebaseParams(additionalInfo);
      if (converted != null) {
        params.addAll(converted);
      }
    }
    
    return params;
  }
  
  /// قص النص الطويل
  static String _truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
  
  /// التحقق من أن المعاملات ضمن حدود Firebase
  /// Firebase Analytics له حدود:
  /// - 25 معامل لكل حدث
  /// - 40 حرف لاسم المعامل
  /// - 100 حرف لقيمة String
  static Map<String, Object>? validateAndLimitParams(Map<String, Object>? params) {
    if (params == null || params.isEmpty) return null;
    
    final validatedParams = <String, Object>{};
    var count = 0;
    
    for (final entry in params.entries) {
      // حد 25 معامل
      if (count >= 25) break;
      
      // تنظيف اسم المعامل
      final key = sanitizeParamName(entry.key);
      var value = entry.value;
      
      // قص النصوص الطويلة
      if (value is String && value.length > 100) {
        value = _truncateString(value, 100);
      }
      
      validatedParams[key] = value;
      count++;
    }
    
    return validatedParams;
  }
}

/// Extension للتسهيل
extension FirebaseParamsExtension on Map<String, dynamic> {
  /// تحويل إلى معاملات Firebase
  Map<String, Object>? toFirebaseParams() {
    return FirebaseHelpers.convertToFirebaseParams(this);
  }
  
  /// تحويل مع إضافة المعاملات الافتراضية
  Map<String, Object> toFirebaseParamsWithDefaults() {
    final converted = FirebaseHelpers.convertToFirebaseParams(this);
    return FirebaseHelpers.addDefaultEventParams(converted);
  }
}