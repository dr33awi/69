// lib/app/themes/theme_constants.dart - محدث مع flutter_screenutil
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/color_helper.dart';
import 'constants/app_constants.dart';

/// ثوابت الثيم - استخدام AppColors و AppConstants مع ScreenUtil
class ThemeConstants {
  ThemeConstants._();

  // ===== الألوان من AppColors (تبقى كما هي) =====
  static const Color primary = Color(0xFF5D7052);
  static const Color primaryLight = AppColors.primaryLight;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primarySoft = AppColors.primarySoft;

  static const Color accent = AppColors.accent;
  static const Color accentLight = AppColors.accentLight;
  static const Color accentDark = AppColors.accentDark;
  
  static const Color tertiary = AppColors.tertiary;
  static const Color tertiaryLight = AppColors.tertiaryLight;
  static const Color tertiaryDark = AppColors.tertiaryDark;

  static const Color success = AppColors.success;
  static const Color error = AppColors.error;
  static const Color warning = AppColors.warning;
  static const Color info = AppColors.info;

  // ===== ألوان الوضع الفاتح =====
  static const Color lightBackground = AppColors.lightBackground;
  static const Color lightSurface = AppColors.lightSurface;
  static const Color lightCard = AppColors.lightCard;
  static const Color lightDivider = AppColors.lightDivider;
  static const Color lightTextPrimary = AppColors.lightTextPrimary;
  static const Color lightTextSecondary = AppColors.lightTextSecondary;
  static const Color lightTextHint = AppColors.lightTextHint;

  // ===== ألوان الوضع الداكن =====
  static const Color darkBackground = AppColors.darkBackground;
  static const Color darkSurface = AppColors.darkSurface;
  static const Color darkCard = AppColors.darkCard;
  static const Color darkDivider = AppColors.darkDivider;
  static const Color darkTextPrimary = AppColors.darkTextPrimary;
  static const Color darkTextSecondary = AppColors.darkTextSecondary;
  static const Color darkTextHint = AppColors.darkTextHint;

  // ===== الخطوط (ثابتة) =====
  static const String fontFamily = AppConstants.fontFamily;
  static const String fontFamilyArabic = AppConstants.fontFamilyArabic;
  static const String fontFamilyQuran = AppConstants.fontFamilyQuran;

  // ===== أوزان الخطوط (ثابتة) =====
  static const FontWeight light = AppConstants.light;
  static const FontWeight regular = AppConstants.regular;
  static const FontWeight medium = AppConstants.medium;
  static const FontWeight semiBold = AppConstants.semiBold;
  static const FontWeight bold = AppConstants.bold;

  // ===== أحجام النصوص مع ScreenUtil (ديناميكية) =====
  static double get textSizeXs => 11.sp;
  static double get textSizeSm => 12.sp;
  static double get textSizeMd => 14.sp;
  static double get textSizeLg => 16.sp;
  static double get textSizeXl => 18.sp;
  static double get textSize2xl => 20.sp;
  static double get textSize3xl => 24.sp;
  static double get textSize4xl => 28.sp;
  static double get textSize5xl => 32.sp;

  // ===== المسافات مع ScreenUtil (ديناميكية) =====
  static double get space0 => 0.w;
  static double get space1 => 4.w;
  static double get space2 => 8.w;
  static double get space3 => 12.w;
  static double get space4 => 16.w;
  static double get space5 => 20.w;
  static double get space6 => 24.w;
  static double get space8 => 32.w;
  static double get space10 => 40.w;
  static double get space12 => 48.w;
  static double get space16 => 64.w;

  // ===== نصف القطر مع ScreenUtil (ديناميكية) =====
  static double get radiusNone => 0.r;
  static double get radiusXs => 4.r;
  static double get radiusSm => 8.r;
  static double get radiusMd => 12.r;
  static double get radiusLg => 16.r;
  static double get radiusXl => 20.r;
  static double get radius2xl => 24.r;
  static double get radius3xl => 28.r;
  static double get radiusFull => 999.r;

