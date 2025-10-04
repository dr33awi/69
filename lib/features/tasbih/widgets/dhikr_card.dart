// lib/features/tasbih/widgets/dhikr_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/dhikr_model.dart';

class DhikrCardSimple extends StatelessWidget {
  final DhikrItem dhikr;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;

  const DhikrCardSimple({
    super.key,
    required this.dhikr,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? dhikr.primaryColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 12.r : 8.r,
            offset: Offset(0, isSelected ? 6.h : 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected 
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dhikr.gradient,
                    )
                  : null,
              color: !isSelected ? context.cardColor : null,
              borderRadius: BorderRadius.circular(16.r),
              border: isSelected 
                  ? Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.w,
                    )
                  : Border.all(
                      color: context.dividerColor.withOpacity(0.2),
                      width: 1.w,
                    ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الرأس مع التصنيف والإجراءات
                  Row(
                    children: [
                      // تصنيف الذكر
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.2)
                              : dhikr.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              dhikr.category.icon,
                              size: 14.sp,
                              color: isSelected 
                                  ? Colors.white
                                  : dhikr.primaryColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              dhikr.category.title,
                              style: TextStyle(
                                color: isSelected 
                                    ? Colors.white
                                    : dhikr.primaryColor,
                                fontWeight: ThemeConstants.medium,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // العدد المقترح
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.2)
                              : context.textSecondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${dhikr.recommendedCount}×',
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.white
                                : context.textSecondaryColor,
                            fontWeight: ThemeConstants.semiBold,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // نص الذكر
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.white.withOpacity(0.15)
                          : dhikr.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.white.withOpacity(0.3)
                            : dhikr.primaryColor.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      dhikr.text,
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white
                            : context.textPrimaryColor,
                        fontWeight: ThemeConstants.medium,
                        fontSize: 16.sp,
                        height: 1.8,
                        fontFamily: ThemeConstants.fontFamilyArabic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // الفضل (إذا وُجد)
                  if (dhikr.virtue != null) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withOpacity(0.1)
                            : ThemeConstants.accent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.2)
                              : ThemeConstants.accent.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16.sp,
                            color: isSelected 
                                ? Colors.white
                                : ThemeConstants.accent,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الفضل',
                                  style: TextStyle(
                                    color: isSelected 
                                        ? Colors.white
                                        : ThemeConstants.accent,
                                    fontWeight: ThemeConstants.semiBold,
                                    fontSize: 11.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  dhikr.virtue!,
                                  style: TextStyle(
                                    color: isSelected 
                                        ? Colors.white.withOpacity(0.8)
                                        : context.textSecondaryColor,
                                    fontSize: 12.sp,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // مؤشر الاختيار
                  if (isSelected) ...[
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'مُحدد حالياً',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: ThemeConstants.semiBold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}