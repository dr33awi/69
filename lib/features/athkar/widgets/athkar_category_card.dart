// lib/features/athkar/widgets/athkar_category_card.dart
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
          borderRadius: BorderRadius.circular(18.r),
          gradient: CategoryUtils.getCategoryGradient(category.id),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.25),
              blurRadius: 12.r,
              offset: Offset(0, 6.h),
              spreadRadius: 1.r,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.05),
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
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: Colors.white,
                      size: 26.sp,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  Text(
                    category.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: ThemeConstants.bold,
                      fontSize: 16.sp,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  
                  if (category.notifyTime != null && CategoryUtils.shouldShowTime(category.id)) ...[
                    SizedBox(height: 8.h),
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 14.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              category.notifyTime!.format(context),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11.sp,
                                fontWeight: ThemeConstants.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}