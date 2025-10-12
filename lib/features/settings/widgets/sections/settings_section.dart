// lib/features/settings/widgets/settings_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_theme.dart';

/// قسم في شاشة الإعدادات
class SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? iconColor;
  final bool showDividers;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.icon,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMargin = margin ?? EdgeInsets.symmetric(
      horizontal: 12.w,
      vertical: 8.h,
    );

    final effectiveBorderRadius = BorderRadius.circular(16.r);

    return Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.cardColor,
        borderRadius: effectiveBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final effectiveTitleColor = titleColor ?? context.primaryColor;
    final effectiveIconColor = iconColor ?? context.primaryColor;
    final effectivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: 12.w,
      vertical: 10.h,
    );

    return Container(
      padding: effectivePadding,
      child: Row(
        children: [
          // أيقونة القسم
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                size: 18.sp,
                color: effectiveIconColor,
              ),
            ),
            SizedBox(width: 10.w),
          ],
          
          // العنوان والعنوان الفرعي
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.titleMedium?.copyWith(
                    color: effectiveTitleColor,
                    fontWeight: ThemeConstants.bold,
                    height: 1.2,
                    fontSize: 14.sp,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: context.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                      height: 1.3,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        // خط فاصل بين الهيدر والمحتوى
        if (showDividers)
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: context.dividerColor.withValues(alpha: 0.3),
            indent: 0,
            endIndent: 0,
          ),
        
        // محتوى القسم مع الفواصل
        ...List.generate(
          children.length,
          (index) {
            final child = children[index];
            final isLast = index == children.length - 1;
            
            return Column(
              children: [
                child,
                // خط فاصل بين العناصر
                if (!isLast && showDividers)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Divider(
                      height: 1.h,
                      thickness: 1.h,
                      color: context.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}