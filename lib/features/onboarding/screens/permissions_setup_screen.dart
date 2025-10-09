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

/// شاشة إعداد الأذونات محسّنة لجميع أحجام الشاشات
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
    // حساب حجم الشاشة
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    final isMediumScreen = screenHeight >= 600 && screenHeight < 800;
    
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: _buildResponsiveContent(
                      isSmallScreen: isSmallScreen,
                      isMediumScreen: isMediumScreen,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveContent({
    required bool isSmallScreen,
    required bool isMediumScreen,
  }) {
    // المساحات الديناميكية
    final double topSpace = isSmallScreen ? 20.h : (isMediumScreen ? 25.h : 30.h);
    final double horizontalPadding = isSmallScreen ? 16.w : 20.w;
    final double bottomSpace = isSmallScreen ? 16.h : 24.h;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          // مساحة علوية
          SizedBox(height: topSpace),
          
          // Icon Badge
          _buildResponsiveIconBadge(
            isSmallScreen: isSmallScreen,
            isMediumScreen: isMediumScreen,
          ),

          // Spacer مرن
          Expanded(
            flex: isSmallScreen ? 1 : 2,
            child: Container(),
          ),

          // المحتوى الرئيسي
          _buildMainContent(
            isSmallScreen: isSmallScreen,
            isMediumScreen: isMediumScreen,
          ),

          // Spacer مرن
          Expanded(
            flex: isSmallScreen ? 1 : 2,
            child: Container(),
          ),

          // Action Buttons
          _buildResponsiveActionButtons(
            isSmallScreen: isSmallScreen,
            isMediumScreen: isMediumScreen,
          ),

          SizedBox(height: bottomSpace),
        ],
      ),
    );
  }

  Widget _buildResponsiveIconBadge({
    required bool isSmallScreen,
    required bool isMediumScreen,
  }) {
    final double outerSize = isSmallScreen ? 70.w : (isMediumScreen ? 77.w : 85.w);
    final double innerSize = isSmallScreen ? 55.w : (isMediumScreen ? 60.w : 65.w);
    final double iconSize = isSmallScreen ? 28.sp : (isMediumScreen ? 30.sp : 32.sp);
    
    return Container(
      width: outerSize,
      height: outerSize,
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
          width: innerSize,
          height: innerSize,
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
            size: iconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent({
    required bool isSmallScreen,
    required bool isMediumScreen,
  }) {
    final double titleSize = isSmallScreen ? 16.sp : (isMediumScreen ? 17.sp : 18.sp);
    final double spacing = isSmallScreen ? 12.h : 16.h;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          'الأذونات المطلوبة',
          style: TextStyle(
            fontSize: titleSize,
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

        SizedBox(height: spacing),

        // Permissions List
        _buildResponsivePermissionsList(
          isSmallScreen: isSmallScreen,
          isMediumScreen: isMediumScreen,
        ),
      ],
    );
  }

  Widget _buildResponsivePermissionsList({
    required bool isSmallScreen,
    required bool isMediumScreen,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        _criticalPermissions.length,
        (index) => _buildResponsivePermissionItem(
          index: index,
          isSmallScreen: isSmallScreen,
          isMediumScreen: isMediumScreen,
        ),
      ),
    );
  }

  Widget _buildResponsivePermissionItem({
    required int index,
    required bool isSmallScreen,
    required bool isMediumScreen,
  }) {
    final permission = _criticalPermissions[index];
    final status = _permissionStatuses[permission] ?? AppPermissionStatus.unknown;
    final isGranted = status == AppPermissionStatus.granted;
    final isProcessing = _isProcessingMap[permission] == true;
    final info = PermissionConstants.getInfo(permission);

    // أحجام متجاوبة
    final double verticalMargin = isSmallScreen ? 2.h : 3.h;
    final double padding = isSmallScreen ? 8.r : 10.r;
    final double borderRadius = isSmallScreen ? 8.r : 10.r;
    final double iconContainerSize = isSmallScreen ? 32.r : 36.r;
    final double iconSize = isSmallScreen ? 14.sp : 16.sp;
    final double titleSize = isSmallScreen ? 10.sp : 11.sp;
    final double descSize = isSmallScreen ? 8.sp : 9.sp;
    final double badgeSize = isSmallScreen ? 7.sp : 8.sp;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalMargin),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isGranted || isProcessing 
              ? null 
              : () => _requestPermission(permission),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isGranted ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(isGranted ? 0.35 : 0.25),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: isProcessing
                      ? Padding(
                          padding: EdgeInsets.all(6.r),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          isGranted ? Icons.check : info.icon,
                          size: iconSize,
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
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        info.description,
                        style: TextStyle(
                          fontSize: descSize,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.2,
                        ),
                        maxLines: isSmallScreen ? 1 : 2,
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
                        fontSize: badgeSize,
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

  Widget _buildResponsiveActionButtons({
    required bool isSmallScreen,
    required bool isMediumScreen,
  }) {
    final double buttonHeight = isSmallScreen ? 44.h : 46.h;
    final double buttonRadius = isSmallScreen ? 10.r : 12.r;
    final double buttonTextSize = isSmallScreen ? 12.sp : 13.sp;
    final double iconSize = isSmallScreen ? 14.sp : 15.sp;
    final double statusTextSize = isSmallScreen ? 9.sp : 10.sp;
    final double statusIconSize = isSmallScreen ? 12.sp : 13.sp;
    final double spacing = isSmallScreen ? 6.h : 8.h;
    
    return Column(
      children: [
        // Main Button
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
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
                borderRadius: BorderRadius.circular(buttonRadius),
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
                          fontSize: buttonTextSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_allPermissionsGranted) ...[
                        SizedBox(width: 5.w),
                        Icon(
                          Icons.arrow_back,
                          size: iconSize,
                        ),
                      ],
                    ],
                  ),
          ),
        ),

        SizedBox(height: spacing),

        // Status Text
        if (_allPermissionsGranted)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: statusIconSize,
              ),
              SizedBox(width: 5.w),
              Text(
                'جميع الأذونات مفعلة',
                style: TextStyle(
                  fontSize: statusTextSize,
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
              fontSize: statusTextSize,
              color: Colors.white.withOpacity(0.75),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}