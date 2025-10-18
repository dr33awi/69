// lib/features/qibla/widgets/qibla_compass.dart - بدون عرض الاتجاه الحالي
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';

class QiblaCompass extends StatefulWidget {
  final double qiblaDirection;
  final double currentDirection;
  final double accuracy;
  final bool isCalibrated;
  final VoidCallback? onCalibrate;
  final bool showAccuracyIndicator;
  final bool enableHapticFeedback;

  const QiblaCompass({
    super.key,
    required this.qiblaDirection,
    required this.currentDirection,
    this.accuracy = 1.0,
    this.isCalibrated = true,
    this.onCalibrate,
    this.showAccuracyIndicator = true,
    this.enableHapticFeedback = true,
  });

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass>
    with TickerProviderStateMixin {
  
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _qiblaFoundController;
  late AnimationController _accuracyController;
  late AnimationController _pointerController; // للمؤشر المحسّن
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _qiblaFoundAnimation;
  late Animation<double> _accuracyAnimation;
  late Animation<double> _pointerAnimation; // للمؤشر المحسّن
  late Animation<Color?> _qiblaColorAnimation;

  double _previousDirection = 0.0;
  bool _hasVibratedForQibla = false;
  bool _isPointingToQibla = false;
  Timer? _hapticTimer;

  static const Duration _animationDuration = Duration(milliseconds: 250); // أسرع قليلاً
  static const double _qiblaThreshold = 3.0; // أدق - من 5 إلى 3 درجات

  @override
  void initState() {
    super.initState();
    _previousDirection = widget.currentDirection;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Animation للدوران - محسّن
    _rotationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: _previousDirection,
      end: widget.currentDirection,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutCubic, // منحنى سلس
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _qiblaFoundController = AnimationController(
      duration: const Duration(milliseconds: 600), // أسرع
      vsync: this,
    );

    _qiblaFoundAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15, // تكبير أقل
    ).animate(CurvedAnimation(
      parent: _qiblaFoundController,
      curve: Curves.elasticOut,
    ));

    _qiblaColorAnimation = ColorTween(
      begin: ThemeConstants.primary,
      end: ThemeConstants.success,
    ).animate(_qiblaFoundController);

    _accuracyController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _accuracyAnimation = Tween<double>(
      begin: 0.0,
      end: widget.accuracy,
    ).animate(CurvedAnimation(
      parent: _accuracyController,
      curve: Curves.easeOut,
    ));

    _accuracyController.forward();
    
    // Animation للمؤشر المحسّن
    _pointerController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pointerAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pointerController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(QiblaCompass oldWidget) {
    super.didUpdateWidget(oldWidget);

    // تحديث دوران البوصلة
    if (oldWidget.currentDirection != widget.currentDirection) {
      _updateRotation(oldWidget.currentDirection, widget.currentDirection);
    }

    if (oldWidget.accuracy != widget.accuracy) {
      _accuracyAnimation = Tween<double>(
        begin: oldWidget.accuracy,
        end: widget.accuracy,
      ).animate(CurvedAnimation(
        parent: _accuracyController,
        curve: Curves.easeOut,
      ));
      _accuracyController.forward(from: 0);
    }

    _checkQiblaAlignment();
  }

  void _updateRotation(double from, double to) {
    // حساب أقصر مسار للدوران (محسّن)
    double diff = to - from;
    
    // تطبيع الفرق ليكون بين -180 و 180
    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;
    
    // تجاهل التغييرات الصغيرة جداً لتقليل الاهتزاز
    if (diff.abs() < 0.5) return;
    
    final targetAngle = from + diff;
    
    _rotationAnimation = Tween<double>(
      begin: from,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutCubic, // منحنى سلس
    ));
    
    _rotationController.forward(from: 0).then((_) {
      _previousDirection = targetAngle % 360;
    });
  }

