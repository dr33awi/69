// lib/features/dua/widgets/dua_item_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/infrastructure/services/text_settings/extensions/text_settings_extensions.dart';
import '../../../core/infrastructure/services/text_settings/models/text_settings_models.dart';
import '../models/dua_model.dart';

class DuaItemCard extends StatelessWidget {
  final DuaItem dua;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onCopy;
  final Color? categoryColor;
  
  const DuaItemCard({
    super.key,
    required this.dua,
    required this.onTap,
    this.onFavorite,
    this.onShare,
    this.onCopy,
    this.categoryColor,
  });

  Color _getCategoryColor(BuildContext context) {
    if (categoryColor != null) {
      return categoryColor!;
    }
    
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
        return DuaType.fromValue(dua.type).color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final duaType = DuaType.fromValue(dua.type);
    final cardColor = _getCategoryColor(context);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: cardColor.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.06),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.08 : 0.03),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
                spreadRadius: -1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, duaType, cardColor),
              _buildContent(context, cardColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DuaType duaType, Color cardColor) {
    return Container(
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
    );
  }

  Widget _buildContent(BuildContext context, Color cardColor) {
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نص الدعاء مع الإعدادات الموحدة
          FutureBuilder<DisplaySettings>(
            future: context.getDisplaySettings(ContentType.dua),
            builder: (context, displaySnapshot) {
              if (!displaySnapshot.hasData) {
                return _buildDefaultText(context);
              }
              
              return AdaptiveText(
                displaySnapshot.data!.showTashkeel 
                    ? dua.arabicText 
                    : dua.arabicText.removeTashkeel(),
                contentType: ContentType.dua,
                color: context.textPrimaryColor,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                applyDisplaySettings: false, // لأننا طبقناها يدوياً
              );
            },
          ),
          
          SizedBox(height: 10.h),
          
          _buildFooter(context, cardColor),
        ],
      ),
    );
  }

  Widget _buildDefaultText(BuildContext context) {
    return Text(
      dua.arabicText,
      style: TextStyle(
        fontSize: 18.sp,
        fontFamily: 'Scheherazade New',
        height: 1.9,
        color: context.textPrimaryColor,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    );
  }

  Widget _buildFooter(BuildContext context, Color cardColor) {
    return Row(
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
    );
  }
}