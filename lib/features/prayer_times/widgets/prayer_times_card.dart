// lib/features/prayer_times/widgets/prayer_times_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/prayer_time_model.dart';
import '../utils/prayer_utils.dart';

class PrayerTimeCard extends StatelessWidget {
  final PrayerTime prayer;
  final bool forceColored;

  const PrayerTimeCard({
    super.key,
    required this.prayer,
    this.forceColored = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNext = prayer.isNext;
    final isPassed = prayer.isPassed;
    final useGradient = forceColored || isNext;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          if (isNext) ...[
            BoxShadow(
              color: prayer.color.withValues(alpha: 0.25),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: prayer.color.withValues(alpha: 0.15),
              blurRadius: 6.r,
              offset: Offset(0, 2.h),
            ),
          ] else ...[
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.12 : 0.04),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
              spreadRadius: -2,
            ),
          ],
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showPrayerDetails(context),
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            decoration: BoxDecoration(
              gradient: useGradient ? prayer.gradient : null,
              color: !useGradient 
                ? (isPassed 
                    ? context.cardColor.darken(0.02) 
                    : context.cardColor) 
                : null,
              border: Border.all(
                color: useGradient 
                  ? Colors.white.withValues(alpha: 0.25)
                  : context.dividerColor.withValues(alpha: 0.12),
                width: isNext ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  _buildPrayerIcon(context, useGradient),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildPrayerInfo(context, useGradient),
                  ),
                  SizedBox(width: 8.w),
                  _buildTimeSection(context, useGradient),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerIcon(BuildContext context, bool useGradient) {
    final iconColor = useGradient ? Colors.white : prayer.color;
    final bgColor = useGradient 
      ? Colors.white.withValues(alpha: 0.25)
      : prayer.color.withValues(alpha: 0.12);
    
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: useGradient 
            ? Colors.white.withValues(alpha: 0.35)
            : prayer.color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: useGradient ? [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ] : [],
      ),
      child: Icon(
        prayer.icon,
        color: iconColor,
        size: 20.sp,
      ),
    );
  }

  Widget _buildPrayerInfo(BuildContext context, bool useGradient) {
    final textColor = _getTextColor(context, useGradient);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            prayer.nameAr,
            style: TextStyle(
              color: textColor,
              fontWeight: prayer.isNext 
                ? ThemeConstants.bold 
                : ThemeConstants.semiBold,
              fontSize: 13.sp,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        _buildPrayerStatus(context, useGradient),
      ],
    );
  }

  Widget _buildPrayerStatus(BuildContext context, bool useGradient) {
    if (prayer.isNext) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 5.w,
          vertical: 2.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 11.sp,
              color: Colors.white,
            ),
            SizedBox(width: 2.w),
            Text(
              prayer.statusText,
              style: TextStyle(
                color: Colors.white,
                fontWeight: ThemeConstants.semiBold,
                fontSize: 9.sp,
              ),
            ),
          ],
        ),
      );
    } else if (prayer.isPassed) {
      return Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 11.sp,
            color: useGradient ? Colors.white : ThemeConstants.success,
          ),
          SizedBox(width: 2.w),
          Text(
            'انتهى الوقت',
            style: TextStyle(
              color: useGradient 
                ? Colors.white.withOpacity(0.8)
                : context.textSecondaryColor,
              fontWeight: ThemeConstants.medium,
              fontSize: 9.sp,
            ),
          ),
        ],
      );
    } else {
      return Text(
        PrayerUtils.formatTimeUntil(prayer.time),
        style: TextStyle(
          color: _getTextColor(context, useGradient).withOpacity(0.8),
          fontSize: 9.sp,
        ),
      );
    }
  }

  Widget _buildTimeSection(BuildContext context, bool useGradient) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 7.w,
        vertical: 5.h,
      ),
      decoration: BoxDecoration(
        color: useGradient 
          ? Colors.white.withOpacity(0.2)
          : prayer.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: useGradient 
            ? Colors.white.withOpacity(0.3)
            : prayer.color.withOpacity(0.2),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          prayer.formattedTime,
          style: TextStyle(
            color: useGradient ? Colors.white : prayer.color,
            fontWeight: ThemeConstants.bold,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  Color _getTextColor(BuildContext context, bool useGradient) {
    if (useGradient) return Colors.white;
    if (prayer.isPassed) return context.textSecondaryColor;
    return context.textPrimaryColor;
  }

  void _showPrayerDetails(BuildContext context) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => PrayerDetailsDialog(prayer: prayer),
    );
  }
}

class PrayerDetailsDialog extends StatelessWidget {
  final PrayerTime prayer;

  const PrayerDetailsDialog({
    super.key,
    required this.prayer,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          gradient: prayer.gradient,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    prayer.icon,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.nameAr,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      Text(
                        prayer.nameEn,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 10.h),
            
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.access_time,
                    label: 'وقت الصلاة',
                    value: prayer.formattedTime,
                  ),
                  
                  if (prayer.isNext) ...[
                    SizedBox(height: 5.h),
                    _buildDetailRow(
                      context,
                      icon: Icons.hourglass_empty,
                      label: 'الوقت المتبقي',
                      value: prayer.statusText,
                    ),
                  ],
                  
                  if (prayer.isPassed) ...[
                    SizedBox(height: 5.h),
                    _buildDetailRow(
                      context,
                      icon: Icons.check_circle,
                      label: 'الحالة',
                      value: 'انتهى الوقت',
                    ),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 10.h),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                    child: Text(
                      'إغلاق',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/prayer-settings');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'الإعدادات',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 14.sp,
        ),
        SizedBox(width: 5.w),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10.sp,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: ThemeConstants.semiBold,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}