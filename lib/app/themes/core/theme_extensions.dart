// lib/app/themes/core/theme_extensions.dart - محدث مع flutter_screenutil
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../text_styles.dart';
import '../theme_constants.dart';
import 'color_utils.dart';

/// Extensions لتسهيل الوصول للثيم مع ScreenUtil
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // الألوان الأساسية
  Color get primaryColor => theme.primaryColor;
  Color get backgroundColor => theme.scaffoldBackgroundColor;
  Color get surfaceColor => colorScheme.surface;
  Color get cardColor => theme.cardTheme.color ?? ThemeConstants.card(this);
  Color get errorColor => colorScheme.error;
  Color get dividerColor => theme.dividerTheme.color ?? ThemeConstants.divider(this);

  // ألوان النصوص
  Color get textPrimaryColor => ThemeConstants.textPrimary(this);
  Color get textSecondaryColor => ThemeConstants.textSecondary(this);

  // الألوان الدلالية
  Color get successColor => ThemeConstants.success;
  Color get warningColor => ThemeConstants.warning;
  Color get infoColor => ThemeConstants.info;

  // حالة الثيم
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isLightMode => !isDarkMode;

  // أنماط النصوص - مباشرة من TextTheme
  TextStyle? get displayLarge => textTheme.displayLarge;
  TextStyle? get displayMedium => textTheme.displayMedium;
  TextStyle? get displaySmall => textTheme.displaySmall;
  TextStyle? get headlineLarge => textTheme.headlineLarge;
  TextStyle? get headlineMedium => textTheme.headlineMedium;
  TextStyle? get headlineSmall => textTheme.headlineSmall;
  TextStyle? get titleLarge => textTheme.titleLarge;
  TextStyle? get titleMedium => textTheme.titleMedium;
  TextStyle? get titleSmall => textTheme.titleSmall;
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
  TextStyle? get bodySmall => textTheme.bodySmall;
  TextStyle? get labelLarge => textTheme.labelLarge;
  TextStyle? get labelMedium => textTheme.labelMedium;
  TextStyle? get labelSmall => textTheme.labelSmall;

  // أنماط خاصة
  TextStyle get quranStyle => AppTextStyles.quran;
  TextStyle get athkarStyle => AppTextStyles.athkar;
  TextStyle get duaStyle => AppTextStyles.dua;

  // معلومات الشاشة مع ScreenUtil
  double get screenWidth => ScreenUtil().screenWidth;
  double get screenHeight => ScreenUtil().screenHeight;
  EdgeInsets get screenPadding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  // نوع الجهاز مع ScreenUtil
  bool get isMobile => ScreenUtil().screenWidth < 600;
  bool get isTablet => ScreenUtil().screenWidth >= 600 && ScreenUtil().screenWidth < 1024;
  bool get isDesktop => ScreenUtil().screenWidth >= 1024;

  // الحشوات المتجاوبة مع ScreenUtil
  EdgeInsets get responsivePadding {
    if (isMobile) return EdgeInsets.all(16.w);
    if (isTablet) return EdgeInsets.all(24.w);
    return EdgeInsets.all(32.w);
  }

  // معلومات النظام
  bool get isIOS => theme.platform == TargetPlatform.iOS;
  bool get isAndroid => theme.platform == TargetPlatform.android;

  // لوحة المفاتيح
  bool get isKeyboardOpen => viewInsets.bottom > 0;
  double get keyboardHeight => viewInsets.bottom;

  // المناطق الآمنة
  double get safeTop => screenPadding.top;
  double get safeBottom => screenPadding.bottom;
}

/// Extensions للألوان - استخدام ColorUtils
extension ColorExtensions on Color {
  /// تطبيق شفافية آمنة
  Color withOpacitySafe(double opacity) => ColorUtils.applyOpacitySafely(this, opacity);

  /// تفتيح اللون
  Color lighten([double amount = 0.1]) => ColorUtils.lighten(this, amount);

  /// تغميق اللون
  Color darken([double amount = 0.1]) => ColorUtils.darken(this, amount);

