// lib/features/onboarding/screens/permissions_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/routes/app_router.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../core/infrastructure/services/permissions/permission_manager.dart';
import '../../../core/infrastructure/services/permissions/permission_constants.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';

/// شاشة إعداد الأذونات بتصميم مشابه لـ Onboarding
class PermissionsSetupScreen extends StatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen> {
  late final UnifiedPermissionManager _permissionManager;
  late final PermissionService _permissionService;

  final Map<AppPermissionType, AppPermissionStatus> _permissionStatuses = {};
  final Map<AppPermissionType, bool> _isProcessingMap = {};
  
  bool _isCompletingSetup = false;

  final List<AppPermissionType> _criticalPermissions = 
      PermissionConstants.criticalPermissions;

  @override
  void initState() {
    super.initState();
    _permissionManager = getIt<UnifiedPermissionManager>();
    _permissionService = getIt<PermissionService>();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    for (final permission in _criticalPermissions) {
      final status = await _permissionService.checkPermissionStatus(permission);
      if (mounted) {
        setState(() {
          _permissionStatuses[permission] = status;
        });
      }
    }
  }

  Future<void> _requestPermission(AppPermissionType permission) async {
    if (_isProcessingMap[permission] == true) return;

    setState(() {
      _isProcessingMap[permission] = true;
    });
    
    HapticFeedback.lightImpact();

    try {
      final granted = await _permissionManager.requestPermissionWithExplanation(
        context,
        permission,
        forceRequest: false,
      );

      if (mounted) {
        setState(() {
          _permissionStatuses[permission] = granted
              ? AppPermissionStatus.granted
              : AppPermissionStatus.denied;
          _isProcessingMap[permission] = false;
        });

        if (granted) {
          HapticFeedback.mediumImpact();
        }
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      if (mounted) {
        setState(() {
          _isProcessingMap[permission] = false;
        });
      }
    }
  }

  Future<void> _completeSetup() async {
    if (_isCompletingSetup) return;

    setState(() => _isCompletingSetup = true);
    HapticFeedback.mediumImpact();

    try {
      final storage = getIt<StorageService>();
      await storage.setBool('permissions_setup_completed', true);

      if (mounted) {
        await Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } catch (e) {
      debugPrint('Error completing setup: $e');
      if (mounted) {
        setState(() => _isCompletingSetup = false);
      }
    }
  }

  bool get _allPermissionsGranted {
    return _criticalPermissions.every((permission) =>
        _permissionStatuses[permission] == AppPermissionStatus.granted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ThemeConstants.primary,
              ThemeConstants.primary.withOpacity(0.9),
              ThemeConstants.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // مساحة علوية صغيرة
              SizedBox(height: 30.h),
              
              // Icon Badge
              _buildIconBadge(),

              // Spacer للمحاذاة الوسطية
              const Spacer(),

              // المحتوى في المنتصف
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'الأذونات المطلوبة',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 16.h),

                    // Permissions List
                    _buildPermissionsList(),
                  ],
                ),
              ),

              // Spacer للمحاذاة الوسطية
              const Spacer(),

              // Action Buttons
              _buildActionButtons(),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge() {
    return Container(
      width: 85.w,
      height: 85.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 65.w,
          height: 65.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 2.w,
            ),
          ),
          child: Icon(
            Icons.verified_user_rounded,
            size: 32.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        _criticalPermissions.length,
        (index) => _buildPermissionItem(index),
      ),
    );
  }

  Widget _buildPermissionItem(int index) {
    final permission = _criticalPermissions[index];
    final status = _permissionStatuses[permission] ?? AppPermissionStatus.unknown;
    final isGranted = status == AppPermissionStatus.granted;
    final isProcessing = _isProcessingMap[permission] == true;
    final info = PermissionConstants.getInfo(permission);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isGranted || isProcessing 
              ? null 
              : () => _requestPermission(permission),
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isGranted ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: Colors.white.withOpacity(isGranted ? 0.35 : 0.25),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(5.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: isProcessing
                      ? SizedBox(
                          width: 12.w,
                          height: 12.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          isGranted ? Icons.check : info.icon,
                          size: 16.sp,
                          color: Colors.white,
                        ),
                ),

                SizedBox(width: 8.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.name,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        info.description,
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 6.w),

                // Status Badge
                if (isGranted)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'مفعل',
                      style: TextStyle(
                        fontSize: 8.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (!isProcessing)
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 10.sp,
                    color: Colors.white.withOpacity(0.7),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        children: [
          // Main Button
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: ElevatedButton(
              onPressed: !_isCompletingSetup ? _completeSetup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ThemeConstants.primary,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                disabledForegroundColor: ThemeConstants.primary.withOpacity(0.7),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isCompletingSetup
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5.w,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeConstants.primary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _allPermissionsGranted ? 'ابدأ الآن' : 'تخطي في الوقت الحالي',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_allPermissionsGranted) ...[
                          SizedBox(width: 5.w),
                          Icon(
                            Icons.arrow_back,
                            size: 15.sp,
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          SizedBox(height: 8.h),

          // Status Text
          if (_allPermissionsGranted)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 13.sp,
                ),
                SizedBox(width: 5.w),
                Text(
                  'جميع الأذونات مفعلة',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            Text(
              'يمكنك تفعيل الأذونات لاحقاً من الإعدادات',
              style: TextStyle(
                fontSize: 9.sp,
                color: Colors.white.withOpacity(0.75),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}