// lib/features/settings/widgets/permissions/permission_item_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_theme.dart';
import '../../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../../core/infrastructure/services/permissions/permission_constants.dart';

/// بطاقة إذن واحد في القائمة
class PermissionItemCard extends StatelessWidget {
  final AppPermissionType permission;
  final AppPermissionStatus status;
  final VoidCallback onRequestPermission;

  const PermissionItemCard({
    super.key,
    required this.permission,
    required this.status,
    required this.onRequestPermission,
  });

  bool get isGranted => status == AppPermissionStatus.granted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isGranted 
              ? ThemeConstants.success.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (!isGranted) ...[
              SizedBox(height: 10.h),
              _buildActivateButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // أيقونة الإذن
        Container(
          width: 38.w,
          height: 38.h,
          decoration: BoxDecoration(
            color: isGranted
                ? ThemeConstants.success.withValues(alpha: 0.1)
                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            PermissionConstants.getIcon(permission),
            color: isGranted
                ? ThemeConstants.success
                : Theme.of(context).primaryColor,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 10.w),
        
        // معلومات الإذن
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                PermissionConstants.getName(permission),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                PermissionConstants.getDescription(permission),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        
        // حالة الإذن
        _buildStatusBadge(context),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isGranted
            ? ThemeConstants.success.withValues(alpha: 0.1)
            : ThemeConstants.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.warning,
            size: 12.sp,
            color: isGranted
                ? ThemeConstants.success
                : ThemeConstants.warning,
          ),
          SizedBox(width: 3.w),
          Text(
            isGranted ? 'مفعل' : 'معطل',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: isGranted
                  ? ThemeConstants.success
                  : ThemeConstants.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onRequestPermission,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: Text(
          'تفعيل الإذن',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}