// lib/features/quran/widgets/reader_settings_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';

class ReaderSettingsSheet extends StatefulWidget {
  final double currentFontSize;
  final Function(double) onFontSizeChanged;
  
  const ReaderSettingsSheet({
    super.key,
    required this.currentFontSize,
    required this.onFontSizeChanged,
  });

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late double _fontSize;
  
  @override
  void initState() {
    super.initState();
    _fontSize = widget.currentFontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeConstants.card(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          
          // Handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: ThemeConstants.divider(context),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          SizedBox(height: 20.h),
          
          // العنوان
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  color: ThemeConstants.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'إعدادات القراءة',
                  style: AppTextStyles.h4.copyWith(
                    color: ThemeConstants.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // حجم الخط
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'حجم الخط',
                      style: AppTextStyles.body1.copyWith(
                        color: ThemeConstants.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _fontSize.toStringAsFixed(0),
                      style: AppTextStyles.body1.copyWith(
                        color: ThemeConstants.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // مثال على النص
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: ThemeConstants.surface(context),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      style: AppTextStyles.quran.copyWith(
                        fontSize: _fontSize.sp,
                        color: ThemeConstants.textPrimary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Slider
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.remove,
                        color: ThemeConstants.primary,
                        size: 24.sp,
                      ),
                      onPressed: () {
                        if (_fontSize > 16) {
                          setState(() => _fontSize -= 1);
                          widget.onFontSizeChanged(_fontSize);
                        }
                      },
                    ),
                    
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: ThemeConstants.primary,
                          inactiveTrackColor: ThemeConstants.primary.withValues(alpha: 0.2),
                          thumbColor: ThemeConstants.primary,
                          overlayColor: ThemeConstants.primary.withValues(alpha: 0.2),
                          trackHeight: 4.h,
                        ),
                        child: Slider(
                          value: _fontSize,
                          min: 16.0,
                          max: 32.0,
                          divisions: 16,
                          onChanged: (value) {
                            setState(() => _fontSize = value);
                            widget.onFontSizeChanged(value);
                          },
                        ),
                      ),
                    ),
                    
                    IconButton(
                      icon: Icon(
                        Icons.add,
                        color: ThemeConstants.primary,
                        size: 24.sp,
                      ),
                      onPressed: () {
                        if (_fontSize < 32) {
                          setState(() => _fontSize += 1);
                          widget.onFontSizeChanged(_fontSize);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // أزرار الإغلاق
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'حسناً',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 20.h),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}