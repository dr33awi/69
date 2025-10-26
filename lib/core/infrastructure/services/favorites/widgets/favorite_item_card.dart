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
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: context.dividerColor.withValues(alpha: 0.2),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8.r,
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
                  // أيقونة النوع
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      color: typeColor,
                      size: 16.sp,
                    ),
                  ),
                  
                  SizedBox(width: 8.w),
                  
                  // اسم النوع
                  Text(
                    item.contentType.displayName,
                    style: context.labelMedium?.copyWith(
                      color: typeColor,
                      fontSize: 12.sp,
                      fontWeight: ThemeConstants.semiBold,
                    ),
                  ),
                  
                  Spacer(),
                  
                  // زر المفضلة
                  IconButton(
                    icon: Icon(
                      Icons.bookmark_rounded,
                      color: typeColor,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onToggleFavorite();
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    splashRadius: 20.r,
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // العنوان
              Text(
                item.title,
                style: context.titleMedium?.copyWith(
                  fontWeight: ThemeConstants.semiBold,
                  color: context.textPrimaryColor,
                  fontSize: 16.sp,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // المحتوى
              if (item.content.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: typeColor.withValues(alpha: 0.1),
                      width: 1.w,
                    ),
                  ),
                  child: Text(
                    item.content,
                    style: context.bodyMedium?.copyWith(
                      color: context.textPrimaryColor,
                      fontSize: 14.sp,
                      height: 1.8,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              
              // الترجمة/الوصف
              if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  item.subtitle!,
                  style: context.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // المصدر والمرجع
              if (item.source != null || item.reference != null) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    if (item.source != null) ...[
                      Icon(
                        Icons.book_outlined,
                        size: 14.sp,
                        color: context.textSecondaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          '${item.source}${item.reference != null ? ' - ${item.reference}' : ''}',
                          style: context.bodySmall?.copyWith(
                            color: context.textSecondaryColor,
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              // التاريخ
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 12.sp,
                    color: context.textSecondaryColor.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDate(item.addedAt),
                    style: context.bodySmall?.copyWith(
                      color: context.textSecondaryColor.withValues(alpha: 0.7),
                      fontSize: 10.sp,
                    ),
                  ),
                  
                  if (item.lastAccessedAt != null) ...[
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.visibility_outlined,
                      size: 12.sp,
                      color: context.textSecondaryColor.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'آخر دخول ${_formatDate(item.lastAccessedAt!)}',
                      style: context.bodySmall?.copyWith(
                        color: context.textSecondaryColor.withValues(alpha: 0.7),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ],
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
