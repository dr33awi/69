// lib/features/qibla/widgets/phone_calibration_animation.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget الجوال المتحرك على شكل 8 (Lissajous)
/// مع ميل ثلاثي الأبعاد خفيف وحركة سلسة محسّنة
class PhoneCalibrationAnimation extends StatefulWidget {
  final Color primaryColor;
  final double width;
  final double height;
  final double amplitudeX;
  final double amplitudeY;
  final Duration duration;

  const PhoneCalibrationAnimation({
    Key? key,
    required this.primaryColor,
    this.width = 280,
    this.height = 140,
    this.amplitudeX = 60,
    this.amplitudeY = 35,
    this.duration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  State<PhoneCalibrationAnimation> createState() => _PhoneCalibrationAnimationState();
}

class _PhoneCalibrationAnimationState extends State<PhoneCalibrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _tAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    
    _tAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // خلفية شكل 8
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: Figure8BackgroundPainter(
              color: widget.primaryColor.withOpacity(0.28),
            ),
          ),

          // الجوال المتحرك
          AnimatedBuilder(
            animation: _tAnim,
            builder: (context, child) {
              final t = _tAnim.value;
              
              // حركة Lissajous: x = sin(t), y = sin(2t)
              final x = math.sin(t) * widget.amplitudeX;
              final y = math.sin(2 * t) * widget.amplitudeY;
              
              // الميل ثلاثي الأبعاد
              final tiltY = math.sin(t) * 0.25; // دوران حول Y
              final tiltZ = tiltY * 0.6; // دوران حول Z
              final tiltX = math.sin(t * 0.7) * 0.12; // دوران حول X (اختياري)
              
              // نبضة خفيفة
              final scale = 1 + 0.03 * math.cos(2 * t);

              final transform = Matrix4.identity()
                ..rotateX(tiltX)
                ..rotateY(tiltY)
                ..rotateZ(tiltZ);

              return Transform.translate(
                offset: Offset(x, y),
                child: Transform(
                  alignment: Alignment.center,
                  transform: transform..scale(scale, scale, 1),
                  child: child,
                ),
              );
            },
            child: PhoneAnimationWidget(
              color: widget.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// شكل الجوال المستخدم في الأنيميشن
class PhoneAnimationWidget extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const PhoneAnimationWidget({
    Key? key,
    this.width = 45,
    this.height = 40,
    this.color = const Color(0xFF2F80ED),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.w,
      height: height.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            _darken(color, 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.explore,
              color: color,
              size: 16.sp,
            ),
          ),
        ),
      ),
    );
  }

  /// تغميق اللون
  Color _darken(Color c, double amount) {
    assert(amount >= 0 && amount <= 1);
    final f = 1 - amount;
    return Color.fromARGB(
      c.alpha,
      (c.red * f).round(),
      (c.green * f).round(),
      (c.blue * f).round(),
    );
  }
}

/// رسام خلفية شكل 8 (∞) بأسلوب منحنيات Bézier
class Figure8BackgroundPainter extends CustomPainter {
  final Color color;

  Figure8BackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width * 0.33;
    final ry = size.height * 0.33;

    // البداية: الجانب الأيسر
    path.moveTo(cx - rx, cy);

    // الحلقة اليسرى -> المركز
    path.cubicTo(
      cx - rx, cy - ry,
      cx - rx * 0.18, cy - ry,
      cx, cy,
    );

    // المركز -> الجانب الأيمن السفلي
    path.cubicTo(
      cx + rx * 0.18, cy + ry,
      cx + rx, cy + ry,
      cx + rx, cy,
    );

    // الجانب الأيمن العلوي -> المركز
    path.cubicTo(
      cx + rx, cy - ry,
      cx + rx * 0.18, cy - ry,
      cx, cy,
    );

    // العودة للجانب الأيسر السفلي -> إغلاق الحلقة
    path.cubicTo(
      cx - rx * 0.18, cy + ry,
      cx - rx, cy + ry,
      cx - rx, cy,
    );

    canvas.drawPath(path, paint);

    // نقاط التوضيح
    final dotPaint = Paint()..color = color;
    final points = [
      Offset(cx - rx, cy),
      Offset(cx, cy - ry),
      Offset(cx + rx, cy),
      Offset(cx, cy + ry),
    ];

    for (var p in points) {
      canvas.drawCircle(p, 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant Figure8BackgroundPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
