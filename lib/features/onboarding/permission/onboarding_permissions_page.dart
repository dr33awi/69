// lib/features/onboarding/permission/onboarding_permissions_page.dart
// محدث: بدون رسالة التهنئة وبدون شريط التقدم

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../../app/themes/widgets/core/islamic_pattern_painter.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../core/infrastructure/services/permissions/permission_constants.dart';
import '../models/onboarding_item.dart';

class OnboardingPermissionsPage extends StatefulWidget {
  final OnboardingItem item;
  final VoidCallback onNext;
  final bool isProcessing;

  const OnboardingPermissionsPage({
    super.key,
    required this.item,
    required this.onNext,
    this.isProcessing = false,
  });

  @override
  State<OnboardingPermissionsPage> createState() => _OnboardingPermissionsPageState();
}

class _OnboardingPermissionsPageState extends State<OnboardingPermissionsPage> {
  
  late PermissionService _permissionService;
  
  final List<AppPermissionType> _permissions = [
    AppPermissionType.notification,
    AppPermissionType.location,
    AppPermissionType.batteryOptimization,
  ];
  
  Map<AppPermissionType, bool> _permissionStatuses = {};
  int _grantedCount = 0;

  // حساب الأحجام المتجاوبة
  double get _animationSize {
    if (1.sw > 600) return 180.w;
    if (1.sw > 400) return 160.w;
    return 140.w;
  }

  double get _lottieSize {
    if (1.sw > 600) return 130.w;
    if (1.sw > 400) return 115.w;
    return 100.w;
  }

  double get _titleSize {
    if (1.sw > 600) return 32.sp;
    if (1.sw > 400) return 30.sp;
    return 28.sp;
  }

  double get _subtitleSize {
    if (1.sw > 600) return 17.sp;
    if (1.sw > 400) return 16.sp;
    return 15.sp;
  }

  @override
  void initState() {
    super.initState();
    
    _permissionService = getIt<PermissionService>();
    _checkPermissionsStatus();
  }
  
  Future<void> _checkPermissionsStatus() async {
    for (final permission in _permissions) {
      final status = await _permissionService.checkPermissionStatus(permission);
      if (mounted) {
        setState(() {
          _permissionStatuses[permission] = status == AppPermissionStatus.granted;
          if (status == AppPermissionStatus.granted) {
            _grantedCount++;
          }
        });
      }
    }
  }
  
  Future<void> _handlePermissionTap(AppPermissionType permission) async {
    if (_permissionStatuses[permission] == true) return;
    
    HapticFeedback.lightImpact();
    
    final status = await _permissionService.requestPermission(permission);
    
    if (mounted) {
      setState(() {
        final wasGranted = _permissionStatuses[permission] == true;
        _permissionStatuses[permission] = status == AppPermissionStatus.granted;
        
        if (!wasGranted && status == AppPermissionStatus.granted) {
          _grantedCount++;
          HapticFeedback.mediumImpact();
        }
      });
    }
  }
  
  bool get _allPermissionsGranted => _grantedCount == _permissions.length;

  @override
  Widget build(BuildContext context) {
    final verticalPadding = 1.sh > 700 ? 20.h : 16.h;
    final horizontalPadding = 1.sw > 600 ? 36.w : 24.w;
    final topSpacing = 1.sh > 700 ? 50.h : 35.h;
    final itemSpacing = 1.sh > 700 ? 28.h : 20.h;
    
    return SizedBox(
      width: 1.sw,
      height: 1.sh,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: IslamicPatternPainter(
                rotation: 0,
                color: Colors.white,
                opacity: 0.05,
                patternType: PatternType.standard,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                             MediaQuery.of(context).padding.top - 
                             MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: topSpacing),
                          
                          _buildAnimationWidget(),
                          
                          SizedBox(height: itemSpacing),
                          
                          _buildTitle(),
                          
                          SizedBox(height: itemSpacing * 0.5),
                          
                          _buildSubtitle(),
                          
                          SizedBox(height: itemSpacing * 1.5),
                          
                          _buildPermissionsList(),
                        ],
                      ),
                      
