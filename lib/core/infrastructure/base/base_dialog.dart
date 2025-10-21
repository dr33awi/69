// lib/core/infrastructure/base/base_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/theme_constants.dart';

/// Base Dialog موحد لجميع الـ Dialogs في التطبيق
///
/// يوفر:
/// - تصميم موحد
/// - دعم RTL
/// - أزرار قابلة للتخصيص
/// - أيقونة اختيارية
class BaseDialog extends StatelessWidget {
  /// العنوان
  final String title;

  /// المحتوى (نص أو widget)
  final dynamic content;

  /// الأيقونة (اختياري)
  final IconData? icon;

  /// لون الأيقونة
  final Color? iconColor;

  /// زر التأكيد الأساسي
  final String? primaryButtonText;

  /// دالة زر التأكيد
  final VoidCallback? onPrimaryPressed;

  /// لون زر التأكيد
  final Color? primaryButtonColor;

  /// زر الإلغاء
  final String? secondaryButtonText;

  /// دالة زر الإلغاء
  final VoidCallback? onSecondaryPressed;

  /// زر ثالث (اختياري)
  final String? tertiaryButtonText;

  /// دالة زر الثالث
  final VoidCallback? onTertiaryPressed;

  /// هل يمكن إغلاق Dialog بالضغط خارجه
  final bool barrierDismissible;

  /// widget إضافي أسفل المحتوى
  final Widget? additionalWidget;

  /// محاذاة المحتوى
  final TextAlign contentAlignment;

  const BaseDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor,
    this.primaryButtonText,
    this.onPrimaryPressed,
    this.primaryButtonColor,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.tertiaryButtonText,
    this.onTertiaryPressed,
    this.barrierDismissible = true,
    this.additionalWidget,
    this.contentAlignment = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400.w,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(ThemeConstants.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الأيقونة والعنوان
            _buildHeader(context, isDark, theme),

            SizedBox(height: ThemeConstants.space4),

            // المحتوى
            Flexible(
              child: SingleChildScrollView(
                child: _buildContent(context, theme),
              ),
            ),

            // Widget إضافي
            if (additionalWidget != null) ...[
              SizedBox(height: ThemeConstants.space4),
              additionalWidget!,
            ],

            // الأزرار
            if (_hasButtons) ...[
              SizedBox(height: ThemeConstants.space6),
              _buildButtons(context, theme),
            ],
          ],
        ),
      ),
    );
  }

  /// بناء الرأس (الأيقونة + العنوان)
  Widget _buildHeader(BuildContext context, bool isDark, ThemeData theme) {
    return Column(
      children: [
        // الأيقونة
        if (icon != null) ...[
          Container(
            padding: EdgeInsets.all(ThemeConstants.space4),
            decoration: BoxDecoration(
              color: (iconColor ?? theme.primaryColor).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40.sp,
              color: iconColor ?? theme.primaryColor,
            ),
          ),
          SizedBox(height: ThemeConstants.space3),
        ],

        // العنوان
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: ThemeConstants.semiBold,
            fontSize: ThemeConstants.textSize2xl,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// بناء المحتوى
  Widget _buildContent(BuildContext context, ThemeData theme) {
    if (content is Widget) {
      return content as Widget;
    } else if (content is String) {
      return Text(
        content as String,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: ThemeConstants.textSizeLg,
          height: 1.6,
        ),
        textAlign: contentAlignment,
      );
    } else {
      return Text(
        content.toString(),
        style: theme.textTheme.bodyLarge,
        textAlign: contentAlignment,
      );
    }
  }

  /// بناء الأزرار
  Widget _buildButtons(BuildContext context, ThemeData theme) {
    final buttons = <Widget>[];

    // زر ثانوي (إلغاء)
    if (secondaryButtonText != null) {
      buttons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
              ),
            ),
            child: Text(
              secondaryButtonText!,
              style: TextStyle(fontSize: ThemeConstants.textSizeLg),
            ),
          ),
        ),
      );
    }

    // مسافة بين الأزرار
    if (buttons.isNotEmpty && primaryButtonText != null) {
      buttons.add(SizedBox(width: ThemeConstants.space3));
    }

    // زر أساسي (تأكيد)
    if (primaryButtonText != null) {
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryButtonColor ?? theme.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
              ),
            ),
            child: Text(
              primaryButtonText!,
              style: TextStyle(
                fontSize: ThemeConstants.textSizeLg,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    // زر ثالث
    if (tertiaryButtonText != null) {
      buttons.add(SizedBox(width: ThemeConstants.space3));
      buttons.add(
        Expanded(
          child: TextButton(
            onPressed: onTertiaryPressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
            child: Text(
              tertiaryButtonText!,
              style: TextStyle(fontSize: ThemeConstants.textSizeMd),
            ),
          ),
        ),
      );
    }

    return Row(children: buttons);
  }

  /// هل يوجد أزرار
  bool get _hasButtons =>
      primaryButtonText != null ||
      secondaryButtonText != null ||
      tertiaryButtonText != null;
}

