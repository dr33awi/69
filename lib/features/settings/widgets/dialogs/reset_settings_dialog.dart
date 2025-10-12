// lib/features/settings/widgets/dialogs/reset_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_theme.dart';

/// حوار تأكيد إعادة تعيين الإعدادات
class ResetSettingsDialog extends StatelessWidget {
  const ResetSettingsDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ResetSettingsDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: ThemeConstants.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.warning,
              color: ThemeConstants.error,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'إعادة تعيين الإعدادات',
              style: TextStyle(fontSize: 15.sp),
            ),
          ),
        ],
      ),
      content: Text(
        'هل أنت متأكد من إعادة جميع الإعدادات إلى الوضع الافتراضي؟\n\nسيتم مسح جميع التخصيصات والإعدادات المحفوظة.',
        style: TextStyle(height: 1.5, fontSize: 13.sp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('إلغاء', style: TextStyle(fontSize: 13.sp)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeConstants.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          child: Text('إعادة تعيين', style: TextStyle(fontSize: 13.sp)),
        ),
      ],
    );
  }
}