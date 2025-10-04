// lib/core/infrastructure/firebase/widgets/smart_notification_widget.dart
// محسّن للشاشات الصغيرة

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:athkar_app/core/infrastructure/firebase/firebase_messaging_service.dart';
import 'package:athkar_app/core/infrastructure/firebase/remote_config_manager.dart';

/// Widget ذكي للإشعارات يتكيف مع إعدادات Remote Config
class SmartNotificationWidget extends StatefulWidget {
  final Widget child;
  
  const SmartNotificationWidget({
    super.key,
    required this.child,
  });

  @override
  State<SmartNotificationWidget> createState() => _SmartNotificationWidgetState();
}

class _SmartNotificationWidgetState extends State<SmartNotificationWidget> {
  FirebaseMessagingService? _messagingService;
  RemoteConfigManager? _configManager;
  StreamSubscription? _configSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  void _initializeServices() {
    try {
      // يمكن استخدام GetIt هنا إذا كان متوفراً
      // _messagingService = getIt<FirebaseMessagingService>();
      // _configManager = getIt<RemoteConfigManager>();
      
      if (_configManager != null) {
        _setupConfigListener();
      }
    } catch (e) {
      debugPrint('Smart notification widget: Services not available');
    }
  }
  
  void _setupConfigListener() {
    _configManager?.notificationsEnabled.addListener(_onNotificationSettingsChanged);
  }
  
  void _onNotificationSettingsChanged() {
    if (!mounted) return;
    
    final enabled = _configManager?.isNotificationsFeatureEnabled ?? true;
    
    if (enabled) {
      _enableNotifications();
    } else {
      _disableNotifications();
    }
  }
  
  Future<void> _enableNotifications() async {
    if (_messagingService == null) return;
    
    try {
      await _messagingService!.subscribeToGeneralNotifications();
      
      _showNotificationSnackBar(
        'تم تفعيل الإشعارات',
        Colors.green,
        Icons.notifications_active,
      );
    } catch (e) {
      debugPrint('Error enabling notifications: $e');
    }
  }
  
  Future<void> _disableNotifications() async {
    if (_messagingService == null) return;
    
    try {
      await _messagingService!.unsubscribeFromGeneralNotifications();
      
      _showNotificationSnackBar(
        'تم تعطيل الإشعارات',
        Colors.orange,
        Icons.notifications_off,
      );
    } catch (e) {
      debugPrint('Error disabling notifications: $e');
    }
  }
  
  void _showNotificationSnackBar(String message, Color color, IconData icon) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  @override
  void dispose() {
    _configSubscription?.cancel();
    _configManager?.notificationsEnabled.removeListener(_onNotificationSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Widget لعرض حالة الإشعارات في الإعدادات
class NotificationStatusWidget extends StatefulWidget {
  const NotificationStatusWidget({super.key});

  @override
  State<NotificationStatusWidget> createState() => _NotificationStatusWidgetState();
}

class _NotificationStatusWidgetState extends State<NotificationStatusWidget> {
  FirebaseMessagingService? _messagingService;
  RemoteConfigManager? _configManager;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  void _initializeServices() {
    try {
      // الحصول على الخدمات
      // _messagingService = getIt<FirebaseMessagingService>();
      // _configManager = getIt<RemoteConfigManager>();
    } catch (e) {
      debugPrint('Notification status widget: Services not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isServiceAvailable = _messagingService?.isInitialized ?? false;
    final isFeatureEnabled = _configManager?.isNotificationsFeatureEnabled ?? true;
    final hasPermission = _messagingService?.isPermissionGranted ?? false;
    
    return Card(
      margin: EdgeInsets.all(16.w),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Theme.of(context).primaryColor,
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'حالة الإشعارات',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // حالة الخدمة
            _buildStatusRow(
              'خدمة Firebase',
              isServiceAvailable,
              isServiceAvailable ? 'متصلة' : 'غير متاحة',
            ),
            
            SizedBox(height: 8.h),
            
            // حالة الميزة
            _buildStatusRow(
              'تفعيل الميزة',
              isFeatureEnabled,
              isFeatureEnabled ? 'مفعلة' : 'معطلة من الخادم',
            ),
            
            SizedBox(height: 8.h),
            
            // حالة الإذن
            _buildStatusRow(
              'أذونات الجهاز',
              hasPermission,
              hasPermission ? 'ممنوحة' : 'مطلوبة',
            ),
            
            // معلومات إضافية
            if (_messagingService?.fcmToken != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: const Divider(),
              ),
              
              Text(
                'معرف الجهاز:',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                  fontFamily: 'Cairo',
                ),
              ),
              
              SizedBox(height: 4.h),
              
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _messagingService!.fcmToken!.substring(0, 32) + '...',
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(String label, bool isActive, String status) {
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.h,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 11.sp,
            color: isActive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}