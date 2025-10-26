// lib/core/infrastructure/services/text/screens/widgets/content_type_selector.dart
import 'package:athkar_app/core/infrastructure/services/text_settings/models/text_settings_models.dart' as models;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../app/themes/app_theme.dart';


/// Widget لاختيار نوع المحتوى
class ContentTypeSelector extends StatelessWidget {
  final models.ContentType selectedContentType;
  final ValueChanged<models.ContentType> onChanged;
  final Map<models.ContentType, Color> colorMap;
  final Map<models.ContentType, IconData> iconMap;

  const ContentTypeSelector({
    super.key,
    required this.selectedContentType,
    required this.onChanged,
    required this.colorMap,
    required this.iconMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.1),
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
      child: Row(
        children: models.ContentType.values.map((contentType) {
          final isSelected = selectedContentType == contentType;
          final color = colorMap[contentType] ?? ThemeConstants.primary;
          final icon = iconMap[contentType] ?? Icons.article_rounded;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                onChanged(contentType);
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color,
                            color.withOpacity(0.85),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 10.r,
                            offset: Offset(0, 3.h),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSelected ? 10.r : 8.r),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : color.withOpacity(0.12),
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: isSelected ? 22.sp : 18.sp,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      contentType.displayName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected
                            ? ThemeConstants.bold
                            : ThemeConstants.medium,
                        color: isSelected
                            ? Colors.white
                            : context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}