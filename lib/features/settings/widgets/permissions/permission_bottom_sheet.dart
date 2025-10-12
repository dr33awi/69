// lib/features/settings/widgets/permissions/permission_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/infrastructure/services/permissions/permission_service.dart';
import 'permission_item_card.dart';
import 'system_settings_button.dart';

/// نافذة منبثقة لإدارة الأذونات
class PermissionBottomSheet extends StatelessWidget {
  final Map<AppPermissionType, AppPermissionStatus> permissionStatuses;
  final List<AppPermissionType> criticalPermissions;
  final Function(AppPermissionType) onRequestPermission;
  final VoidCallback onOpenSystemSettings;

  const PermissionBottomSheet({
    super.key,
    required this.permissionStatuses,
    required this.criticalPermissions,
    required this.onRequestPermission,
    required this.onOpenSystemSettings,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<AppPermissionType, AppPermissionStatus> permissionStatuses,
    required List<AppPermissionType> criticalPermissions,
    required Function(AppPermissionType) onRequestPermission,
    required VoidCallback onOpenSystemSettings,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PermissionBottomSheet(
        permissionStatuses: permissionStatuses,
        criticalPermissions: criticalPermissions,
        onRequestPermission: onRequestPermission,
        onOpenSystemSettings: onOpenSystemSettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            _buildDragHandle(context),
            _buildHeader(context),
            Divider(height: 1.h),
            Expanded(
              child: _buildContent(context, scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10.h),
      width: 36.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: Theme.of(context).primaryColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الأذونات',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'تحكم في أذونات التطبيق',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            iconSize: 20.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(12.w),
      children: [
        // قائمة الأذونات
        ...criticalPermissions
            .where((p) => permissionStatuses.containsKey(p))
            .map((permission) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: PermissionItemCard(
                permission: permission,
                status: permissionStatuses[permission]!,
                onRequestPermission: () {
                  onRequestPermission(permission);
                  Navigator.pop(context);
                },
              ),
            )),
        
        SizedBox(height: 16.h),
        
        // زر إعدادات النظام
        SystemSettingsButton(
          onTap: () {
            Navigator.pop(context);
            onOpenSystemSettings();
          },
        ),
      ],
    );
  }
}