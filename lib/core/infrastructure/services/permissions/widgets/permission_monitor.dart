// lib/core/infrastructure/services/permissions/widgets/permission_monitor.dart
// محدث: حل مشكلة عدم ظهور الإشعار عند تعطيل الأذونات

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/app/themes/widgets/core/app_button.dart';
import '../permission_manager.dart';
import '../permission_service.dart';
import '../permission_constants.dart';
import '../models/permission_state.dart';

/// مراقب الأذونات بنمط أنيق وبسيط - محدث للكشف عن تعطيل الأذونات
class PermissionMonitor extends StatefulWidget {
  final Widget child;
  final bool showNotifications;
  final bool skipInitialCheck;
  
  const PermissionMonitor({
    super.key,
    required this.child,
    this.showNotifications = true,
    this.skipInitialCheck = false,
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
  
  bool _hasPerformedInitialCheck = false;
  bool _isSubscribedToManager = false;
  DateTime? _lastResumeCheckTime;
  static const Duration _resumeCheckThrottle = Duration(seconds: 3); // تقليل الوقت
  
  // إضافة Timer للفحص الدوري
  Timer? _periodicCheckTimer;
  static const Duration _periodicCheckInterval = Duration(seconds: 10); // فحص كل 10 ثواني
  
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
    _startPeriodicCheck(); // بدء الفحص الدوري
    
    if (!widget.skipInitialCheck) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        _performInitialCheck();
      });
    } else {
      debugPrint('[PermissionMonitor] ℹ️ Skipping initial check as requested');
      _useExistingResultIfAvailable();
    }
  }
  
  // إضافة دالة الفحص الدوري
  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(_periodicCheckInterval, (_) {
      if (mounted && !_isProcessing) {
        _performBackgroundCheck();
      }
    });
  }
  
  // فحص صامت في الخلفية
  Future<void> _performBackgroundCheck() async {
    try {
      debugPrint('[PermissionMonitor] 🔄 Background permission check...');
      
      // فحص سريع للأذونات الحرجة
      final currentStatuses = await _permissionService.checkAllPermissions();
      
      bool hasChanges = false;
      final newMissing = <AppPermissionType>[];
      
      for (final entry in currentStatuses.entries) {
        final permission = entry.key;
        final newStatus = entry.value;
        final oldStatus = _cachedStatuses[permission];
        
        // إذا كان الإذن حرج
        if (PermissionConstants.isCritical(permission)) {
          if (newStatus != AppPermissionStatus.granted) {
            newMissing.add(permission);
            
            // إذا تغير من ممنوح إلى غير ممنوح
            if (oldStatus == AppPermissionStatus.granted) {
              hasChanges = true;
              debugPrint('[PermissionMonitor] ⚠️ Permission revoked: $permission');
            }
          }
        }
        
        _cachedStatuses[permission] = newStatus;
      }
      
      // تحديث قائمة الأذونات المفقودة
      setState(() {
        _missingPermissions = newMissing;
      });
      
      // إذا كان هناك تغييرات وهناك أذونات مفقودة، اعرض الإشعار
      if (hasChanges || (newMissing.isNotEmpty && !_isShowingNotification)) {
        if (widget.showNotifications && newMissing.isNotEmpty && !_isShowingNotification) {
          debugPrint('[PermissionMonitor] 🔔 Showing notification for revoked permissions');
          _showNotificationForPermission(newMissing.first);
        }
      }
      
      // إذا تم منح جميع الأذونات وكان الإشعار معروض، أخفه
      if (newMissing.isEmpty && _isShowingNotification) {
        debugPrint('[PermissionMonitor] ✅ All permissions restored - hiding notification');
        _hideNotification(success: true);
      }
      
    } catch (e) {
      debugPrint('[PermissionMonitor] ❌ Background check error: $e');
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
      debugPrint('[PermissionMonitor]   - All granted: ${result.allGranted}');
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
    
    if (widget.skipInitialCheck) {
      debugPrint('[PermissionMonitor] ℹ️ Skipping initial check as requested (double check)');
      _useExistingResultIfAvailable();
      return;
    }
    
    _hasPerformedInitialCheck = true;
    
    debugPrint('[PermissionMonitor] 🔍 Performing initial check...');
    
    if (_manager.lastCheckResult != null) {
      debugPrint('[PermissionMonitor] ✅ Using existing manager result');
      _processCheckResult(_manager.lastCheckResult!);
    } else {
      debugPrint('[PermissionMonitor] ℹ️ No existing result, waiting for manager to check');
    }
  }
  
  void _processCheckResult(PermissionCheckResult result) {
    if (!mounted) return;
    
    debugPrint('[PermissionMonitor] 📊 Processing result:');
    debugPrint('[PermissionMonitor]   - Missing: ${result.missingCount} permissions');
    debugPrint('[PermissionMonitor]   - Granted: ${result.grantedCount} permissions');
    debugPrint('[PermissionMonitor]   - All granted: ${result.allGranted}');
    
    setState(() {
      // تحديث الأذونات المفقودة - فقط الحرجة
      _missingPermissions = result.missingPermissions
          .where((p) => PermissionConstants.isCritical(p))
          .toList();
      
      _cachedStatuses = Map.from(result.statuses);
      
      // إذا كانت جميع الأذونات ممنوحة، تأكد من إخفاء الإشعار
      if (result.allGranted || _missingPermissions.isEmpty) {
        if (_isShowingNotification) {
          debugPrint('[PermissionMonitor] ✅ All permissions granted - hiding notification');
          _hideNotification(success: true);
        }
      }
    });
    
    // عرض الإشعار فقط إذا كانت هناك أذونات مفقودة
    if (_missingPermissions.isNotEmpty && 
        widget.showNotifications && 
        !_isShowingNotification) {
      
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_isShowingNotification && _missingPermissions.isNotEmpty) {
          debugPrint('[PermissionMonitor] 🔔 Showing notification for missing permissions');
          _showNotificationForPermission(_missingPermissions.first);
        }
      });
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[PermissionMonitor] 📱 App lifecycle state: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        // تسجيل أن المستخدم قد يكون ذهب للإعدادات
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
  
  // تحسين دالة العودة للتطبيق
  void _onAppResumed() {
    // فحص فوري عند العودة للتطبيق بغض النظر عن المصدر
    debugPrint('[PermissionMonitor] 🔄 App resumed - checking permissions immediately');
    
    // تأخير بسيط للتأكد من استقرار النظام
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _recheckPermissionsAfterResume();
      }
    });
  }
  
  Future<void> _recheckPermissionsAfterResume() async {
    try {
      debugPrint('[PermissionMonitor] 🔍 Rechecking permissions after resume');
      
      // فحص سريع ومباشر
      final currentStatuses = await _permissionService.checkAllPermissions();
      
      final newMissing = <AppPermissionType>[];
      bool hasChanges = false;
      
      for (final entry in currentStatuses.entries) {
        final permission = entry.key;
        final newStatus = entry.value;
        final oldStatus = _cachedStatuses[permission];
        
        if (PermissionConstants.isCritical(permission)) {
          if (newStatus != AppPermissionStatus.granted) {
            newMissing.add(permission);
          }
          
          // رصد التغييرات
          if (oldStatus != newStatus) {
            hasChanges = true;
            debugPrint('[PermissionMonitor] 🔄 Permission changed: $permission from $oldStatus to $newStatus');
          }
        }
        
        _cachedStatuses[permission] = newStatus;
      }
      
      // تحديث الحالة
      setState(() {
        _missingPermissions = newMissing;
      });
      
      // إدارة الإشعارات
      if (newMissing.isEmpty && _isShowingNotification) {
        // إخفاء الإشعار إذا تم منح جميع الأذونات
        debugPrint('[PermissionMonitor] ✅ All permissions granted after resume');
        _hideNotification(success: true);
      } else if (newMissing.isNotEmpty && !_isShowingNotification && widget.showNotifications) {
        // عرض الإشعار إذا كانت هناك أذونات مفقودة
        debugPrint('[PermissionMonitor] ⚠️ Missing permissions detected after resume');
        _showNotificationForPermission(newMissing.first);
      }
      
      // أيضاً قم بفحص Manager
      final managerResult = await _manager.performQuickCheck();
      _processCheckResult(managerResult);
      
    } catch (e) {
      debugPrint('[PermissionMonitor] ❌ Error rechecking after resume: $e');
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
    
    // إذا نجح الطلب، تحقق من باقي الأذونات
    if (success && _missingPermissions.isNotEmpty) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !_isShowingNotification) {
          // فحص كامل للتأكد من الحالة الحالية
          debugPrint('[PermissionMonitor] 🔄 Checking for remaining missing permissions');
          _manager.performQuickCheck().then((result) {
            if (mounted) {
              _processCheckResult(result);
            }
          });
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
      debugPrint('[PermissionMonitor] 📱 Requesting permission: $_currentPermission');
      
      // استخدام Manager للطلب
      final granted = await _manager.requestPermissionWithExplanation(
        context,
        _currentPermission!,
        forceRequest: true,
      );
      
      debugPrint('[PermissionMonitor] 📊 Permission request result: $granted');
      
      if (granted) {
        // تحديث الحالة المحلية فوراً
        setState(() {
          _cachedStatuses[_currentPermission!] = AppPermissionStatus.granted;
          _missingPermissions.remove(_currentPermission!);
          debugPrint('[PermissionMonitor] ✅ Updated local state - remaining missing: ${_missingPermissions.length}');
        });
        
        // إخفاء الإشعار
        _hideNotification(success: true);
        _showSuccessMessage(_currentPermission!);
        
        // فحص كامل للأذونات بعد التحديث للتأكد من الحالة
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (mounted) {
            debugPrint('[PermissionMonitor] 🔄 Performing full check after permission grant');
            final result = await _manager.performQuickCheck();
            _processCheckResult(result);
          }
        });
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
        
        // عرض الإشعار فقط إذا كان هناك إذن حالي وكانت هناك أذونات مفقودة
        if (_isShowingNotification && _currentPermission != null && _missingPermissions.isNotEmpty)
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
    _periodicCheckTimer?.cancel(); // إيقاف الفحص الدوري
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
              AppButton(
                text: 'تفعيل الآن',
                onPressed: isProcessing ? null : onActivate,
                size: ButtonSize.medium,
                customColor: info.color,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}