// lib/features/onboarding/widgets/progress_indicator.dart
import 'package:flutter/material.dart';
import 'package:athkar_app/app/themes/app_theme.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalSteps;
  final Function(int)? onStepTap;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentIndex;
        final isCompleted = index < currentIndex;
        
        return GestureDetector(
          onTap: onStepTap != null ? () => onStepTap!(index) : null,
          child: AnimatedContainer(
            duration: ThemeConstants.durationNormal,
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: isActive ? 32 : 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ThemeConstants.radiusFull),
              gradient: isActive || isCompleted
                  ? AppColors.primaryGradient
                  : null,
              color: isActive || isCompleted
                  ? null
                  : ThemeConstants.lightDivider,
            ),
          ),
        );
      }),
    );
  }
}