// lib/features/onboarding/widgets/navigation_controls.dart
import 'package:flutter/material.dart';
import 'package:athkar_app/app/themes/app_theme.dart';

class OnboardingNavigationControls extends StatelessWidget {
  final int currentIndex;
  final int totalSteps;
  final bool canProceed;
  final bool isLoading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onFinish;

  const OnboardingNavigationControls({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
    required this.canProceed,
    this.isLoading = false,
    this.onPrevious,
    this.onNext,
    this.onFinish,
  });

  bool get isFirstStep => currentIndex == 0;
  bool get isLastStep => currentIndex == totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // زر السابق
        if (!isFirstStep)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onPrevious,
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: const Text('السابق'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeConstants.primary,
                side: const BorderSide(color: ThemeConstants.primary),
                padding: const EdgeInsets.symmetric(vertical: ThemeConstants.space4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
                ),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox.shrink()),

        const SizedBox(width: ThemeConstants.space4),

        // معلومات التقدم
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeConstants.space3,
            vertical: ThemeConstants.space2,
          ),
          decoration: BoxDecoration(
            color: ThemeConstants.lightSurface,
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
          ),
          child: Text(
            '${currentIndex + 1} من $totalSteps',
            style: AppTextStyles.caption.copyWith(
              color: ThemeConstants.lightTextSecondary,
              fontWeight: ThemeConstants.medium,
            ),
          ),
        ),

        const SizedBox(width: ThemeConstants.space4),

        // زر التالي/الإنهاء
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (canProceed && !isLoading)
                ? (isLastStep ? onFinish : onNext)
                : null,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    isLastStep ? Icons.check : Icons.arrow_forward_ios,
                    size: 16,
                  ),
            label: Text(isLastStep ? 'ابدأ الآن' : 'التالي'),
            style: ElevatedButton.styleFrom(
              backgroundColor: canProceed ? ThemeConstants.primary : ThemeConstants.lightDivider,
              foregroundColor: canProceed ? Colors.white : ThemeConstants.lightTextSecondary,
              padding: const EdgeInsets.symmetric(vertical: ThemeConstants.space4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
              ),
              elevation: canProceed ? 2 : 0,
            ),
          ),
        ),
      ],
    );
  }
}