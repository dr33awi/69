// lib/features/onboarding/widgets/onboarding_permission_card.dart
// بطاقة خاصة لشرح الأذونات في الـ onboarding

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../core/infrastructure/services/permissions/permission_constants.dart';

class OnboardingPermissionCard extends StatelessWidget {
  final AppPermissionType permission;
  final VoidCallback? onTap;

  const OnboardingPermissionCard({
    super.key,
    required this.permission,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = PermissionConstants.getInfo(permission);
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                // الأيقونة
                Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    info.icon,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                // النص
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.name,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        info.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // سهم
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}