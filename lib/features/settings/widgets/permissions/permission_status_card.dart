// lib/features/settings/widgets/permissions/permission_status_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_theme.dart';
import '../../../../core/infrastructure/services/permissions/models/permission_state.dart';
import 'quick_stat_widget.dart';

/// بطاقة حالة الأذونات الرئيسية
class PermissionStatusCard extends StatelessWidget {
  final PermissionCheckResult? result;
  final VoidCallback onTap;

  const PermissionStatusCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const SizedBox();
    }
    
    final granted = result!.grantedCount;
    final denied = result!.missingCount;
    final total = granted + denied;
    final percentage = total > 0 ? granted / total : 0.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 6.h,
        ),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStatusColor(percentage),
              _getStatusColor(percentage).withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor(percentage).withValues(alpha: 0.3),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: 12.h),
            _buildStats(granted, denied, total),
            SizedBox(height: 10.h),
            _buildActionHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final granted = result!.grantedCount;
    final denied = result!.missingCount;
    final total = granted + denied;
    
    return Row(
      children: [
        // الأيقونة
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.security,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
        
        SizedBox(width: 10.w),
        
        // المعلومات
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حالة الأذونات',
                style: context.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              Text(
                '$granted من $total أذونات مفعلة',
                style: context.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
        
        // أيقونة السهم
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(int granted, int denied, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        QuickStatWidget(
          label: 'مفعلة',
          value: granted,
          color: Colors.white,
        ),
        Container(
          width: 1.w,
          height: 24.h,
          color: Colors.white.withValues(alpha: 0.3),
        ),
        QuickStatWidget(
          label: 'معطلة',
          value: denied,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        Container(
          width: 1.w,
          height: 24.h,
          color: Colors.white.withValues(alpha: 0.3),
        ),
        QuickStatWidget(
          label: 'الكل',
          value: total,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildActionHint() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app,
            color: Colors.white,
            size: 12.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            'اضغط لإدارة الأذونات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 1.0) return ThemeConstants.success;
    if (percentage >= 0.5) return ThemeConstants.warning;
    return ThemeConstants.error;
  }
}