// lib/features/onboarding/widgets/onboarding_permission_card.dart
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
      margin: EdgeInsets.symmetric(vertical: 5.h),
      child: Material(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    info.icon,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                
                SizedBox(width: 10.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        info.description,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.6),
                  size: 12.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}