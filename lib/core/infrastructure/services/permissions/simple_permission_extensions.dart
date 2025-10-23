// lib/core/infrastructure/services/permissions/simple_permission_extensions.dart
// Extensions مفيدة للخدمة البسيطة

import 'package:flutter/material.dart';
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

  /// طلب أذونات متعددة بطريقة مجمعة
  Future<PermissionResults> requestMultiplePermissions() async {
    return await permissionService.requestMultiplePermissions(this);
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

  /// عرض رسالة خطأ الأذونات
  void showPermissionDeniedSnackBar(String permissionName) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text('⚠️ إذن $permissionName مطلوب لعمل هذه الميزة'),
        action: SnackBarAction(
          label: 'الإعدادات',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  /// عرض رسالة نجاح الأذونات
  void showPermissionGrantedSnackBar(String permissionName) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text('✅ تم منح إذن $permissionName بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
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

  /// عرض نتائج الأذونات في SnackBar
  void showResultInSnackBar(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    
    if (allGranted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(description),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('المطلوب: ${deniedPermissionNames.join('، ')}'),
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