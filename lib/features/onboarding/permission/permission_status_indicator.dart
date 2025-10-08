// lib/features/onboarding/widgets/permission_status_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PermissionStatusIndicator extends StatefulWidget {
  final int totalPermissions;
  final int grantedPermissions;
  final VoidCallback? onTap;

  const PermissionStatusIndicator({
    super.key,
    required this.totalPermissions,
    required this.grantedPermissions,
    this.onTap,
  });

  @override
  State<PermissionStatusIndicator> createState() => _PermissionStatusIndicatorState();
}

class _PermissionStatusIndicatorState extends State<PermissionStatusIndicator>
    with TickerProviderStateMixin {
  
  late AnimationController _progressController;
  late AnimationController _shimmerController;
  late Animation<double> _progressAnimation;
  
  double _previousProgress = 0.0;

  // حساب الأحجام المتجاوبة
  double get _containerHorizontalPadding {
    if (1.sw > 600) return 18.w;
    return 14.w;
  }

  double get _containerVerticalPadding {
    if (1.sw > 600) return 12.h;
    return 10.h;
  }

  double get _iconSize {
    if (1.sw > 600) return 34.w;
    if (1.sw > 400) return 32.w;
    return 30.w;
  }

  double get _iconInnerSize {
    if (1.sw > 600) return 20.sp;
    return 18.sp;
  }

  double get _progressBarWidth {
    if (1.sw > 600) return 100.w;
    if (1.sw > 400) return 90.w;
    return 80.w;
  }

  double get _progressBarHeight {
    if (1.sw > 600) return 6.h;
    return 5.h;
  }

  double get _textSize {
    if (1.sw > 600) return 15.sp;
    if (1.sw > 400) return 14.sp;
    return 13.sp;
  }

  double get _spacing {
    if (1.sw > 600) return 10.w;
    return 8.w;
  }

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _calculateProgress(),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressController.forward();
    
    if (!_isComplete) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PermissionStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.grantedPermissions != widget.grantedPermissions) {
      _animateToNewProgress();
      
      if (_isComplete && _shimmerController.isAnimating) {
        _shimmerController.stop();
      } else if (!_isComplete && !_shimmerController.isAnimating) {
        _shimmerController.repeat();
      }
    }
  }

  void _animateToNewProgress() {
    _previousProgress = _progressAnimation.value;
    
    _progressAnimation = Tween<double>(
      begin: _previousProgress,
      end: _calculateProgress(),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressController.reset();
    _progressController.forward();
    
    if (widget.grantedPermissions > 0) {
      HapticFeedback.lightImpact();
    }
  }

  double _calculateProgress() {
    if (widget.totalPermissions == 0) return 0.0;
    return widget.grantedPermissions / widget.totalPermissions;
  }

  bool get _isComplete => widget.grantedPermissions == widget.totalPermissions;

  @override
  void dispose() {
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _containerHorizontalPadding,
          vertical: _containerVerticalPadding,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1.2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            SizedBox(width: _spacing),
            _buildProgressBar(),
            SizedBox(width: _spacing),
            _buildText(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: _iconSize,
          height: _iconSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isComplete
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
            boxShadow: _isComplete
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10.r,
                      spreadRadius: 1.r,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            _isComplete ? Icons.check_circle_rounded : Icons.security_rounded,
            color: Colors.white,
            size: _iconInnerSize,
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: _progressBarWidth,
          height: _progressBarHeight,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(_progressBarHeight / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_progressBarHeight / 2),
            child: Stack(
              children: [
                // Progress fill
                FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isComplete
                            ? [
                                Colors.green.shade300,
                                Colors.green.shade400,
                              ]
                            : [
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.7),
                              ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 3.r,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Shimmer effect
                if (!_isComplete && _progressAnimation.value > 0)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            (_shimmerController.value * 3 - 1) * _progressBarWidth,
                            0,
                          ),
                          child: Container(
                            width: 25.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildText() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Text(
          '${widget.grantedPermissions}/${widget.totalPermissions}',
          style: TextStyle(
            fontSize: _textSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 3.r,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// نسخة مبسطة - دائرة تقدم
class CircularPermissionProgress extends StatefulWidget {
  final int totalPermissions;
  final int grantedPermissions;
  final double? size;

  const CircularPermissionProgress({
    super.key,
    required this.totalPermissions,
    required this.grantedPermissions,
    this.size,
  });

  @override
  State<CircularPermissionProgress> createState() => _CircularPermissionProgressState();
}

class _CircularPermissionProgressState extends State<CircularPermissionProgress>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // حساب الحجم المتجاوب
  double get _effectiveSize {
    if (widget.size != null) return widget.size!;
    if (1.sw > 600) return 60;
    if (1.sw > 400) return 55;
    return 50;
  }

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotationController);
    
    if (widget.grantedPermissions < widget.totalPermissions) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CircularPermissionProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.grantedPermissions == widget.totalPermissions &&
        oldWidget.grantedPermissions != widget.grantedPermissions) {
      _rotationController.stop();
      HapticFeedback.mediumImpact();
    } else if (widget.grantedPermissions < widget.totalPermissions &&
               !_rotationController.isAnimating) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  double get _progress {
    if (widget.totalPermissions == 0) return 0.0;
    return widget.grantedPermissions / widget.totalPermissions;
  }

  bool get _isComplete => widget.grantedPermissions == widget.totalPermissions;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return SizedBox(
          width: _effectiveSize.w,
          height: _effectiveSize.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: _effectiveSize.w,
                height: _effectiveSize.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              
              // Progress circle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: _progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return CustomPaint(
                    size: Size(_effectiveSize.w, _effectiveSize.w),
                    painter: _CircularProgressPainter(
                      progress: value,
                      isComplete: _isComplete,
                      rotation: _rotationAnimation.value,
                    ),
                  );
                },
              ),
              
              // Center icon
              Container(
                width: (_effectiveSize * 0.6).w,
                height: (_effectiveSize * 0.6).w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
                child: Icon(
                  _isComplete ? Icons.check_rounded : Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: (_effectiveSize * 0.35).sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter للدائرة المتقدمة
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isComplete;
  final double rotation;

  _CircularProgressPainter({
    required this.progress,
    required this.isComplete,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Progress arc
    final progressPaint = Paint()
      ..color = isComplete ? Colors.green.shade300 : Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    if (!isComplete) {
      progressPaint.shader = SweepGradient(
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white,
          Colors.white.withOpacity(0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(rotation * 2 * 3.14159),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    }
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -3.14159 / 2,
      2 * 3.14159 * progress,
      false,
      progressPaint,
    );
    
    // Glow effect when complete
    if (isComplete) {
      final glowPaint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      
      canvas.drawCircle(center, radius - 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.isComplete != isComplete ||
           oldDelegate.rotation != rotation;
  }
}