                      Column(
                        children: [
                          SizedBox(height: itemSpacing),
                          _buildActionButton(),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationWidget() {
    return Container(
      width: _animationSize,
      height: _animationSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 40.r,
            spreadRadius: 5.r,
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: _lottieSize,
          height: _lottieSize,
          child: widget.item.hasValidLottie
              ? Lottie.asset(
                  widget.item.lottiePath!,
                  fit: BoxFit.contain,
                  repeat: false,
                  animate: true,
                  options: LottieOptions(
                    enableMergePaths: true,
                  ),
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackIcon();
                  },
                )
              : _buildFallbackIcon(),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    final iconSize = _lottieSize * 0.6;
    
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: Icon(
        Icons.security_rounded,
        size: iconSize * 0.5,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'أذونات التطبيق',
      style: TextStyle(
        fontSize: _titleSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'هذه الأذونات ضرورية لعمل التطبيق بشكل صحيح',
      style: TextStyle(
        fontSize: _subtitleSize,
        color: Colors.white.withOpacity(0.85),
        height: 1.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPermissionsList() {
    return Column(
      children: List.generate(
        _permissions.length,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _PermissionCard(
            permission: _permissions[index],
            index: index,
            isGranted: _permissionStatuses[_permissions[index]] ?? false,
            onTap: () => _handlePermissionTap(_permissions[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final buttonHeight = 1.sh > 700 ? 58.h : 54.h;
    final buttonFontSize = 1.sw > 600 ? 18.sp : 16.sp;
    final iconSize = 1.sw > 600 ? 22.sp : 20.sp;
    
    return Container(
      width: double.infinity,
      height: buttonHeight,
      constraints: BoxConstraints(
        maxWidth: 1.sw > 600 ? 450.w : double.infinity,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(buttonHeight / 2),
        gradient: _allPermissionsGranted
            ? LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          if (_allPermissionsGranted)
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 20.r,
              spreadRadius: 2.r,
              offset: Offset(0, 8.h),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15.r,
              spreadRadius: 1.r,
              offset: Offset(0, 6.h),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (_allPermissionsGranted && !widget.isProcessing) 
              ? widget.onNext 
              : null,
          borderRadius: BorderRadius.circular(buttonHeight / 2),
          child: Container(
            alignment: Alignment.center,
            child: widget.isProcessing
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5.w,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_allPermissionsGranted)
                        Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: Icon(
                            Icons.lock_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: iconSize,
                          ),
                        ),
                      Text(
                        _allPermissionsGranted 
                            ? 'المتابعة إلى التطبيق' 
                            : 'يجب منح جميع الأذونات',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                          color: _allPermissionsGranted 
                              ? Colors.white 
                              : Colors.white.withOpacity(0.7),
                        ),
                      ),
                      if (_allPermissionsGranted) ...[
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final AppPermissionType permission;
  final int index;
  final bool isGranted;
  final VoidCallback onTap;

  const _PermissionCard({
    required this.permission,
    required this.index,
    required this.isGranted,
    required this.onTap,
  });

  // حساب الأحجام المتجاوبة
  double get _cardPadding {
    if (1.sw > 600) return 20.w;
    return 16.w;
  }

  double get _iconSize {
    if (1.sw > 600) return 58.w;
    if (1.sw > 400) return 54.w;
    return 52.w;
  }

  double get _iconInnerSize {
    if (1.sw > 600) return 28.sp;
    return 26.sp;
  }

  double get _titleSize {
    if (1.sw > 600) return 17.sp;
    return 16.sp;
  }

  double get _descSize {
    if (1.sw > 600) return 13.sp;
    return 12.sp;
  }

  double get _badgeFontSize {
    if (1.sw > 600) return 11.sp;
    return 10.sp;
  }

  @override
  Widget build(BuildContext context) {
    final info = PermissionConstants.getInfo(permission);
    final cardMargin = 1.sh > 700 ? 14.h : 12.h;
    
    return Container(
      margin: EdgeInsets.only(bottom: cardMargin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGranted
              ? [
                  Colors.green.withOpacity(0.15),
                  Colors.green.withOpacity(0.10),
                ]
              : [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.08),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isGranted
              ? Colors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.2),
          width: isGranted ? 2.w : 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
          if (isGranted)
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 12.r,
              spreadRadius: 2.r,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isGranted ? null : onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.all(_cardPadding),
            child: Row(
              children: [
                Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isGranted
                          ? [
                              Colors.green.withOpacity(0.3),
                              Colors.green.withOpacity(0.2),
                            ]
                          : [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: isGranted
                            ? Colors.green.withOpacity(0.2)
                            : Colors.white.withOpacity(0.15),
                        blurRadius: 12.r,
                        spreadRadius: 1.r,
                      ),
                    ],
                  ),
                  child: Icon(
                    isGranted ? Icons.check_circle_rounded : info.icon,
                    color: Colors.white,
                    size: _iconInnerSize,
                  ),
                ),
                
                SizedBox(width: 14.w),
                
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
                                fontSize: _titleSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4.r,
                                  ),
                                ],
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
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'مُفعّل',
                                style: TextStyle(
                                  fontSize: _badgeFontSize,
                                  fontWeight: FontWeight.bold,
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
                          fontSize: _descSize,
                          color: Colors.white.withOpacity(0.75),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 8.w),
                
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isGranted
                          ? [
                              Colors.green.withOpacity(0.3),
                              Colors.green.withOpacity(0.2),
                            ]
                          : [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: isGranted
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8.r,
                              spreadRadius: 1.r,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 8.r,
                              spreadRadius: 1.r,
                            ),
                          ],
                  ),
                  child: Icon(
                    isGranted
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: Colors.white.withOpacity(0.9),
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
}