  // ===== الحدود مع ScreenUtil (ديناميكية) =====
  static double get borderNone => 0.w;
  static double get borderThin => 0.5.w;
  static double get borderLight => 1.w;
  static double get borderMedium => 1.5.w;
  static double get borderThick => 2.w;
  static double get borderHeavy => 3.w;

  // ===== أحجام الأيقونات مع ScreenUtil (ديناميكية) =====
  static double get iconXs => 16.sp;
  static double get iconSm => 20.sp;
  static double get iconMd => 24.sp;
  static double get iconLg => 32.sp;
  static double get iconXl => 40.sp;
  static double get icon2xl => 48.sp;
  static double get icon3xl => 56.sp;

  // ===== الارتفاعات مع ScreenUtil (ديناميكية) =====
  static double get heightXs => 32.h;
  static double get heightSm => 36.h;
  static double get heightMd => 40.h;
  static double get heightLg => 48.h;
  static double get heightXl => 56.h;
  static double get height2xl => 64.h;
  static double get height3xl => 72.h;

  // ===== مكونات خاصة مع ScreenUtil (ديناميكية) =====
  static double get appBarHeight => 64.h;
  static double get bottomNavHeight => 64.h;
  static double get buttonHeight => 52.h;
  static double get inputHeight => 56.h;
  static double get fabSize => 56.w;
  static double get fabSizeMini => 40.w;

  // ===== الظلال (ثابتة) =====
  static const double elevationNone = AppConstants.elevationNone;
  static const double elevation1 = AppConstants.elevation1;
  static const double elevation2 = AppConstants.elevation2;
  static const double elevation4 = AppConstants.elevation4;
  static const double elevation6 = AppConstants.elevation6;
  static const double elevation8 = AppConstants.elevation8;
  static const double elevation12 = AppConstants.elevation12;
  static const double elevation16 = AppConstants.elevation16;

  // ===== الشفافية (ثابتة) =====
  static const double opacity5 = AppConstants.opacity5;
  static const double opacity05 = AppConstants.opacity05;
  static const double opacity10 = AppConstants.opacity10;
  static const double opacity20 = AppConstants.opacity20;
  static const double opacity30 = AppConstants.opacity30;
  static const double opacity40 = AppConstants.opacity40;
  static const double opacity50 = AppConstants.opacity50;
  static const double opacity60 = AppConstants.opacity60;
  static const double opacity70 = AppConstants.opacity70;
  static const double opacity80 = AppConstants.opacity80;
  static const double opacity90 = AppConstants.opacity90;

  // ===== مدد الحركات (ثابتة) =====
  static const Duration durationInstant = AppConstants.durationInstant;
  static const Duration durationFast = AppConstants.durationFast;
  static const Duration durationNormal = AppConstants.durationNormal;
  static const Duration durationSlow = AppConstants.durationSlow;
  static const Duration durationVerySlow = AppConstants.durationVerySlow;
  static const Duration durationExtraSlow = AppConstants.durationExtraSlow;

  // ===== منحنيات الحركة (ثابتة) =====
  static const Curve curveDefault = AppConstants.curveDefault;
  static const Curve curveSharp = AppConstants.curveSharp;
  static const Curve curveSmooth = AppConstants.curveSmooth;
  static const Curve curveBounce = AppConstants.curveBounce;
  static const Curve curveOvershoot = AppConstants.curveOvershoot;
  static const Curve curveAnticipate = AppConstants.curveAnticipate;

  // ===== نقاط التوقف للتصميم المتجاوب مع ScreenUtil =====
  static double get breakpointMobile => 600.w;
  static double get breakpointTablet => 1024.w;
  static double get breakpointDesktop => 1440.w;
  static double get breakpointWide => 1920.w;

  // ===== الأيقونات المشتركة (ثابتة) =====
  static const IconData iconPrayer = AppConstants.iconPrayer;
  static const IconData iconPrayerTime = AppConstants.iconPrayerTime;
  static const IconData iconQibla = AppConstants.iconQibla;
  static const IconData iconAdhan = AppConstants.iconAdhan;
  static const IconData iconAthkar = AppConstants.iconAthkar;
  static const IconData iconMorningAthkar = AppConstants.iconMorningAthkar;
  static const IconData iconEveningAthkar = AppConstants.iconEveningAthkar;
  static const IconData iconSleepAthkar = AppConstants.iconSleepAthkar;
  static const IconData iconFavorite = AppConstants.iconFavorite;
  static const IconData iconFavoriteOutline = AppConstants.iconFavoriteOutline;
  static const IconData iconShare = AppConstants.iconShare;
  static const IconData iconCopy = AppConstants.iconCopy;
  static const IconData iconSettings = AppConstants.iconSettings;
  static const IconData iconNotifications = AppConstants.iconNotifications;

