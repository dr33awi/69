// lib/core/infrastructure/services/permissions/permission_constants.dart
// تعريفات وثوابت الأذونات

import 'package:flutter/material.dart';

/// أنواع الأذونات المستخدمة في التطبيق
enum AppPermissionType {
  /// إذن الموقع الأساسي (GPS)
  location,
  
  /// إذن الموقع في الخلفية
  backgroundLocation,
  
  /// إذن الإشعارات (Android 13+)
  notification,
  
  /// إذن التنبيهات الدقيقة (Android 12+)
  exactAlarm,
  
  /// إذن تجاهل تحسين البطارية
  batteryOptimization,
  
  /// إذن عرض نوافذ فوق التطبيقات
  systemAlertWindow,
}

/// حالات الإذن
enum AppPermissionStatus {
  /// الإذن ممنوح
  granted,
  
  /// الإذن مرفوض (يمكن إعادة الطلب)
  denied,
  
  /// الإذن مرفوض بشكل دائم (يحتاج فتح الإعدادات)
  permanentlyDenied,
  
  /// الإذن محظور من قبل النظام
  restricted,
  
  /// الإذن مؤقت (iOS)
  provisional,
  
  /// لم يتم تحديد حالة الإذن بعد
  notDetermined,
}

/// ثوابت الأذونات
class PermissionConstants {
  PermissionConstants._(); // منع إنشاء كائنات
  
  // ============== الأولويات ==============
  
  /// الأذونات الحرجة (يجب طلبها)
  static const List<AppPermissionType> criticalPermissions = [
    AppPermissionType.location,
    AppPermissionType.notification,
    AppPermissionType.exactAlarm,
  ];
  
  /// الأذونات الاختيارية (يمكن تخطيها)
  static const List<AppPermissionType> optionalPermissions = [
    AppPermissionType.backgroundLocation,
    AppPermissionType.batteryOptimization,
    AppPermissionType.systemAlertWindow,
  ];
  
  /// الأذونات الموصى بها (مهمة لكن ليست ضرورية)
  static const List<AppPermissionType> recommendedPermissions = [
    AppPermissionType.batteryOptimization,
  ];
  
  // ============== الترتيب ==============
  
  /// ترتيب طلب الأذونات (من الأهم إلى الأقل أهمية)
  static const List<AppPermissionType> requestOrder = [
    AppPermissionType.notification,    // أولاً: الإشعارات
    AppPermissionType.location,        // ثانياً: الموقع
    AppPermissionType.exactAlarm,      // ثالثاً: التنبيهات الدقيقة
    AppPermissionType.batteryOptimization, // رابعاً: البطارية
    AppPermissionType.backgroundLocation,  // خامساً: الموقع في الخلفية
    AppPermissionType.systemAlertWindow,   // أخيراً: النوافذ الطافية
  ];
  
  // ============== الفترات الزمنية ==============
  
  /// عدد الأيام قبل إعادة طلب الإذن المرفوض
  static const int daysBeforeRetry = 7;
  
  /// الحد الأقصى لعدد محاولات طلب الإذن
  static const int maxRequestAttempts = 3;
  
  /// الوقت بين كل محاولة طلب (بالثواني)
  static const int secondsBetweenRequests = 2;
  
  /// الوقت قبل عرض رسالة "تم الرفض دائماً" (بالمحاولات)
  static const int attemptsBeforePermanentDenied = 2;
  
  // ============== متطلبات الإصدار ==============
  
  /// الحد الأدنى لإصدار Android المطلوب لكل إذن
  static const Map<AppPermissionType, int> minAndroidVersions = {
    AppPermissionType.notification: 33,      // Android 13+
    AppPermissionType.exactAlarm: 31,        // Android 12+
    AppPermissionType.backgroundLocation: 29, // Android 10+
    AppPermissionType.location: 23,          // Android 6+
    AppPermissionType.batteryOptimization: 23,
    AppPermissionType.systemAlertWindow: 23,
  };
  
  // ============== الرسائل ==============
  
  /// عناوين الأذونات
  static const Map<AppPermissionType, String> permissionTitles = {
    AppPermissionType.location: 'إذن الموقع',
    AppPermissionType.backgroundLocation: 'الموقع في الخلفية',
    AppPermissionType.notification: 'إذن الإشعارات',
    AppPermissionType.exactAlarm: 'التنبيهات الدقيقة',
    AppPermissionType.batteryOptimization: 'تحسين البطارية',
    AppPermissionType.systemAlertWindow: 'النوافذ الطافية',
  };
  
  /// أوصاف الأذونات المختصرة
  static const Map<AppPermissionType, String> permissionShortDescriptions = {
    AppPermissionType.location: 
        'لتحديد أوقات الصلاة واتجاه القبلة',
    AppPermissionType.backgroundLocation: 
        'للتنبيهات الذكية حسب موقعك',
    AppPermissionType.notification: 
        'للتذكير بالأذكار وأوقات الصلاة',
    AppPermissionType.exactAlarm: 
        'لضمان دقة مواعيد التنبيهات',
    AppPermissionType.batteryOptimization: 
        'لضمان عمل التطبيق في الخلفية',
    AppPermissionType.systemAlertWindow: 
        'لعرض تنبيهات سريعة',
  };
  
