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
}