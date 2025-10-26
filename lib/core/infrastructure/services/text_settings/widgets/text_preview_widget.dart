// lib/core/infrastructure/services/text/screens/widgets/text_preview_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import '../models/text_settings_models.dart';
import '../constants/text_settings_constants.dart';

/// Widget معاينة النص المحسّن مع التحديث المباشر
class TextPreviewWidget extends StatelessWidget {
  final ContentType contentType;
  final TextSettings textSettings;
  final DisplaySettings displaySettings;
  final Color accentColor;
  final Map<ContentType, String> previewTexts;
  final Map<ContentType, Map<String, dynamic>>? previewMetadata;
  final ValueChanged<String>? onFontChanged;
  final ValueChanged<double>? onFontSizeChanged;
  final ValueChanged<double>? onLineHeightChanged;
  final ValueChanged<double>? onLetterSpacingChanged;
  final ValueChanged<TextStylePreset>? onPresetSelected;
  final String? currentPresetName;

  const TextPreviewWidget({
    super.key,
    required this.contentType,
    required this.textSettings,
    required this.displaySettings,
    required this.accentColor,
    required this.previewTexts,
    this.previewMetadata,
    this.onFontChanged,
    this.onFontSizeChanged,
    this.onLineHeightChanged,
    this.onLetterSpacingChanged,
    this.onPresetSelected,
    this.currentPresetName,
  });

