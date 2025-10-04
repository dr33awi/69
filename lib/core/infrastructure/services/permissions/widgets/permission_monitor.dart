// lib/core/infrastructure/services/permissions/widgets/permission_monitor.dart
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  late final UnifiedPermissionManager _manager;
  late final PermissionService _permissionService;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
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
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _manager = getIt<UnifiedPermissionManager>();
    _permissionService = getIt<PermissionService>();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    debugPrint('[PermissionMonitor] Initializing...');
    _performInstantCheck();
  }
  
  void _performInstantCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _hasCheckedPermissions) return;
      
      debugPrint('[PermissionMonitor] Starting instant check...');
      _hasCheckedPermissions = true;
      
      if (_manager.lastCheckResult != null) {
        _processCheckResult(_manager.lastCheckResult!);
      } else {
        await _ultraFastPermissionCheck();
      }
    });
  }
  
  Future<void> _ultraFastPermissionCheck() async {
    try {
      final stopwatch = Stopwatch()..start();
      debugPrint('[PermissionMonitor] Ultra fast check starting...');
      
      final missing = <AppPermissionType>[];
      final granted = <AppPermissionType>[];
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
      
      stopwatch.stop();
      debugPrint('[PermissionMonitor] Check completed in ${stopwatch.elapsedMilliseconds}ms');
      
      if (missing.isNotEmpty) {
        setState(() {
          _missingPermissions = missing;
        });
        
        if (widget.showNotifications && !_isShowingNotification) {
          _showNotificationForPermission(missing.first);
        }
      } else {
        debugPrint('[PermissionMonitor] All permissions granted ✅');
      }
      
    } catch (e) {
      debugPrint('[PermissionMonitor] Error in ultra fast check: $e');
    }
  }
  
  void _processCheckResult(PermissionCheckResult result) {
    setState(() {
      _missingPermissions = result.missingPermissions
          .where((p) => PermissionConstants.isCritical(p))
          .toList();
      
      _cachedStatuses = Map.from(result.statuses);
    });
    
    if (_missingPermissions.isNotEmpty && widget.showNotifications && !_isShowingNotification) {
      _showNotificationForPermission(_missingPermissions.first);
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _userWentToSettings = true;
        break;
      default:
        break;
    }
  }
  
  void _onAppResumed() {
    if (!_userWentToSettings) return;
    
    _userWentToSettings = false;
    debugPrint('[PermissionMonitor] App resumed - checking permissions...');
    
    _instantPermissionCheck();
  }
  
  Future<void> _instantPermissionCheck() async {
    if (_lastCheckTime != null) {
      final timeSince = DateTime.now().difference(_lastCheckTime!);
      if (timeSince < const Duration(milliseconds: 500)) return;
    }
    
    _lastCheckTime = DateTime.now();
    
    try {
      await Future.wait(
        _cachedStatuses.entries.map((entry) async {
          final permission = entry.key;
          final oldStatus = entry.value;
          
          final newStatus = await _permissionService.checkPermissionStatus(permission);
          
          if (oldStatus != newStatus) {
            _cachedStatuses[permission] = newStatus;
            
            if (mounted) {
              setState(() {
                if (newStatus != AppPermissionStatus.granted) {
                  if (!_missingPermissions.contains(permission)) {
                    _missingPermissions.add(permission);
                  }
                  
                  if (!_isShowingNotification && widget.showNotifications) {
                    _showNotificationForPermission(permission);
                  }
                } else {
                  _missingPermissions.remove(permission);
                  
                  if (_currentPermission == permission) {
                    _hideNotification(success: true);
                  }
                  
                  _showSuccessMessage(permission);
                }
              });
            }
          }
        }),
        eagerError: false,
      );
      
    } catch (e) {
      debugPrint('[PermissionMonitor] Error in instant check: $e');
    }
  }
  
  void _showNotificationForPermission(AppPermissionType permission) {
    final dismissedAt = _dismissedPermissions[permission];
    if (dismissedAt != null && 
        DateTime.now().difference(dismissedAt) < _dismissalDuration) {
      return;
    }
    
    debugPrint('[PermissionMonitor] 🔔 Showing notification for: $permission');
    
    setState(() {
      _currentPermission = permission;
      _isShowingNotification = true;
    });
    
    _animationController.forward();
    HapticFeedback.mediumImpact();
  }
  
  void _hideNotification({bool success = false, bool dismissed = false}) {
    if (!mounted) return;
    
    if (dismissed && _currentPermission != null) {
      _dismissedPermissions[_currentPermission!] = DateTime.now();
    }
    
    _animationController.reverse().then((_) {
      if (mounted) {
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
      }
    });
    
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
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Container(
              color: Colors.black.withOpacity(_fadeAnimation.value * 0.6),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 8 * _fadeAnimation.value,
                  sigmaY: 8 * _fadeAnimation.value,
                ),
                child: Container(color: Colors.transparent),
              ),
            );
          },
        ),
      ),
      
      Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: child,
              ),
            );
          },
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
      ),
    ];
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
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