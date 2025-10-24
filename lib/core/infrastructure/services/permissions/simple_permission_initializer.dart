// lib/core/infrastructure/services/permissions/simple_permission_initializer.dart
// تهيئة نظام الأذونات المحسّن - Smart Permission

import 'package:flutter/foundation.dart';
import 'simple_permission_service.dart';

/// فئة تهيئة نظام الأذونات المحسّن
///
/// استخدام:
/// ```dart
/// await SimplePermissionInitializer.initialize();
/// ```
class SimplePermissionInitializer {
  static SimplePermissionService? _service;

  /// الحصول على instance الخدمة
  static SimplePermissionService get service {
    _service ??= SimplePermissionService();
    return _service!;
  }

  /// تهيئة النظام المحسّن
  static Future<void> initialize() async {
    try {
      debugPrint('🔐 Initializing Smart Permission System...');
      
      // الحصول على الخدمة وتهيئتها
      final service = SimplePermissionInitializer.service;
      await service.initialize();
      
      debugPrint('✅ Smart Permission System initialized successfully');
      debugPrint('   - Adaptive Dialogs: ✅');
      debugPrint('   - Cache Duration: 1 hour');
      debugPrint('   - Retry Logic: 3 attempts');
      debugPrint('   - Analytics: Enabled');
      
    } catch (e) {
      debugPrint('❌ Error initializing Smart Permission System: $e');
      rethrow;
    }
  }

  /// إعادة تعيين النظام
  static void reset() {
    _service?.dispose();
    _service = null;
    debugPrint('🔄 Smart Permission System reset');
  }
}

/// Extension سهل للاستخدام في التطبيق
extension SimplePermissionGlobal on Object {
  /// الحصول على خدمة الأذونات المحسّنة من أي مكان
  SimplePermissionService get simplePermissions => SimplePermissionInitializer.service;
}