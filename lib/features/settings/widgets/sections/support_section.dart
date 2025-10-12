// lib/features/settings/widgets/sections/support_section.dart

import 'package:athkar_app/features/settings/widgets/sections/settings_section.dart';
import 'package:athkar_app/features/settings/widgets/sections/settings_tile.dart';
import 'package:flutter/material.dart';


/// قسم الدعم والمعلومات
class SupportSection extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onRate;
  final VoidCallback onContact;
  final VoidCallback onAbout;

  const SupportSection({
    super.key,
    required this.onShare,
    required this.onRate,
    required this.onContact,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'الدعم والمعلومات',
      subtitle: 'معلومات التطبيق والدعم',
      icon: Icons.info_outline,
      children: [
        SettingsTile(
          icon: Icons.share_outlined,
          title: 'مشاركة التطبيق',
          subtitle: 'شارك التطبيق مع الأصدقاء والعائلة',
          onTap: onShare,
        ),
        SettingsTile(
          icon: Icons.star_outline,
          title: 'تقييم التطبيق',
          subtitle: 'قيم التطبيق على المتجر وادعمنا',
          onTap: onRate,
        ),
        SettingsTile(
          icon: Icons.headset_mic_outlined,
          title: 'تواصل معنا',
          subtitle: 'أرسل استفساراتك ومقترحاتك',
          onTap: onContact,
        ),
        SettingsTile(
          icon: Icons.info_outline,
          title: 'عن التطبيق',
          subtitle: 'معلومات الإصدار والمطور',
          onTap: onAbout,
        ),
      ],
    );
  }
}