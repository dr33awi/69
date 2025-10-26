// lib/app/themes/widgets/cards/app_card.dart (منظف)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme_constants.dart';
import '../../core/theme_extensions.dart';

/// أنواع البطاقات
enum CardType {
  normal,      // بطاقة عادية
  athkar,      // بطاقة أذكار
  quote,       // بطاقة اقتباس
  completion,  // بطاقة إكمال
  info,        // بطاقة معلومات
  stat,        // بطاقة إحصائيات
}

/// أنماط البطاقات
enum CardStyle {
  normal,        // عادي
  gradient,      // متدرج
  glassmorphism, // زجاجي
  outlined,      // محدد
  elevated,      // مرتفع
}

/// إجراءات البطاقة
class CardAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final bool isPrimary;

  const CardAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.isPrimary = false,
  });
}

/// بطاقة موحدة لجميع الاستخدامات
class AppCard extends StatelessWidget {
  // النوع والأسلوب
  final CardType type;
  final CardStyle style;
  
  // المحتوى الأساسي
  final String? title;
  final String? subtitle;
  final String? content;
  final Widget? child;
  
  // الأيقونات
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  
  // الألوان والتصميم
  final Color? primaryColor;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final double? elevation;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  
  // التفاعل
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final List<CardAction>? actions;
  
  // خصائص إضافية
  final bool isSelected;
  final bool showShadow;
  
  // خصائص خاصة بالأذكار
  final int? currentCount;
  final int? totalCount;
  final bool? isFavorite;
  final String? source;
  final VoidCallback? onFavoriteToggle;
  
  // خصائص خاصة بالإحصائيات
  final String? value;
  final String? unit;
  final double? progress;

  const AppCard({
    super.key,
    this.type = CardType.normal,
    this.style = CardStyle.normal,
    this.title,
    this.subtitle,
    this.content,
    this.child,
    this.icon,
    this.leading,
    this.trailing,
    this.primaryColor,
    this.backgroundColor,
    this.gradientColors,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.actions,
    this.isSelected = false,
    this.showShadow = true,
    this.currentCount,
    this.totalCount,
    this.isFavorite,
    this.source,
    this.onFavoriteToggle,
    this.value,
    this.unit,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    final effectiveColor = primaryColor ?? context.primaryColor;
    final effectiveBorderRadius = borderRadius ?? 20.r;
    
    return Container(
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ),
      child: Material(
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: _getDecoration(context, effectiveColor, effectiveBorderRadius),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(effectiveBorderRadius),
            child: Stack(
              children: [
                Padding(
                  padding: padding ?? EdgeInsets.all(16.w),
                  child: _buildContent(context),
                ),
                if (isSelected) _buildSelectionIndicator(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(BuildContext context, Color color, double radius) {
    final bgColor = backgroundColor ?? context.cardColor;
    
    // ظلال محسّنة موحدة
    final shadows = showShadow ? [
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
    ] : <BoxShadow>[];
    
    switch (style) {
      case CardStyle.gradient:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: ThemeConstants.customGradient(
            colors: gradientColors ?? [color, color.darken(0.2)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: shadows,
        );
        
      case CardStyle.glassmorphism:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: bgColor.withValues(alpha: ThemeConstants.opacity70),
          border: Border.all(
            color: context.isDarkMode ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: shadows,
        );
        
      case CardStyle.outlined:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: bgColor,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: shadows,
        );
        
      case CardStyle.elevated:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: bgColor,
          border: Border.all(
            color: context.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 16.r,
              offset: Offset(0, 6.h),
              spreadRadius: -2,
            ),
            ...shadows,
          ],
        );
        
      case CardStyle.normal:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: bgColor,
          border: Border.all(
            color: context.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: shadows,
        );
    }
  }

  Widget _buildContent(BuildContext context) {
    // إذا كان هناك child مخصص، استخدمه
    if (child != null) return child!;
    
    // بناء المحتوى حسب النوع
    switch (type) {
      case CardType.athkar:
        return _buildAthkarContent(context);
      case CardType.quote:
        return _buildQuoteContent(context);
      case CardType.completion:
        return _buildCompletionContent(context);
      case CardType.info:
        return _buildInfoContent(context);
      case CardType.stat:
        return _buildStatContent(context);
      case CardType.normal:
        return _buildNormalContent(context);
    }
  }

  Widget _buildNormalContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || leading != null || trailing != null)
          _buildHeader(context),
        if (subtitle != null) ...[
          if (title != null) SizedBox(height: 4.h),
          Text(
            subtitle!,
            style: context.bodyMedium?.textColor(_getTextColor(context, isSecondary: true)).copyWith(
              fontSize: context.bodyMedium?.fontSize?.sp,
            ),
          ),
        ],
        if (content != null) ...[
          SizedBox(height: 12.h),
          Text(
            content!,
            style: context.bodyLarge?.textColor(_getTextColor(context)).copyWith(
              fontSize: context.bodyLarge?.fontSize?.sp,
            ),
          ),
        ],
        if (actions != null && actions!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildActions(context),
        ],
      ],
    );
  }

