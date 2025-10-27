// lib/features/settings/widgets/sections/appearance_section.dart

import 'package:athkar_app/core/infrastructure/services/text_settings/extensions/text_settings_extensions.dart';
import 'package:athkar_app/features/settings/widgets/sections/settings_section.dart';
import 'package:athkar_app/features/settings/widgets/sections/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_theme.dart';
import '../../services/settings_services_manager.dart';


/// قسم إعدادات المظهر
class AppearanceSection extends StatefulWidget {
  final SettingsServicesManager manager;

  const AppearanceSection({
    super.key,
    required this.manager,
  });

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'المظهر والعرض',
      subtitle: 'تخصيص شكل التطبيق',
      icon: Icons.palette,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 10.h,
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: context.primaryColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.manager.isDarkMode 
                      ? Icons.dark_mode 
                      : Icons.light_mode,
                  color: context.primaryColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وضع العرض',
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      widget.manager.currentThemeName,
                      style: context.bodySmall?.copyWith(
                        color: context.textSecondaryColor,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: widget.manager.isDarkMode,
                onChanged: (value) async {
                  await widget.manager.changeTheme(
                    value ? ThemeMode.dark : ThemeMode.light
                  );
                  setState(() {});
                },
                activeColor: context.primaryColor,
              ),
            ],
          ),
        ),
        
        // إعدادات النصوص والخطوط
        SettingsTile(
          icon: Icons.text_fields_rounded,
          title: 'إعدادات النصوص',
          subtitle: 'تخصيص حجم الخط وتباعد الأسطر',
          iconColor: ThemeConstants.info,
          trailing: Icon(
            Icons.arrow_back_ios_rounded,
            color: context.textSecondaryColor,
            size: 14.sp,
          ),
          onTap: () {
            HapticFeedback.lightImpact();
            context.showGlobalTextSettings();
          },
        ),
      ],
    );
  }
}