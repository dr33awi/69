// lib/features/onboarding/widgets/permission_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../core/infrastructure/services/permissions/permission_constants.dart';
import '../../../app/themes/app_theme.dart';

/// بطاقة عرض الإذن
class PermissionCard extends StatelessWidget {
  final AppPermissionType permission;
  final AppPermissionStatus status;
  final VoidCallback onRequest;
  final bool isProcessing;

  const PermissionCard({
    super.key,
    required this.permission,
    required this.status,
    required this.onRequest,
    this.isProcessing = false,
  });

  bool get isGranted => status == AppPermissionStatus.granted;
  bool get isPermanentlyDenied => status == AppPermissionStatus.permanentlyDenied;

  @override
  Widget build(BuildContext context) {
    final info = PermissionConstants.getInfo(permission);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isGranted ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isGranted
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1.5.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isGranted || isProcessing ? null : onRequest,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: isGranted
                        ? Colors.white.withOpacity(0.2)
                        : info.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    isGranted ? Icons.check_circle : info.icon,
                    color: isGranted ? ThemeConstants.success : Colors.white,
                    size: 28.sp,
                  ),
                ),

                SizedBox(width: 16.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        info.description,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.3,
                        ),
                      ),
                      if (isPermanentlyDenied) ...[
                        SizedBox(height: 8.h),
                        Text(
                          'يرجى التفعيل من الإعدادات',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.orange[300],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // Status/Action
                _buildStatusWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    if (isGranted) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check,
              color: ThemeConstants.success,
              size: 16.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              'مفعل',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (isProcessing) {
      return SizedBox(
        width: 24.w,
        height: 24.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.5.w,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        'تفعيل',
        style: TextStyle(
          fontSize: 13.sp,
          color: ThemeConstants.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}