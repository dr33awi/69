// lib/features/onboarding/widgets/islamic_pattern_painter.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class IslamicPatternPainter extends CustomPainter {
  final String patternType;
  final Color color;
  final double opacity;

  IslamicPatternPainter({
    required this.patternType,
    required this.color,
    this.opacity = 0.1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    switch (patternType) {
      case 'spiritual':
        _drawSpiritualPattern(canvas, size, paint);
        break;
      case 'notifications':
        _drawNotificationsPattern(canvas, size, paint);
        break;
      case 'prayer':
        _drawPrayerPattern(canvas, size, paint);
        break;
      case 'final':
        _drawFinalPattern(canvas, size, paint);
        break;
    }
  }

  void _drawSpiritualPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 80.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // دوائر متداخلة
        canvas.drawCircle(Offset(x, y), 30, paint);
        canvas.drawCircle(Offset(x, y), 15, paint);
        
        // نجمة في المركز
        _drawStar(canvas, Offset(x, y), 8, paint);
      }
    }
  }

  void _drawNotificationsPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // نقطة مركزية
        canvas.drawCircle(Offset(x, y), 2, Paint()..color = color.withValues(alpha: opacity));
        
        // دوائر متقطعة
        _drawDashedCircle(canvas, Offset(x, y), 15, paint);
        _drawDashedCircle(canvas, Offset(x, y), 25, paint);
      }
    }
  }

  void _drawPrayerPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 100.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // مربع مدور
        final rect = Rect.fromCenter(
          center: Offset(x, y),
          width: 50,
          height: 50,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          paint,
        );
        
        // دائرة داخلية
        canvas.drawCircle(Offset(x, y), 20, paint);
        
        // خطوط اتجاهية
        for (int i = 0; i < 4; i++) {
          final angle = i * math.pi / 2;
          final start = Offset(
            x + 25 * math.cos(angle),
            y + 25 * math.sin(angle),
          );
          final end = Offset(
            x + 35 * math.cos(angle),
            y + 35 * math.sin(angle),
          );
          canvas.drawLine(start, end, paint);
        }
      }
    }
  }

  void _drawFinalPattern(Canvas canvas, Size size, Paint paint) {
    const spacing = 120.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // دوائر متعددة
        canvas.drawCircle(Offset(x, y), 40, paint);
        canvas.drawCircle(Offset(x, y), 25, paint);
        canvas.drawCircle(Offset(x, y), 10, Paint()..color = color.withValues(alpha: opacity * 2));
        
        // خطوط شعاعية
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final start = Offset(
            x + 35 * math.cos(angle),
            y + 35 * math.sin(angle),
          );
          final end = Offset(
            x + 50 * math.cos(angle),
            y + 50 * math.sin(angle),
          );
          canvas.drawLine(start, end, paint);
        }
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, int points, Paint paint) {
    final path = Path();
    final outerRadius = 8.0;
    final innerRadius = 4.0;
    
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi) / points;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: opacity * 2));
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashCount = 20;
    const dashLength = 2 * math.pi / dashCount;
    
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = i * dashLength;
      final endAngle = (i + 1) * dashLength;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return oldDelegate.patternType != patternType ||
           oldDelegate.color != color ||
           oldDelegate.opacity != opacity;
  }
}