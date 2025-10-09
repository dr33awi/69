// lib/features/tasbih/widgets/tasbih_bead_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../../app/themes/app_theme.dart';

/// Widget الخرزة/الزر الدائري للتسبيح
class TasbihBeadWidget extends StatelessWidget {
  final double size;
  final List<Color> gradient;
  final bool isPressed;
  final Widget child;

  const TasbihBeadWidget({
    super.key,
    required this.size,
    required this.gradient,
    required this.isPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    assert(size > 0, 'Size must be positive');
    assert(gradient.length >= 2, 'Gradient must have at least 2 colors');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPressed 
              ? gradient.map((c) => c.darken(0.1)).toList()
              : gradient,
        ),
        boxShadow: _buildShadows(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5.w,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _buildShadows() {
    return [
      BoxShadow(
        color: gradient[0].withOpacity(0.25),
        blurRadius: isPressed ? 20.r : 16.r,
        offset: Offset(0, isPressed ? 6.h : 10.h),
        spreadRadius: isPressed ? 1.5.r : 3.r,
      ),
      BoxShadow(
        color: gradient[1].withOpacity(0.1),
        blurRadius: isPressed ? 28.r : 24.r,
        offset: Offset(0, isPressed ? 10.h : 14.h),
        spreadRadius: isPressed ? 3.r : 5.r,
      ),
    ];
  }
}