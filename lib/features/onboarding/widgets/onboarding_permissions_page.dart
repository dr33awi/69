// lib/features/onboarding/widgets/onboarding_permissions_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../../app/themes/widgets/core/islamic_pattern_painter.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../core/infrastructure/services/permissions/permission_constants.dart';
import '../models/onboarding_item.dart';
import '../data/onboarding_data.dart';
import 'permission_status_indicator.dart';
import 'success_celebration_widget.dart';

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

class _OnboardingPermissionsPageState extends State<OnboardingPermissionsPage>
    with TickerProviderStateMixin {
  
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late PermissionService _permissionService;
  
  final List<AppPermissionType> _permissions = [
    AppPermissionType.notification,
    AppPermissionType.location,
    AppPermissionType.batteryOptimization,
  ];
  
  Map<AppPermissionType, bool> _permissionStatuses = {};
  int _grantedCount = 0;
  bool _showCelebration = false;
  bool _celebrationShown = false;

  @override
  void initState() {
    super.initState();
    
    _permissionService = getIt<PermissionService>();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _scaleController.forward();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _slideController.forward();
    });
    
    // فحص حالة الأذونات
    _checkPermissionsStatus();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
    
    // تحقق إذا كانت كل الأذونات ممنوحة مسبقاً
    if (_grantedCount == _permissions.length && !_celebrationShown) {
      _triggerCelebration();
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
          
          // تحقق إذا تم منح كل الأذونات
          if (_grantedCount == _permissions.length && !_celebrationShown) {
            _triggerCelebration();
          }
        }
      });
    }
  }
  
  void _triggerCelebration() {
    debugPrint('🎉 Triggering celebration!');
    setState(() {
      _showCelebration = true;
      _celebrationShown = true;
    });
    
    HapticFeedback.heavyImpact();
    
    // إخفاء الاحتفال بعد 3 ثواني
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCelebration = false;
        });
      }
    });
  }
  
  bool get _allPermissionsGranted => _grantedCount == _permissions.length;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
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
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              SizedBox(height: 40.h),
                              
                              _buildAnimationWidget(),
                              
                              SizedBox(height: 24.h),
                              
                              _buildTitle(),
                              
                              SizedBox(height: 12.h),
                              
                              _buildSubtitle(),
                              
                              SizedBox(height: 20.h),
                              
                              // مؤشر التقدم
                              _buildProgressIndicator(),
                              
                              SizedBox(height: 32.h),
                              
                              _buildPermissionsList(),
                            ],
                          ),
                          
                          Column(
                            children: [
                              SizedBox(height: 24.h),
                              _buildActionButton(),
                              // إزالة زر التخطي
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
        ),
        
        // عرض الاحتفال
        if (_showCelebration)
          Positioned.fill(
            child: SuccessCelebrationWidget(
              onComplete: () {
                if (mounted) {
                  setState(() {
                    _showCelebration = false;
                  });
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAnimationWidget() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 140.w,
            height: 140.w,
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
                width: 100.w,
                height: 100.w,
                child: widget.item.hasValidLottie
                    ? Lottie.asset(
                        widget.item.lottiePath!,
                        fit: BoxFit.contain,
                        repeat: false,
                        animate: true,
                        options: LottieOptions(
                          enableMergePaths: true,
                        ),
                        onLoaded: (composition) {
                          debugPrint('✅ Lottie loaded: ${widget.item.lottiePath}');
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ Lottie error: $error');
                          return _buildFallbackIcon();
                        },
                      )
                    : _buildFallbackIcon(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 70.w,
      height: 70.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: Icon(
        Icons.security_rounded,
        size: 35.sp,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20.h * (1 - _fadeAnimation.value)),
            child: Text(
              'أذونات التطبيق',
              style: TextStyle(
                fontSize: 28.sp,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value * 0.9,
          child: Transform.translate(
            offset: Offset(0, 25.h * (1 - _fadeAnimation.value)),
            child: Text(
              'هذه الأذونات ضرورية لعمل التطبيق بشكل صحيح',
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.white.withOpacity(0.85),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 28.h * (1 - _fadeAnimation.value)),
            child: Center(
              child: PermissionStatusIndicator(
                totalPermissions: _permissions.length,
                grantedPermissions: _grantedCount,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionsList() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: List.generate(
            _permissions.length,
            (index) => TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30.h * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _PermissionCard(
                permission: _permissions[index],
                index: index,
                isGranted: _permissionStatuses[_permissions[index]] ?? false,
                onTap: () => _handlePermissionTap(_permissions[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 40.h * (1 - _fadeAnimation.value)),
            child: Container(
              width: double.infinity,
              height: 54.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27.r),
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
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.2),
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
                      color: Colors.white.withOpacity(0.15),
                      blurRadius: 20.r,
                      spreadRadius: 2.r,
                      offset: Offset(0, 8.h),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (_allPermissionsGranted && !widget.isProcessing) 
                      ? widget.onNext 
                      : null,
                  borderRadius: BorderRadius.circular(27.r),
                  child: Container(
                    alignment: Alignment.center,
                    child: widget.isProcessing
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5.w,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _allPermissionsGranted ? Colors.white : widget.item.primaryColor,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _allPermissionsGranted 
                                    ? 'المتابعة إلى التطبيق' 
                                    : 'يجب منح جميع الأذونات',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_allPermissionsGranted) ...[
                                SizedBox(width: 8.w),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionCard extends StatefulWidget {
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

  @override
  State<_PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<_PermissionCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.1,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    Future.delayed(Duration(milliseconds: 1000 + (widget.index * 300)), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = PermissionConstants.getInfo(widget.permission);
    final shouldPulse = !widget.isGranted;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: shouldPulse ? _pulseAnimation.value : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isGranted
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
                color: widget.isGranted
                    ? Colors.green.withOpacity(0.3)
                    : Colors.white.withOpacity(0.2),
                width: widget.isGranted ? 2.w : 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
                if (shouldPulse)
                  BoxShadow(
                    color: Colors.white.withOpacity(_glowAnimation.value),
                    blurRadius: 16.r,
                    spreadRadius: 0,
                  ),
                if (widget.isGranted)
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
                onTap: widget.isGranted ? null : widget.onTap,
                borderRadius: BorderRadius.circular(18.r),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (shouldPulse)
                            Container(
                              width: 56.w,
                              height: 56.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(_glowAnimation.value),
                                    blurRadius: 20.r,
                                    spreadRadius: 4.r,
                                  ),
                                ],
                              ),
                            ),
                          
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 52.w,
                            height: 52.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.isGranted
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
                                  color: widget.isGranted
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.15),
                                  blurRadius: 12.r,
                                  spreadRadius: 1.r,
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.isGranted ? Icons.check_circle_rounded : info.icon,
                              color: Colors.white,
                              size: 26.sp,
                            ),
                          ),
                        ],
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
                                      fontSize: 16.sp,
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
                                if (widget.isGranted)
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
                                        fontSize: 10.sp,
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
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.75),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(width: 8.w),
                      
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isGranted
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
                          boxShadow: widget.isGranted
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
                          widget.isGranted
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
          ),
        );
      },
    );
  }
}