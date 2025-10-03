// lib/app/themes/responsive/responsive_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget للتخطيط المتجاوب لدعم الايباد
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final double mobileBreakpoint;
  final double tabletBreakpoint;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.mobileBreakpoint = 600,
    this.tabletBreakpoint = 1024,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = ScreenUtil().screenWidth;
    
    if (screenWidth >= tabletBreakpoint && desktop != null) {
      return desktop!;
    } else if (screenWidth >= mobileBreakpoint && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

/// Builder للتخطيط المتجاوب
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = ScreenUtil().screenWidth;
    
    DeviceType deviceType;
    if (screenWidth >= 1024) {
      deviceType = DeviceType.desktop;
    } else if (screenWidth >= 600) {
      deviceType = DeviceType.tablet;
    } else {
      deviceType = DeviceType.mobile;
    }
    
    return builder(context, deviceType);
  }
}

enum DeviceType { mobile, tablet, desktop }

/// Extensions للتخطيط المتجاوب
extension ResponsiveExtensions on BuildContext {
  bool get isMobile => ScreenUtil().screenWidth < 600;
  bool get isTablet => ScreenUtil().screenWidth >= 600 && ScreenUtil().screenWidth < 1024;
  bool get isDesktop => ScreenUtil().screenWidth >= 1024;
  
  DeviceType get deviceType {
    if (isDesktop) return DeviceType.desktop;
    if (isTablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }
  
  /// عدد الأعمدة المناسب للشاشة
  int get gridCrossAxisCount {
    if (isDesktop) return 4;
    if (isTablet) return 3;
    return 2;
  }
  
  /// العرض الأقصى للمحتوى
  double get maxContentWidth {
    if (isDesktop) return 1200.w;
    if (isTablet) return 800.w;
    return double.infinity;
  }
  
  /// التباعد المناسب للشاشة
  double get responsiveSpacing {
    if (isDesktop) return 32.w;
    if (isTablet) return 24.w;
    return 16.w;
  }
}