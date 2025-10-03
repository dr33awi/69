// lib/features/athkar/widgets/athkar_category_card.dart - محدث
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/athkar_model.dart';
import '../utils/category_utils.dart';

class AthkarCategoryCard extends StatelessWidget {
  final AthkarCategory category;
  final VoidCallback onTap;

  const AthkarCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryUtils.getCategoryThemeColor(category.id);
    final categoryIcon = CategoryUtils.getCategoryIcon(category.id);
    final description = CategoryUtils.getCategoryDescription(category.id);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: CategoryUtils.getCategoryGradient(category.id),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.25),
              blurRadius: 15.r,
              offset: Offset(0, 8.h),
              spreadRadius: 1.r,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52.w,
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: Colors.white,
                      size: 32.sp,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: context.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 16.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 4.h),
                      
                      Text(
                        description,
                        style: context.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.sp,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.format_list_numbered_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 16.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${category.athkar.length} ذكر',
                              style: context.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11.sp,
                                fontWeight: ThemeConstants.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (category.notifyTime != null && CategoryUtils.shouldShowTime(category.id))
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 16.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                category.notifyTime!.format(context),
                                style: context.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11.sp,
                                  fontWeight: ThemeConstants.medium,
                                ),
                              ),
                            ],
                          ),
                        ),
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
}