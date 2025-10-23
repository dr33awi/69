// lib/core/infrastructure/services/permissions/simple_permission_initializer.dart
// تهيئة نظام الأذونات البسيط

import 'package:flutter/foundation.dart';
import 'simple_permission_service.dart';

/// فئة تهيئة نظام الأذونات البسيط
class SimplePermissionInitializer {
  static SimplePermissionService? _service;

  /// الحصول على instance الخدمة
  static SimplePermissionService get service {
    _service ??= SimplePermissionService();
    return _service!;
  }

  /// تهيئة النظام
  static Future<void> initialize() async {
    try {
      debugPrint('🔐 Initializing Simple Permission System...');
      
      // الحصول على الخدمة وتهيئتها
      final service = SimplePermissionInitializer.service;
      await service.initialize();
      
      debugPrint('✅ Simple Permission System initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Error initializing Simple Permission System: $e');
      rethrow;
    }
  }

  /// إعادة تعيين النظام
  static void reset() {
    _service?.dispose();
    _service = null;
    debugPrint('🔄 Simple Permission System reset');
  }
}

/// Extension سهل للاستخدام في التطبيق
extension SimplePermissionGlobal on Object {
  /// الحصول على خدمة الأذونات البسيطة من أي مكان
  SimplePermissionService get simplePermissions => SimplePermissionInitializer.service;
}