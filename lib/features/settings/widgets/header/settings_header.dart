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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.1),
            width: 1.w,
          ),
        ),
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
          
          SizedBox(width: 8.w),
          
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
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(
        Icons.settings,
        color: Colors.white,
        size: 20.sp,
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
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: ThemeConstants.error.withValues(alpha: 0.3),
              width: 1.w,
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: ThemeConstants.error,
                size: 16.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                'إعادة تعيين',
                style: TextStyle(
                  color: ThemeConstants.error,
                  fontSize: 10.sp,
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