  // ===== ثوابت التطبيق (ثابتة) =====
  static const Duration defaultCacheDuration = AppConstants.defaultCacheDuration;
  static const Duration splashDuration = AppConstants.splashDuration;
  static const Duration debounceDelay = AppConstants.debounceDelay;
  static const int defaultMinBatteryLevel = AppConstants.defaultMinBatteryLevel;
  static const int criticalBatteryLevel = AppConstants.criticalBatteryLevel;

  // ===== التدرجات اللونية (ثابتة) =====
  static const LinearGradient primaryGradient = AppColors.primaryGradient;
  static const LinearGradient accentGradient = AppColors.accentGradient;
  static const LinearGradient tertiaryGradient = AppColors.tertiaryGradient;

  // ===== الظلال الجاهزة مع ScreenUtil =====
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: primary.withValues(alpha: opacity5),
      blurRadius: 4.r,
      offset: Offset(0, 2.h),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: primary.withValues(alpha: opacity10),
      blurRadius: 8.r,
      offset: Offset(0, 4.h),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: primary.withValues(alpha: opacity10),
      blurRadius: 16.r,
      offset: Offset(0, 8.h),
    ),
  ];

  static List<BoxShadow> get shadowXl => [
    BoxShadow(
      color: primary.withValues(alpha: opacity20),
      blurRadius: 24.r,
      offset: Offset(0, 12.h),
    ),
  ];

  // ===== دوال مساعدة موحدة =====
  static Color background(BuildContext context) => AppColors.getBackground(
    Theme.of(context).brightness == Brightness.dark
  );

  static Color surface(BuildContext context) => AppColors.getSurface(
    Theme.of(context).brightness == Brightness.dark
  );

  static Color card(BuildContext context) => AppColors.getCard(
    Theme.of(context).brightness == Brightness.dark
  );

  static Color textPrimary(BuildContext context) => AppColors.getTextPrimary(
    Theme.of(context).brightness == Brightness.dark
  );

  static Color textSecondary(BuildContext context) => AppColors.getTextSecondary(
    Theme.of(context).brightness == Brightness.dark
  );

  static Color divider(BuildContext context) => AppColors.getDivider(
    Theme.of(context).brightness == Brightness.dark
  );

  /// الحصول على ظل حسب الارتفاع
  static List<BoxShadow> shadowForElevation(double elevation) {
    if (elevation <= 0) return [];
    if (elevation <= 2) return shadowSm;
    if (elevation <= 4) return shadowMd;
    if (elevation <= 8) return shadowLg;
    return shadowXl;
  }

  /// استخدام دوال AppColors
  static LinearGradient customGradient({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<double>? stops,
  }) => AppColors.createCustomGradient(
    colors: colors,
    begin: begin,
    end: end,
    stops: stops,
  );

  static LinearGradient prayerGradient(String prayerName) => 
    AppColors.getPrayerGradient(prayerName);

  static Color getPrayerColor(String name) => AppColors.getPrayerColor(name);
  
  static IconData getPrayerIcon(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
      case 'الفجر':
        return Icons.dark_mode;
      case 'dhuhr':
      case 'الظهر':
        return Icons.light_mode;
      case 'asr':
      case 'العصر':
        return Icons.wb_cloudy;
      case 'maghrib':
      case 'المغرب':
        return Icons.wb_twilight;
      case 'isha':
      case 'العشاء':
        return Icons.bedtime;
      case 'sunrise':
      case 'الشروق':
        return Icons.wb_sunny;
      default:
        return Icons.access_time;
    }
  }

  static LinearGradient getTimeBasedGradient() => AppColors.getTimeBasedGradient();
}