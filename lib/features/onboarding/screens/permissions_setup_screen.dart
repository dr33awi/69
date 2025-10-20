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

  Future<void> _requestAllPermissions() async {
    // منع النقر المتكرر
    if (_isProcessingMap.values.any((isProcessing) => isProcessing)) return;

    HapticFeedback.mediumImpact();

    // طلب جميع الأذونات واحدة تلو الأخرى
    for (final permission in _criticalPermissions) {
      // تخطي الأذونات التي تم منحها بالفعل
      if (_permissionStatuses[permission] == AppPermissionStatus.granted) {
        continue;
      }

      await _requestPermission(permission);
      
      // انتظار قصير بين الطلبات
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // إعطاء تغذية راجعة للمستخدم
    if (mounted && _allPermissionsGranted) {
      HapticFeedback.heavyImpact();
    }
  }

  bool get _allPermissionsGranted {
    return _criticalPermissions.every((permission) =>
        _permissionStatuses[permission] == AppPermissionStatus.granted);
  }

  @override
  Widget build(BuildContext context) {
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
    final double topSpace = isSmallScreen ? 20.h : (isMediumScreen ? 25.h : 30.h);
    final double horizontalPadding = isSmallScreen ? 16.w : 20.w;
    final double bottomSpace = isSmallScreen ? 16.h : 24.h;
    final double middleSpace = isSmallScreen ? 24.h : 32.h;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          SizedBox(height: topSpace),

          Spacer(flex: 1),

          _buildMainContent(
            isSmallScreen: isSmallScreen,
            isMediumScreen: isMediumScreen,
          ),

          SizedBox(height: middleSpace),

          _buildResponsiveActionButtons(
            isSmallScreen: isSmallScreen,
            isMediumScreen: isMediumScreen,
          ),

          SizedBox(height: bottomSpace),
          
          Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildMainContent({
    required bool isSmallScreen,
    required bool isMediumScreen,
  }) {
    final double titleSize = isSmallScreen ? 18.sp : (isMediumScreen ? 20.sp : 22.sp);
    final double spacing = isSmallScreen ? 14.h : 18.h;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '🔒 منح الأذونات',
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
        
        SizedBox(height: 6.h),
        
        Text(
          'لتجربة مثالية، نحتاج بعض الأذونات',
          style: TextStyle(
            fontSize: isSmallScreen ? 11.sp : 12.sp,
            color: Colors.white.withOpacity(0.9),
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: spacing),

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

    final double verticalMargin = isSmallScreen ? 4.h : 5.h;
    final double padding = isSmallScreen ? 12.r : 14.r;
    final double borderRadius = isSmallScreen ? 10.r : 12.r;
    final double iconContainerSize = isSmallScreen ? 38.r : 42.r;
    final double iconSize = isSmallScreen ? 18.sp : 20.sp;
    final double titleSize = isSmallScreen ? 12.sp : 13.sp;
    final double descSize = isSmallScreen ? 10.sp : 11.sp;
    final double badgeSize = isSmallScreen ? 9.sp : 10.sp;

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
                width: 1.5.w,
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
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: isProcessing
                      ? Padding(
                          padding: EdgeInsets.all(8.r),
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

                SizedBox(width: 10.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.name,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.15),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        info.description,
                        style: TextStyle(
                          fontSize: descSize,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 1),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // Status Badge
                if (isGranted)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8.r),
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
                    size: 12.sp,
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
    final double buttonHeight = isSmallScreen ? 46.h : 48.h;
    final double buttonRadius = isSmallScreen ? 12.r : 14.r;
    final double buttonTextSize = isSmallScreen ? 13.sp : 14.sp;
    final double statusTextSize = isSmallScreen ? 10.sp : 11.sp;
    final double statusIconSize = isSmallScreen ? 13.sp : 14.sp;
    final double spacing = isSmallScreen ? 8.h : 10.h;
    
    return Column(
      children: [
        // زر منح جميع الأذونات (يظهر فقط عند وجود أذونات غير مفعلة)
        if (!_allPermissionsGranted)
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: _requestAllPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: ThemeConstants.primary,
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonRadius),
                ),
              ),
              child: Text(
                '✨ تفعيل جميع الأذونات',
                style: TextStyle(
                  fontSize: buttonTextSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

        if (!_allPermissionsGranted)
          SizedBox(height: spacing),

        // Main Button - ابدأ الآن
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: !_isCompletingSetup ? _completeSetup : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _allPermissionsGranted 
                  ? Colors.white 
                  : Colors.white.withOpacity(0.85),
              foregroundColor: ThemeConstants.primary,
              disabledBackgroundColor: Colors.white.withOpacity(0.5),
              disabledForegroundColor: ThemeConstants.primary.withOpacity(0.7),
              elevation: _allPermissionsGranted ? 8 : 4,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonRadius),
              ),
            ),
            child: _isCompletingSetup
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5.w,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ThemeConstants.primary,
                      ),
                    ),
                  )
                : Text(
                    _allPermissionsGranted ? '🚀 ابدأ الآن' : 'المتابعة لاحقًا',
                    style: TextStyle(
                      fontSize: buttonTextSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
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
              SizedBox(width: 6.w),
              Text(
                '✅ تمام! كل شيء جاهز الآن',
                style: TextStyle(
                  fontSize: statusTextSize,
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Text(
            'يمكنك تفعيلها لاحقًا من ⚙️ الإعدادات',
            style: TextStyle(
              fontSize: statusTextSize,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}