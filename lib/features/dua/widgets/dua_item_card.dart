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
  final Color? categoryColor; // لون الفئة
  
  const DuaItemCard({
    super.key,
    required this.dua,
    this.fontSize = 18.0,
    required this.onTap,
    this.onFavorite,
    this.onShare,
    this.onCopy,
    this.categoryColor,
  });

  Color _getCategoryColor(BuildContext context) {
    // استخدام لون الفئة إذا كان متوفراً، وإلا استخدام لون النوع
    if (categoryColor != null) {
      return categoryColor!;
    }
    
    // استخدام لون حسب categoryId
    switch (dua.categoryId) {
      case 'quran':
        return ThemeConstants.primary;
      case 'sahihain':
        return ThemeConstants.accent;
      case 'sunan':
        return ThemeConstants.tertiary;
      case 'other_authentic':
        return ThemeConstants.primaryDark;
      default:
        // استخدام لون النوع كاحتياطي
        return DuaType.fromValue(dua.type).color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final duaType = DuaType.fromValue(dua.type);
    final cardColor = _getCategoryColor(context);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16.r),
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
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
                    // أيقونة النوع
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        duaType.icon,
                        color: cardColor,
                        size: 16.sp,
                      ),
                    ),
                    
                    SizedBox(width: 10.w),
                    
                    // العنوان
                    Expanded(
                      child: Text(
                        dua.title,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 14.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
              
              // نص الدعاء المختصر
              Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // النص العربي المختصر
                    Text(
                      dua.arabicText,
                      style: TextStyle(
                        fontSize: fontSize.sp,
                        fontFamily: ThemeConstants.fontFamilyArabic,
                        height: 1.8,
                        color: context.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                    
                    SizedBox(height: 10.h),
                    
                    // المصدر وزر التفاصيل
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 12.sp,
                          color: context.textSecondaryColor.withOpacity(0.7),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            '${dua.source} - ${dua.reference}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: context.textSecondaryColor.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        SizedBox(width: 8.w),
                        
                        // زر عرض التفاصيل
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: cardColor.withOpacity(0.3),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'التفاصيل',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: cardColor,
                                  fontWeight: ThemeConstants.medium,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.arrow_back_ios_rounded,
                                size: 12.sp,
                                color: cardColor,
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
      ),
    );
  }
}