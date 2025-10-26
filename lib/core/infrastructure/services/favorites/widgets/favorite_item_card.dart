// lib/core/infrastructure/services/favorites/widgets/favorite_item_card.dart
// بطاقة عنصر المفضلة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../app/themes/app_theme.dart';
import '../models/favorite_models.dart';

/// بطاقة عنصر مفضلة
class FavoriteItemCard extends StatelessWidget {
  final FavoriteItem item;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const FavoriteItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onToggleFavorite,
  });

  Color _getTypeColor() {
    switch (item.contentType) {
      case FavoriteContentType.dua:
        return ThemeConstants.primary;
      case FavoriteContentType.athkar:
        return ThemeConstants.accent;
      case FavoriteContentType.asmaAllah:
        return ThemeConstants.tertiary;
    }
  }

  IconData _getTypeIcon() {
    return item.contentType.icon;
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            typeColor.withValues(alpha: 0.03),
            typeColor.withValues(alpha: 0.01),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20.r),
          splashColor: typeColor.withValues(alpha: 0.1),
          highlightColor: typeColor.withValues(alpha: 0.05),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.cardColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: typeColor.withValues(alpha: 0.15),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: typeColor.withValues(alpha: 0.08),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الرأس: النوع والمفضلة
                Row(
                  children: [
                    // أيقونة النوع مع تأثير متدرج
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            typeColor.withValues(alpha: 0.2),
                            typeColor.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withValues(alpha: 0.15),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getTypeIcon(),
                        color: typeColor,
                        size: 18.sp,
                      ),
                    ),
                    
                    SizedBox(width: 10.w),
                    
                    // اسم النوع
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        item.contentType.displayName,
                        style: context.labelMedium?.copyWith(
                          color: typeColor,
                          fontSize: 11.sp,
                          fontWeight: ThemeConstants.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    
                    Spacer(),
                    
                    // زر المفضلة مع تأثير جميل
                    Material(
                      color: Colors.transparent,
                      shape: CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onToggleFavorite();
                        },
                        customBorder: CircleBorder(),
                        splashColor: typeColor.withValues(alpha: 0.2),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                typeColor.withValues(alpha: 0.15),
                                typeColor.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: typeColor.withValues(alpha: 0.2),
                                blurRadius: 6.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.bookmark_rounded,
                            color: typeColor,
                            size: 22.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 14.h),
                
                // العنوان مع تنسيق أفضل
                Text(
                  item.title,
                  style: context.titleMedium?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 17.sp,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // المحتوى
                if (item.content.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          typeColor.withValues(alpha: 0.06),
                          typeColor.withValues(alpha: 0.03),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.12),
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      item.content,
                      style: context.bodyMedium?.copyWith(
                        color: context.textPrimaryColor,
                        fontSize: 14.sp,
                        height: 1.9,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
                
                // الترجمة/الوصف
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: context.isDarkMode 
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: context.dividerColor.withValues(alpha: 0.1),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          size: 14.sp,
                          color: context.textSecondaryColor,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            item.subtitle!,
                            style: context.bodySmall?.copyWith(
                              color: context.textSecondaryColor,
                              fontSize: 12.sp,
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // المصدر والمرجع
                if (item.source != null || item.reference != null) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 14.sp,
                          color: typeColor,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            '${item.source}${item.reference != null ? ' - ${item.reference}' : ''}',
                            style: context.bodySmall?.copyWith(
                              color: typeColor,
                              fontSize: 11.sp,
                              fontWeight: ThemeConstants.medium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // التاريخ والمعلومات
                SizedBox(height: 12.h),
                Row(
                  children: [
                    // تاريخ الإضافة
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: context.isDarkMode 
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12.sp,
                            color: context.textSecondaryColor.withValues(alpha: 0.8),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _formatDate(item.addedAt),
                            style: context.bodySmall?.copyWith(
                              color: context.textSecondaryColor.withValues(alpha: 0.8),
                              fontSize: 10.sp,
                              fontWeight: ThemeConstants.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (item.lastAccessedAt != null) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_rounded,
                              size: 12.sp,
                              color: typeColor.withValues(alpha: 0.8),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _formatDate(item.lastAccessedAt!),
                              style: context.bodySmall?.copyWith(
                                color: typeColor.withValues(alpha: 0.9),
                                fontSize: 10.sp,
                                fontWeight: ThemeConstants.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'الآن';
        }
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'منذ $weeks ${weeks == 1 ? 'أسبوع' : 'أسابيع'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months ${months == 1 ? 'شهر' : 'أشهر'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'منذ $years ${years == 1 ? 'سنة' : 'سنوات'}';
    }
  }
}
