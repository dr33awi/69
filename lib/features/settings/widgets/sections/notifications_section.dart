// lib/features/settings/widgets/sections/notifications_section.dart

import 'package:athkar_app/features/settings/widgets/sections/settings_section.dart';
import 'package:athkar_app/features/settings/widgets/sections/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/routes/app_router.dart';
import '../../services/settings_services_manager.dart';


/// قسم إعدادات الإشعارات
class NotificationsSection extends StatefulWidget {
  final SettingsServicesManager manager;

  const NotificationsSection({
    super.key,
    required this.manager,
  });

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  @override
  Widget build(BuildContext context) {
    final settings = widget.manager.settings;
    
    return SettingsSection(
      title: 'الإشعارات',
      subtitle: 'إدارة التنبيهات والتذكيرات',
      icon: Icons.notifications_active,
      children: [
        SettingsTile(
          icon: Icons.access_time,
          title: 'إشعارات الصلاة',
          subtitle: 'تنبيهات أوقات الصلاة والأذان',
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.prayerNotificationsSettings,
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 14.sp),
        ),
        SettingsTile(
          icon: Icons.menu_book,
          title: 'إشعارات الأذكار',
          subtitle: 'تذكيرات الأذكار اليومية',
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.athkarNotificationsSettings,
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 14.sp),
        ),
        SettingsTile(
          icon: Icons.vibration,
          title: 'الاهتزاز',
          subtitle: 'اهتزاز عند وصول الإشعارات',
          trailing: SettingsSwitch(
            value: settings.vibrationEnabled,
            onChanged: (value) async {
              await widget.manager.toggleVibration(value);
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}