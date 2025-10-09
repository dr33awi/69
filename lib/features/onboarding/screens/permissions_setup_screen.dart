// lib/features/onboarding/screens/permissions_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/routes/app_router.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../core/infrastructure/services/permissions/permission_manager.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../widgets/permission_card.dart';

/// شاشة إعداد الأذونات بتصميم احترافي
class PermissionsSetupScreen extends StatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen>
    with SingleTickerProviderStateMixin {
  late final UnifiedPermissionManager _permissionManager;
  late final PermissionService _permissionService;
  late AnimationController _animationController;

  final Map<AppPermissionType, AppPermissionStatus> _permissionStatuses = {};
  bool _isProcessing = false;
  int _currentPermissionIndex = 0;

  final List<AppPermissionType> _criticalPermissions = [
    AppPermissionType.notification,
    AppPermissionType.location,
    AppPermissionType.batteryOptimization,
  ];

  @override
  void initState() {
    super.initState();
    _permissionManager = getIt<UnifiedPermissionManager>();
    _permissionService = getIt<PermissionService>();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    for (final permission in _criticalPermissions) {
      final status = await _permissionService.checkPermissionStatus(permission);
      setState(() {
        _permissionStatuses[permission] = status;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission(AppPermissionType permission) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    try {
      final granted = await _permissionManager.requestPermissionWithExplanation(
        context,
        permission,
        forceRequest: false,
      );

      setState(() {
        _permissionStatuses[permission] = granted
            ? AppPermissionStatus.granted
            : AppPermissionStatus.denied;
        _isProcessing = false;
      });

      if (granted) {
        HapticFeedback.mediumImpact();
        _showSuccessAnimation();
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  Future<void> _completeSetup() async {
    HapticFeedback.mediumImpact();

    try {
      final storage = getIt<StorageService>();
      await storage.setBool('permissions_setup_completed', true);

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } catch (e) {
      debugPrint('Error completing setup: $e');
    }
  }

  bool get _allPermissionsGranted {
    return _criticalPermissions.every((permission) =>
        _permissionStatuses[permission] == AppPermissionStatus.granted);
  }

  int get _grantedCount {
    return _criticalPermissions
        .where((p) => _permissionStatuses[p] == AppPermissionStatus.granted)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ThemeConstants.primary,
              ThemeConstants.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Permissions List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: _criticalPermissions.length,
                  itemBuilder: (context, index) {
                    final permission = _criticalPermissions[index];
                    final status = _permissionStatuses[permission];

                    return PermissionCard(
                      permission: permission,
                      status: status ?? AppPermissionStatus.unknown,
                      onRequest: () => _requestPermission(permission),
                      isProcessing: _isProcessing,
                    );
                  },
                ),
              ),

              // Progress Indicator
              _buildProgressIndicator(),

              // Action Buttons
              _buildActionButtons(),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          // Animation/Icon
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Icon(
                Icons.security_rounded,
                size: 60.sp,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: 24.h),

          Text(
            'الأذونات المطلوبة',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 12.h),

          Text(
            'نحتاج بعض الأذونات لتقديم أفضل تجربة لك',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _grantedCount / _criticalPermissions.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_grantedCount/${_criticalPermissions.length}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _allPermissionsGranted
                    ? ThemeConstants.success
                    : ThemeConstants.accentLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _allPermissionsGranted ? _completeSetup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ThemeConstants.primary,
                disabledBackgroundColor: Colors.white.withOpacity(0.3),
                disabledForegroundColor: Colors.white.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'ابدأ الآن',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Skip Button
          if (!_allPermissionsGranted)
            TextButton(
              onPressed: _completeSetup,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: Text(
                'تخطي في الوقت الحالي',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.white.withOpacity(0.8),
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withOpacity(0.8),
                ),
              ),
            ),

          if (_allPermissionsGranted)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: ThemeConstants.success,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'جميع الأذونات مفعلة',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}