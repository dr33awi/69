// lib/features/onboarding/widgets/onboarding_permission_request.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../core/infrastructure/services/permissions/permission_constants.dart';
import '../../../core/infrastructure/services/permissions/permission_manager.dart';

/// Widget لعرض طلب الأذونات في صفحة الـ onboarding
class OnboardingPermissionRequest extends StatefulWidget {
  final List<AppPermissionType> permissions;
  final VoidCallback onComplete;
  final Color primaryColor;
  final UnifiedPermissionManager permissionManager;

  const OnboardingPermissionRequest({
    super.key,
    required this.permissions,
    required this.onComplete,
    required this.primaryColor,
    required this.permissionManager,
  });

  @override
  State<OnboardingPermissionRequest> createState() => _OnboardingPermissionRequestState();
}

class _OnboardingPermissionRequestState extends State<OnboardingPermissionRequest> {
  
  final Map<AppPermissionType, AppPermissionStatus> _permissionStatuses = {};
  
  bool _isProcessing = false;
  int _grantedCount = 0;
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();
    
    // تهيئة حالات الأذونات
    for (final permission in widget.permissions) {
      _permissionStatuses[permission] = AppPermissionStatus.unknown;
    }
    
    // فحص الحالات الحالية للأذونات
    _checkCurrentStatuses();
  }

  Future<void> _checkCurrentStatuses() async {
    for (final permission in widget.permissions) {
      final result = await widget.permissionManager.performQuickCheck();
      final status = result.statuses[permission] ?? AppPermissionStatus.unknown;
      
      if (mounted) {
        setState(() {
          _permissionStatuses[permission] = status;
          if (status == AppPermissionStatus.granted) {
            _grantedCount++;
          }
        });
      }
    }
    
    _updateCanContinue();
  }

  void _updateCanContinue() {
    // التحقق من أن جميع الأذونات ممنوحة فعلياً
    final allGranted = widget.permissions.every((permission) {
      final status = _permissionStatuses[permission];
      return status == AppPermissionStatus.granted;
    });
    
    setState(() {
      _canContinue = allGranted && _grantedCount == widget.permissions.length;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handlePermissionRequest(AppPermissionType permission) async {
    if (_isProcessing) return;
    
    final currentStatus = _permissionStatuses[permission];
    if (currentStatus == AppPermissionStatus.granted) return;
    
    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();
    
    try {
      final granted = await widget.permissionManager.requestPermissionWithExplanation(
        context,
        permission,
        forceRequest: true,
      );
      
      if (mounted) {
        setState(() {
          if (granted) {
            _permissionStatuses[permission] = AppPermissionStatus.granted;
            _grantedCount++;
            HapticFeedback.mediumImpact();
          } else {
            _permissionStatuses[permission] = AppPermissionStatus.denied;
          }
        });
        
        _updateCanContinue();
      }
      
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          // عنوان القسم
          _buildHeader(),
          
          SizedBox(height: 24.h),
          
          // قائمة الأذونات
          ...widget.permissions.asMap().entries.map((entry) {
            return _buildPermissionCard(
              entry.value,
              entry.key,
            );
          }),
          
          SizedBox(height: 24.h),
          
          // زر المتابعة
          _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.primaryColor.withOpacity(0.2),
                widget.primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.verified_user_rounded,
            color: widget.primaryColor,
            size: 28.sp,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        Text(
          'للحصول على أفضل تجربة',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
        
        SizedBox(height: 6.h),
        
        Text(
          'نحتاج الأذونات التالية',
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionCard(AppPermissionType permission, int index) {
    final info = PermissionConstants.getInfo(permission);
    final status = _permissionStatuses[permission] ?? AppPermissionStatus.unknown;
    final isGranted = status == AppPermissionStatus.granted;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isGranted ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isGranted 
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.15),
          width: 1.w,
        ),
        boxShadow: isGranted ? [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.2),
            blurRadius: 12.r,
            spreadRadius: 0,
          ),
        ] : null,
      ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isGranted ? null : () => _handlePermissionRequest(permission),
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // الأيقونة
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isGranted ? [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ] : [
                          info.color.withOpacity(0.15),
                          info.color.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: isGranted ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 8.r,
                          spreadRadius: 0,
                        ),
                      ] : null,
                    ),
                    child: Icon(
                      isGranted ? Icons.check_circle_rounded : info.icon,
                      color: isGranted ? Colors.white : info.color,
                      size: 24.sp,
                    ),
                  ),
                  
                  SizedBox(width: 14.w),
                  
                  // النص
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                info.name,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(isGranted ? 0.95 : 0.9),
                                ),
                              ),
                            ),
                            if (isGranted)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  'مُفعّل',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          info.description,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withOpacity(0.65),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 8.w),
                  
                  // زر التفعيل / علامة صح
                  if (!isGranted)
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.touch_app_rounded,
                        color: widget.primaryColor,
                        size: 18.sp,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildContinueButton() {
    // حساب الـ opacity بشكل صحيح
    final buttonOpacity = _canContinue ? 1.0 : 0.5;
    
    return Opacity(
      opacity: buttonOpacity,
      child: Container(
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26.r),
          gradient: _canContinue ? LinearGradient(
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: _canContinue ? null : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(_canContinue ? 0.35 : 0.2),
            width: 1.5.w,
          ),
          boxShadow: _canContinue ? [
            BoxShadow(
              color: Colors.white.withOpacity(0.15),
              blurRadius: 16.r,
              spreadRadius: 2.r,
            ),
          ] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            // تعطيل الزر تماماً إذا لم تكن جميع الأذونات ممنوحة
            onTap: _canContinue ? () {
              // تحقق مرة أخرى قبل المتابعة
              if (_grantedCount == widget.permissions.length) {
                widget.onComplete();
              } else {
                // عرض رسالة تنبيه
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'يجب تفعيل جميع الأذونات أولاً',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    margin: EdgeInsets.all(16.w),
                  ),
                );
              }
            } : null, // null = الزر معطل تماماً
            borderRadius: BorderRadius.circular(26.r),
            child: Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_canContinue)
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  if (_canContinue) SizedBox(width: 8.w),
                  Text(
                    _canContinue ? 'ممتاز! ابدأ الآن' : 'فعّل جميع الأذونات للمتابعة',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(_canContinue ? 1.0 : 0.7),
                    ),
                  ),
                  if (_canContinue) SizedBox(width: 8.w),
                  if (_canContinue)
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}