  Widget _buildAthkarContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // الرأس مع العداد والمفضلة
        if (currentCount != null || onFavoriteToggle != null)
          _buildAthkarHeader(context),
        
        if (currentCount != null || onFavoriteToggle != null)
          SizedBox(height: 12.h),
        
        // محتوى الذكر
        _buildAthkarBody(context),
        
        // المصدر
        if (source != null) ...[
          SizedBox(height: 12.h),
          _buildSource(context),
        ],
        
        // الإجراءات
        if (actions != null && actions!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildActions(context),
        ],
      ],
    );
  }

  Widget _buildQuoteContent(BuildContext context) {
    final effectiveColor = primaryColor ?? context.primaryColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (subtitle != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: ThemeConstants.opacity20),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              subtitle!,
              style: context.labelMedium?.textColor(_getTextColor(context)).semiBold.copyWith(
                fontSize: context.labelMedium?.fontSize?.sp,
              ),
            ),
          ),
        
        if (subtitle != null) SizedBox(height: 12.h),
        
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _getTextColor(context).withValues(alpha: ThemeConstants.opacity10),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _getTextColor(context).withValues(alpha: ThemeConstants.opacity20),
              width: 1.w,
            ),
          ),
          child: Stack(
            children: [
              // علامة اقتباس في البداية
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.format_quote,
                  size: 20.sp,
                  color: Colors.black26,
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  content ?? title ?? '',
                  textAlign: TextAlign.center,
                  style: context.bodyLarge?.textColor(_getTextColor(context)).copyWith(
                    fontSize: 18.sp,
                    height: 1.8,
                  ),
                ),
              ),
              
              // علامة اقتباس في النهاية
              Positioned(
                bottom: 0,
                left: 0,
                child: Transform.rotate(
                  angle: 3.14159,
                  child: Icon(
                    Icons.format_quote,
                    size: 20.sp,
                    color: _getTextColor(context).withValues(alpha: ThemeConstants.opacity50),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        if (source != null) ...[
          SizedBox(height: 12.h),
          _buildSource(context),
        ],
      ],
    );
  }

  Widget _buildCompletionContent(BuildContext context) {
    final effectiveColor = primaryColor ?? context.primaryColor;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الأيقونة
        Container(
          width: 80.w,
          height: 80.h,
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: ThemeConstants.opacity10),
            shape: BoxShape.circle,
            border: Border.all(
              color: effectiveColor.withValues(alpha: ThemeConstants.opacity30),
              width: 2.w,
            ),
          ),
          child: Icon(
            icon ?? Icons.check_circle_outline,
            color: effectiveColor,
            size: 40.sp,
          ),
        ),
        
        SizedBox(height: 20.h),
        
        // العنوان
        if (title != null)
          Text(
            title!,
            style: context.headlineMedium?.textColor(_getTextColor(context)).copyWith(
              fontSize: context.headlineMedium?.fontSize?.sp,
            ),
            textAlign: TextAlign.center,
          ),
        
        if (content != null) ...[
          SizedBox(height: 12.h),
          Text(
            content!,
            textAlign: TextAlign.center,
            style: context.bodyLarge?.textColor(_getTextColor(context)).copyWith(
              fontSize: context.bodyLarge?.fontSize?.sp,
            ),
          ),
        ],
        
        if (subtitle != null) ...[
          SizedBox(height: 8.h),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: context.bodyMedium?.textColor(_getTextColor(context, isSecondary: true)).copyWith(
              fontSize: context.bodyMedium?.fontSize?.sp,
            ),
          ),
        ],
        
        if (actions != null && actions!.isNotEmpty) ...[
          SizedBox(height: 24.h),
          _buildActions(context),
        ],
      ],
    );
  }

  Widget _buildInfoContent(BuildContext context) {
    final effectiveColor = primaryColor ?? context.primaryColor;
    
    return Row(
      children: [
        if (icon != null)
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: ThemeConstants.opacity10),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: effectiveColor,
              size: 32.sp,
            ),
          ),
        
        if (icon != null) SizedBox(width: 16.w),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: context.titleMedium?.semiBold.textColor(_getTextColor(context)).copyWith(
                    fontSize: context.titleMedium?.fontSize?.sp,
                  ),
                ),
              if (subtitle != null) ...[
                SizedBox(height: 4.h),
                Text(
                  subtitle!,
                  style: context.bodyMedium?.textColor(_getTextColor(context, isSecondary: true)).copyWith(
                    fontSize: context.bodyMedium?.fontSize?.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        if (trailing != null) trailing!,
      ],
    );
  }

  Widget _buildStatContent(BuildContext context) {
    final effectiveColor = primaryColor ?? context.primaryColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: effectiveColor,
                size: 32.sp,
              ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20.sp,
                color: _getTextColor(context, isSecondary: true),
              ),
          ],
        ),
        
        SizedBox(height: 8.h),
        
        if (value != null)
          Text(
            value!,
            style: context.headlineMedium?.textColor(effectiveColor).bold.copyWith(
              fontSize: context.headlineMedium?.fontSize?.sp,
            ),
          ),
        
        if (title != null) ...[
          SizedBox(height: 4.h),
          Text(
            title!,
            style: context.bodyMedium?.textColor(_getTextColor(context, isSecondary: true)).copyWith(
              fontSize: context.bodyMedium?.fontSize?.sp,
            ),
          ),
        ],
        
        if (progress != null) ...[
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(999.r),
            child: LinearProgressIndicator(
              value: progress!,
              minHeight: 4.h,
              backgroundColor: context.dividerColor.withValues(alpha: ThemeConstants.opacity50),
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final effectiveColor = primaryColor ?? context.primaryColor;
    
    return Row(
      children: [
        if (leading != null)
          leading!
        else if (icon != null)
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: ThemeConstants.opacity10),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: effectiveColor,
              size: 24.sp,
            ),
          ),
        
        if ((leading != null || icon != null) && title != null)
          SizedBox(width: 12.w),
        
        if (title != null)
          Expanded(
            child: Text(
              title!,
              style: context.titleMedium?.textColor(_getTextColor(context)).semiBold.copyWith(
                fontSize: context.titleMedium?.fontSize?.sp,
              ),
            ),
          ),
        
        if (trailing != null) trailing!,
      ],
    );
  }

  Widget _buildAthkarHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentCount != null && totalCount != null)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: ThemeConstants.opacity20),
              borderRadius: BorderRadius.circular(999.r),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 4.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  SizedBox(width: 4.w),
                ],
                Text(
                  'عدد التكرار $currentCount/$totalCount',
                  style: context.labelMedium?.textColor(Colors.white).semiBold.copyWith(
                    fontSize: context.labelMedium?.fontSize?.sp,
                  ),
                ),
              ],
            ),
          ),
        
        if (onFavoriteToggle != null)
          IconButton(
            icon: Icon(
              isFavorite == true ? Icons.favorite : Icons.favorite_border,
              color: style == CardStyle.gradient ? Colors.white : primaryColor ?? context.primaryColor,
              size: 24.sp,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              onFavoriteToggle!();
            },
            tooltip: isFavorite == true ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
          ),
      ],
    );
  }

  Widget _buildAthkarBody(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: style == CardStyle.gradient 
            ? Colors.white.withValues(alpha: ThemeConstants.opacity10)
            : (primaryColor ?? context.primaryColor).withValues(alpha: ThemeConstants.opacity10),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: style == CardStyle.gradient
              ? Colors.white.withValues(alpha: ThemeConstants.opacity20)
              : (primaryColor ?? context.primaryColor).withValues(alpha: ThemeConstants.opacity20),
          width: 1.w,
        ),
      ),
      child: Text(
        content ?? title ?? '',
        textAlign: TextAlign.center,
        style: context.bodyLarge?.textColor(_getTextColor(context)).copyWith(
          fontSize: 20.sp,
          fontFamily: ThemeConstants.fontFamilyArabic,
          fontWeight: ThemeConstants.semiBold,
          height: 2.0,
        ),
      ),
    );
  }

  Widget _buildSource(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: style == CardStyle.gradient
              ? Colors.black.withValues(alpha: ThemeConstants.opacity20)
              : (primaryColor ?? context.primaryColor).withValues(alpha: ThemeConstants.opacity10),
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Text(
          source!,
          style: context.labelLarge?.textColor(_getTextColor(context)).semiBold.copyWith(
            fontSize: context.labelLarge?.fontSize?.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    // للبطاقات من نوع completion، عرض الإجراءات بشكل عمودي
    if (type == CardType.completion) {
      return Column(
        children: actions!.map((action) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildActionButton(context, action, fullWidth: true),
        )).toList(),
      );
    }
    
    // للبطاقات الأخرى، عرض الإجراءات بشكل أفقي
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: actions!.map((action) => _buildActionButton(context, action)).toList(),
    );
  }

  Widget _buildActionButton(BuildContext context, CardAction action, {bool fullWidth = false}) {
    final effectiveColor = action.color ?? primaryColor ?? context.primaryColor;
    
    if (action.isPrimary) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            action.onPressed();
          },
          icon: Icon(action.icon, size: 20.sp),
          label: Text(action.label, style: TextStyle(fontSize: 14.sp)),
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveColor,
            foregroundColor: effectiveColor.contrastingTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      );
    }
    
    // زر ثانوي
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onPressed();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ),
          decoration: BoxDecoration(
            color: style == CardStyle.gradient
                ? Colors.white.withValues(alpha: ThemeConstants.opacity20)
                : effectiveColor.withValues(alpha: ThemeConstants.opacity10),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: style == CardStyle.gradient
                  ? Colors.white.withValues(alpha: ThemeConstants.opacity30)
                  : effectiveColor.withValues(alpha: ThemeConstants.opacity30),
              width: 1.w,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                color: style == CardStyle.gradient ? Colors.white : effectiveColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                action.label,
                style: context.labelMedium?.textColor(
                  style == CardStyle.gradient ? Colors.white : effectiveColor
                ).semiBold.copyWith(
                  fontSize: context.labelMedium?.fontSize?.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(BuildContext context) {
    final effectiveColor = primaryColor ?? context.primaryColor;
    
    return Positioned(
      top: 8.h,
      right: 8.w,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: effectiveColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: backgroundColor ?? context.cardColor,
            width: 1.5.w,
          ),
        ),
        child: Icon(
          Icons.check,
          color: effectiveColor.contrastingTextColor,
          size: 20.sp,
        ),
      ),
    );
  }

  Color _getTextColor(BuildContext context, {bool isSecondary = false}) {
    if (style == CardStyle.gradient) {
      return Colors.white.withValues(alpha: isSecondary ? ThemeConstants.opacity70 : 1.0);
    }
    
    if (backgroundColor != null) {
      return backgroundColor!.contrastingTextColor.withValues(
        alpha: isSecondary ? ThemeConstants.opacity70 : 1.0
      );
    }
    
    return isSecondary ? context.textSecondaryColor : context.textPrimaryColor;
  }

  // Factory constructors الضرورية فقط
  factory AppCard.athkar({
    required String content,
    String? source,
    int currentCount = 0,
    int totalCount = 1,
    bool isFavorite = false,
    Color? primaryColor,
    VoidCallback? onTap,
    VoidCallback? onFavoriteToggle,
    List<CardAction>? actions,
  }) {
    return AppCard(
      type: CardType.athkar,
      style: CardStyle.gradient,
      content: content,
      source: source,
      currentCount: currentCount,
      totalCount: totalCount,
      isFavorite: isFavorite,
      primaryColor: primaryColor,
      onTap: onTap,
      onFavoriteToggle: onFavoriteToggle,
      actions: actions,
    );
  }

  factory AppCard.info({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    return AppCard(
      type: CardType.info,
      title: title,
      subtitle: subtitle,
      icon: icon,
      onTap: onTap,
      primaryColor: iconColor,
      trailing: trailing,
    );
  }

  factory AppCard.stat({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
    double? progress,
  }) {
    return AppCard(
      type: CardType.stat,
      title: title,
      value: value,
      icon: icon,
      primaryColor: color,
      onTap: onTap,
      progress: progress,
    );
  }
}