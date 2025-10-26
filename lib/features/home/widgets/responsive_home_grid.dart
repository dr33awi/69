// lib/features/home/widgets/responsive_home_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' hide DeviceType;
import '../../../app/themes/responsive/responsive_layout.dart';

/// شبكة متجاوبة للشاشة الرئيسية تدعم الايباد
class ResponsiveHomeGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;

  const ResponsiveHomeGrid({
    super.key,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: context.maxContentWidth,
          ),
          child: GridView.builder(
            padding: padding ?? EdgeInsets.all(context.responsiveSpacing),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(deviceType),
              crossAxisSpacing: context.responsiveSpacing,
              mainAxisSpacing: context.responsiveSpacing,
              childAspectRatio: _getAspectRatio(deviceType),
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.tablet:
        return 3; // ✅ مثالي للايباد
      case DeviceType.desktop:
        return 4;
    }
  }

  double _getAspectRatio(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.2; // ✅ نسبة أفضل للايباد
      case DeviceType.desktop:
        return 1.3;
    }
  }
}

/// Widget بطاقة متجاوبة للايباد
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final borderRadius = _getBorderRadius(deviceType);
        final padding = _getPadding(deviceType);

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: boxShadow ?? [
              BoxShadow(
                color: Colors.black.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.06,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.03,
                ),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: -1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  double _getBorderRadius(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 16.r;
      case DeviceType.tablet:
        return 20.r; // ✅ زوايا أكبر للايباد
      case DeviceType.desktop:
        return 24.r;
    }
  }

  double _getPadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 18.w;
      case DeviceType.tablet:
        return 22.w; // ✅ حشو أكبر للايباد
      case DeviceType.desktop:
        return 26.w;
    }
  }
}