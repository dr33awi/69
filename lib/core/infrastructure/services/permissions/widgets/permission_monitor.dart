// lib/core/infrastructure/services/permissions/widgets/permission_monitor.dart
// ✅ الحل البسيط: فحص واحد فقط عند فتح التطبيق

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

/// مراقب الأذونات البسيط - فحص واحد فقط
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
  
  // ✅ متغيرات بسيطة - بدون تعقيد
  static bool _hasCheckedOnce = false; // فحص مرة واحدة فقط للتطبيق بالكامل
  bool _isShowingNotification = false;
  bool _isProcessing = false;
  AppPermissionType? _currentPermission;
  List<AppPermissionType> _missingPermissions = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _manager = getIt<UnifiedPermissionManager>();
    _permissionService = getIt<PermissionService>();
    
    debugPrint('[PermissionMonitor] 🚀 Simple Monitor - One Check Only');
    
    // ✅ فحص واحد فقط إذا لم يتم الفحص مسبقاً
    if (!widget.skipInitialCheck && !_hasCheckedOnce) {
      _performSingleCheck();
    }
  }
  
  // ✅ الفحص الوحيد - مرة واحدة فقط
  void _performSingleCheck() {
    if (_hasCheckedOnce) {
      debugPrint('[PermissionMonitor] ✅ Already checked once - skipping');
      return;
    }
    
    _hasCheckedOnce = true;
    
    debugPrint('[PermissionMonitor] 🔍 Performing ONE-TIME check...');
    
    // تأخير بسيط للتأكد من استقرار التطبيق
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      
      try {
        // فحص واحد فقط
        final statuses = await _permissionService.checkAllPermissions();
        
        final missing = <AppPermissionType>[];
        
        for (final entry in statuses.entries) {
          final permission = entry.key;
          final status = entry.value;
          
          // فقط الأذونات الحرجة
          if (PermissionConstants.isCritical(permission)) {
            if (status != AppPermissionStatus.granted) {
              missing.add(permission);
              debugPrint('[PermissionMonitor] ❌ Missing: $permission');
            } else {
              debugPrint('[PermissionMonitor] ✅ Granted: $permission');
            }
          }
        }
        
        setState(() {
          _missingPermissions = missing;
        });
        
        // عرض الإشعار إذا كانت هناك أذونات مفقودة
        if (_missingPermissions.isNotEmpty && widget.showNotifications) {
          debugPrint('[PermissionMonitor] 🔔 Showing notification for missing permissions');
          _showNotificationForPermission(_missingPermissions.first);
        } else {
          debugPrint('[PermissionMonitor] ✅ All permissions granted - no notification needed');
        }
        
      } catch (e) {
        debugPrint('[PermissionMonitor] ❌ Check error: $e');
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ فقط نتعامل مع العودة من الإعدادات بعد طلب إذن
    if (state == AppLifecycleState.resumed) {
      if (_isShowingNotification && _currentPermission != null) {
        _checkAfterSettings();
      }
    }
  }
  
  // ✅ فحص بسيط بعد العودة من الإعدادات
  void _checkAfterSettings() {
    if (_currentPermission == null) return;
    
    debugPrint('[PermissionMonitor] 🔄 Checking after settings return...');
    
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted || _currentPermission == null) return;
      
      try {
        final status = await _permissionService.checkPermissionStatus(_currentPermission!);
        
        if (status == AppPermissionStatus.granted) {
          debugPrint('[PermissionMonitor] ✅ Permission granted after settings!');
          
          setState(() {
            _missingPermissions.remove(_currentPermission);
          });
          
          _hideNotification(success: true);
          _showSuccessMessage(_currentPermission!);
          
          // إذا كانت هناك أذونات أخرى مفقودة، اعرضها
          if (_missingPermissions.isNotEmpty) {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && !_isShowingNotification) {
                _showNotificationForPermission(_missingPermissions.first);
              }
            });
          }
        }
      } catch (e) {
        debugPrint('[PermissionMonitor] ❌ Error checking after settings: $e');
      }
    });
  }
  
  void _showNotificationForPermission(AppPermissionType permission) {
    debugPrint('[PermissionMonitor] 🔔 Showing notification for: $permission');
    
    setState(() {
      _currentPermission = permission;
      _isShowingNotification = true;
    });
    
    HapticFeedback.mediumImpact();
  }
  
  void _hideNotification({bool success = false}) {
    if (!mounted) return;
    
    setState(() {
      _isShowingNotification = false;
      _currentPermission = null;
      _isProcessing = false;
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
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
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
      
      final granted = await _manager.requestPermissionWithExplanation(
        context,
        _currentPermission!,
        forceRequest: true,
      );
      
      debugPrint('[PermissionMonitor] 📊 Result: $granted');
      
      if (granted) {
        setState(() {
          _missingPermissions.remove(_currentPermission!);
        });
        
        _hideNotification(success: true);
        _showSuccessMessage(_currentPermission!);
        
        // عرض الإذن التالي إن وجد
        if (_missingPermissions.isNotEmpty) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted && !_isShowingNotification) {
              _showNotificationForPermission(_missingPermissions.first);
            }
          });
        }
      } else {
        setState(() => _isProcessing = false);
        
        // فحص إذا كان مرفوض نهائياً
        final status = await _permissionService.checkPermissionStatus(_currentPermission!);
        
        if (status == AppPermissionStatus.permanentlyDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'يرجى تفعيل الإذن من إعدادات النظام',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'الإعدادات',
                textColor: Colors.white,
                onPressed: () {
                  _permissionService.openAppSettings();
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
      debugPrint('[PermissionMonitor] ❌ Error: $e');
      setState(() => _isProcessing = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // عرض الإشعار إذا كان هناك إذن مفقود
        if (_isShowingNotification && _currentPermission != null)
          ..._buildNotificationOverlay(),
      ],
    );
  }
  
  List<Widget> _buildNotificationOverlay() {
    return [
      // خلفية شفافة مع blur
      GestureDetector(
        onTap: () {
          if (!_isProcessing) {
            _hideNotification();
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
      
      // كارد الإذن
      Center(
        child: _SimplePermissionCard(
          permission: _currentPermission!,
          isProcessing: _isProcessing,
          onActivate: _handlePermissionRequest,
          onDismiss: () {
            if (!_isProcessing) {
              _hideNotification();
              
              // الانتقال للإذن التالي إن وجد
              final remainingPermissions = List<AppPermissionType>.from(_missingPermissions);
              remainingPermissions.remove(_currentPermission);
              
              if (remainingPermissions.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && !_isShowingNotification) {
                    _showNotificationForPermission(remainingPermissions.first);
                  }
                });
              }
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
  
  // ✅ دالة لإعادة تعيين الفحص (للتطوير فقط)
  static void resetCheckFlag() {
    _hasCheckedOnce = false;
    debugPrint('[PermissionMonitor] 🔄 Check flag reset - will check on next app start');
  }
}

/// بطاقة الإذن البسيطة
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