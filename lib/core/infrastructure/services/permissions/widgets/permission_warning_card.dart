// lib/core/infrastructure/services/permissions/widgets/permission_warning_card.dart
// Widget موحد لعرض تحذير الأذونات - محسّن مع الثيم الموحد

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/theme_constants.dart';
import '../../../../../app/themes/core/theme_extensions.dart';
import '../../../../../app/themes/widgets/core/app_button.dart';

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
      description: 'لحساب مواقيت الصلاة بدقة لمدينتك، يجب منح التطبيق إذن الوصول إلى موقعك الحالي',
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
      description: 'لإرسال تنبيهات أوقات الصلاة والأذكار، يجب منح التطبيق إذن الإشعارات',
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
      margin: margin ?? EdgeInsets.all(ThemeConstants.space4),
      padding: padding ?? EdgeInsets.all(ThemeConstants.space5),
      decoration: BoxDecoration(
        color: ThemeConstants.warning.withOpacity(ThemeConstants.opacity10),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
        border: Border.all(
          color: ThemeConstants.warning.withOpacity(ThemeConstants.opacity30),
          width: 1.5.w,
        ),
        boxShadow: ThemeConstants.shadowSm,
      ),
      child: Column(
        children: [
          // أيقونة التحذير
          Container(
            padding: EdgeInsets.all(ThemeConstants.space4),
            decoration: BoxDecoration(
              color: ThemeConstants.warning.withOpacity(ThemeConstants.opacity20),
              shape: BoxShape.circle,
              boxShadow: ThemeConstants.shadowMd,
            ),
            child: Icon(
              icon,
              size: ThemeConstants.icon2xl,
              color: ThemeConstants.warning,
            ),
          ),
          
          SizedBox(height: ThemeConstants.space4),
          
          // العنوان
          Text(
            'إذن $permissionName مطلوب',
            style: TextStyle(
              fontSize: ThemeConstants.textSizeXl,
              fontWeight: ThemeConstants.bold,
              color: context.textPrimaryColor,
            ),
          ),
          
          SizedBox(height: ThemeConstants.space3),
          
          // الوصف
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ThemeConstants.textSizeSm,
              color: context.textSecondaryColor,
              height: 1.5,
            ),
          ),
          
          SizedBox(height: ThemeConstants.space5),
          
          // الزر - استخدام AppButton
          SizedBox(
            width: double.infinity,
            child: AppButton.custom(
              text: 'منح إذن $permissionName',
              onPressed: onGrantPermission,
              icon: icon,
              size: ButtonSize.large,
              isFullWidth: true,
              backgroundColor: ThemeConstants.warning,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: ThemeConstants.space3),
      padding: padding ?? EdgeInsets.all(ThemeConstants.space3 + ThemeConstants.space1),
      decoration: BoxDecoration(
        color: ThemeConstants.warning.withOpacity(ThemeConstants.opacity10),
        borderRadius: BorderRadius.circular(ThemeConstants.radius2xl),
        border: Border.all(
          color: ThemeConstants.warning.withOpacity(ThemeConstants.opacity30),
          width: ThemeConstants.borderLight,
        ),
        boxShadow: ThemeConstants.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // أيقونة
              Container(
                padding: EdgeInsets.all(ThemeConstants.space2),
                decoration: BoxDecoration(
                  color: ThemeConstants.warning.withOpacity(ThemeConstants.opacity20),
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                  boxShadow: ThemeConstants.shadowSm,
                ),
                child: Icon(
                  icon,
                  color: ThemeConstants.warning,
                  size: ThemeConstants.iconSm,
                ),
              ),
              
              SizedBox(width: ThemeConstants.space2 + ThemeConstants.space1),
              
              // النص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إذن $permissionName مطلوب',
                      style: TextStyle(
                        color: ThemeConstants.warning,
                        fontWeight: ThemeConstants.bold,
                        fontSize: ThemeConstants.textSizeMd,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      description.length > 50 
                          ? '${description.substring(0, 47)}...'
                          : description,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: ThemeConstants.textSizeXs,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: ThemeConstants.space2 + ThemeConstants.space1),
          
          // الزر المدمج - استخدام AppButton
          SizedBox(
            width: double.infinity,
            height: 36.h,
            child: AppButton.custom(
              text: 'منح إذن $permissionName',
              onPressed: onGrantPermission,
              icon: icon,
              size: ButtonSize.small,
              isFullWidth: true,
              backgroundColor: ThemeConstants.warning,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}