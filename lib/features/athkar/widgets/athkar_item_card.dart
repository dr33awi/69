// lib/features/athkar/widgets/athkar_item_card.dart - محدث
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
  final double fontSize;
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
    required this.fontSize,
    required this.onTap,
    required this.onLongPress,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeConstants.primary;
    
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        decoration: BoxDecoration(
          gradient: isCompleted 
              ? LinearGradient(
                  colors: [
                    effectiveColor.withValues(alpha: 0.05),
                    effectiveColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isCompleted ? null : context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: effectiveColor.withValues(alpha: isCompleted ? 0.4 : 0.3),
            width: isCompleted ? 2.w : 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withValues(alpha: isCompleted ? 0.2 : 0.1),
              blurRadius: isCompleted ? 16.r : 8.r,
              offset: Offset(0, 4.h),
              spreadRadius: isCompleted ? 1.r : 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isCompleted)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          effectiveColor.withValues(alpha: 0.05),
                          effectiveColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
            
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
                      top: Radius.circular(20.r),
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNumberBadge(context),
                      
                      SizedBox(width: 12.w),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: isCompleted 
                                    ? effectiveColor.withValues(alpha: 0.1)
                                    : context.isDarkMode 
                                        ? effectiveColor.withValues(alpha: 0.08)
                                        : effectiveColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: effectiveColor.withValues(alpha: 0.2),
                                  width: 1.w,
                                ),
                              ),
                              child: Text(
                                item.text,
                                style: context.bodyLarge?.copyWith(
                                  fontSize: fontSize.sp,
                                  height: 2.0,
                                  fontFamily: ThemeConstants.fontFamilyArabic,
                                  color: isCompleted 
                                      ? effectiveColor.darken(0.2)
                                      : context.textPrimaryColor,
                                  fontWeight: isCompleted 
                                      ? ThemeConstants.medium 
                                      : ThemeConstants.regular,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                            
                            if (item.fadl != null) ...[
                              SizedBox(height: 12.h),
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: ThemeConstants.accent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: ThemeConstants.accent.withValues(alpha: 0.2),
                                    width: 1.w,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(4.w),
                                      decoration: BoxDecoration(
                                        color: ThemeConstants.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 20.sp,
                                        color: ThemeConstants.accent,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الفضل',
                                            style: context.labelMedium?.copyWith(
                                              color: ThemeConstants.accent,
                                              fontWeight: ThemeConstants.semiBold,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            item.fadl!,
                                            style: context.bodySmall?.copyWith(
                                              color: context.textSecondaryColor,
                                              height: 1.5,
                                              fontSize: (fontSize * 0.8).sp.clamp(12.sp, 20.sp),
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
                  
                  SizedBox(height: 16.h),
                  
                  Row(
                    children: [
                      if (item.source != null) ...[
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: context.textSecondaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999.r),
                              border: Border.all(
                                color: context.textSecondaryColor.withValues(alpha: 0.15),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.source_rounded,
                                  size: 16.sp,
                                  color: context.textSecondaryColor,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    item.source!,
                                    style: context.labelSmall?.copyWith(
                                      color: context.textSecondaryColor,
                                      fontWeight: ThemeConstants.medium,
                                      fontSize: 11.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                      ] else
                        const Spacer(),
                      
                      _buildCounter(context),
                      
                      if (onShare != null) ...[
                        SizedBox(width: 12.w),
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
      width: 44.w,
      height: 44.h,
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [effectiveColor.lighten(0.1), effectiveColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isCompleted ? null : effectiveColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: effectiveColor.withValues(alpha: isCompleted ? 0.6 : 0.3),
          width: isCompleted ? 2.w : 1.w,
        ),
        boxShadow: isCompleted ? [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.3),
            blurRadius: 8.r,
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
              size: 24.sp,
            )
          else
            Text(
              '$number',
              style: context.labelLarge?.copyWith(
                color: effectiveColor,
                fontWeight: ThemeConstants.bold,
                fontSize: 14.sp,
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
        horizontal: 12.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [
                  effectiveColor.withValues(alpha: 0.15),
                  effectiveColor.withValues(alpha: 0.1),
                ],
              )
            : null,
        color: isCompleted ? null : context.surfaceColor,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: isCompleted
              ? effectiveColor.withValues(alpha: 0.3)
              : context.dividerColor,
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24.w,
            height: 24.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.dividerColor.withValues(alpha: 0.5),
                      width: 2.w,
                    ),
                  ),
                ),
                
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2.w,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? effectiveColor : ThemeConstants.primary,
                    ),
                  ),
                ),
                
                if (isCompleted)
                  Icon(
                    Icons.check_rounded,
                    size: 12.sp,
                    color: effectiveColor,
                  )
                else if (currentCount > 0)
                  Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: const BoxDecoration(
                      color: ThemeConstants.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(width: 8.w),
          
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$currentCount / ${item.count}',
                style: context.labelMedium?.copyWith(
                  color: isCompleted ? effectiveColor : context.textPrimaryColor,
                  fontWeight: isCompleted ? ThemeConstants.bold : ThemeConstants.medium,
                  fontSize: 14.sp,
                ),
              ),
              if (!isCompleted && currentCount > 0)
                Text(
                  'اضغط للمتابعة',
                  style: context.labelSmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 9.sp,
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
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: color,
          ),
        ),
      ),
    );
  }
}