// lib/core/infrastructure/services/text/screens/widgets/font_selector_widget.dart
import 'dart:io';

import 'package:athkar_app/core/infrastructure/services/text/constants/text_settings_constants.dart';
import 'package:athkar_app/core/infrastructure/services/text/models/text_settings_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../app/themes/app_theme.dart';

/// Widget لاختيار الخط مع معاينة مباشرة
class FontSelectorWidget extends StatefulWidget {
  final ContentType contentType;
  final String currentFont;
  final ValueChanged<String?> onChanged;
  final Color accentColor;

  const FontSelectorWidget({
    super.key,
    required this.contentType,
    required this.currentFont,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  State<FontSelectorWidget> createState() => _FontSelectorWidgetState();
}

class _FontSelectorWidgetState extends State<FontSelectorWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final recommendedFonts = 
        TextSettingsConstants.getRecommendedFontsForContentType(widget.contentType as ContentType);
    
    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          childrenPadding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
          onExpansionChanged: (expanded) {
            setState(() => isExpanded = expanded);
            HapticFeedback.selectionClick();
          },
          title: Row(
            children: [
              Icon(
                Icons.font_download_rounded,
                size: 20.sp,
                color: ThemeConstants.primary,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نوع الخط',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: ThemeConstants.medium,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      TextSettingsConstants.availableFonts[widget.currentFont] ?? 
                          widget.currentFont,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontFamily: widget.currentFont,
                        color: widget.accentColor,
                        fontWeight: ThemeConstants.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Icon(
            isExpanded 
                ? Icons.keyboard_arrow_up_rounded 
                : Icons.keyboard_arrow_down_rounded,
            color: ThemeConstants.primary,
            size: 28.sp,
          ),
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: 280.h),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.all(8.w),
                itemCount: TextSettingsConstants.availableFonts.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final fontEntry = TextSettingsConstants.availableFonts.entries
                      .elementAt(index);
                  final fontFamily = fontEntry.key;
                  final fontName = fontEntry.value;
                  final isSelected = widget.currentFont == fontFamily;
                  final isRecommended = recommendedFonts.contains(fontFamily);
                  
                  return _buildFontItem(
                    context,
                    fontFamily,
                    fontName,
                    isSelected,
                    isRecommended,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontItem(
    BuildContext context,
    String fontFamily,
    String fontName,
    bool isSelected,
    bool isRecommended,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () {
          widget.onChanged(fontFamily);
          HapticFeedback.selectionClick();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.accentColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? widget.accentColor.withOpacity(0.3)
                  : context.dividerColor.withOpacity(0.2),
              width: isSelected ? 2.w : 1.5.w,
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
                        Flexible(
                          child: Text(
                            fontName,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: isSelected
                                  ? ThemeConstants.bold
                                  : ThemeConstants.medium,
                              color: isSelected
                                  ? widget.accentColor
                                  : context.textPrimaryColor,
                              fontFamily: fontFamily,
                            ),
                          ),
                        ),
                        if (isRecommended) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: ThemeConstants.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: ThemeConstants.success.withOpacity(0.3),
                                width: 1.w,
                              ),
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
                    SizedBox(height: 6.h),
                    Text(
                      'أ ب ت ث ج ح خ • ١ ٢ ٣ ٤',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontFamily: fontFamily,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              if (isSelected)
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.4),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
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
  }
}