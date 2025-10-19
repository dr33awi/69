// lib/core/infrastructure/services/review/review_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_theme.dart';

/// مربع حوار جذاب لطلب تقييم التطبيق
/// 
/// يعرض رسالة ودية تشجع المستخدم على تقييم التطبيق
class ReviewDialog extends StatelessWidget {
  const ReviewDialog({super.key});

  /// عرض مربع الحوار
  static Future<ReviewDialogResult?> show(BuildContext context) {
    return showDialog<ReviewDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ReviewDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة النجمة
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_rounded,
                size: 48.sp,
                color: context.primaryColor,
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // العنوان
            Text(
              'هل تستمتع بالتطبيق؟ 💚',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12.h),
            
            // الوصف
            Text(
              'سعادتك تهمنا! ساعدنا في تحسين التطبيق بتقييمك',
              style: TextStyle(
                fontSize: 14.sp,
                color: context.textSecondaryColor,
                fontFamily: 'Cairo',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 24.h),
            
            // زر التقييم الإيجابي
            _BuildGradientButton(
              onPressed: () => Navigator.pop(context, ReviewDialogResult.rate),
              text: '⭐ قيّم التطبيق',
              colors: [context.primaryColor, context.primaryColor.withOpacity(0.8)],
            ),
            
            SizedBox(height: 12.h),
            
            // زر التواصل
            _BuildOutlinedButton(
              onPressed: () => Navigator.pop(context, ReviewDialogResult.feedback),
              text: '💬 إرسال ملاحظات',
              context: context,
            ),
            
            SizedBox(height: 8.h),
            
            // زر لاحقاً
            TextButton(
              onPressed: () => Navigator.pop(context, ReviewDialogResult.later),
              child: Text(
                'ربما لاحقاً',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: context.textSecondaryColor.withOpacity(0.5),
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر متدرج اللون
class _BuildGradientButton extends StatelessWidget {
  const _BuildGradientButton({
    required this.onPressed,
    required this.text,
    required this.colors,
  });

  final VoidCallback onPressed;
  final String text;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// زر محدد بإطار
class _BuildOutlinedButton extends StatelessWidget {
  const _BuildOutlinedButton({
    required this.onPressed,
    required this.text,
    required this.context,
  });

  final VoidCallback onPressed;
  final String text;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50.h,
      decoration: BoxDecoration(
        border: Border.all(
          color: context.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// نتائج مربع حوار التقييم
enum ReviewDialogResult {
  /// المستخدم اختار التقييم
  rate,
  
  /// المستخدم اختار إرسال ملاحظات
  feedback,
  
  /// المستخدم اختار "لاحقاً"
  later,
}
