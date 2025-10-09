// lib/features/tasbih/widgets/tasbih_counter_ring.dart - محسّن
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

/// Widget الحلقة الدائرية التي تُظهر تقدم التسبيح
class TasbihCounterRing extends StatefulWidget {
  final double progress; // التقدم من 0.0 إلى 1.0
  final List<Color> gradient; // ألوان التدرج للحلقة
  final double strokeWidth; // سُمك الخط

  const TasbihCounterRing({
    super.key,
    required this.progress,
    required this.gradient,
    this.strokeWidth = 8.0,
  });

  @override
  State<TasbihCounterRing> createState() => _TasbihCounterRingState();
}

class _TasbihCounterRingState extends State<TasbihCounterRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // إنشاء Animation Controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // إنشاء Animation من 0 إلى التقدم الحالي
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _previousProgress = widget.progress;
    _controller.forward();
  }

  @override
  void didUpdateWidget(TasbihCounterRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // تحديث الأنيميشن عند تغيير التقدم
    if (oldWidget.progress != widget.progress) {
      // تجنب إعادة التشغيل إذا كان الأنيميشن قيد التشغيل (يمنع الوميض)
      if (!_controller.isAnimating) {
        _animation = Tween<double>(
          begin: _previousProgress,
          end: widget.progress,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ));
        
        _previousProgress = widget.progress;
        _controller.reset();
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _CounterRingPainter(
            progress: _animation.value,
            gradient: widget.gradient,
            strokeWidth: widget.strokeWidth,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// الرسام المخصص للحلقة الدائرية
class _CounterRingPainter extends CustomPainter {
  final double progress; // التقدم من 0.0 إلى 1.0
  final List<Color> gradient; // ألوان التدرج
  final double strokeWidth; // سُمك الخط

  _CounterRingPainter({
    required this.progress,
    required this.gradient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. رسم الحلقة الخلفية (الرمادية الباهتة)
    _drawBackgroundRing(canvas, center, radius);

    // 2. رسم حلقة التقدم (الملونة)
    if (progress > 0) {
      _drawProgressRing(canvas, center, radius);
      
      // 3. رسم النقطة في نهاية الحلقة (إذا لم تكتمل)
      if (progress < 1.0) {
        _drawEndDot(canvas, center, radius);
      }
    }
  }

  /// رسم الحلقة الخلفية
  void _drawBackgroundRing(Canvas canvas, Offset center, double radius) {
    final backgroundPaint = Paint()
      ..color = gradient[0].withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
  }

  /// رسم حلقة التقدم
  void _drawProgressRing(Canvas canvas, Offset center, double radius) {
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: gradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // بداية الرسم من الأعلى (-90 درجة)
    const startAngle = -math.pi / 2;
    // زاوية القوس حسب التقدم (محدودة بين 0 و 1)
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  /// رسم النقطة في نهاية الحلقة
  void _drawEndDot(Canvas canvas, Offset center, double radius) {
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final endAngle = startAngle + sweepAngle;
    
    // حساب موقع النقطة
    final endX = center.dx + radius * math.cos(endAngle);
    final endY = center.dy + radius * math.sin(endAngle);
    
    // رسم النقطة الداخلية
    final dotPaint = Paint()
      ..color = gradient.last
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(endX, endY),
      strokeWidth / 2 + 1.5.w,
      dotPaint,
    );
    
    // رسم Halo حول النقطة (للتأثير البصري)
    final haloPaint = Paint()
      ..color = gradient.last.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(endX, endY),
      strokeWidth / 2 + 4.w,
      haloPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CounterRingPainter oldDelegate) {
    // إعادة الرسم فقط إذا تغيرت القيم
    return oldDelegate.progress != progress ||
           oldDelegate.gradient != gradient ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}