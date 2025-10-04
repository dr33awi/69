// lib/features/athkar/utils/athkar_extensions.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';

/// امتدادات خاصة بميزة الأذكار فقط
/// تستخدم بجانب الـ extensions العامة من app_theme.dart
extension AthkarSpecificHelpers on BuildContext {
  
  /// عرض رسالة معلومات خاصة بالأذكار
  void showAthkarInfoSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ThemeConstants.info,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
  
  /// عرض رسالة تقدم الأذكار
  void showAthkarProgressSnackBar({
    required String message,
    required int progress,
    Color? progressColor,
  }) {
    final color = progressColor ?? ThemeConstants.primary;
    
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                value: progress / 100,
                strokeWidth: 3.w,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: ThemeConstants.medium,
                      fontSize: 14.sp,
                    ),
                  ),
                  Text(
                    'التقدم: $progress%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// عرض رسالة إكمال الأذكار مع أنيميشن
  void showAthkarCompletionSnackBar({
    required String categoryName,
    VoidCallback? onShare,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أحسنت! أكملت $categoryName',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: ThemeConstants.semiBold,
                      fontSize: 14.sp,
                    ),
                  ),
                  Text(
                    'جعله الله في ميزان حسناتك',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (onShare != null)
              TextButton(
                onPressed: onShare,
                child: Text(
                  'مشاركة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: ThemeConstants.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: ThemeConstants.success,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.r),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// امتدادات خاصة بنصوص الأذكار
extension AthkarTextExtensions on String {
  /// تقصير النص مع إضافة نقاط في النهاية
  String truncateAthkar(int maxLength) {
    if (length <= maxLength) return this;
    
    final lastSpace = lastIndexOf(' ', maxLength);
    final cutIndex = lastSpace > 0 ? lastSpace : maxLength;
    
    return '${substring(0, cutIndex)}...';
  }
  
  /// إزالة التشكيل من النص (للبحث)
  String removeArabicDiacritics() {
    return replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }
  
  /// التحقق من أن النص عربي
  bool get isArabicText {
    return contains(RegExp(r'[\u0600-\u06FF]'));
  }
}