  /// الحصول على لون متباين للنص
  Color get contrastingTextColor => ColorUtils.getContrastingTextColor(this);

  /// تحويل إلى Material Color
  MaterialColor toMaterialColor() => ColorUtils.toMaterialColor(this);
}

/// Extensions للنصوص
extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: ThemeConstants.bold);
  TextStyle get semiBold => copyWith(fontWeight: ThemeConstants.semiBold);
  TextStyle get medium => copyWith(fontWeight: ThemeConstants.medium);
  TextStyle get regular => copyWith(fontWeight: ThemeConstants.regular);
  TextStyle get light => copyWith(fontWeight: ThemeConstants.light);

  TextStyle size(double fontSize) => copyWith(fontSize: fontSize);
  TextStyle textColor(Color color) => copyWith(color: color);
  TextStyle withHeight(double height) => copyWith(height: height);
  TextStyle withSpacing(double letterSpacing) => copyWith(letterSpacing: letterSpacing);
  
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);
  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);
}

/// Extensions للحواف
extension EdgeInsetsExtensions on EdgeInsets {
  EdgeInsets add(EdgeInsets other) => EdgeInsets.only(
    left: left + other.left,
    top: top + other.top,
    right: right + other.right,
    bottom: bottom + other.bottom,
  );

  EdgeInsets subtract(EdgeInsets other) => EdgeInsets.only(
    left: (left - other.left).clamp(0.0, double.infinity),
    top: (top - other.top).clamp(0.0, double.infinity),
    right: (right - other.right).clamp(0.0, double.infinity),
    bottom: (bottom - other.bottom).clamp(0.0, double.infinity),
  );

  EdgeInsets get copyWith => EdgeInsets.only(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
  );
}

/// Extensions للأرقام مع ScreenUtil
extension ScreenUtilExtensions on num {
  // مسافات مع ScreenUtil
  SizedBox get width => SizedBox(width: w);
  SizedBox get height => SizedBox(height: h);
  SizedBox get square => SizedBox(width: w, height: w);
  
  // حشوات مع ScreenUtil
  EdgeInsets get allPadding => EdgeInsets.all(w);
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: w);
  EdgeInsets get verticalPadding => EdgeInsets.symmetric(vertical: h);
  EdgeInsets get leftPadding => EdgeInsets.only(left: w);
  EdgeInsets get topPadding => EdgeInsets.only(top: h);
  EdgeInsets get rightPadding => EdgeInsets.only(right: w);
  EdgeInsets get bottomPadding => EdgeInsets.only(bottom: h);

  // زوايا دائرية مع ScreenUtil
  BorderRadius get circularRadius => BorderRadius.circular(r);
  BorderRadius get topCircularRadius => BorderRadius.only(
    topLeft: Radius.circular(r),
    topRight: Radius.circular(r),
  );
  BorderRadius get bottomCircularRadius => BorderRadius.only(
    bottomLeft: Radius.circular(r),
    bottomRight: Radius.circular(r),
  );
  
  // Radius مباشر
  Radius get radiusCircular => Radius.circular(r);
}

/// Extensions للـ Lists
extension ListExtensions<T> on List<T> {
  /// فصل العناصر بـ separator
  List<T> separated(T separator) {
    if (isEmpty) return this;
    
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(separator);
      }
    }
    return result;
  }
  
  /// الحصول على أول عنصر بأمان
  T? get firstOrNull => isEmpty ? null : first;
  
  /// الحصول على آخر عنصر بأمان
  T? get lastOrNull => isEmpty ? null : last;
}

/// Extensions للـ Widgets مع ScreenUtil
extension WidgetExtensions on Widget {
  /// إضافة padding مع ScreenUtil
  Widget paddingAll(double value) => Padding(
    padding: EdgeInsets.all(value.w),
    child: this,
  );

