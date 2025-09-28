// lib/features/onboarding/widgets/enhanced_page_indicator.dart
import 'package:flutter/material.dart';
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // مؤشر الصفحة الحالية
          _buildCurrentPageInfo(),
          const SizedBox(width: 16),
          // النقاط
          ..._buildDots(),
        ],
      ),
    );
  }

  Widget _buildCurrentPageInfo() {
    final currentItem = items[currentIndex];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الإيموجي
        Text(
          currentItem.emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 8),
        // رقم الصفحة
        Text(
          '${currentIndex + 1}/${items.length}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
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
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: currentIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
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