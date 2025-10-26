// lib/core/infrastructure/services/text/screens/widgets/text_preview_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import '../models/text_settings_models.dart';

/// Widget معاينة النص المحسّن مع التحديث المباشر
class TextPreviewWidget extends StatelessWidget {
  final ContentType contentType;
  final TextSettings textSettings;
  final DisplaySettings displaySettings;
  final Color accentColor;
  final Map<ContentType, String> previewTexts;

  const TextPreviewWidget({
    super.key,
    required this.contentType,
    required this.textSettings,
    required this.displaySettings,
    required this.accentColor,
    required this.previewTexts,
  });

  @override
  Widget build(BuildContext context) {
    final previewText = previewTexts[contentType] ?? '';
    
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
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1.5.w,
        ),
      ),
      child: Column(
        children: [
          // هيدر مضغوط
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
            child: Row(
              children: [
                Icon(
                  Icons.preview_rounded,
                  color: accentColor,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'معاينة مباشرة',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: ThemeConstants.bold,
                    color: accentColor,
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${textSettings.fontSize.round()}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: ThemeConstants.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                Spacer(),
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
          
          // خط فاصل رفيع
          Container(
            height: 1.h,
            margin: EdgeInsets.symmetric(horizontal: 14.w),
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
          
          // النص المعاين - بدون أنيميشن
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
          
          // معلومات إضافية
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18.r),
                bottomRight: Radius.circular(18.r),
              ),
            ),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              alignment: WrapAlignment.center,
              children: [
                _buildInfoChip(
                  context,
                  Icons.font_download_rounded,
                  'الخط: ${_getFontDisplayName(textSettings.fontFamily)}',
                  accentColor,
                ),
                _buildInfoChip(
                  context,
                  Icons.format_size,
                  'الحجم: ${textSettings.fontSize.round()}',
                  accentColor,
                ),
                _buildInfoChip(
                  context,
                  Icons.format_line_spacing,
                  'السطور: ${textSettings.lineHeight.toStringAsFixed(1)}',
                  accentColor,
                ),
                _buildInfoChip(
                  context,
                  Icons.space_bar,
                  'الأحرف: ${textSettings.letterSpacing.toStringAsFixed(1)}',
                  accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: color.withOpacity(0.7)),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.sp,
            color: context.textSecondaryColor,
            fontWeight: ThemeConstants.medium,
          ),
        ),
      ],
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

  String _getFontDisplayName(String fontFamily) {
    // تحويل اسم الخط الفني إلى اسم عرض مختصر
    final fontMap = {
      'Amiri': 'أميري',
      'Lateef': 'لطيف',
      'Scheherazade': 'شهرزاد',
      'Cairo': 'القاهرة',
      'Tajawal': 'تجوال',
      'Almarai': 'المرعي',
      'ElMessiri': 'المسيري',
      'Markazi': 'مركزي',
      'Noto Naskh Arabic': 'نسخ',
      'Harmattan': 'هرمتن',
    };
    
    return fontMap[fontFamily] ?? fontFamily;
  }

  String _removeTashkeel(String text) {
    final tashkeelRegex = RegExp(r'[\u0617-\u061A\u064B-\u0652]');
    return text.replaceAll(tashkeelRegex, '');
  }
}