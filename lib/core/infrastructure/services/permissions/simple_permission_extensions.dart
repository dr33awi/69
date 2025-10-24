// lib/core/infrastructure/services/permissions/simple_permission_extensions.dart
// Extensions مفيدة للخدمة البسيطة - محسّن مع UI موحد

import 'package:athkar_app/app/themes/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/di/service_locator.dart';
import 'simple_permission_service.dart';

/// Extensions مفيدة لـ BuildContext
extension SimplePermissionContext on BuildContext {
  /// الحصول على خدمة الأذونات البسيطة
  SimplePermissionService get permissionService => getIt<SimplePermissionService>();

  /// طلب إذن الإشعارات بسهولة
  Future<bool> requestNotificationPermission() async {
    return await permissionService.requestNotificationPermission(this);
  }

  /// طلب إذن الموقع بسهولة
  Future<bool> requestLocationPermission() async {
    return await permissionService.requestLocationPermission(this);
  }

  /// طلب جميع الأذونات بسهولة
  Future<PermissionResults> requestAllPermissions() async {
    return await permissionService.requestAllPermissions(this);
  }

  /// فحص الأذونات بدون طلب
  Future<PermissionResults> checkAllPermissions() async {
    return await permissionService.checkAllPermissions();
  }

  /// فحص إذن الإشعارات فقط
  Future<bool> checkNotificationPermission() async {
    return await permissionService.checkNotificationPermission();
  }

  /// فحص إذن الموقع فقط
  Future<bool> checkLocationPermission() async {
    return await permissionService.checkLocationPermission();
  }

  /// فتح إعدادات التطبيق
  Future<bool> openAppSettings() async {
    return await permissionService.openAppSettings();
  }

  // ==================== رسائل موحدة ====================

  /// عرض رسالة نجاح منح الإذن - موحدة
  void showPermissionGrantedMessage(String permissionName) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'تم منح إذن $permissionName بنجاح',
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeConstants.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  /// عرض رسالة رفض الإذن - موحدة
  void showPermissionDeniedMessage(String permissionName) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.location_off, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'إذن $permissionName مطلوب لاستخدام هذه الميزة',
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeConstants.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'الإعدادات',
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  /// طلب إذن مع رسائل موحدة
  Future<bool> requestPermissionWithMessages({
    required Future<bool> Function() requestFunction,
    required String permissionName,
  }) async {
    final granted = await requestFunction();
    
    if (granted) {
      showPermissionGrantedMessage(permissionName);
    } else {
      showPermissionDeniedMessage(permissionName);
    }
    
    return granted;
  }

  /// عرض رسالة طلب الأذونات مع إجراء
  Future<void> showPermissionRequestDialog({
    required String title,
    required String message,
    required VoidCallback onAccept,
    VoidCallback? onDecline,
  }) async {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onDecline != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDecline();
              },
              child: const Text('لاحقاً'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAccept();
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// عرض رسالة خطأ الأذونات - استخدام النظام الموحد
  void showPermissionDeniedSnackBar(String permissionName) {
    showPermissionDeniedMessage(permissionName);
  }

  /// عرض رسالة نجاح الأذونات - استخدام النظام الموحد
  void showPermissionGrantedSnackBar(String permissionName) {
    showPermissionGrantedMessage(permissionName);
  }
}

/// Extensions مفيدة للـ PermissionResults
extension PermissionResultsExtension on PermissionResults {
  /// رسالة وصفية للنتائج
  String get description {
    if (allGranted) {
      return '✅ تم منح جميع الأذونات بنجاح';
    } else if (anyGranted) {
      return '⚠️ تم منح بعض الأذونات فقط';
    } else {
      return '❌ لم يتم منح أي أذونات';
    }
  }

  /// قائمة الأذونات الممنوحة بالأسماء العربية
  List<String> get grantedPermissionNames {
    final granted = <String>[];
    if (notification) granted.add('الإشعارات');
    if (location) granted.add('الموقع');
    return granted;
  }

  /// قائمة الأذونات المرفوضة بالأسماء العربية  
  List<String> get deniedPermissionNames {
    final denied = <String>[];
    if (!notification) denied.add('الإشعارات');
    if (!location) denied.add('الموقع');
    return denied;
  }

  /// عرض نتائج الأذونات في SnackBar - استخدام النظام الموحد
  void showResultInSnackBar(BuildContext context) {
    if (allGranted) {
      context.showPermissionGrantedMessage('جميع الأذونات');
    } else {
      final deniedList = deniedPermissionNames.join('، ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('المطلوب: $deniedList'),
          action: SnackBarAction(
            label: 'الإعدادات',
            onPressed: () => context.openAppSettings(),
          ),
        ),
      );
    }
  }
}

/// Extensions لـ PermissionType
extension PermissionTypeHelpers on PermissionType {
  /// الاسم العربي للإذن
  String get nameAr {
    switch (this) {
      case PermissionType.notification:
        return 'الإشعارات';
      case PermissionType.location:
        return 'الموقع';
    }
  }

  /// أيقونة الإذن
  IconData get icon {
    switch (this) {
      case PermissionType.notification:
        return Icons.notifications_active;
      case PermissionType.location:
        return Icons.location_on;
    }
  }

  /// لون الإذن
  Color get color {
    switch (this) {
      case PermissionType.notification:
        return Colors.blue;
      case PermissionType.location:
        return Colors.green;
    }
  }
}

/// Widget بسيط لطلب الأذونات
class SimplePermissionRequester extends StatefulWidget {
  final Widget child;
  final bool checkOnInit;
  final bool requestOnInit;
  final bool showSnackBarResults;

  const SimplePermissionRequester({
    super.key,
    required this.child,
    this.checkOnInit = true,
    this.requestOnInit = false,
    this.showSnackBarResults = true,
  });

  @override
  State<SimplePermissionRequester> createState() => _SimplePermissionRequesterState();
}

class _SimplePermissionRequesterState extends State<SimplePermissionRequester> {
  @override
  void initState() {
    super.initState();
    if (widget.checkOnInit) {
      _checkPermissions();
    }
    if (widget.requestOnInit) {
      _requestPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final results = await context.checkAllPermissions();
    if (widget.showSnackBarResults && !results.allGranted) {
      results.showResultInSnackBar(context);
    }
  }

  Future<void> _requestPermissions() async {
    final results = await context.requestAllPermissions();
    if (widget.showSnackBarResults) {
      results.showResultInSnackBar(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}