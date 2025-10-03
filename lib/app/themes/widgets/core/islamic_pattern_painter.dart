// lib/core/shared/widgets/islamic_pattern_painter.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// رسام الأنماط الإسلامية الموحد لجميع الشاشات
class IslamicPatternPainter extends CustomPainter {
  final double rotation;
  final Color color;
  final PatternType patternType;
  final double opacity;

  IslamicPatternPainter({
    required this.rotation,
    required this.color,
    this.patternType = PatternType.standard,
    this.opacity = 0.05,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = patternType == PatternType.bold ? 1.5 : 1.0;
    
    final fillPaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    
    // رسم النمط حسب النوع
    switch (patternType) {
      case PatternType.standard:
        _drawStandardPattern(canvas, size, paint, fillPaint);
        break;
      case PatternType.geometric:
        _drawGeometricPattern(canvas, size, paint, fillPaint);
        break;
      case PatternType.floral:
        _drawFloralPattern(canvas, size, paint, fillPaint);
        break;
      case PatternType.bold:
        _drawBoldPattern(canvas, size, paint, fillPaint);
        break;
    }
    
    canvas.restore();
    
    // عناصر ثابتة
    _drawStaticElements(canvas, size, paint);
  }

  // باقي الدوال كما هي في الملف الأصلي...
  
  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return oldDelegate.rotation != rotation || 
           oldDelegate.color != color ||
           oldDelegate.patternType != patternType ||
           oldDelegate.opacity != opacity;
  }

  // [تم اختصار باقي الدوال المساعدة لتوفير المساحة - ستبقى كما هي في الملف الأصلي]
  void _drawStandardPattern(Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {}
  void _drawGeometricPattern(Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {}
  void _drawFloralPattern(Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {}
  void _drawBoldPattern(Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {}
  void _drawStaticElements(Canvas canvas, Size size, Paint paint) {}
}

/// أنواع الأنماط
enum PatternType {
  standard,   // النمط الافتراضي
  geometric,  // هندسي
  floral,     // نباتي
  bold,       // قوي للأدعية
}