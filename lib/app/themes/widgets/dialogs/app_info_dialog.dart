// ========== app_info_dialog.dart ==========
// lib/app/themes/widgets/dialogs/app_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme_constants.dart';
import '../../text_styles.dart';

/// حوار عام لعرض المعلومات
class AppInfoDialog extends StatelessWidget {
  final String title;
  final String? content;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final String closeButtonText;
  final List<DialogAction>? actions;
  final Widget? customContent;
  final bool barrierDismissible;

  const AppInfoDialog({
    super.key,
    required this.title,
    this.content,
    this.subtitle,
    this.icon = Icons.info_outline,
    this.accentColor,
    this.closeButtonText = 'إغلاق',
    this.actions,
    this.customContent,
    this.barrierDismissible = true,
  });

  /// عرض الحوار
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? subtitle,
    IconData icon = Icons.info_outline,
    Color? accentColor,
    String closeButtonText = 'إغلاق',
    List<DialogAction>? actions,
    Widget? customContent,
    bool barrierDismissible = true,
    bool hapticFeedback = true,
  }) {
    if (hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppInfoDialog(
        title: title,
        content: content,
        subtitle: subtitle,
        icon: icon,
        accentColor: accentColor,
        closeButtonText: closeButtonText,
        actions: actions,
        customContent: customContent,
        barrierDismissible: barrierDismissible,
      ),
    );
  }

  /// عرض حوار تأكيد
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    IconData icon = Icons.help_outline,
    Color? accentColor,
    bool destructive = false,
    Color? confirmButtonColor,
  }) {
    return show<bool>(
      context: context,
      title: title,
      content: content,
      icon: icon,
      accentColor: destructive ? ThemeConstants.error : accentColor,
      closeButtonText: cancelText,
      actions: [
        DialogAction(
          label: confirmText,
          onPressed: () => Navigator.of(context).pop(true),
          isPrimary: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.primaryColor;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h5.copyWith(fontSize: 18.sp),
            ),
          ),
        ],
      ),
      content: customContent ?? _buildDefaultContent(context, color),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      actionsPadding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: 12.h,
      ),
      actions: _buildActions(context, color),
    );
  }

  Widget? _buildDefaultContent(BuildContext context, Color color) {
    if (content == null && subtitle == null) return null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content != null)
          Text(
            content!,
            style: AppTextStyles.body1.copyWith(
              height: 1.6,
              fontSize: 14.sp,
            ),
          ),
        if (subtitle != null) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: ThemeConstants.opacity10),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: color.withValues(alpha: ThemeConstants.opacity20),
                width: 1.w,
              ),
            ),
            child: Text(
              subtitle!,
              style: AppTextStyles.body2.copyWith(
                color: color,
                fontWeight: ThemeConstants.medium,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, Color color) {
    final defaultActions = <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          closeButtonText,
          style: TextStyle(color: color, fontSize: 14.sp),
        ),
      ),
    ];
    
    if (actions == null || actions!.isEmpty) {
      return defaultActions;
    }
    
    final customActions = actions!.map((action) {
      if (action.isPrimary) {
        return ElevatedButton(
          onPressed: action.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(action.label, style: TextStyle(fontSize: 14.sp)),
        );
      }
      
      return TextButton(
        onPressed: action.onPressed,
        child: Text(
          action.label,
          style: TextStyle(
            color: action.isDestructive ? ThemeConstants.error : color,
            fontSize: 14.sp,
          ),
        ),
      );
    }).toList();
    
    return [...customActions, ...defaultActions];
  }
}

/// إجراء في الحوار
class DialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  
  const DialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });
}
