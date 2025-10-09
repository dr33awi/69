// lib/features/onboarding/permission/permission_monitor.dart


import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import '../permission_manager.dart';
import '../permission_service.dart';
import '../permission_constants.dart';
import '../models/permission_state.dart';

/// مراقب الأذونات بنمط أنيق وبسيط
class PermissionMonitor extends StatefulWidget {
  final Widget child;
  final bool showNotifications;
  
  const PermissionMonitor({
    super.key,
    required this.child,
    this.showNotifications = true,
  });

  @override
  State<PermissionMonitor> createState() => _PermissionMonitorState();
}

class _PermissionMonitorState extends State<PermissionMonitor> 
    with WidgetsBindingObserver {
  
  late final UnifiedPermissionManager _manager;
  late final PermissionService _permissionService;
  
  Map<AppPermissionType, AppPermissionStatus> _cachedStatuses = {};
  List<AppPermissionType> _missingPermissions = [];
  AppPermissionType? _currentPermission;
  bool _isShowingNotification = false;
  bool _isProcessing = false;
  bool _hasCheckedPermissions = false;
  bool _userWentToSettings = false;
  
  final Map<AppPermissionType, DateTime> _dismissedPermissions = {};
  DateTime? _lastCheckTime;
  
  static const Duration _dismissalDuration = Duration(hours: 1);
  static const Duration _initialCheckDelay = Duration(milliseconds: 500);
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _manager = getIt<UnifiedPermissionManager>();
    _permissionService = getIt<PermissionService>();
    
    debugPrint('[PermissionMonitor] Initializing...');
    
    _listenToPermissionChanges();
    
    Future.delayed(_initialCheckDelay, () {
      _performInitialCheck();
    });
  }
  
  void _listenToPermissionChanges() {
    _manager.stateStream.listen((result) {
      debugPrint('[PermissionMonitor] Received state update from manager');
      _processCheckResult(result);
    });
    
    _manager.changeStream.listen((event) {
      debugPrint('[PermissionMonitor] Permission change event: ${event.permission}');
      _handlePermissionChangeEvent(event);
    });
  }
  
  void _handlePermissionChangeEvent(PermissionChangeEvent event) {
    if (event.wasGranted) {
      setState(() {
        _missingPermissions.remove(event.permission);
        _cachedStatuses[event.permission] = event.newStatus;
      });
      
      if (_currentPermission == event.permission) {
        _hideNotification(success: true);
      }
      
      _showSuccessMessage(event.permission);
      
    } else if (event.wasRevoked) {
      setState(() {
        if (!_missingPermissions.contains(event.permission)) {
          _missingPermissions.add(event.permission);
        }
        _cachedStatuses[event.permission] = event.newStatus;
      });
      
      if (!_isShowingNotification && widget.showNotifications) {
        _showNotificationForPermission(event.permission);
      }
    }
  }
  
  void _performInitialCheck() {
    if (!mounted || _hasCheckedPermissions) return;
    
    debugPrint('[PermissionMonitor] Performing initial check...');
    
    if (_manager.lastCheckResult != null) {
      debugPrint('[PermissionMonitor] Using existing manager result');
      _processCheckResult(_manager.lastCheckResult!);
      _hasCheckedPermissions = true;
    } else {
      debugPrint('[PermissionMonitor] No existing result, performing new check');
      _performFreshCheck();
    }
  }
  
  Future<void> _performFreshCheck() async {
    if (_hasCheckedPermissions) return;
    
    try {
      _hasCheckedPermissions = true;
      
      debugPrint('[PermissionMonitor] Starting fresh permission check...');
      
      final result = await _checkCriticalPermissions();
      
      _processCheckResult(result);
      
    } catch (e) {
      debugPrint('[PermissionMonitor] Error in fresh check: $e');
    }
  }
  
  Future<PermissionCheckResult> _checkCriticalPermissions() async {
    final granted = <AppPermissionType>[];
    final missing = <AppPermissionType>[];
    final statuses = <AppPermissionType, AppPermissionStatus>{};
    
    await Future.wait(
      PermissionConstants.criticalPermissions.map((permission) async {
        try {
          final status = await _permissionService.checkPermissionStatus(permission);
          statuses[permission] = status;
          _cachedStatuses[permission] = status;
          
          if (status == AppPermissionStatus.granted) {
            granted.add(permission);
            debugPrint('[PermissionMonitor] ✅ $permission: GRANTED');
          } else {
            missing.add(permission);
            debugPrint('[PermissionMonitor] ❌ $permission: ${status.toString()}');
          }
        } catch (e) {
          debugPrint('[PermissionMonitor] Error checking $permission: $e');
          missing.add(permission);
        }
      }),
      eagerError: false,
    );
    
    if (missing.isEmpty) {
      return PermissionCheckResult.success(
        granted: granted,
        statuses: statuses,
      );
    } else {
      return PermissionCheckResult.partial(
        granted: granted,
        missing: missing,
        statuses: statuses,
      );
    }
  }
  
  void _processCheckResult(PermissionCheckResult result) {
    if (!mounted) return;
    
    debugPrint('[PermissionMonitor] Processing result: ${result.missingCount} missing permissions');
    
    setState(() {
      _missingPermissions = result.missingPermissions
          .where((p) => PermissionConstants.isCritical(p))
          .toList();
      
      _cachedStatuses = Map.from(result.statuses);
    });
    
    if (_missingPermissions.isNotEmpty && 
        widget.showNotifications && 
        !_isShowingNotification) {
      
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_isShowingNotification && _missingPermissions.isNotEmpty) {
          _showNotificationForPermission(_missingPermissions.first);
        }
      });
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        if (_isShowingNotification || _missingPermissions.isNotEmpty) {
          _userWentToSettings = true;
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }
  
  void _onAppResumed() {
    if (!_userWentToSettings) return;
    
    _userWentToSettings = false;
    debugPrint('[PermissionMonitor] App resumed from settings - checking permissions...');
    
    _recheckPermissionsAfterSettings();
  }
  
  Future<void> _recheckPermissionsAfterSettings() async {
    if (_lastCheckTime != null) {
      final timeSince = DateTime.now().difference(_lastCheckTime!);
      if (timeSince < const Duration(milliseconds: 500)) return;
    }
    
    _lastCheckTime = DateTime.now();
    
    try {
      debugPrint('[PermissionMonitor] Rechecking permissions after settings...');
      
      final changedPermissions = <AppPermissionType>[];
      
      await Future.wait(
        _missingPermissions.map((permission) async {
          final oldStatus = _cachedStatuses[permission] ?? AppPermissionStatus.unknown;
          final newStatus = await _permissionService.checkPermissionStatus(permission);
          
          _cachedStatuses[permission] = newStatus;
          
          if (newStatus == AppPermissionStatus.granted) {
            changedPermissions.add(permission);
            debugPrint('[PermissionMonitor] ✅ Permission granted after settings: $permission');
          }
        }),
        eagerError: false,
      );
      
      if (changedPermissions.isNotEmpty && mounted) {
        setState(() {
          for (final permission in changedPermissions) {
            _missingPermissions.remove(permission);
            
            if (_currentPermission == permission) {
              _hideNotification(success: true);
            }
            
            _showSuccessMessage(permission);
          }
        });
        
        if (_missingPermissions.isNotEmpty && !_isShowingNotification) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && !_isShowingNotification && _missingPermissions.isNotEmpty) {
              _showNotificationForPermission(_missingPermissions.first);
            }
          });
        }
      }
      
      if (changedPermissions.isEmpty && 
          _missingPermissions.isNotEmpty && 
          !_isShowingNotification) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isShowingNotification && _missingPermissions.isNotEmpty) {
            _showNotificationForPermission(_missingPermissions.first);
          }
        });
      }
      
    } catch (e) {
      debugPrint('[PermissionMonitor] Error rechecking after settings: $e');
    }
  }
  
  void _showNotificationForPermission(AppPermissionType permission) {
    final dismissedAt = _dismissedPermissions[permission];
    if (dismissedAt != null && 
        DateTime.now().difference(dismissedAt) < _dismissalDuration) {
      debugPrint('[PermissionMonitor] Permission notification dismissed temporarily: $permission');
      
      for (final p in _missingPermissions) {
        final otherDismissedAt = _dismissedPermissions[p];
        if (otherDismissedAt == null || 
            DateTime.now().difference(otherDismissedAt) >= _dismissalDuration) {
          _showNotificationForPermission(p);
          return;
        }
      }
      return;
    }
    
    debugPrint('[PermissionMonitor] 🔔 Showing notification for: $permission');
    
    setState(() {
      _currentPermission = permission;
      _isShowingNotification = true;
    });
    
    HapticFeedback.mediumImpact();
  }
  
  void _hideNotification({bool success = false, bool dismissed = false}) {
    if (!mounted) return;
    
    if (dismissed && _currentPermission != null) {
      _dismissedPermissions[_currentPermission!] = DateTime.now();
      debugPrint('[PermissionMonitor] Permission dismissed: $_currentPermission');
    }
    
    setState(() {
      _isShowingNotification = false;
      _currentPermission = null;
      _isProcessing = false;
    });
    
    if (success && _missingPermissions.isNotEmpty) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !_isShowingNotification) {
          for (final perm in _missingPermissions) {
            final dismissedAt = _dismissedPermissions[perm];
            if (dismissedAt == null || 
                DateTime.now().difference(dismissedAt) > _dismissalDuration) {
              _showNotificationForPermission(perm);
              break;
            }
          }
        }
      });
    }
    
    if (success) {
      HapticFeedback.heavyImpact();
    }
  }
  
  void _showSuccessMessage(AppPermissionType permission) {
    if (!mounted || !widget.showNotifications) return;
    
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'تم تفعيل إذن ${PermissionConstants.getName(permission)} بنجاح',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeConstants.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }
  
  Future<void> _handlePermissionRequest() async {
    if (_currentPermission == null || _isProcessing) return;
    
    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();
    
    try {
      final currentStatus = await _permissionService.checkPermissionStatus(_currentPermission!);
      
      if (currentStatus == AppPermissionStatus.permanentlyDenied) {
        await _permissionService.openAppSettings();
        _userWentToSettings = true;
        setState(() => _isProcessing = false);
        
      } else {
        final newStatus = await _permissionService.requestPermission(_currentPermission!);
        
        if (newStatus == AppPermissionStatus.granted) {
          _cachedStatuses[_currentPermission!] = newStatus;
          _missingPermissions.remove(_currentPermission!);
          _hideNotification(success: true);
          _showSuccessMessage(_currentPermission!);
        } else {
          setState(() => _isProcessing = false);
          
          if (newStatus == AppPermissionStatus.permanentlyDenied && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'يرجى تفعيل الإذن من إعدادات النظام',
                  style: TextStyle(fontSize: 14.sp),
                ),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'فتح الإعدادات',
                  textColor: Colors.white,
                  onPressed: () {
                    _permissionService.openAppSettings();
                    _userWentToSettings = true;
                  },
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                margin: EdgeInsets.all(16.w),
              ),
            );
          }
        }
      }
      
    } catch (e) {
      debugPrint('[PermissionMonitor] Error requesting permission: $e');
      setState(() => _isProcessing = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        if (_isShowingNotification && _currentPermission != null)
          ..._buildNotificationOverlay(),
      ],
    );
  }
  
  List<Widget> _buildNotificationOverlay() {
    return [
      GestureDetector(
        onTap: () {
          if (!_isProcessing) {
            _hideNotification(dismissed: true);
          }
        },
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      
      Center(
        child: _SimplePermissionCard(
          permission: _currentPermission!,
          isProcessing: _isProcessing,
          onActivate: _handlePermissionRequest,
          onDismiss: () {
            if (!_isProcessing) {
              _hideNotification(dismissed: true);
            }
          },
        ),
      ),
    ];
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// بطاقة الإذن البسيطة والأنيقة
class _SimplePermissionCard extends StatelessWidget {
  final AppPermissionType permission;
  final bool isProcessing;
  final VoidCallback onActivate;
  final VoidCallback onDismiss;
  
  const _SimplePermissionCard({
    required this.permission,
    required this.isProcessing,
    required this.onActivate,
    required this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    final info = PermissionConstants.getInfo(permission);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 0.85.sw,
      constraints: BoxConstraints(
        maxWidth: 380.w,
        minHeight: 260.h,
      ),
      child: Card(
        elevation: 0,
        color: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: isProcessing ? null : onDismiss,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 8.h),
              
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      info.color.withOpacity(0.15),
                      info.color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  info.icon,
                  color: info.color,
                  size: 32.sp,
                ),
              ),
              
              SizedBox(height: 20.h),
              
              Text(
                'إذن ${info.name}',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 10.h),
              
              Text(
                info.description,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.4,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 28.h),
              
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onActivate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: info.color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: info.color.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: isProcessing
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5.w,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'تفعيل الآن',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}