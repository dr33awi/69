// lib/features/tasbih/widgets/tasbih_counter_ring.dart
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
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _currentProgress = widget.progress;
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(TasbihCounterRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // ✅ إصلاح: إيقاف الأنيميشن السابق قبل بدء جديد
    if ((widget.progress - oldWidget.progress).abs() > 0.001) {
      // إيقاف الأنيميشن الحالي
      _controller.stop();
      
      // استخدام القيمة الحالية كنقطة بداية
      final beginValue = _controller.isAnimating 
          ? _animation.value 
          : _currentProgress;
      
      _animation = Tween<double>(
        begin: beginValue,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      
      _currentProgress = widget.progress;
      
      // بدء الأنيميشن من الصفر
      _controller.forward(from: 0.0);
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
  final double progress;
  final List<Color> gradient;
  final double strokeWidth;

  _CounterRingPainter({
    required this.progress,
    required this.gradient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. رسم الحلقة الخلفية
    _drawBackgroundRing(canvas, center, radius);

    // 2. رسم حلقة التقدم
    if (progress > 0.001) {
      _drawProgressRing(canvas, center, radius);
      
      // 3. رسم النقطة في نهاية الحلقة
      if (progress < 0.999) {
        _drawEndDot(canvas, center, radius);
      }
    }
  }

  void _drawBackgroundRing(Canvas canvas, Offset center, double radius) {
    final backgroundPaint = Paint()
      ..color = gradient[0].withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
  }

  void _drawProgressRing(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: gradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  void _drawEndDot(Canvas canvas, Offset center, double radius) {
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    final endAngle = startAngle + sweepAngle;
    
    final endX = center.dx + radius * math.cos(endAngle);
    final endY = center.dy + radius * math.sin(endAngle);
    final endPoint = Offset(endX, endY);
    
    // Halo خارجي
    final haloPaint = Paint()
      ..color = gradient.last.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(endPoint, strokeWidth / 2 + 4.w, haloPaint);
    
    // النقطة الرئيسية
    final dotPaint = Paint()
      ..color = gradient.last
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(endPoint, strokeWidth / 2 + 1.5.w, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _CounterRingPainter oldDelegate) {
    // ✅ تحسين: فقط إعادة الرسم عند التغيير الملحوظ
    return (oldDelegate.progress - progress).abs() > 0.001 ||
           oldDelegate.gradient != gradient ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}