// lib/features/prayer_times/widgets/next_prayer_countdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/prayer_time_model.dart';

class NextPrayerCountdown extends StatelessWidget {
  final PrayerTime nextPrayer;
  final PrayerTime? currentPrayer;

  const NextPrayerCountdown({
    super.key,
    required this.nextPrayer,
    this.currentPrayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getPrayerColor(nextPrayer.type),
            _getPrayerColor(nextPrayer.type).darken(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: _getPrayerColor(nextPrayer.type).withOpacity(0.3),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // العنوان
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time_filled,
                color: Colors.white.withOpacity(0.9),
                size: 14.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                'الصلاة القادمة',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: ThemeConstants.medium,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // اسم الصلاة والوقت
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // اسم الصلاة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextPrayer.nameAr,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: ThemeConstants.bold,
                        fontSize: 19.sp,
                      ),
                    ),
                    if (currentPrayer != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'الصلاة الحالية: ${currentPrayer!.nameAr}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // العد التنازلي
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final duration = nextPrayer.remainingTime;
                    final hours = duration.inHours;
                    final minutes = duration.inMinutes % 60;
                    final seconds = duration.inSeconds % 60;
                    
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTimeUnit(hours.toString().padLeft(2, '0'), 'س'),
                        Text(
                          ':',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: ThemeConstants.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'د'),
                        Text(
                          ':',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: ThemeConstants.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'ث'),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                return LinearProgressIndicator(
                  value: _calculateProgress(),
                  minHeight: 4.h,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String unit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double _calculateProgress() {
    if (currentPrayer == null) return 0.0;
    
    final now = DateTime.now();
    final totalDuration = nextPrayer.time.difference(currentPrayer!.time);
    final elapsed = now.difference(currentPrayer!.time);
    
    if (totalDuration.inSeconds == 0) return 0.0;
    
    return (elapsed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);
  }
  
  Color _getPrayerColor(PrayerType type) {
    return ThemeConstants.getPrayerColor(type.name);
  }
}