/// دالة مساعدة لعرض BaseDialog
Future<T?> showBaseDialog<T>({
  required BuildContext context,
  required String title,
  required dynamic content,
  IconData? icon,
  Color? iconColor,
  String? primaryButtonText,
  VoidCallback? onPrimaryPressed,
  Color? primaryButtonColor,
  String? secondaryButtonText,
  VoidCallback? onSecondaryPressed,
  String? tertiaryButtonText,
  VoidCallback? onTertiaryPressed,
  bool barrierDismissible = true,
  Widget? additionalWidget,
  TextAlign contentAlignment = TextAlign.center,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => BaseDialog(
      title: title,
      content: content,
      icon: icon,
      iconColor: iconColor,
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      primaryButtonColor: primaryButtonColor,
      secondaryButtonText: secondaryButtonText,
      onSecondaryPressed: onSecondaryPressed,
      tertiaryButtonText: tertiaryButtonText,
      onTertiaryPressed: onTertiaryPressed,
      barrierDismissible: barrierDismissible,
      additionalWidget: additionalWidget,
      contentAlignment: contentAlignment,
    ),
  );
}

/// Dialogs جاهزة للاستخدام السريع

/// Dialog تأكيد
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'تأكيد',
  String cancelText = 'إلغاء',
  IconData? icon,
  Color? iconColor,
}) async {
  final result = await showBaseDialog<bool>(
    context: context,
    title: title,
    content: message,
    icon: icon ?? Icons.help_outline,
    iconColor: iconColor,
    primaryButtonText: confirmText,
    secondaryButtonText: cancelText,
  );
  return result ?? false;
}

/// Dialog معلومات
Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'حسناً',
  IconData? icon,
}) {
  return showBaseDialog(
    context: context,
    title: title,
    content: message,
    icon: icon ?? Icons.info_outline,
    iconColor: Colors.blue,
    primaryButtonText: buttonText,
  );
}

/// Dialog خطأ
Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'حسناً',
}) {
  return showBaseDialog(
    context: context,
    title: title,
    content: message,
    icon: Icons.error_outline,
    iconColor: Colors.red,
    primaryButtonText: buttonText,
  );
}

/// Dialog نجاح
Future<void> showSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'حسناً',
}) {
  return showBaseDialog(
    context: context,
    title: title,
    content: message,
    icon: Icons.check_circle_outline,
    iconColor: Colors.green,
    primaryButtonText: buttonText,
  );
}

/// Dialog تحذير
Future<bool> showWarningDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'متابعة',
  String cancelText = 'إلغاء',
}) async {
  final result = await showBaseDialog<bool>(
    context: context,
    title: title,
    content: message,
    icon: Icons.warning_amber_outlined,
    iconColor: Colors.orange,
    primaryButtonText: confirmText,
    secondaryButtonText: cancelText,
  );
  return result ?? false;
}
