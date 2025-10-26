// lib/core/infrastructure/services/text/widgets/presets_section.dart
import 'package:athkar_app/core/infrastructure/services/text_settings/models/text_settings_models.dart';
import 'package:athkar_app/core/infrastructure/services/text_settings/constants/text_settings_constants.dart'; // ✅ المسار الصحيح
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../app/themes/app_theme.dart';

/// قسم القوالب الجاهزة
class PresetsSection extends StatelessWidget {
  final ContentType contentType;
  final String? currentPresetName;
  final ValueChanged<TextStylePreset> onPresetSelected;
  final Color accentColor;

  const PresetsSection({
    super.key,
    required this.contentType,
    this.currentPresetName,
    required this.onPresetSelected,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(20.w),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.w),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor,
                      accentColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قوالب جاهزة',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      currentPresetName != null
                          ? 'القالب الحالي: $currentPresetName'
                          : 'اختر قالباً وطبقه بضغطة واحدة',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: currentPresetName != null
                            ? accentColor
                            : context.textSecondaryColor,
                        fontWeight: currentPresetName != null
                            ? ThemeConstants.semiBold
                            : ThemeConstants.regular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: accentColor,
            size: 28.sp,
          ),
          children: [
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: TextStylePresets.all.map((preset) {
                return PresetCard(
                  preset: preset,
                  isSelected: currentPresetName == preset.name,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onPresetSelected(preset);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة القالب
class PresetCard extends StatelessWidget {
  final TextStylePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const PresetCard({
    super.key,
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected 
                ? context.textPrimaryColor
                : context.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected 
                  ? Colors.transparent
                  : context.dividerColor.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: context.isDarkMode ? 0.15 : 0.06,
                      ),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: context.isDarkMode ? 0.08 : 0.03,
                      ),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            preset.name,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected 
                  ? ThemeConstants.semiBold 
                  : ThemeConstants.medium,
              color: isSelected 
                  ? context.backgroundColor
                  : context.textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }
}