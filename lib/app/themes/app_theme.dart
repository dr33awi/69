// lib/app/themes/app_theme.dart - محدث مع flutter_screenutil
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// الاستيرادات المصححة
import 'core/color_helper.dart';
import 'core/theme_extensions.dart';
import 'text_styles.dart';
import 'theme_constants.dart';

// Barrel Exports
export 'core/color_helper.dart';
export 'core/color_utils.dart';
export 'core/theme_extensions.dart';
export 'text_styles.dart';
export 'theme_constants.dart';

// Widgets exports
export 'widgets/cards/app_card.dart';
export 'widgets/dialogs/app_info_dialog.dart';
export 'widgets/feedback/app_snackbar.dart';
export 'widgets/feedback/app_notice_card.dart';
export 'widgets/layout/app_bar.dart';
export 'widgets/states/app_empty_state.dart';
export 'widgets/core/app_button.dart';
export 'widgets/core/app_text_field.dart';
export 'widgets/core/app_loading.dart';

/// نظام الثيم الموحد للتطبيق
class AppTheme {
  AppTheme._();

  /// الثيم الفاتح
  static ThemeData get lightTheme => _buildTheme(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    backgroundColor: AppColors.lightBackground,
    surfaceColor: AppColors.lightSurface,
    cardColor: AppColors.lightCard,
    textPrimaryColor: AppColors.lightTextPrimary,
    textSecondaryColor: AppColors.lightTextSecondary,
    dividerColor: AppColors.lightDivider,
  );

  /// الثيم الداكن
  static ThemeData get darkTheme => _buildTheme(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryLight,
    backgroundColor: AppColors.darkBackground,
    surfaceColor: AppColors.darkSurface,
    cardColor: AppColors.darkCard,
    textPrimaryColor: AppColors.darkTextPrimary,
    textSecondaryColor: AppColors.darkTextSecondary,
    dividerColor: AppColors.darkDivider,
  );

  /// بناء الثيم الموحد مع ScreenUtil
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color cardColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required Color dividerColor,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final Color onPrimaryColor = primaryColor.contrastingTextColor;
    final Color onSecondaryColor = AppColors.accent.contrastingTextColor;

    // Create text theme
    final textTheme = AppTextStyles.createTextTheme(
      color: textPrimaryColor,
      secondaryColor: textSecondaryColor,
    );

    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,
      fontFamily: ThemeConstants.fontFamily,
      
      // ColorScheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        secondary: AppColors.accent,
        onSecondary: onSecondaryColor,
        tertiary: AppColors.accentLight,
        onTertiary: AppColors.accentLight.contrastingTextColor,
        error: AppColors.error,
        onError: Colors.white,
        surface: backgroundColor,
        onSurface: textPrimaryColor,
        surfaceContainerHighest: cardColor,
        onSurfaceVariant: textSecondaryColor,
        outline: dividerColor,
      ),
      
      // AppBar Theme مع ScreenUtil
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h4.copyWith(color: textPrimaryColor),
        iconTheme: IconThemeData(
          color: textPrimaryColor,
          size: 24.sp,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      
      // Card Theme مع ScreenUtil
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: ThemeConstants.elevationNone,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      
      // Text Theme
      textTheme: textTheme,
      
      // Button Themes مع ScreenUtil
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedButtonStyle(primaryColor, onPrimaryColor),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(primaryColor),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(primaryColor),
      ),
      
      // Input Theme مع ScreenUtil
      inputDecorationTheme: _inputDecorationTheme(
        isDark: isDark,
        primaryColor: primaryColor,
        surfaceColor: surfaceColor,
        dividerColor: dividerColor,
        textSecondaryColor: textSecondaryColor,
      ),
      
      // Other Themes مع ScreenUtil
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1.w,
        space: 4.h,
      ),
      
      iconTheme: IconThemeData(
        color: textPrimaryColor,
        size: 24.sp,
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: dividerColor.withValues(alpha: ThemeConstants.opacity50),
        circularTrackColor: dividerColor.withValues(alpha: ThemeConstants.opacity50),
      ),
      
      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      
      // Bottom Navigation مع ScreenUtil
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor.withValues(alpha: ThemeConstants.opacity70),
        type: BottomNavigationBarType.fixed,
        elevation: ThemeConstants.elevation8,
        selectedLabelStyle: AppTextStyles.label2.copyWith(
          fontWeight: ThemeConstants.semiBold,
        ),
        unselectedLabelStyle: AppTextStyles.label2,
        selectedIconTheme: IconThemeData(size: 24.sp),
        unselectedIconTheme: IconThemeData(size: 24.sp),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return dividerColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: ThemeConstants.opacity50);
          }
          return dividerColor.withValues(alpha: ThemeConstants.opacity30);
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onPrimaryColor),
        side: BorderSide(
          color: dividerColor,
          width: 2.w,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return dividerColor;
        }),
      ),
      
      // Chip Theme مع ScreenUtil
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        deleteIconColor: textSecondaryColor,
        labelStyle: AppTextStyles.label2.copyWith(color: textPrimaryColor),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        side: BorderSide(
          color: dividerColor,
          width: 1.w,
        ),
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        minVerticalPadding: 8.h,
        horizontalTitleGap: 12.w,
        iconColor: textSecondaryColor,
        textColor: textPrimaryColor,
        titleTextStyle: AppTextStyles.body1.copyWith(color: textPrimaryColor),
        subtitleTextStyle: AppTextStyles.body2.copyWith(color: textSecondaryColor),
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        labelStyle: AppTextStyles.label1,
        unselectedLabelStyle: AppTextStyles.label2,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: primaryColor,
            width: 2.h,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: ThemeConstants.elevation6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      
      // Dialog Theme مع ScreenUtil
      dialogTheme: DialogTheme(
        backgroundColor: cardColor,
        elevation: ThemeConstants.elevation8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        titleTextStyle: AppTextStyles.h4.copyWith(color: textPrimaryColor),
        contentTextStyle: AppTextStyles.body1.copyWith(color: textPrimaryColor),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        elevation: ThemeConstants.elevation8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? cardColor : primaryColor,
        contentTextStyle: AppTextStyles.body2.copyWith(
          color: isDark ? textPrimaryColor : Colors.white,
        ),
        actionTextColor: AppColors.accentLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Button Styles مع ScreenUtil
  static ButtonStyle _elevatedButtonStyle(Color primaryColor, Color onPrimaryColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      disabledBackgroundColor: AppColors.lightTextHint.withValues(alpha: ThemeConstants.opacity30),
      disabledForegroundColor: AppColors.lightTextHint.withValues(alpha: ThemeConstants.opacity70),
      elevation: ThemeConstants.elevationNone,
      padding: EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 16.h,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      textStyle: AppTextStyles.button,
      minimumSize: Size(48.w, 52.h),
    );
  }

  static ButtonStyle _outlinedButtonStyle(Color primaryColor) {
    return OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: BorderSide(
        color: primaryColor,
        width: 1.5.w,
      ),
      disabledForegroundColor: AppColors.lightTextHint.withValues(alpha: ThemeConstants.opacity70),
      padding: EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 16.h,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      textStyle: AppTextStyles.button,
      minimumSize: Size(48.w, 52.h),
    );
  }

  static ButtonStyle _textButtonStyle(Color primaryColor) {
    return TextButton.styleFrom(
      foregroundColor: primaryColor,
      disabledForegroundColor: AppColors.lightTextHint.withValues(alpha: ThemeConstants.opacity70),
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      textStyle: AppTextStyles.button,
    );
  }

  // Input Decoration Theme مع ScreenUtil
  static InputDecorationTheme _inputDecorationTheme({
    required bool isDark,
    required Color primaryColor,
    required Color surfaceColor,
    required Color dividerColor,
    required Color textSecondaryColor,
  }) {
    return InputDecorationTheme(
      fillColor: surfaceColor.withValues(
        alpha: isDark ? ThemeConstants.opacity10 : ThemeConstants.opacity50
      ),
      filled: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 16.h,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: dividerColor,
          width: 1.w,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: dividerColor,
          width: 1.w,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: primaryColor,
          width: 2.w,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 1.w,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 2.w,
        ),
      ),
      hintStyle: AppTextStyles.body2.copyWith(
        color: textSecondaryColor.withValues(alpha: ThemeConstants.opacity70),
      ),
      labelStyle: AppTextStyles.body2.copyWith(color: textSecondaryColor),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
      alignLabelWithHint: true,
    );
  }
}