  Widget paddingSymmetric({double? horizontal, double? vertical}) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: (horizontal ?? 0).w,
      vertical: (vertical ?? 0).h,
    ),
    child: this,
  );

  Widget paddingOnly({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) => Padding(
    padding: EdgeInsets.only(
      left: (left ?? 0).w,
      top: (top ?? 0).h,
      right: (right ?? 0).w,
      bottom: (bottom ?? 0).h,
    ),
    child: this,
  );

  /// إضافة padding باستخدام EdgeInsets
  Widget padded(EdgeInsetsGeometry padding) => Padding(
    padding: padding,
    child: this,
  );

  /// توسيط Widget
  Widget get centered => Center(child: this);

  /// إضافة Expanded
  Widget get expanded => Expanded(child: this);

  /// إضافة Flexible
  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) => Flexible(
    flex: flex,
    fit: fit,
    child: this,
  );

  /// إضافة حاوية مع ScreenUtil
  Widget container({
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BoxDecoration? decoration,
    Color? color,
    double? width,
    double? height,
    AlignmentGeometry? alignment,
  }) => Container(
    padding: padding,
    margin: margin,
    decoration: decoration,
    color: decoration == null ? color : null,
    width: width?.w,
    height: height?.h,
    alignment: alignment,
    child: this,
  );

  /// إضافة InkWell
  Widget inkWell({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    BorderRadius? borderRadius,
  }) => InkWell(
    onTap: onTap,
    onLongPress: onLongPress,
    borderRadius: borderRadius,
    child: this,
  );

  /// إضافة GestureDetector
  Widget gesture({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onDoubleTap,
  }) => GestureDetector(
    onTap: onTap,
    onLongPress: onLongPress,
    onDoubleTap: onDoubleTap,
    child: this,
  );

  /// إضافة تأثير تلاشي
  Widget opacity(double opacity) => Opacity(
    opacity: opacity.clamp(0.0, 1.0),
    child: this,
  );

  /// إضافة دوران
  Widget rotate(double angle) => Transform.rotate(
    angle: angle,
    child: this,
  );

  /// إضافة تحجيم
  Widget scale(double scale) => Transform.scale(
    scale: scale,
    child: this,
  );

  /// إضافة ClipRRect مع ScreenUtil
  Widget clipRRect(double radius) => ClipRRect(
    borderRadius: BorderRadius.circular(radius.r),
    child: this,
  );

  /// إضافة Card مع ScreenUtil
  Widget card({
    Color? color,
    double? elevation,
    EdgeInsetsGeometry? margin,
    double? radius,
  }) => Card(
    color: color,
    elevation: elevation,
    margin: margin,
    shape: radius != null
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.r),
          )
        : null,
    child: this,
  );

  /// إضافة SizedBox مع ScreenUtil
  Widget sized({double? width, double? height}) => SizedBox(
    width: width?.w,
    height: height?.h,
    child: this,
  );

  /// جعل Widget غير مرئي
  Widget visible(bool isVisible) => Visibility(
    visible: isVisible,
    child: this,
  );

  /// تجاهل التفاعل
  Widget ignorePointer(bool ignore) => IgnorePointer(
    ignoring: ignore,
    child: this,
  );
}

/// Extensions للـ Strings
extension StringExtensions on String {
  /// التحقق من أن النص غير فارغ
  bool get isNotBlank => trim().isNotEmpty;
  
  /// التحقق من أن النص فارغ
  bool get isBlank => trim().isEmpty;
  
  /// الحصول على أول حرف كبير
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
  
  /// إزالة المسافات الزائدة
  String get removeExtraSpaces => replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Extensions للـ DateTime
extension DateTimeExtensions on DateTime {
  /// التحقق من أن التاريخ اليوم
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// التحقق من أن التاريخ أمس
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }
  
  /// التحقق من أن التاريخ غداً
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && 
           month == tomorrow.month && 
           day == tomorrow.day;
  }
  
  /// الحصول على الوقت بصيغة 12 ساعة
  String get time12Hour {
    final hour = this.hour > 12 ? this.hour - 12 : this.hour;
    final period = this.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}