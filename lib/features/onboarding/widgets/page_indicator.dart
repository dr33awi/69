// lib/features/onboarding/widgets/page_indicator.dart - محدث بدون إيموجي مع ScreenUtil
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // النقاط فقط
          ..._buildDots(),
        ],
      ),
    );
  }

  // تم إزالة دالة _buildCurrentPageInfo() لأنها لم تعد مطلوبة

  List<Widget> _buildDots() {
    return List.generate(
      items.length,
      (index) => GestureDetector(
        onTap: onPageTap != null ? () => onPageTap!(index) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: currentIndex == index ? 24.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            color: currentIndex == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            boxShadow: currentIndex == index ? [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ] : null,
          ),
          child: currentIndex == index 
              ? Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: items[index].primaryColor.withValues(alpha: 0.8),
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