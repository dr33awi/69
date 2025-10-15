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

/// مراقب الأذونات بنمط أنيق وبسيط - محدث بدون تكرار
class PermissionMonitor extends StatefulWidget {
  final Widget child;
  final bool showNotifications;
  final bool skipInitialCheck; // إضافة خيار لتخطي الفحص الأولي
  
  const PermissionMonitor({
    super.key,
    required this.child,
    this.showNotifications = true,
    this.skipInitialCheck = false, // القيمة الافتراضية
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
  bool _userWentToSettings = false;
  
  // ==================== متغيرات محدثة لمنع التكرار ====================
  bool _hasPerformedInitialCheck = false;
  bool _isSubscribedToManager = false;
  DateTime? _lastResumeCheckTime;
  static const Duration _resumeCheckThrottle = Duration(seconds: 5);
  // ========================================================================
  
  final Map<AppPermissionType, DateTime> _dismissedPermissions = {};
  DateTime? _lastCheckTime;
  
  static const Duration _dismissalDuration = Duration(hours: 1);
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _manager = getIt<UnifiedPermissionManager>();
    _permissionService = getIt<PermissionService>();
    
    debugPrint('[PermissionMonitor] 🚀 Initializing...');
    debugPrint('[PermissionMonitor]   - skipInitialCheck: ${widget.skipInitialCheck}');
    debugPrint('[PermissionMonitor]   - showNotifications: ${widget.showNotifications}');
    
    _listenToPermissionChanges();
    
    // فحص أولي فقط إذا لم يُطلب تخطيه
    if (!widget.skipInitialCheck) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        _performInitialCheck();
      });
    } else {
      debugPrint('[PermissionMonitor] ℹ️ Skipping initial check as requested');
      // فقط نستخدم النتيجة الموجودة إن وجدت
      _useExistingResultIfAvailable();
    }
  }
  
  void _listenToPermissionChanges() {
    if (_isSubscribedToManager) return;
    
    _isSubscribedToManager = true;
    
    debugPrint('[PermissionMonitor] 👂 Subscribing to permission changes');
    
    _manager.stateStream.listen((result) {
      debugPrint('[PermissionMonitor] 📨 Received state update from manager');
      debugPrint('[PermissionMonitor]   - Missing: ${result.missingCount}');
      debugPrint('[PermissionMonitor]   - Granted: ${result.grantedCount}');
      _processCheckResult(result);
    });
    
    _manager.changeStream.listen((event) {
      debugPrint('[PermissionMonitor] 🔄 Permission change event: ${event.permission}');
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
  
  // دالة جديدة لاستخدام النتيجة الموجودة
  void _useExistingResultIfAvailable() {
    if (_manager.lastCheckResult != null) {
      debugPrint('[PermissionMonitor] ✅ Using existing result from manager');
      _processCheckResult(_manager.lastCheckResult!);
    } else {
      debugPrint('[PermissionMonitor] ℹ️ No existing result available');
    }
  }
  
  void _performInitialCheck() {
    if (!mounted || _hasPerformedInitialCheck) {
      debugPrint('[PermissionMonitor] ⚠️ Skipping initial check - already performed or not mounted');
      return;
    }
    
    // إضافة فحص إذا كان يجب التخطي
    if (widget.skipInitialCheck) {
      debugPrint('[PermissionMonitor] ℹ️ Skipping initial check as requested (double check)');
      _useExistingResultIfAvailable();
      return;
    }
    
    _hasPerformedInitialCheck = true;
    
    debugPrint('[PermissionMonitor] 🔍 Performing initial check...');
    
    // استخدام النتيجة الموجودة من Manager بدلاً من فحص جديد
    if (_manager.lastCheckResult != null) {
      debugPrint('[PermissionMonitor] ✅ Using existing manager result');
      _processCheckResult(_manager.lastCheckResult!);
    } else {
      debugPrint('[PermissionMonitor] ℹ️ No existing result, waiting for manager to check');
      // لا نقوم بفحص جديد، ننتظر النتيجة من Manager عبر Stream
    }
  }
  
  void _processCheckResult(PermissionCheckResult result) {
    if (!mounted) return;
    
    debugPrint('[PermissionMonitor] 📊 Processing result:');
    debugPrint('[PermissionMonitor]   - Missing: ${result.missingCount} permissions');
    debugPrint('[PermissionMonitor]   - Granted: ${result.grantedCount} permissions');
    
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
        _onAppResumedThrottled();
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
  
  // دالة محدثة مع Throttling
  void _onAppResumedThrottled() {
    // تطبيق throttling للفحص عند العودة
    if (_lastResumeCheckTime != null) {
      final timeSince = DateTime.now().difference(_lastResumeCheckTime!);
      if (timeSince < _resumeCheckThrottle) {
        debugPrint('[PermissionMonitor] ⏱️ Resume check throttled (${timeSince.inSeconds}s < ${_resumeCheckThrottle.inSeconds}s)');
        return;
      }
    }
    
    _lastResumeCheckTime = DateTime.now();
    
    if (_userWentToSettings) {
      _userWentToSettings = false;
      debugPrint('[PermissionMonitor] 🔄 App resumed from settings - checking permissions');
      _recheckPermissionsAfterSettings();
    }
  }
  
  Future<void> _recheckPermissionsAfterSettings() async {
    try {
      debugPrint('[PermissionMonitor] 🔍 Using manager quick check after settings');
      
      // استخدام performQuickCheck من Manager بدلاً من فحص مستقل
      final result = await _manager.performQuickCheck();
      
      if (mounted) {
        _processCheckResult(result);
      }
    } catch (e) {
      debugPrint('[PermissionMonitor] ❌ Error in quick check: $e');
    }
  }
  
  void _showNotificationForPermission(AppPermissionType permission) {
    final dismissedAt = _dismissedPermissions[permission];
    if (dismissedAt != null && 
        DateTime.now().difference(dismissedAt) < _dismissalDuration) {
      debugPrint('[PermissionMonitor] ⏰ Permission notification dismissed temporarily: $permission');
      
      // البحث عن إذن آخر غير مؤجل
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
      debugPrint('[PermissionMonitor] 🚫 Permission dismissed: $_currentPermission');
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
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeConstants.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
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
      // استخدام Manager للطلب (الذي يستخدم Coordinator)
      final granted = await _manager.requestPermissionWithExplanation(
        context,
        _currentPermission!,
        forceRequest: true,
      );
      
      if (granted) {
        _cachedStatuses[_currentPermission!] = AppPermissionStatus.granted;
        _missingPermissions.remove(_currentPermission!);
        _hideNotification(success: true);
        _showSuccessMessage(_currentPermission!);
      } else {
        setState(() => _isProcessing = false);
        
        // فحص إذا كان مرفوض نهائياً
        final status = await _permissionService.checkPermissionStatus(_currentPermission!);
        
        if (status == AppPermissionStatus.permanentlyDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'يرجى تفعيل الإذن من إعدادات النظام',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'الإعدادات',
                textColor: Colors.white,
                onPressed: () {
                  _permissionService.openAppSettings();
                  _userWentToSettings = true;
                },
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              margin: EdgeInsets.all(16.w),
            ),
          );
        }
      }
      
    } catch (e) {
      debugPrint('[PermissionMonitor] ❌ Error requesting permission: $e');
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
    debugPrint('[PermissionMonitor] 🛑 Disposing...');
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
        minHeight: 280.h,
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
              // زر الإغلاق
              Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isProcessing ? null : onDismiss,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 8.h),
              
              // الأيقونة
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      info.color.withOpacity(0.2),
                      info.color.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: info.color.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  info.icon,
                  color: info.color,
                  size: 36.sp,
                ),
              ),
              
              SizedBox(height: 20.h),
              
              // العنوان
              Text(
                'إذن ${info.name}',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[900],
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 10.h),
              
              // الوصف
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  info.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 28.h),
              
              // زر التفعيل
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onActivate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: info.color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: info.color.withOpacity(0.5),
                    elevation: 0,
                    shadowColor: info.color.withOpacity(0.3),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'تفعيل الآن',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.arrow_back,
                              size: 18.sp,
                            ),
                          ],
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