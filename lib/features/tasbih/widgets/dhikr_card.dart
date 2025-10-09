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
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: _buildShadows(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            decoration: _buildContainerDecoration(context),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: 10.h),
                  _buildDhikrText(context),
                  if (dhikr.virtue != null) ...[
                    SizedBox(height: 10.h),
                    _buildVirtueSection(context),
                  ],
                  if (isSelected) ...[
                    SizedBox(height: 10.h),
                    _buildSelectedIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _buildShadows() {
    return [
      BoxShadow(
        color: isSelected 
            ? dhikr.primaryColor.withOpacity(0.25)
            : Colors.black.withOpacity(0.05),
        blurRadius: isSelected ? 10.r : 6.r,
        offset: Offset(0, isSelected ? 4.h : 3.h),
      ),
    ];
  }

  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: isSelected 
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dhikr.gradient,
            )
          : null,
      color: !isSelected ? context.cardColor : null,
      borderRadius: BorderRadius.circular(14.r),
      border: isSelected 
          ? Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.w,
            )
          : Border.all(
              color: context.dividerColor.withOpacity(0.2),
              width: 1.w,
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildCategoryBadge(),
        const Spacer(),
        _buildCountBadge(context),
      ],
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.white.withOpacity(0.2)
            : dhikr.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dhikr.category.icon,
            size: 12.sp,
            color: isSelected ? Colors.white : dhikr.primaryColor,
          ),
          SizedBox(width: 3.w),
          Text(
            dhikr.category.title,
            style: TextStyle(
              color: isSelected ? Colors.white : dhikr.primaryColor,
              fontWeight: ThemeConstants.medium,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.white.withOpacity(0.2)
            : context.textSecondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        '${dhikr.recommendedCount}×',
        style: TextStyle(
          color: isSelected 
              ? Colors.white
              : context.textSecondaryColor,
          fontWeight: ThemeConstants.semiBold,
          fontSize: 10.sp,
        ),
      ),
    );
  }

  Widget _buildDhikrText(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.white.withOpacity(0.15)
            : dhikr.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
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
          fontSize: 14.sp,
          height: 1.6,
          fontFamily: ThemeConstants.fontFamilyArabic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildVirtueSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
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
            size: 14.sp,
            color: isSelected 
                ? Colors.white
                : ThemeConstants.accent,
          ),
          SizedBox(width: 6.w),
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
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  dhikr.virtue!,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.8)
                        : context.textSecondaryColor,
                    fontSize: 11.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedIndicator() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 6.h),
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
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            'مُحدد حالياً',
            style: TextStyle(
              color: Colors.white,
              fontWeight: ThemeConstants.semiBold,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// === بطاقة مدمجة للقوائم ===
class DhikrCardCompact extends StatelessWidget {
  final DhikrItem dhikr;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const DhikrCardCompact({
    super.key,
    required this.dhikr,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isSelected 
                ? dhikr.primaryColor.withOpacity(0.1)
                : context.cardColor,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected 
                  ? dhikr.primaryColor.withOpacity(0.3)
                  : context.dividerColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              _buildIcon(),
              SizedBox(width: 10.w),
              Expanded(child: _buildContent(context)),
              SizedBox(width: 10.w),
              _buildTrailing(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: EdgeInsets.all(6.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: dhikr.gradient),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        dhikr.category.icon,
        color: Colors.white,
        size: 14.sp,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dhikr.text,
                style: TextStyle(
                  fontWeight: isSelected 
                      ? ThemeConstants.semiBold 
                      : ThemeConstants.regular,
                  color: isSelected 
                      ? dhikr.primaryColor
                      : context.textPrimaryColor,
                  fontSize: 12.sp,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dhikr.isCustom) ...[
              SizedBox(width: 6.w),
              _buildCustomBadge(),
            ],
          ],
        ),
        if (dhikr.virtue != null) ...[
          SizedBox(height: 6.h),
          Text(
            dhikr.virtue!,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 10.sp,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildCustomBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: ThemeConstants.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        'مخصص',
        style: TextStyle(
          color: ThemeConstants.accent,
          fontSize: 9.sp,
          fontWeight: ThemeConstants.semiBold,
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: dhikr.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            '${dhikr.recommendedCount}×',
            style: TextStyle(
              color: dhikr.primaryColor,
              fontWeight: ThemeConstants.semiBold,
              fontSize: 10.sp,
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Icon(
          isSelected 
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: isSelected 
              ? dhikr.primaryColor
              : context.textSecondaryColor.withOpacity(0.3),
          size: 18.sp,
        ),
      ],
    );
  }
}