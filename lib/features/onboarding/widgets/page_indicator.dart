// lib/features/onboarding/widgets/page_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/onboarding_item.dart';

class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final List<OnboardingItem> items;
  final Function(int)? onPageTap;

  const PageIndicator({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onPageTap,
  });

  // حساب الأحجام المتجاوبة
  double get _activeWidth {
    if (1.sw > 600) return 28.w;
    if (1.sw > 400) return 26.w;
    return 24.w;
  }

  double get _inactiveWidth {
    if (1.sw > 600) return 10.w;
    return 8.w;
  }

  double get _height {
    if (1.sw > 600) return 10.h;
    return 8.h;
  }

  double get _horizontalMargin {
    if (1.sw > 600) return 4.w;
    return 3.w;
  }

  double get _containerPadding {
    if (1.sw > 600) return 18.w;
    return 16.w;
  }

  double get _innerDotSize {
    if (1.sw > 600) return 5.w;
    return 4.w;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _containerPadding,
        vertical: 12.h,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildDots(),
      ),
    );
  }

  List<Widget> _buildDots() {
    return List.generate(
      items.length,
      (index) => GestureDetector(
        onTap: onPageTap != null ? () => onPageTap!(index) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: _horizontalMargin),
          width: currentIndex == index ? _activeWidth : _inactiveWidth,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_height / 2),
            color: currentIndex == index
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            boxShadow: currentIndex == index ? [
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 6.r,
                spreadRadius: 1.r,
              ),
            ] : null,
          ),
          child: currentIndex == index 
              ? Center(
                  child: Container(
                    width: _innerDotSize,
                    height: _innerDotSize,
                    decoration: BoxDecoration(
                      color: items[index].primaryColor.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}