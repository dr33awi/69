// lib/features/onboarding/data/onboarding_data.dart - بدون Lottie
import 'package:flutter/material.dart';
import '../models/onboarding_item.dart';
import '../../../app/themes/app_theme.dart';

class OnboardingData {
  static List<OnboardingItem> get items => [
    // الشاشة الأولى - مرحباً
    OnboardingItem(
      title: 'مرحباً بك في',
      subtitle: 'حصن المسلم',
      description: 'تطبيقك المتكامل للأذكار والأدعية\nوأوقات الصلاة واتجاه القبلة',
      imagePath: 'assets/images/onboarding/welcome.png',
      primaryColor: AppColors.primary,
      secondaryColor: AppColors.primaryLight,
      animationType: OnboardingAnimationType.mosque,
    ),
    
    // الشاشة الثانية - الأذكار
    OnboardingItem(
      title: 'أذكار وأدعية',
      subtitle: 'من القرآن والسنة',
      description: 'مجموعة شاملة من الأذكار اليومية\nوالأدعية المستجابة مع تتبع التقدم',
      imagePath: 'assets/images/onboarding/athkar.png',
      primaryColor: AppColors.accent,
      secondaryColor: AppColors.accentLight,
      animationType: OnboardingAnimationType.book,
    ),
    
    // الشاشة الثالثة - أوقات الصلاة
    OnboardingItem(
      title: 'أوقات الصلاة',
      subtitle: 'دقيقة ومضبوطة',
      description: 'حساب أوقات الصلاة بدقة عالية\nمع تذكيرات ذكية وأصوات أذان متنوعة',
      imagePath: 'assets/images/onboarding/prayer.png',
      primaryColor: AppColors.tertiary,
      secondaryColor: AppColors.tertiaryLight,
      animationType: OnboardingAnimationType.clock,
    ),
    
    // الشاشة الرابعة - القبلة والتسبيح
    OnboardingItem(
      title: 'القبلة والتسبيح',
      subtitle: 'أدوات روحانية',
      description: 'تحديد اتجاه القبلة بدقة\nوعداد تسبيح رقمي مع إحصائيات يومية',
      imagePath: 'assets/images/onboarding/qibla.png',
      primaryColor: AppColors.primaryDark,
      secondaryColor: AppColors.primary,
      animationType: OnboardingAnimationType.compass,
    ),
    
    // الشاشة الخامسة - الأذونات
    OnboardingItem(
      title: 'أذونات مطلوبة',
      subtitle: 'لتجربة مثالية',
      description: 'نحتاج بعض الأذونات لتوفير\nأفضل تجربة وميزات دقيقة',
      imagePath: 'assets/images/onboarding/permissions.png',
      primaryColor: AppColors.info,
      secondaryColor: Colors.blue.shade300,
      animationType: OnboardingAnimationType.security,
    ),
  ];
}