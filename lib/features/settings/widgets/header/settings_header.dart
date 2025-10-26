// lib/features/settings/widgets/header/settings_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_theme.dart';

/// هيدر شاشة الإعدادات
class SettingsHeader extends StatelessWidget {
  final VoidCallback onReset;
  final String title;
  final String subtitle;

  const SettingsHeader({
    super.key,
    required this.onReset,
    this.title = 'الإعدادات',
    this.subtitle = 'تخصيص تجربتك مع التطبيق',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.08),
            width: 1.w,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.08 : 0.02),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الرجوع
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 8.w),
          
          // الأيقونة
          _buildIcon(context),
          
          SizedBox(width: 10.w),
          
          // العنوان والوصف
          Expanded(
            child: _buildTitleSection(context),
          ),
          
          // زر إعادة التعيين
          _buildResetButton(context),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Icon(
        Icons.settings_rounded,
        color: Colors.white,
        size: 22.sp,
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
          ),
        ),
        Text(
          subtitle,
          style: context.bodySmall?.copyWith(
            color: context.textSecondaryColor,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onReset,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: ThemeConstants.error.withValues(alpha: 0.08),
            border: Border.all(
              color: ThemeConstants.error.withValues(alpha: 0.2),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: ThemeConstants.error.withValues(alpha: 0.1),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
                spreadRadius: -1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: ThemeConstants.error,
                size: 18.sp,
              ),
              SizedBox(width: 5.w),
              Text(
                'إعادة تعيين',
                style: TextStyle(
                  color: ThemeConstants.error,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}