  @override
  Widget build(BuildContext context) {
    final previewText = previewTexts[contentType] ?? '';
    final metadata = previewMetadata?[contentType];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
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
        ],
      ),
      child: Column(
        children: [
          // هيدر مضغوط
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        accentColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.preview_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معاينة مباشرة',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: ThemeConstants.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      Text(
                        _getPreviewSubtitle(contentType),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // خط فاصل رفيع
          Container(
            height: 1.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accentColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // محتوى الكارد (مشابه لكارد الأذكار)
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // النص المعاين داخل صندوق
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: context.isDarkMode 
                        ? accentColor.withOpacity(0.08)
                        : accentColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: accentColor.withOpacity(0.2),
                      width: 1.w,
                    ),
                  ),
                  child: Text(
                    displaySettings.showTashkeel 
                        ? previewText 
                        : _removeTashkeel(previewText),
                    style: TextStyle(
                      fontSize: textSettings.fontSize,
                      fontFamily: textSettings.fontFamily,
                      height: textSettings.lineHeight,
                      letterSpacing: textSettings.letterSpacing,
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                
                // الفضيلة (إن كانت معروضة)
                if (displaySettings.showFadl && metadata?['fadl'] != null) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: ThemeConstants.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: ThemeConstants.accent.withOpacity(0.2),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: ThemeConstants.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            size: 16.sp,
                            color: ThemeConstants.accent,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الفضيلة',
                                style: TextStyle(
                                  color: ThemeConstants.accent,
                                  fontWeight: ThemeConstants.semiBold,
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                metadata!['fadl'],
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  height: 1.4,
                                  fontSize: ((textSettings.fontSize) * 0.75).sp.clamp(11.sp, 18.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 12.h),
                
                // المصدر والعداد
                Row(
                  children: [
                    // المصدر (إن كان معروضاً)
                    if (displaySettings.showSource && metadata != null && metadata['source'] != null) ...[
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: context.textSecondaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999.r),
                            border: Border.all(
                              color: context.textSecondaryColor.withOpacity(0.15),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.source_rounded,
                                size: 14.sp,
                                color: context.textSecondaryColor,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  metadata['source'],
                                  style: TextStyle(
                                    color: context.textSecondaryColor,
                                    fontWeight: ThemeConstants.medium,
                                    fontSize: 10.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (displaySettings.showCounter && 
                          contentType == ContentType.athkar && 
                          metadata['count'] != null) 
                        SizedBox(width: 10.w),
                    ],
                    
                    // العداد (للأذكار فقط وإن كان معروضاً)
                    if (displaySettings.showCounter && 
                        contentType == ContentType.athkar && 
                        metadata != null &&
                        metadata['count'] != null)
                      _buildCounter(context, metadata),
                  ],
                ),
              ],
            ),
          ),
          
          // خط فاصل
          Container(
            height: 1.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accentColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // قائمة منسدلة لأدوات التحكم
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              childrenPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              title: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: accentColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'تخصيص الخط',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: ThemeConstants.semiBold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: accentColor,
                size: 24.sp,
              ),
              children: [
                SizedBox(height: 8.h),
                
                // القوالب الجاهزة
                if (onPresetSelected != null) ...[
                  _buildPresetSelector(context),
                  SizedBox(height: 16.h),
                ],
                
                // اختيار نوع الخط
                if (onFontChanged != null) ...[
                  _buildFontSelector(context),
                  SizedBox(height: 16.h),
                ],
                
                // التحكم في الأحجام والمسافات
                if (onFontSizeChanged != null || 
                    onLineHeightChanged != null || 
                    onLetterSpacingChanged != null) ...[
                  _buildAdvancedSettingsSelector(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCounter(BuildContext context, Map<String, dynamic> metadata) {
    final count = metadata['count'] as int;
    final currentCount = metadata['currentCount'] as int? ?? 0;
    final progress = currentCount / count;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: context.dividerColor,
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20.r,
            height: 20.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 20.r,
                  height: 20.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.dividerColor.withOpacity(0.5),
                      width: 1.5.w,
                    ),
                  ),
                ),
                
                SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 1.5.w,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeConstants.primary,
                    ),
                  ),
                ),
                
                if (currentCount > 0)
                  Container(
                    width: 6.r,
                    height: 6.r,
                    decoration: const BoxDecoration(
                      color: ThemeConstants.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(width: 6.w),
          
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$currentCount / $count',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontWeight: ThemeConstants.medium,
                  fontSize: 12.sp,
                ),
              ),
              if (currentCount > 0)
                Text(
                  'اضغط للمتابعة',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 8.sp,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl({
    required BuildContext context,
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18.sp, color: color),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: ThemeConstants.medium,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
                displayValue,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: ThemeConstants.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.15),
            trackHeight: 6.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
            trackShape: RoundedRectSliderTrackShape(),
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

  Widget _buildAdvancedSettingsSelector(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAdvancedSettingsPicker(context),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 20.sp,
                  color: accentColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إعدادات متقدمة',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: context.textSecondaryColor,
                        fontWeight: ThemeConstants.medium,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'الحجم والمسافات',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: ThemeConstants.semiBold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_left_rounded,
                color: accentColor,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetSelector(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPresetPicker(context),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.dashboard_customize_rounded,
                  size: 20.sp,
                  color: accentColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قالب جاهز',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: context.textSecondaryColor,
                        fontWeight: ThemeConstants.medium,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      currentPresetName ?? 'اختر قالباً',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: ThemeConstants.semiBold,
                        color: currentPresetName != null 
                            ? context.textPrimaryColor
                            : context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_left_rounded,
                color: accentColor,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontSelector(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showFontPicker(context),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.font_download_rounded,
                  size: 20.sp,
                  color: accentColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نوع الخط',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: context.textSecondaryColor,
                        fontWeight: ThemeConstants.medium,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      TextSettingsConstants.availableFonts[textSettings.fontFamily] ?? textSettings.fontFamily,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: ThemeConstants.semiBold,
                        color: context.textPrimaryColor,
                        fontFamily: textSettings.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_left_rounded,
                color: accentColor,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdvancedSettingsPicker(BuildContext context) {
    // نسخ القيم الحالية للاستخدام المحلي
    double tempFontSize = textSettings.fontSize;
    double tempLineHeight = textSettings.lineHeight;
    double tempLetterSpacing = textSettings.letterSpacing;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: context.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مقبض السحب
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.dividerColor,
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
                      Icons.tune_rounded,
                      color: accentColor,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'إعدادات متقدمة',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              // المحتوى
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    // حجم الخط
                    if (onFontSizeChanged != null) ...[
                      _buildSliderControl(
                        context: context,
                        icon: Icons.format_size_rounded,
                        label: 'حجم الخط',
                        value: tempFontSize,
                        min: 12.0,
                        max: 36.0,
                        divisions: 24,
                        displayValue: '${tempFontSize.round()}',
                        color: ThemeConstants.primary,
                        onChanged: (value) {
                          setModalState(() {
                            tempFontSize = value;
                          });
                          onFontSizeChanged!(value);
                        },
                      ),
                      SizedBox(height: 20.h),
                    ],
                    
                    // تباعد الأسطر
                    if (onLineHeightChanged != null) ...[
                      _buildSliderControl(
                        context: context,
                        icon: Icons.format_line_spacing_rounded,
                        label: 'تباعد الأسطر',
                        value: tempLineHeight,
                        min: 1.0,
                        max: 3.0,
                        divisions: 20,
                        displayValue: tempLineHeight.toStringAsFixed(1),
                        color: ThemeConstants.accent,
                        onChanged: (value) {
                          setModalState(() {
                            tempLineHeight = value;
                          });
                          onLineHeightChanged!(value);
                        },
                      ),
                      SizedBox(height: 20.h),
                    ],
                    
                    // تباعد الأحرف
                    if (onLetterSpacingChanged != null) ...[
                      _buildSliderControl(
                        context: context,
                        icon: Icons.space_bar_rounded,
                        label: 'تباعد الأحرف',
                        value: tempLetterSpacing,
                        min: 0.0,
                        max: 2.0,
                        divisions: 20,
                        displayValue: tempLetterSpacing.toStringAsFixed(1),
                        color: ThemeConstants.tertiary,
                        onChanged: (value) {
                          setModalState(() {
                            tempLetterSpacing = value;
                          });
                          onLetterSpacingChanged!(value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showPresetPicker(BuildContext context) {
    final allPresets = TextStylePresets.all;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مقبض السحب
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.dividerColor,
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
                    Icons.dashboard_customize_rounded,
                    color: accentColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'اختر قالباً جاهزاً',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: ThemeConstants.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            // قائمة القوالب
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 400.h),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: allPresets.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final preset = allPresets[index];
                  final isSelected = preset.name == currentPresetName;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onPresetSelected?.call(preset);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? accentColor.withOpacity(0.1)
                              : context.cardColor,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isSelected
                                ? accentColor.withValues(alpha: 0.3)
                                : context.dividerColor.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    preset.name,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: ThemeConstants.bold,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      _buildPresetSpec(
                                        context,
                                        Icons.format_size_rounded,
                                        '${preset.fontSize.round()}',
                                      ),
                                      SizedBox(width: 12.w),
                                      _buildPresetSpec(
                                        context,
                                        Icons.format_line_spacing_rounded,
                                        preset.lineHeight.toStringAsFixed(1),
                                      ),
                                      SizedBox(width: 12.w),
                                      _buildPresetSpec(
                                        context,
                                        Icons.space_bar_rounded,
                                        preset.letterSpacing.toStringAsFixed(1),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSpec(BuildContext context, IconData icon, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: accentColor),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: ThemeConstants.semiBold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getPreviewSubtitle(ContentType type) {
    switch (type) {
      case ContentType.athkar:
        return 'من أذكار الصباح';
      case ContentType.dua:
        return 'من الأدعية المأثورة';
      case ContentType.asmaAllah:
        return 'من أسماء الله الحسنى';
    }
  }

  void _showFontPicker(BuildContext context) {
    final recommendedFonts = TextSettingsConstants.getRecommendedFontsForContentType(contentType);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مقبض السحب
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.dividerColor,
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
                    Icons.font_download_rounded,
                    color: accentColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'اختر الخط',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: ThemeConstants.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            // قائمة الخطوط
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 400.h),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: recommendedFonts.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final font = recommendedFonts[index];
                  final isSelected = font == textSettings.fontFamily;
                  final isRecommended = index < 3; // أول 3 خطوط موصى بها
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onFontChanged?.call(font);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? accentColor.withOpacity(0.1)
                              : context.cardColor,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isSelected
                                ? accentColor.withValues(alpha: 0.3)
                                : context.dividerColor.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        TextSettingsConstants.availableFonts[font] ?? font,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: ThemeConstants.semiBold,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      if (isRecommended) ...[
                                        SizedBox(width: 8.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                          decoration: BoxDecoration(
                                            color: ThemeConstants.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8.r),
                                          ),
                                          child: Text(
                                            'موصى به',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: ThemeConstants.bold,
                                              color: ThemeConstants.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontFamily: font,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  String _removeTashkeel(String text) {
    final tashkeelRegex = RegExp(r'[\u0617-\u061A\u064B-\u0652]');
    return text.replaceAll(tashkeelRegex, '');
  }
}