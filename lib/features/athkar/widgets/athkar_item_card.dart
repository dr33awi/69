// lib/features/athkar/widgets/athkar_item_card.dart
import 'package:athkar_app/core/infrastructure/services/text_settings/models/text_settings_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/athkar_model.dart';

class AthkarItemCard extends StatelessWidget {
  final AthkarItem item;
  final int currentCount;
  final bool isCompleted;
  final int number;
  final Color? color;
  final TextSettings? textSettings;
  final DisplaySettings? displaySettings;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onShare;

  const AthkarItemCard({
    super.key,
    required this.item,
    required this.currentCount,
    required this.isCompleted,
    required this.number,
    this.color,
    this.textSettings,
    this.displaySettings,
    required this.onTap,
    required this.onLongPress,
    this.onShare,
  });

  String _removeTashkeel(String text) {
    final tashkeelRegex = RegExp(r'[\u0617-\u061A\u064B-\u0652]');
    return text.replaceAll(tashkeelRegex, '');
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeConstants.primary;
    final showTashkeel = displaySettings?.showTashkeel ?? true;
    final showFadl = displaySettings?.showFadl ?? true;
    final showSource = displaySettings?.showSource ?? true;
    final showCounter = displaySettings?.showCounter ?? true;
    
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          gradient: isCompleted 
              ? LinearGradient(
                  colors: [
                    effectiveColor.withValues(alpha: 0.08),
                    effectiveColor.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isCompleted ? null : context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: effectiveColor.withValues(alpha: isCompleted ? 0.4 : 0.15),
            width: isCompleted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withValues(alpha: isCompleted ? 0.2 : 0.08),
              blurRadius: isCompleted ? 16.r : 12.r,
              offset: Offset(0, 4.h),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.1 : 0.04),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
              spreadRadius: -1,
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isCompleted)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        effectiveColor.lighten(0.1),
                        effectiveColor,
                        effectiveColor.darken(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16.r),
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNumberBadge(context),
                      
                      SizedBox(width: 10.w),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: isCompleted 
                                    ? effectiveColor.withOpacity(0.1)
                                    : context.isDarkMode 
                                        ? effectiveColor.withOpacity(0.08)
                                        : effectiveColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: effectiveColor.withOpacity(0.2),
                                  width: 1.w,
                                ),
                              ),
                              child: Text(
                                showTashkeel ? item.text : _removeTashkeel(item.text),
                                style: textSettings?.toTextStyle(
                                  color: isCompleted 
                                      ? effectiveColor.darken(0.2)
                                      : context.textPrimaryColor,
                                ) ?? TextStyle(
                                  fontSize: 18.sp,
                                  height: 1.8,
                                  fontFamily: 'Cairo',
                                  color: isCompleted 
                                      ? effectiveColor.darken(0.2)
                                      : context.textPrimaryColor,
                                  fontWeight: isCompleted 
                                      ? ThemeConstants.medium 
                                      : ThemeConstants.regular,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                            
                            if (showFadl && item.fadl != null) ...[
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
                                            item.fadl!,
                                            style: TextStyle(
                                              color: context.textSecondaryColor,
                                              height: 1.4,
                                              fontSize: ((textSettings?.fontSize ?? 18) * 0.75).sp.clamp(11.sp, 18.sp),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  Row(
                    children: [
                      if (showSource && item.source != null) ...[
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
                                    item.source!,
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
                        SizedBox(width: 10.w),
                      ] else if (!showCounter && onShare == null)
                        const Spacer(),
                      
                      if (showCounter) ...[
                        _buildCounter(context),
                        if (onShare != null) SizedBox(width: 10.w),
                      ],
                      
                      if (onShare != null) ...[
                        _ActionButton(
                          icon: Icons.share_rounded,
                          onTap: onShare!,
                          tooltip: 'مشاركة',
                          color: context.textSecondaryColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberBadge(BuildContext context) {
    final effectiveColor = color ?? ThemeConstants.primary;
    
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [effectiveColor.lighten(0.1), effectiveColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isCompleted ? null : effectiveColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: effectiveColor.withOpacity(isCompleted ? 0.6 : 0.3),
          width: isCompleted ? 1.5.w : 1.w,
        ),
        boxShadow: isCompleted ? [
          BoxShadow(
            color: effectiveColor.withOpacity(0.25),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ] : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCompleted)
            Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20.sp,
            )
          else
            Text(
              '$number',
              style: TextStyle(
                color: effectiveColor,
                fontWeight: ThemeConstants.bold,
                fontSize: 13.sp,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCounter(BuildContext context) {
    final effectiveColor = color ?? ThemeConstants.primary;
    final progress = currentCount / item.count;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [
                  effectiveColor.withOpacity(0.15),
                  effectiveColor.withOpacity(0.1),
                ],
              )
            : null,
        color: isCompleted ? null : context.surfaceColor,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: isCompleted
              ? effectiveColor.withOpacity(0.3)
              : context.dividerColor,
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
                      isCompleted ? effectiveColor : ThemeConstants.primary,
                    ),
                  ),
                ),
                
                if (isCompleted)
                  Icon(
                    Icons.check_rounded,
                    size: 10.sp,
                    color: effectiveColor,
                  )
                else if (currentCount > 0)
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
                '$currentCount / ${item.count}',
                style: TextStyle(
                  color: isCompleted ? effectiveColor : context.textPrimaryColor,
                  fontWeight: isCompleted ? ThemeConstants.bold : ThemeConstants.medium,
                  fontSize: 12.sp,
                ),
              ),
              if (!isCompleted && currentCount > 0)
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
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(999.r),
        child: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: color,
          ),
        ),
      ),
    );
  }
}