// lib/core/infrastructure/services/permissions/widgets/permission_check_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  bool _hasNotificationPermission = true;
  bool _hasLocationPermission = true;
  bool _showWarning = false;
  DateTime? _lastCheckTime;

  @override
  void initState() {
    super.initState();
    _permissionService = getIt<SimplePermissionService>();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_lastCheckTime != null) {
        final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
        if (timeSinceLastCheck.inSeconds < 5) {
          return;
        }
      }
      _checkPermissionsOnResume();
    }
  }

  Future<void> _checkInitialPermissions() async {
    _lastCheckTime = DateTime.now();
    final results = await _permissionService.checkAllPermissions();
    if (mounted) {
      setState(() {
        _hasNotificationPermission = results.notification;
        _hasLocationPermission = results.location;
        _showWarning = widget.showWarningCard && 
                      (!_hasNotificationPermission || !_hasLocationPermission);
      });
    }
  }

  Future<void> _checkPermissionsOnResume() async {
    _lastCheckTime = DateTime.now();
    debugPrint('🔄 Checking permissions on app resume');
    
    final results = await _permissionService.checkPermissionsOnResume();
    
    if (mounted) {
      setState(() {
        _hasNotificationPermission = results.notification;
        _hasLocationPermission = results.location;
        _showWarning = widget.showWarningCard && 
                      (!_hasNotificationPermission || !_hasLocationPermission);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}