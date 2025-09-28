// lib/features/onboarding/models/onboarding_item.dart - محدث
import 'dart:ui';

enum OnboardingAnimationType {
  mosque,
  book,
  clock,
  compass,
  security,
  custom,
}

class OnboardingItem {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final Color primaryColor;
  final Color secondaryColor;
  final String? animationPath;
  final OnboardingAnimationType animationType;
  final bool useCustomAnimation;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.primaryColor,
    required this.secondaryColor,
    this.animationPath,
    this.animationType = OnboardingAnimationType.custom,
    this.useCustomAnimation = false,
  });
}