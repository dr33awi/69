// lib/features/dua/widgets/dua_item_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/dua_model.dart';

class DuaItemCard extends StatelessWidget {
  final DuaItem dua;
  final double fontSize;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onCopy;
  final bool showFullText;
  
  const DuaItemCard({
    super.key,
    required this.dua,
    this.fontSize = 18.0,
    required this.onTap,
    this.onFavorite,
    this.onShare,
    this.onCopy,
    this.showFullText = false,
  });

  @override
  Widget build(BuildContext context) {
    final duaType = DuaType.fromValue(dua.type);
    final cardColor = duaType.color;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: cardColor.withOpacity(0.2),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cardColor.withOpacity(0.1),
                    cardColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.r),
                  topRight: Radius.circular(15.r),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dua.title,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontWeight: ThemeConstants.bold,
                            fontSize: 14.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        if (dua.tags.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 4.h),
                            child: Wrap(
                              spacing: 4.w,
                              children: dua.tags.take(3).map((tag) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: cardColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // زر المفضلة
                  if (onFavorite != null)
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onFavorite!();
                      },
                      icon: Icon(
                        dua.isFavorite
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                        color: dua.isFavorite
                            ? ThemeConstants.accent
                            : context.textSecondaryColor,
                        size: 20.sp,
                      ),
                    ),
                ],
              ),
            ),
            
            // نص الدعاء
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.dividerColor.withOpacity(0.2),
                        width: 0.5.w,
                      ),
                    ),
                    child: Text(
                      dua.arabicText,
                      style: TextStyle(
                        fontSize: fontSize.sp,
                        fontFamily: ThemeConstants.fontFamilyArabic,
                        height: 1.8,
                        color: context.textPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: showFullText ? null : 4,
                      overflow: showFullText 
                          ? TextOverflow.visible 
                          : TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // النطق اللاتيني
                  if (dua.transliteration != null) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: ThemeConstants.info.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: ThemeConstants.info.withOpacity(0.2),
                          width: 0.5.w,
                        ),
                      ),
                      child: Text(
                        dua.transliteration!,
                        style: TextStyle(
                          fontSize: (fontSize - 4).sp,
                          color: ThemeConstants.info,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        maxLines: showFullText ? null : 3,
                        overflow: showFullText 
                            ? TextOverflow.visible 
                            : TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  
                  // الفضل
                  if (dua.virtue != null) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ThemeConstants.success.withOpacity(0.05),
                            ThemeConstants.success.withOpacity(0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: ThemeConstants.success.withOpacity(0.2),
                          width: 0.5.w,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: ThemeConstants.success,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              dua.virtue!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: context.textSecondaryColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // المصدر والمرجع
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 14.sp,
                        color: context.textSecondaryColor.withOpacity(0.7),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          '${dua.source} - ${dua.reference}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: context.textSecondaryColor.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // أزرار الإجراءات
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                color: context.dividerColor.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(15.r),
                  bottomRight: Radius.circular(15.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onCopy != null)
                    _buildActionButton(
                      icon: Icons.copy_rounded,
                      label: 'نسخ',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onCopy!();
                      },
                      context: context,
                    ),
                  
                  if (onShare != null)
                    _buildActionButton(
                      icon: Icons.share_rounded,
                      label: 'مشاركة',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onShare!();
                      },
                      context: context,
                    ),
                  
                  _buildActionButton(
                    icon: Icons.open_in_new_rounded,
                    label: 'التفاصيل',
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap();
                    },
                    isPrimary: true,
                    context: context,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
    bool isPrimary = false,
  }) {
    final color = isPrimary 
        ? DuaType.fromValue(dua.type).color
        : context.textSecondaryColor;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 6.h,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: color,
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: color,
                fontWeight: isPrimary ? ThemeConstants.medium : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}