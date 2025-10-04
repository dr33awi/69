// 2. prayer_times_card.dart
// =====================================================

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
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          if (isNext)
            BoxShadow(
              color: prayer.color.withOpacity(0.2),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showPrayerDetails(context),
          borderRadius: BorderRadius.circular(16.r),
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
                  ? Colors.white.withOpacity(0.2)
                  : context.dividerColor.withOpacity(0.2),
                width: isNext ? 1.5.w : 1.w,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(12.r),
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
      ? Colors.white.withOpacity(0.2)
      : prayer.color.withOpacity(0.1);
    
    return Container(
      width: 48.r,
      height: 48.r,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: useGradient 
            ? Colors.white.withOpacity(0.3)
            : prayer.color.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Icon(
        prayer.icon,
        color: iconColor,
        size: 24.sp,
      ),
    );
  }

  Widget _buildPrayerInfo(BuildContext context, bool useGradient) {
    final textColor = _getTextColor(context, useGradient);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          prayer.nameAr,
          style: context.titleLarge?.copyWith(
            color: textColor,
            fontWeight: prayer.isNext 
              ? ThemeConstants.bold 
              : ThemeConstants.semiBold,
            fontSize: 16.sp,
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
          horizontal: 6.w,
          vertical: 2.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 12.sp,
              color: Colors.white,
            ),
            SizedBox(width: 3.w),
            Text(
              prayer.statusText,
              style: context.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: ThemeConstants.semiBold,
                fontSize: 10.sp,
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
            size: 12.sp,
            color: useGradient ? Colors.white : ThemeConstants.success,
          ),
          SizedBox(width: 3.w),
          Text(
            'انتهى الوقت',
            style: context.bodySmall?.copyWith(
              color: useGradient 
                ? Colors.white.withOpacity(0.8)
                : context.textSecondaryColor,
              fontWeight: ThemeConstants.medium,
              fontSize: 10.sp,
            ),
          ),
        ],
      );
    } else {
      return Text(
        PrayerUtils.formatTimeUntil(prayer.time),
        style: context.bodySmall?.copyWith(
          color: _getTextColor(context, useGradient).withOpacity(0.8),
          fontSize: 10.sp,
        ),
      );
    }
  }

  Widget _buildTimeSection(BuildContext context, bool useGradient) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: useGradient 
          ? Colors.white.withOpacity(0.2)
          : prayer.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: useGradient 
            ? Colors.white.withOpacity(0.3)
            : prayer.color.withOpacity(0.2),
        ),
      ),
      child: Text(
        prayer.formattedTime,
        style: context.titleLarge?.copyWith(
          color: useGradient ? Colors.white : prayer.color,
          fontWeight: ThemeConstants.bold,
          fontSize: 14.sp,
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
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: prayer.gradient,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    prayer.icon,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.nameAr,
                        style: context.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                      Text(
                        prayer.nameEn,
                        style: context.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
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
                    SizedBox(height: 6.h),
                    _buildDetailRow(
                      context,
                      icon: Icons.hourglass_empty,
                      label: 'الوقت المتبقي',
                      value: prayer.statusText,
                    ),
                  ],
                  
                  if (prayer.isPassed) ...[
                    SizedBox(height: 6.h),
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
            
            SizedBox(height: 12.h),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: Text(
                      'إغلاق',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/prayer-settings');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'الإعدادات',
                      style: TextStyle(fontSize: 14.sp),
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
          size: 16.sp,
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: context.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11.sp,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: context.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: ThemeConstants.semiBold,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}