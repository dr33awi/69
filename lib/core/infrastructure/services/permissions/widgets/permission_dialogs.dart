// lib/core/infrastructure/services/permissions/widgets/permission_dialogs.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../permission_service.dart';
import '../permission_constants.dart';

/// Dialog بسيط وموحد لشرح الأذونات
class PermissionDialogs {
  
  /// عرض dialog شرح الأذونات المتعددة
  static Future<bool> showExplanation({
    required BuildContext context,
    required List<AppPermissionType> permissions,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        contentPadding: EdgeInsets.zero,
        title: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.security,
                  color: Theme.of(context).primaryColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'أذونات مطلوبة',
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نحتاج الأذونات التالية لتشغيل هذه الميزة:',
                  style: TextStyle(fontSize: 14.sp, height: 1.4),
                ),
                SizedBox(height: 16.h),
                ...permissions.map((permission) {
                  final info = PermissionConstants.getInfo(permission);
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: info.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            info.icon,
                            size: 20.sp,
                            color: info.color,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                info.description,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('إلغاء', style: TextStyle(fontSize: 15.sp)),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text('متابعة', style: TextStyle(fontSize: 15.sp)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// عرض dialog لإذن واحد
  static Future<bool> showSinglePermission({
    required BuildContext context,
    required AppPermissionType permission,
    String? customMessage,
  }) async {
    final info = PermissionConstants.getInfo(permission);
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        contentPadding: EdgeInsets.zero,
        title: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(info.icon, color: info.color, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'إذن ${info.name}',
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Text(
            customMessage ?? info.description,
            style: TextStyle(fontSize: 14.sp, height: 1.4),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('إلغاء', style: TextStyle(fontSize: 15.sp)),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text('السماح', style: TextStyle(fontSize: 15.sp)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// عرض dialog الإعدادات
  static Future<void> showSettingsDialog({
    required BuildContext context,
    required List<AppPermissionType> permissions,
    required VoidCallback onOpenSettings,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        contentPadding: EdgeInsets.zero,
        title: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.orange,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'فتح الإعدادات',
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
            ],
          ),
        ),
        content: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الأذونات التالية تحتاج تفعيلها من الإعدادات:',
                style: TextStyle(fontSize: 14.sp, height: 1.4),
              ),
              SizedBox(height: 12.h),
              ...permissions.map((permission) {
                final info = PermissionConstants.getInfo(permission);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.block,
                        size: 16.sp,
                        color: Colors.red[400],
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        info.name,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18.sp,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'ستنتقل إلى إعدادات التطبيق في النظام',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('لاحقاً', style: TextStyle(fontSize: 15.sp)),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onOpenSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text('فتح الإعدادات', style: TextStyle(fontSize: 15.sp)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// عرض dialog نتيجة طلب الأذونات
  static Future<void> showResultDialog({
    required BuildContext context,
    required List<AppPermissionType> granted,
    required List<AppPermissionType> denied,
  }) async {
    final allGranted = denied.isEmpty;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        contentPadding: EdgeInsets.zero,
        title: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: (allGranted ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  allGranted ? Icons.check_circle : Icons.warning,
                  color: allGranted ? Colors.green : Colors.orange,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  allGranted ? 'تم بنجاح!' : 'بعض الأذونات غير مفعلة',
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (granted.isNotEmpty) ...[
                  Text(
                    'الأذونات المفعلة:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...granted.map((permission) {
                    final info = PermissionConstants.getInfo(permission);
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18.sp,
                            color: Colors.green[600],
                          ),
                          SizedBox(width: 8.w),
                          Text(info.name, style: TextStyle(fontSize: 13.sp)),
                        ],
                      ),
                    );
                  }),
                ],
                if (denied.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Text(
                    'الأذونات غير المفعلة:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...denied.map((permission) {
                    final info = PermissionConstants.getInfo(permission);
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel,
                            size: 18.sp,
                            color: Colors.red[600],
                          ),
                          SizedBox(width: 8.w),
                          Text(info.name, style: TextStyle(fontSize: 13.sp)),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16.sp, color: Colors.grey[600]),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'يمكنك تفعيلها لاحقاً من الإعدادات',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              children: [
                if (!allGranted)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text('لاحقاً', style: TextStyle(fontSize: 15.sp)),
                    ),
                  ),
                if (!allGranted) SizedBox(width: 8.w),
                Expanded(
                  flex: allGranted ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      allGranted ? 'ممتاز!' : 'موافق',
                      style: TextStyle(fontSize: 15.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}