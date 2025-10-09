// lib/features/tasbih/widgets/tasbih_bead_widget.dart - محسّن ومشروح
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../../app/themes/app_theme.dart';

/// Widget الخرزة/الزر الدائري للتسبيح
/// 
/// هذا الـ widget يمثل الزر الدائري الكبير في وسط شاشة المسبحة
/// الذي يضغط عليه المستخدم لزيادة عدد التسبيح
/// 
/// المميزات:
/// - تصميم دائري جميل مع تدرجات لونية
/// - تأثيرات ظل متعددة للعمق
/// - استجابة للضغط (يغمق عند الضغط)
/// - BackdropFilter للتأثير الزجاجي
/// - محتوى قابل للتخصيص (child)
class TasbihBeadWidget extends StatelessWidget {
  /// حجم الخرزة (العرض والطول)
  final double size;
  
  /// ألوان التدرج للخرزة (من الأعلى لليسار إلى الأسفل لليمين)
  final List<Color> gradient;
  
  /// هل الخرزة مضغوطة حالياً؟
  /// true = مضغوطة (لون أغمق)
  /// false = غير مضغوطة (لون عادي)
  final bool isPressed;
  
  /// المحتوى الذي سيظهر داخل الخرزة
  /// عادةً يكون Column يحتوي على:
  /// - Text: العدد الحالي
  /// - Text: "اضغط للتسبيح"
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
    // التحقق من صحة البيانات (في وضع التطوير فقط)
    assert(size > 0, 'Size must be positive');
    assert(gradient.length >= 2, 'Gradient must have at least 2 colors');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle, // شكل دائري
        
        // التدرج اللوني
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPressed 
              ? gradient.map((c) => c.darken(0.1)).toList() // أغمق عند الضغط
              : gradient, // عادي عند عدم الضغط
        ),
        
        // الظلال (للعمق ثلاثي الأبعاد)
        boxShadow: _buildShadows(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2), // قص دائري
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1), // تأثير blur خفيف
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              
              // حدود بيضاء شفافة
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5.w,
              ),
              
              // تدرج إضافي للتأثير الزجاجي
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.1),  // إضاءة في الأعلى
                  Colors.transparent,              // شفاف في الوسط
                  Colors.black.withOpacity(0.1),   // ظل خفيف في الأسفل
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            
            // المحتوى (العدد والنص)
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  /// بناء الظلال المتعددة للعمق ثلاثي الأبعاد
  /// 
  /// يتم إنشاء ظلين:
  /// 1. الظل الأساسي: قوي وقريب
  /// 2. الظل الثانوي: أضعف وأبعد
  List<BoxShadow> _buildShadows() {
    return [
      // الظل الأساسي (قوي ومركز)
      BoxShadow(
        color: gradient[0].withOpacity(0.25),
        blurRadius: isPressed ? 20.r : 16.r,      // blur أقل عند الضغط
        offset: Offset(0, isPressed ? 6.h : 10.h), // أقرب عند الضغط
        spreadRadius: isPressed ? 1.5.r : 3.r,     // spread أقل عند الضغط
      ),
      
      // الظل الثانوي (ضعيف وبعيد للعمق)
      BoxShadow(
        color: gradient[1].withOpacity(0.1),
        blurRadius: isPressed ? 28.r : 24.r,
        offset: Offset(0, isPressed ? 10.h : 14.h),
        spreadRadius: isPressed ? 3.r : 5.r,
      ),
    ];
  }
}