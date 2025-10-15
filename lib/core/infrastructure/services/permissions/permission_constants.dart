// lib/core/infrastructure/services/permissions/permission_constants.dart
// مصدر واحد موحد لجميع معلومات وثوابت الأذونات

import 'package:flutter/material.dart';
import 'permission_service.dart';

/// معلومات الإذن
class PermissionInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isCritical;

  const PermissionInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.isCritical,
  });
}

/// ثوابت الأذونات الموحدة - مصدر واحد للحقيقة
class PermissionConstants {
  // منع إنشاء instance
  PermissionConstants._();
  
  // ==================== ثوابت التوقيت الموحدة ====================
  /// الحد الأدنى للفترة بين فحص الأذونات
  static const Duration minCheckInterval = Duration(seconds: 3);
  
  /// الحد الأدنى للفترة بين طلبات الأذونات
  static const Duration minRequestInterval = Duration(seconds: 5);
  
  /// مدة صلاحية الكاش
  static const Duration cacheExpiration = Duration(seconds: 30);
  
  /// مدة تأجيل عرض الإشعار بعد رفضه
  static const Duration dismissalDuration = Duration(hours: 1);
  
  /// تأخير الفحص الأولي في main.dart
  static const Duration initialCheckDelayMain = Duration(milliseconds: 2500);
  
  /// تأخير الفحص الأولي في PermissionMonitor
  static const Duration initialCheckDelayMonitor = Duration(milliseconds: 3000);
  
  /// throttle للفحص عند العودة من الخلفية
  static const Duration resumeCheckThrottle = Duration(seconds: 5);
  
  // ==================== معلومات الأذونات ====================
  static const Map<AppPermissionType, PermissionInfo> permissions = {
    AppPermissionType.notification: PermissionInfo(
      name: 'الإشعارات',
      description: 'لإرسال تنبيهات الصلاة والأذكار في أوقاتها',
      icon: Icons.notifications_active,
      color: Colors.blue,
      isCritical: true,
    ),
    AppPermissionType.location: PermissionInfo(
      name: 'الموقع',
      description: 'لحساب أوقات الصلاة بدقة واتجاه القبلة',
      icon: Icons.location_on,
      color: Colors.green,
      isCritical: true,
    ),
    AppPermissionType.batteryOptimization: PermissionInfo(
      name: 'تحسين البطارية',
      description: 'لضمان عمل التذكيرات في الخلفية',
      icon: Icons.battery_charging_full,
      color: Colors.orange,
      isCritical: true,
    ),
  };
  
  // ==================== قوائم الأذونات ====================
  /// قائمة الأذونات الحرجة (المطلوبة لعمل التطبيق)
  static List<AppPermissionType> get criticalPermissions => [
    AppPermissionType.notification,
    AppPermissionType.location,
    AppPermissionType.batteryOptimization,
  ];
  
  /// قائمة الأذونات الاختيارية (لا توجد حالياً)
  static List<AppPermissionType> get optionalPermissions => [];
  
  /// جميع الأذونات
  static List<AppPermissionType> get allPermissions => [
    ...criticalPermissions,
    ...optionalPermissions,
  ];
  
  // ==================== دوال الوصول للمعلومات ====================
  
  /// الحصول على معلومات إذن محدد
  static PermissionInfo getInfo(AppPermissionType permission) {
    return permissions[permission] ?? 
        const PermissionInfo(
          name: 'إذن غير معروف',
          description: '',
          icon: Icons.security,
          color: Colors.grey,
          isCritical: false,
        );
  }
  
  /// الحصول على اسم الإذن
  static String getName(AppPermissionType permission) => 
      getInfo(permission).name;
  
  /// الحصول على وصف الإذن
  static String getDescription(AppPermissionType permission) => 
      getInfo(permission).description;
  
  /// الحصول على أيقونة الإذن
  static IconData getIcon(AppPermissionType permission) => 
      getInfo(permission).icon;
  
  /// الحصول على لون الإذن
  static Color getColor(AppPermissionType permission) => 
      getInfo(permission).color;
  
  /// هل الإذن حرج؟
  static bool isCritical(AppPermissionType permission) => 
      getInfo(permission).isCritical;
  
  /// هل الإذن اختياري؟
  static bool isOptional(AppPermissionType permission) => 
      !isCritical(permission);
  
  // ==================== رسائل وتسميات ====================
  
  /// رسالة تنبيه عامة للأذونات
  static const String generalPermissionMessage = 
      'يحتاج التطبيق لبعض الأذونات لتقديم أفضل تجربة';
  
  /// رسالة عند رفض الإذن نهائياً
  static const String permanentlyDeniedMessage = 
      'يرجى تفعيل الإذن من إعدادات النظام';
  
  /// رسالة النجاح
  static String getSuccessMessage(AppPermissionType permission) =>
      'تم تفعيل إذن ${getName(permission)} بنجاح';
  
  /// رسالة الخطأ
  static String getErrorMessage(AppPermissionType permission) =>
      'فشل في تفعيل إذن ${getName(permission)}';
  
  // ==================== معلومات تقنية ====================
  
  /// هل الإذن مدعوم على المنصة الحالية
  static bool isSupported(AppPermissionType permission) {
    // يمكن تحديث هذا حسب المنصة
    switch (permission) {
      case AppPermissionType.batteryOptimization:
        // فقط على Android
        return true; // سيتم الفحص الفعلي في Handler
      default:
        return true;
    }
  }
  
  /// الحصول على أولوية الإذن (للترتيب)
  static int getPriority(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.notification:
        return 1; // أعلى أولوية
      case AppPermissionType.location:
        return 2;
      case AppPermissionType.batteryOptimization:
        return 3;
      default:
        return 99;
    }
  }
  
  /// ترتيب قائمة الأذونات حسب الأولوية
  static List<AppPermissionType> sortByPriority(List<AppPermissionType> permissions) {
    final sorted = List<AppPermissionType>.from(permissions);
    sorted.sort((a, b) => getPriority(a).compareTo(getPriority(b)));
    return sorted;
  }
}