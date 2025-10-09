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

/// شاشة إعداد الأذونات بتصميم احترافي محسّن - بدون Progress Bar
class PermissionsSetupScreen extends StatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen>
    with TickerProviderStateMixin {
  late final UnifiedPermissionManager _permissionManager;
  late final PermissionService _permissionService;
  
  late AnimationController _headerAnimationController;
  late AnimationController _successAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerSlideAnimation;

  final Map<AppPermissionType, AppPermissionStatus> _permissionStatuses = {};
  final Map<AppPermissionType, bool> _isProcessingMap = {};
  
  bool _isCompletingSetup = false;
  int _animatingPermissionIndex = -1;

  final List<AppPermissionType> _criticalPermissions = 
      PermissionConstants.criticalPermissions;

  @override
  void initState() {
    super.initState();
    _permissionManager = getIt<UnifiedPermissionManager>();
    _permissionService = getIt<PermissionService>();

    _setupAnimations();
    _checkInitialPermissions();
  }

  void _setupAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _headerSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _headerAnimationController.forward();
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

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission(AppPermissionType permission, int index) async {
    if (_isProcessingMap[permission] == true) return;

    setState(() {
      _isProcessingMap[permission] = true;
      _animatingPermissionIndex = index;
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
          _playSuccessAnimation();
          
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() => _animatingPermissionIndex = -1);
        } else {
          setState(() => _animatingPermissionIndex = -1);
        }
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      if (mounted) {
        setState(() {
          _isProcessingMap[permission] = false;
          _animatingPermissionIndex = -1;
        });
      }
    }
  }

  void _playSuccessAnimation() {
    _successAnimationController.forward().then((_) {
      _successAnimationController.reverse();
    });
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
              _buildAnimatedHeader(),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      SizedBox(height: 12.h),
                      
                      // Permissions Cards
                      ...List.generate(
                        _criticalPermissions.length,
                        (index) => _buildPermissionCard(index),
                      ),
                      
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),

              _buildActionButtons(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: AnimatedBuilder(
        animation: _headerSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _headerSlideAnimation.value),
            child: child,
          );
        },
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // Animated Icon
              ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _headerAnimationController,
                    curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
                  ),
                ),
                child: Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 50.sp,
                    color: Colors.white,
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              Text(
                'الأذونات المطلوبة',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                'نحتاج بعض الأذونات لتقديم أفضل تجربة',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(int index) {
    final permission = _criticalPermissions[index];
    final status = _permissionStatuses[permission] ?? AppPermissionStatus.unknown;
    final isGranted = status == AppPermissionStatus.granted;
    final isProcessing = _isProcessingMap[permission] == true;
    final isAnimating = _animatingPermissionIndex == index;
    final info = PermissionConstants.getInfo(permission);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isGranted ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isGranted
                ? Colors.white.withOpacity(0.4)
                : Colors.white.withOpacity(0.2),
            width: isGranted ? 2.w : 1.5.w,
          ),
          boxShadow: isGranted
              ? [
                  BoxShadow(
                    color: ThemeConstants.success.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isGranted || isProcessing 
                ? null 
                : () => _requestPermission(permission, index),
            borderRadius: BorderRadius.circular(20.r),
            child: Padding(
              padding: EdgeInsets.all(18.w),
              child: Row(
                children: [
                  // Icon with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: isGranted
                          ? ThemeConstants.success.withOpacity(0.2)
                          : info.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: isAnimating
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            isGranted ? Icons.check_circle_rounded : info.icon,
                            color: isGranted 
                                ? ThemeConstants.success 
                                : Colors.white,
                            size: 28.sp,
                          ),
                  ),

                  SizedBox(width: 16.w),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          info.description,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Status Badge
                  _buildStatusBadge(isGranted, isProcessing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isGranted, bool isProcessing) {
    if (isProcessing) {
      return SizedBox(
        width: 24.w,
        height: 24.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.5.w,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (isGranted) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: ThemeConstants.success.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check,
              color: ThemeConstants.success,
              size: 14.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              'مفعل',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        'تفعيل',
        style: TextStyle(
          fontSize: 12.sp,
          color: ThemeConstants.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        children: [
          // Main Button
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: _allPermissionsGranted && !_isCompletingSetup
                  ? _completeSetup
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ThemeConstants.primary,
                disabledBackgroundColor: Colors.white.withOpacity(0.3),
                disabledForegroundColor: Colors.white.withOpacity(0.6),
                elevation: _allPermissionsGranted ? 8 : 0,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: _isCompletingSetup
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
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
                          'ابدأ الآن',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_allPermissionsGranted) ...[
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_back,
                            size: 20.sp,
                          ),
                        ],
                      ],
                    ),
            ),
          ),

          SizedBox(height: 10.h),

          // Status Text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _allPermissionsGranted
                ? Row(
                    key: const ValueKey('completed'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: ThemeConstants.success,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'جميع الأذونات مفعلة',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : TextButton(
                    key: const ValueKey('skip'),
                    onPressed: _isCompletingSetup ? null : _completeSetup,
                    child: Text(
                      'تخطي في الوقت الحالي',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.8),
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}