  /// أوصاف الأذونات التفصيلية
  static const Map<AppPermissionType, String> permissionDetailedDescriptions = {
    AppPermissionType.location: 
        'نحتاج موقعك الجغرافي لحساب أوقات الصلاة الدقيقة بناءً على موقعك، '
        'وكذلك لتحديد اتجاه القبلة بشكل صحيح. '
        'لن يتم مشاركة موقعك مع أي جهة خارجية.',
        
    AppPermissionType.backgroundLocation: 
        'للحصول على تنبيهات دقيقة حتى عندما يكون التطبيق مغلقاً، '
        'خاصةً عند السفر أو تغيير الموقع. '
        'هذا الإذن اختياري ويمكن تخطيه.',
        
    AppPermissionType.notification: 
        'للتذكير بأذكار الصباح والمساء، وأوقات الصلاة الخمس، '
        'والأذكار المخصصة التي تضيفها. '
        'بدون هذا الإذن لن تتلقى أي تنبيهات.',
        
    AppPermissionType.exactAlarm: 
        'لضمان وصول التنبيهات في الوقت المحدد بالضبط، '
        'خاصة لأوقات الصلاة والأذكار المجدولة. '
        'بدونه قد تتأخر التنبيهات عدة دقائق.',
        
    AppPermissionType.batteryOptimization: 
        'لضمان استمرار عمل التطبيق في الخلفية وعدم إيقافه من قبل النظام. '
        'هذا يضمن وصول التنبيهات حتى مع تفعيل وضع توفير الطاقة.',
        
    AppPermissionType.systemAlertWindow: 
        'لعرض تنبيهات سريعة فوق التطبيقات الأخرى عند حلول وقت الذكر. '
        'هذا الإذن اختياري ويحسن تجربة التنبيهات.',
  };
  
  /// الفوائد من كل إذن
  static const Map<AppPermissionType, String> permissionBenefits = {
    AppPermissionType.location: 
        'ستحصل على أوقات صلاة دقيقة 100% واتجاه قبلة صحيح بناءً على موقعك.',
        
    AppPermissionType.backgroundLocation: 
        'تنبيهات ذكية تتكيف مع موقعك حتى أثناء السفر.',
        
    AppPermissionType.notification: 
        'لن تفوتك أي صلاة أو ذكر مع التنبيهات التلقائية.',
        
    AppPermissionType.exactAlarm: 
        'تنبيهات دقيقة 100% في الوقت المحدد بدون تأخير.',
        
    AppPermissionType.batteryOptimization: 
        'التنبيهات ستعمل دائماً حتى مع وضع توفير الطاقة.',
        
    AppPermissionType.systemAlertWindow: 
        'تنبيهات فورية حتى أثناء استخدامك لتطبيقات أخرى.',
  };
  
  /// رسائل الرفض الدائم
  static const Map<AppPermissionType, String> permanentDenialMessages = {
    AppPermissionType.location: 
        'إذن الموقع ضروري لحساب أوقات الصلاة واتجاه القبلة. '
        'بدونه لن يعمل التطبيق بشكل صحيح.',
        
    AppPermissionType.backgroundLocation: 
        'هذا الإذن اختياري لكنه يحسن دقة التنبيهات عند تغيير موقعك.',
        
    AppPermissionType.notification: 
        'الإشعارات ضرورية لتذكيرك بالأذكار والصلوات. '
        'بدونها لن تتلقى أي تنبيهات.',
        
    AppPermissionType.exactAlarm: 
        'هذا الإذن مهم لضمان دقة مواعيد الصلاة والأذكار.',
        
    AppPermissionType.batteryOptimization: 
        'بدون هذا الإذن، قد يوقف النظام التطبيق ولن تصلك التنبيهات.',
        
    AppPermissionType.systemAlertWindow: 
        'هذا الإذن اختياري لكنه يحسن تجربة التنبيهات.',
  };
  
  // ============== الأيقونات ==============
  
  /// أيقونات الأذونات
  static const Map<AppPermissionType, IconData> permissionIcons = {
    AppPermissionType.location: Icons.location_on,
    AppPermissionType.backgroundLocation: Icons.my_location,
    AppPermissionType.notification: Icons.notifications_active,
    AppPermissionType.exactAlarm: Icons.alarm,
    AppPermissionType.batteryOptimization: Icons.battery_charging_full,
    AppPermissionType.systemAlertWindow: Icons.picture_in_picture,
  };
  
  /// ألوان الأذونات
  static const Map<AppPermissionType, Color> permissionColors = {
    AppPermissionType.location: Color(0xFF2196F3),       // أزرق
    AppPermissionType.backgroundLocation: Color(0xFF03A9F4), // أزرق فاتح
    AppPermissionType.notification: Color(0xFF4CAF50),   // أخضر
    AppPermissionType.exactAlarm: Color(0xFFFF9800),     // برتقالي
    AppPermissionType.batteryOptimization: Color(0xFF9C27B0), // بنفسجي
    AppPermissionType.systemAlertWindow: Color(0xFF607D8B),   // رمادي مزرق
  };
  