  void _checkQiblaAlignment() {
    final qiblaAngle = _calculateQiblaAngle();
    final wasPointingToQibla = _isPointingToQibla;
    _isPointingToQibla = qiblaAngle.abs() <= _qiblaThreshold;

    if (widget.enableHapticFeedback && _isPointingToQibla && !_hasVibratedForQibla) {
      _triggerQiblaFoundFeedback();
    } else if (!_isPointingToQibla && _hasVibratedForQibla) {
      _hasVibratedForQibla = false;
    }

    if (_isPointingToQibla && !wasPointingToQibla) {
      _qiblaFoundController.forward().then((_) {
        if (mounted) {
          _qiblaFoundController.reverse();
        }
      });
    }
  }

  void _triggerQiblaFoundFeedback() {
    _hasVibratedForQibla = true;
    HapticFeedback.lightImpact();
    
    _hapticTimer?.cancel();
    _hapticTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted && _isPointingToQibla) {
        HapticFeedback.selectionClick();
      }
    });
  }

  double _calculateQiblaAngle() {
    // استخدام القيمة الحالية من الـ animation أو الـ widget
    final currentDir = _rotationController.isAnimating 
        ? _rotationAnimation.value 
        : widget.currentDirection;
    
    final relativeAngle = (widget.qiblaDirection - currentDir + 360) % 360;
    return relativeAngle > 180 ? relativeAngle - 360 : relativeAngle;
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    _qiblaFoundController.dispose();
    _accuracyController.dispose();
    _pointerController.dispose(); // تنظيف المؤشر
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qiblaAngle = _calculateQiblaAngle();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          alignment: Alignment.center,
          children: [
            _buildCompassBackground(size),
            _buildRotatingCompass(size),
            _buildQiblaIndicator(size, qiblaAngle),
            _buildCenterDot(),
            _buildDeviceIndicator(size),
            _buildStatusInfo(size),
            if (widget.showAccuracyIndicator)
              _buildAccuracyRing(size),
            
            // تحذير المعايرة
            if (!widget.isCalibrated)
              _buildCalibrationWarning(size),
          ],
        );
      },
    );
  }

  Widget _buildCompassBackground(double size) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: size * (0.9 + (widget.accuracy < 0.7 ? _pulseAnimation.value * 0.05 : 0)),
          height: size * (0.9 + (widget.accuracy < 0.7 ? _pulseAnimation.value * 0.05 : 0)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                context.cardColor,
                context.cardColor.darken(0.02),
                context.cardColor.darken(0.05),
                context.cardColor.darken(0.1),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16.r,
                offset: Offset(0, 8.h),
              ),
              BoxShadow(
                color: context.primaryColor.withOpacity(0.1),
                blurRadius: 32.r,
                offset: const Offset(0, 0),
              ),
            ],
            border: Border.all(
              color: context.dividerColor.withOpacity(0.2),
              width: 1.5.w,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRotatingCompass(double size) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        // استخدام الـ animation للدوران السلس
        final angle = -_rotationAnimation.value * (math.pi / 180);
        
        return Transform.rotate(
          angle: angle,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: EnhancedCompassPainter(
                accuracy: widget.accuracy,
                isDarkMode: Theme.of(context).brightness == Brightness.dark,
                isCalibrated: widget.isCalibrated,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQiblaIndicator(double size, double qiblaAngle) {
    return AnimatedBuilder(
      animation: Listenable.merge([_qiblaFoundAnimation, _qiblaColorAnimation, _pointerAnimation]),
      builder: (context, child) {
        // تحريك المؤشر عند الاقتراب من القبلة
        final isNearQibla = qiblaAngle.abs() <= 15.0;
        if (isNearQibla && !_pointerController.isAnimating) {
          _pointerController.repeat(reverse: true);
        } else if (!isNearQibla && _pointerController.isAnimating) {
          _pointerController.stop();
          _pointerController.reset();
        }
        
        return Transform.rotate(
          angle: qiblaAngle * (math.pi / 180),
          child: Transform.scale(
            scale: _qiblaFoundAnimation.value,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: size * 0.8,
              height: size * 0.8,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // المؤشر المحسّن
                  Positioned(
                    top: 0,
                    child: Transform.scale(
                      scale: _pointerAnimation.value,
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: 55.w, // أعرض قليلاً
                        height: size * 0.40, // أطول
                        child: CustomPaint(
                          painter: QiblaArrowPainter(
                            color: _qiblaColorAnimation.value ?? context.primaryColor,
                            isPointingToQibla: _isPointingToQibla,
                            glowIntensity: widget.accuracy,
                            isNearQibla: isNearQibla, // إضافة حالة الاقتراب
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // علامة القبلة
                  Positioned(
                    top: size * 0.08,
                    child: AnimatedContainer(
                      duration: _animationDuration,
                      padding: EdgeInsets.symmetric(
                        horizontal: _isPointingToQibla ? 14.w : 12.w,
                        vertical: _isPointingToQibla ? 7.h : 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _qiblaColorAnimation.value ?? context.primaryColor,
                        borderRadius: BorderRadius.circular(
                          _isPointingToQibla ? 14.r : 12.r
                        ),
                        boxShadow: _isPointingToQibla ? [
                          BoxShadow(
                            color: (context.primaryColor).withOpacity(0.4),
                            blurRadius: 8.r,
                            offset: Offset(0, 3.h),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🕋',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'القبلة',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: _isPointingToQibla 
                                  ? ThemeConstants.bold 
                                  : ThemeConstants.semiBold,
                              fontSize: _isPointingToQibla ? 13.sp : 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterDot() {
    return AnimatedContainer(
      duration: _animationDuration,
      width: _isPointingToQibla ? 32.w : 26.w,
      height: _isPointingToQibla ? 32.w : 26.w,
      decoration: BoxDecoration(
        color: _isPointingToQibla ? ThemeConstants.success : context.primaryColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.cardColor,
          width: 3.w,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isPointingToQibla ? ThemeConstants.success : context.primaryColor)
                .withOpacity(0.4),
            blurRadius: _isPointingToQibla ? 8.r : 4.r,
            offset: const Offset(0, 0),
          ),
          // ظل خارجي
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: _isPointingToQibla ? 12.w : 10.w,
          height: _isPointingToQibla ? 12.w : 10.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIndicator(double size) {
    return Positioned(
      top: (size * 0.04), // أقرب قليلاً للحافة
      child: AnimatedContainer(
        duration: _animationDuration,
        child: Column(
          children: [
            // المثلث الرئيسي
            Container(
              width: 0,
              height: 0,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    width: _isPointingToQibla ? 12.w : 10.w, 
                    color: Colors.transparent
                  ),
                  right: BorderSide(
                    width: _isPointingToQibla ? 12.w : 10.w, 
                    color: Colors.transparent
                  ),
                  bottom: BorderSide(
                    width: _isPointingToQibla ? 24.h : 20.h, 
                    color: _isPointingToQibla 
                        ? ThemeConstants.success.withOpacity(0.9)
                        : ThemeConstants.error.withOpacity(0.8)
                  ),
                ),
              ),
            ),
            // ظل المثلث
            if (_isPointingToQibla)
              Container(
                margin: EdgeInsets.only(top: 2.h),
                width: 3.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: ThemeConstants.success.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(double size) {
    return Positioned(
      bottom: size * 0.1,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 3.h,
            ),
            decoration: BoxDecoration(
              color: _getAccuracyColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: _getAccuracyColor().withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getAccuracyIcon(),
                  size: 18.sp,
                  color: _getAccuracyColor(),
                ),
                SizedBox(width: 3.w),
                Text(
                  _getAccuracyText(),
                  style: TextStyle(
                    color: _getAccuracyColor(),
                    fontWeight: ThemeConstants.medium,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),

          if (_isPointingToQibla) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 3.h,
              ),
              decoration: BoxDecoration(
                color: ThemeConstants.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: ThemeConstants.success.withOpacity(0.3),
                ),
              ),
              child: Text(
                '🕋 تشير نحو القبلة',
                style: TextStyle(
                  color: ThemeConstants.success,
                  fontWeight: ThemeConstants.semiBold,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalibrationWarning(double size) {
    return Positioned(
      top: size * 0.02,
      child: GestureDetector(
        onTap: widget.onCalibrate,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10.w,
            vertical: 5.h,
          ),
          decoration: BoxDecoration(
            color: ThemeConstants.warning.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: ThemeConstants.warning.withOpacity(0.3),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16.sp,
                color: Colors.white,
              ),
              SizedBox(width: 6.w),
              Text(
                'يحتاج معايرة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: ThemeConstants.semiBold,
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.touch_app,
                size: 14.sp,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccuracyRing(double size) {
    return AnimatedBuilder(
      animation: _accuracyAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: AccuracyRingPainter(
            accuracy: _accuracyAnimation.value,
            color: _getAccuracyColor(),
          ),
        );
      },
    );
  }

  Color _getAccuracyColor() {
    if (widget.accuracy >= 0.8) return ThemeConstants.success;
    if (widget.accuracy >= 0.5) return ThemeConstants.warning;
    return ThemeConstants.error;
  }

  IconData _getAccuracyIcon() {
    if (widget.accuracy >= 0.8) return Icons.gps_fixed;
    if (widget.accuracy >= 0.5) return Icons.gps_not_fixed;
    return Icons.gps_off;
  }

  String _getAccuracyText() {
    if (widget.accuracy >= 0.85) return 'دقة ممتازة';
    if (widget.accuracy >= 0.70) return 'دقة جيدة جداً';
    if (widget.accuracy >= 0.50) return 'دقة متوسطة';
    return 'دقة منخفضة';
  }
}

// Painters
class EnhancedCompassPainter extends CustomPainter {
  final double accuracy;
  final bool isDarkMode;
  final bool isCalibrated;

  EnhancedCompassPainter({
    this.accuracy = 1.0,
    required this.isDarkMode,
    this.isCalibrated = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final primaryLineColor = Color.lerp(
      ThemeConstants.error.withOpacity(0.6),
      isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
      accuracy,
    )!;

    final secondaryLineColor = Color.lerp(
      ThemeConstants.error.withOpacity(0.3),
      isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
      accuracy,
    )!;

    _drawCircles(canvas, center, radius, primaryLineColor);
    _drawMarkings(canvas, center, radius, primaryLineColor, secondaryLineColor);
    _drawDirectionLabels(canvas, center, radius, primaryLineColor);
  }

  void _drawCircles(Canvas canvas, Offset center, double radius, Color color) {
    final circlePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8.w;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center, 
        radius * (0.3 + i * 0.2), 
        circlePaint..strokeWidth = i == 3 ? 1.5.w : 0.8.w,
      );
    }
  }

  void _drawMarkings(Canvas canvas, Offset center, double radius, 
                     Color primaryColor, Color secondaryColor) {
    for (int i = 0; i < 360; i += 5) {
      final angle = i * (math.pi / 180);
      final isMainDirection = i % 90 == 0;
      final isMediumDirection = i % 45 == 0;
      final isMinorDirection = i % 15 == 0;

      Paint linePaint;
      double lineLength;
      double startRadius;

      if (isMainDirection) {
        lineLength = 24.h;
        startRadius = radius - lineLength;
        linePaint = Paint()
          ..color = primaryColor
          ..strokeWidth = 2.5.w;
      } else if (isMediumDirection) {
        lineLength = 16.h;
        startRadius = radius - lineLength;
        linePaint = Paint()
          ..color = primaryColor.withOpacity(0.8)
          ..strokeWidth = 1.8.w;
      } else if (isMinorDirection) {
        lineLength = 12.h;
        startRadius = radius - lineLength;
        linePaint = Paint()
          ..color = secondaryColor
          ..strokeWidth = 1.2.w;
      } else {
        lineLength = 8.h;
        startRadius = radius - lineLength;
        linePaint = Paint()
          ..color = secondaryColor.withOpacity(0.6)
          ..strokeWidth = 0.8.w;
      }

      final startPoint = Offset(
        center.dx + startRadius * math.cos(angle - math.pi / 2),
        center.dy + startRadius * math.sin(angle - math.pi / 2),
      );

      final endPoint = Offset(
        center.dx + (radius - 1.5.w) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 1.5.w) * math.sin(angle - math.pi / 2),
      );

      canvas.drawLine(startPoint, endPoint, linePaint);
    }
  }

  void _drawDirectionLabels(Canvas canvas, Offset center, double radius, Color color) {
    final textStyle = TextStyle(
      color: color,
      fontSize: 14.sp,
      fontWeight: FontWeight.bold,
    );

    final directions = ['N', 'E', 'S', 'W'];
    final positions = [
      Offset(center.dx, center.dy - radius + 38.h),
      Offset(center.dx + radius - 38.w, center.dy),
      Offset(center.dx, center.dy + radius - 38.h),
      Offset(center.dx - radius + 38.w, center.dy),
    ];

    for (int i = 0; i < directions.length; i++) {
      final textSpan = TextSpan(text: directions[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      if (directions[i] == 'N') {
        canvas.drawCircle(
          positions[i],
          15.w,
          Paint()..color = ThemeConstants.error.withOpacity(0.2),
        );
      }
      
      textPainter.paint(
        canvas, 
        positions[i] - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedCompassPainter oldDelegate) {
    return oldDelegate.accuracy != accuracy || 
           oldDelegate.isDarkMode != isDarkMode ||
           oldDelegate.isCalibrated != isCalibrated;
  }
}

class QiblaArrowPainter extends CustomPainter {
  final Color color;
  final bool isPointingToQibla;
  final double glowIntensity;
  final bool isNearQibla; // جديد

  QiblaArrowPainter({
    required this.color,
    this.isPointingToQibla = false,
    this.glowIntensity = 1.0,
    this.isNearQibla = false, // جديد
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // توهج محسّن
    if (isPointingToQibla || isNearQibla) {
      final glowIntensityFinal = isPointingToQibla ? 0.5 : 0.25;
      final glowPaint = Paint()
        ..color = color.withOpacity(glowIntensityFinal * glowIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isPointingToQibla ? 10.r : 6.r);
      
      _drawArrowPath(canvas, size, glowPaint);
    }

    _drawArrowPath(canvas, size, paint);

    // تأثير لامع
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withOpacity(isPointingToQibla ? 0.5 : 0.3),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));

    _drawArrowPath(canvas, size, glossPaint);
    
    // حدود للوضوح
    if (isPointingToQibla) {
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5.w;
      _drawArrowPath(canvas, size, borderPaint);
    }
  }

  void _drawArrowPath(Canvas canvas, Size size, Paint paint) {
    final path = Path();

    // شكل سهم محسّن وأوضح
    path.moveTo(size.width / 2, 0); // القمة
    path.lineTo(size.width * 0.78, size.height * 0.32); // يمين رأس السهم
    path.lineTo(size.width * 0.68, size.height * 0.32); // يمين الجسم
    path.lineTo(size.width * 0.68, size.height * 0.88); // يمين القاعدة
    path.lineTo(size.width * 0.32, size.height * 0.88); // يسار القاعدة
    path.lineTo(size.width * 0.32, size.height * 0.32); // يسار الجسم
    path.lineTo(size.width * 0.22, size.height * 0.32); // يسار رأس السهم
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant QiblaArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.isPointingToQibla != isPointingToQibla ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.isNearQibla != isNearQibla;
  }
}

class AccuracyRingPainter extends CustomPainter {
  final double accuracy;
  final Color color;

  AccuracyRingPainter({
    required this.accuracy,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8.w;

    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.w;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (accuracy > 0) {
      final accuracyPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.w
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * accuracy;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        accuracyPaint,
      );

      if (accuracy < 1.0) {
        final endAngle = startAngle + sweepAngle;
        final endX = center.dx + radius * math.cos(endAngle);
        final endY = center.dy + radius * math.sin(endAngle);
        
        final dotPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(endX, endY),
          (5.w / 2) + 1.5.w,
          dotPaint,
        );
        
        final haloPaint = Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(
          Offset(endX, endY),
          (5.w / 2) + 5.w,
          haloPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant AccuracyRingPainter oldDelegate) {
    return oldDelegate.accuracy != accuracy || oldDelegate.color != color;
  }
}