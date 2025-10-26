// lib/core/infrastructure/services/permissions/widgets/permission_warning_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/theme_constants.dart';
import '../../../../../app/themes/core/theme_extensions.dart';

/// بطاقة تحذير موحدة لطلب الأذونات
class PermissionWarningCard extends StatelessWidget {
  final String permissionName;
  final IconData icon;
  final String description;
  final VoidCallback onGrantPermission;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool isCompact;

  const PermissionWarningCard({
    super.key,
    required this.permissionName,
    required this.icon,
    required this.description,
    required this.onGrantPermission,
    this.margin,
    this.padding,
    this.isCompact = false,
  });

  /// Factory للموقع
  factory PermissionWarningCard.location({
    required VoidCallback onGrantPermission,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool isCompact = false,
  }) {
    return PermissionWarningCard(
      permissionName: 'الموقع',
      icon: Icons.location_off,
      description: 'لحساب مواقيت الصلاة بدقة',
      onGrantPermission: onGrantPermission,
      margin: margin,
      padding: padding,
      isCompact: isCompact,
    );
  }

  /// Factory للإشعارات
  factory PermissionWarningCard.notification({
    required VoidCallback onGrantPermission,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool isCompact = false,
  }) {
    return PermissionWarningCard(
      permissionName: 'الإشعارات',
      icon: Icons.notifications_off,
      description: 'لإرسال تنبيهات الصلاة والأذكار',
      onGrantPermission: onGrantPermission,
      margin: margin,
      padding: padding,
      isCompact: isCompact,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildFullCard(BuildContext context) {
    return Container(
      width: 1.sw,
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      padding: padding ?? EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ThemeConstants.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ThemeConstants.warning.withOpacity(0.3),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // أيقونة التحذير
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: ThemeConstants.warning.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.warning.withOpacity(0.2),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 48.sp,
              color: ThemeConstants.warning,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // العنوان
          Text(
            'إذن $permissionName مطلوب',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 8.h),
          
          // الوصف
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.textSecondaryColor,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 20.h),
          
          // ✅ الزر - تم تحسينه
          SizedBox(
            width: double.infinity,
            height: 52.h, // ✅ زيادة الارتفاع
            child: ElevatedButton(
              onPressed: onGrantPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.warning,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon == Icons.notifications_off 
                        ? Icons.notifications_active 
                        : Icons.location_on,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Flexible( // ✅ استخدام Flexible
                    child: Text(
                      'منح إذن $permissionName',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Container(
      width: 1.sw,
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ),
      padding: padding ?? EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ThemeConstants.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ThemeConstants.warning.withOpacity(0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: ThemeConstants.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4.r,
                      offset: Offset(0, 1.h),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: ThemeConstants.warning,
                  size: 20.sp,
                ),
              ),
              
              SizedBox(width: 10.w),
              
              // النص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'إذن $permissionName مطلوب',
                      style: TextStyle(
                        color: ThemeConstants.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      description,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 11.sp,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // ✅ الزر - تم تحسينه
          SizedBox(
            width: double.infinity,
            height: 44.h, // ✅ زيادة الارتفاع
            child: ElevatedButton(
              onPressed: onGrantPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.warning,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon == Icons.notifications_off 
                        ? Icons.notifications_active 
                        : Icons.location_on,
                    size: 18.sp,
                  ),
                  SizedBox(width: 6.w),
                  Flexible( // ✅ استخدام Flexible
                    child: Text(
                      'منح إذن $permissionName',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}