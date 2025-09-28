// lib/features/onboarding/models/onboarding_item.dart - مع دعم Lottie
import 'dart:ui';
import 'package:flutter/material.dart';

enum OnboardingAnimationType {
  welcome,
  dailyAthkar,
  islamicDuaa,
  digitalTasbih,
  qiblaDirection,
  prayerTimes,
  asmaAlHusna,
  permissions,
  custom,
}

class OnboardingItem {
  final String title;
  final String? lottiePath; // مسار ملف Lottie
  final bool useLottie; // هل نستخدم Lottie أم الأيقونة
  final Color primaryColor;
  final Color secondaryColor;
  final Color darkColor;
  final String? animationPath;
  final OnboardingAnimationType animationType;
  final String emoji;
  final IconData iconData;
  final List<String>? features; // ميزات الفئة
  final bool useCustomAnimation;

  const OnboardingItem({
    required this.title,
    this.lottiePath,
    this.useLottie = false,
    required this.primaryColor,
    required this.secondaryColor,
    required this.darkColor,
    required this.emoji,
    required this.iconData,
    this.animationPath,
    this.animationType = OnboardingAnimationType.custom,
    this.features,
    this.useCustomAnimation = false,
  });

  /// هل يحتوي على Lottie animation صالح
  bool get hasValidLottie => useLottie && lottiePath != null && lottiePath!.isNotEmpty;
  
  /// الحصول على مسار الـ animation المناسب
  String? get effectiveAnimationPath => hasValidLottie ? lottiePath : animationPath;
}