  // ============== مساعدات ==============
  
  /// الحصول على الأذونات المطلوبة حسب إصدار Android
  static List<AppPermissionType> getPermissionsForAndroidVersion(int sdkVersion) {
    return AppPermissionType.values.where((permission) {
      final minVersion = minAndroidVersions[permission] ?? 0;
      return sdkVersion >= minVersion;
    }).toList();
  }
  
  /// الحصول على الأذونات الحرجة فقط
  static List<AppPermissionType> getCriticalPermissionsForAndroidVersion(int sdkVersion) {
    return criticalPermissions.where((permission) {
      final minVersion = minAndroidVersions[permission] ?? 0;
      return sdkVersion >= minVersion;
    }).toList();
  }
  
  /// فحص إذا كان الإذن حرجاً
  static bool isCriticalPermission(AppPermissionType permission) {
    return criticalPermissions.contains(permission);
  }
  
  /// فحص إذا كان الإذن اختيارياً
  static bool isOptionalPermission(AppPermissionType permission) {
    return optionalPermissions.contains(permission);
  }
  
  /// فحص إذا كان الإذن موصى به
  static bool isRecommendedPermission(AppPermissionType permission) {
    return recommendedPermissions.contains(permission);
  }
  
  /// الحصول على أولوية الإذن (رقم أصغر = أولوية أعلى)
  static int getPermissionPriority(AppPermissionType permission) {
    final index = requestOrder.indexOf(permission);
    return index >= 0 ? index : 999;
  }
  
  /// ترتيب قائمة أذونات حسب الأولوية
  static List<AppPermissionType> sortByPriority(List<AppPermissionType> permissions) {
    final sorted = List<AppPermissionType>.from(permissions);
    sorted.sort((a, b) => getPermissionPriority(a).compareTo(getPermissionPriority(b)));
    return sorted;
  }
  
  /// الحصول على وصف الإذن
  static String getPermissionDescription(
    AppPermissionType permission, {
    bool detailed = false,
  }) {
    if (detailed) {
      return permissionDetailedDescriptions[permission] ?? 
             permissionShortDescriptions[permission] ?? 
             'إذن مطلوب للتطبيق';
    }
    return permissionShortDescriptions[permission] ?? 'إذن مطلوب';
  }
  
  /// الحصول على عنوان الإذن
  static String getPermissionTitle(AppPermissionType permission) {
    return permissionTitles[permission] ?? permission.name;
  }
  
  /// الحصول على أيقونة الإذن
  static IconData getPermissionIcon(AppPermissionType permission) {
    return permissionIcons[permission] ?? Icons.security;
  }
  
  /// الحصول على لون الإذن
  static Color getPermissionColor(AppPermissionType permission) {
    return permissionColors[permission] ?? Colors.grey;
  }
  
  /// الحصول على فائدة الإذن
  static String getPermissionBenefit(AppPermissionType permission) {
    return permissionBenefits[permission] ?? 'يحسن تجربة التطبيق';
  }
  
  /// الحصول على رسالة الرفض الدائم
  static String getPermanentDenialMessage(AppPermissionType permission) {
    return permanentDenialMessages[permission] ?? 
           'يرجى السماح بهذا الإذن من إعدادات التطبيق.';
  }
  
  /// الحصول على الحد الأدنى لإصدار Android
  static int? getMinAndroidVersion(AppPermissionType permission) {
    return minAndroidVersions[permission];
  }
}

/// امتدادات لـ AppPermissionType
extension AppPermissionTypeExtension on AppPermissionType {
  /// هل الإذن حرج؟
  bool get isCritical => PermissionConstants.isCriticalPermission(this);
  
  /// هل الإذن اختياري؟
  bool get isOptional => PermissionConstants.isOptionalPermission(this);
  
  /// هل الإذن موصى به؟
  bool get isRecommended => PermissionConstants.isRecommendedPermission(this);
  
  /// الحصول على العنوان
  String get title => PermissionConstants.getPermissionTitle(this);
  
  /// الحصول على الوصف المختصر
  String get shortDescription => PermissionConstants.getPermissionDescription(this);
  
  /// الحصول على الوصف التفصيلي
  String get detailedDescription => PermissionConstants.getPermissionDescription(this, detailed: true);
  
  /// الحصول على الفائدة
  String get benefit => PermissionConstants.getPermissionBenefit(this);
  
  /// الحصول على رسالة الرفض الدائم
  String get permanentDenialMessage => PermissionConstants.getPermanentDenialMessage(this);
  
  /// الحصول على الأيقونة
  IconData get icon => PermissionConstants.getPermissionIcon(this);
  
  /// الحصول على اللون
  Color get color => PermissionConstants.getPermissionColor(this);
  
  /// الحصول على الأولوية
  int get priority => PermissionConstants.getPermissionPriority(this);
  
  /// الحصول على الحد الأدنى لإصدار Android
  int? get minAndroidVersion => PermissionConstants.getMinAndroidVersion(this);
}