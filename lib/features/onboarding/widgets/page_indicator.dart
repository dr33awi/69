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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
          margin: EdgeInsets.symmetric(horizontal: 2.5.w),
          width: currentIndex == index ? 20.w : 7.w,
          height: 7.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3.5.r),
            color: currentIndex == index
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            boxShadow: currentIndex == index ? [
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 5.r,
                spreadRadius: 0.5.r,
              ),
            ] : null,
          ),
          child: currentIndex == index 
              ? Center(
                  child: Container(
                    width: 3.w,
                    height: 3.h,
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
