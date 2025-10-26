// lib/core/infrastructure/services/text/screens/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../app/themes/app_theme.dart';

/// Slider محسّن
class EnhancedSlider extends StatelessWidget {
  final String title;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final Color color;
  final ValueChanged<double> onChanged;

  const EnhancedSlider({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20.sp, color: color),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: ThemeConstants.medium,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: ThemeConstants.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.15),
            trackHeight: 8.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 24.r),
            trackShape: RoundedRectSliderTrackShape(),
            tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 0),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Switch محسّن
class EnhancedSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;

  const EnhancedSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              gradient: value
                  ? LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.05),
                        accentColor.withOpacity(0.08),
                      ],
                    )
                  : null,
              color: value ? null : context.backgroundColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: value
                    ? accentColor.withValues(alpha: 0.15)
                    : context.dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: value
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
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: value
                        ? accentColor.withOpacity(0.1)
                        : context.dividerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.2),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 22.sp,
                    color: value ? accentColor : context.textSecondaryColor,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: ThemeConstants.medium,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: accentColor,
                    activeTrackColor: accentColor.withOpacity(0.3),
                    inactiveThumbColor: context.textSecondaryColor,
                    inactiveTrackColor: context.dividerColor.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}