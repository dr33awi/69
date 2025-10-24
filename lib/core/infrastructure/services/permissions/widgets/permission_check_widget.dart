// lib/core/infrastructure/services/permissions/widgets/permission_check_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../app/di/service_locator.dart';
import '../simple_permission_service.dart';

/// Widget لفحص الأذونات عند العودة للتطبيق فقط
class PermissionCheckWidget extends StatefulWidget {
  final Widget child;
  final bool showWarningCard;
  
  const PermissionCheckWidget({
    super.key,
    required this.child,
    this.showWarningCard = true,
  });

  @override
  State<PermissionCheckWidget> createState() => _PermissionCheckWidgetState();
}

class _PermissionCheckWidgetState extends State<PermissionCheckWidget> 
    with WidgetsBindingObserver {
  late final SimplePermissionService _permissionService;
  StreamSubscription<PermissionChange>? _permissionSubscription;
  DateTime? _lastCheckTime;

  @override
  void initState() {
    super.initState();
    _permissionService = getIt<SimplePermissionService>();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialPermissions();
    _listenToPermissionChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _permissionSubscription?.cancel();
    super.dispose();
  }

  /// الاستماع لتغييرات الأذونات
  void _listenToPermissionChanges() {
    _permissionSubscription = _permissionService.permissionChanges.listen((change) {
      debugPrint('🔔 Permission changed: ${change.type.name} = ${change.isGranted}');
      // لا نحتاج setState هنا لأن Widget لا يعرض UI
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ✅ تقليل وقت الانتظار من 5 ثواني إلى 1 ثانية
      // للسماح بفحص أسرع عند العودة من الإعدادات
      if (_lastCheckTime != null) {
        final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
        if (timeSinceLastCheck.inSeconds < 1) {
          return;
        }
      }
      _checkPermissionsOnResume();
    }
  }

  Future<void> _checkInitialPermissions() async {
    _lastCheckTime = DateTime.now();
    await _permissionService.checkAllPermissions();
  }

  Future<void> _checkPermissionsOnResume() async {
    _lastCheckTime = DateTime.now();
    debugPrint('🔄 Checking permissions on app resume');
    await _permissionService.checkPermissionsOnResume();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}