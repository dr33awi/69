// lib/features/tasbih/widgets/tasbih_screen/dhikr_selector_widget.dart
import 'package:athkar_app/features/tasbih/models/dhikr_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_theme.dart';

class DhikrSelectorWidget extends StatelessWidget {
  final DhikrItem currentDhikr;
  final VoidCallback onTap;

  const DhikrSelectorWidget({
    super.key,
    required this.currentDhikr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: currentDhikr.gradient),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: currentDhikr.primaryColor.withOpacity(0.25),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    currentDhikr.category.icon,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                
                SizedBox(width: 10.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentDhikr.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 13.sp,
                          height: 1.3,
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Text(
                            currentDhikr.category.title,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11.sp,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11.sp,
                            ),
                          ),
                          Text(
                            '${currentDhikr.recommendedCount}×',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}