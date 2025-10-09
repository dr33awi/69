// lib/features/onboarding/models/onboarding_page_model.dart

import 'package:flutter/material.dart';

/// نموذج صفحة Onboarding
class OnboardingPageModel {
  final String title;
  final String description;
  final String animationPath;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String>? features;
  
  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.animationPath,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.features,
  });
}

/// صفحات Onboarding للتطبيق
class OnboardingPages {
  OnboardingPages._();
  
  static const Color primaryGreen = Color(0xFF5D7052);
  static const Color accentGold = Color(0xFFB8860B);
  static const Color tertiaryBrown = Color(0xFF8B6F47);
  static const Color infoBlue = Color(0xFF6B8E9F);
  
  static final List<OnboardingPageModel> pages = [
    // الصفحة الأولى - الترحيب
    OnboardingPageModel(
      title: 'مرحباً بك في حصن المسلم',
      description: 'رفيقك اليومي للأذكار والأدعية ومواقيت الصلاة',
      animationPath: 'assets/animations/welcome.json',
      icon: Icons.mosque_rounded,
      primaryColor: primaryGreen,
      secondaryColor: accentGold,
      features: [
        'تطبيق شامل للأذكار والأدعية',
        'واجهة عربية أصيلة وسهلة',
        'يعمل بدون اتصال بالإنترنت',
      ],
    ),
    
    // الصفحة الثانية - الأذكار
    OnboardingPageModel(
      title: 'أذكار الصباح والمساء',
      description: 'أذكار صحيحة من القرآن والسنة مع تذكيرات ذكية',
      animationPath: 'assets/animations/athkar.json',
      icon: Icons.menu_book_rounded,
      primaryColor: accentGold,
      secondaryColor: tertiaryBrown,
      features: [
        'أذكار الصباح والمساء والنوم',
        'تذكيرات في الأوقات المناسبة',
        'عداد تلقائي للتكرار',
      ],
    ),
    
    // الصفحة الثالثة - مواقيت الصلاة
    OnboardingPageModel(
      title: 'مواقيت الصلاة الدقيقة',
      description: 'أوقات دقيقة للصلاة مع تنبيهات مخصصة لكل صلاة',
      animationPath: 'assets/animations/prayer.json',
      icon: Icons.access_time_rounded,
      primaryColor: infoBlue,
      secondaryColor: primaryGreen,
      features: [
        'حساب دقيق لأوقات الصلاة',
        'تنبيهات قبل الأذان',
        'عداد تنازلي للصلاة القادمة',
      ],
    ),
    
    // الصفحة الرابعة - القبلة
    OnboardingPageModel(
      title: 'اتجاه القبلة',
      description: 'بوصلة دقيقة لتحديد اتجاه القبلة في أي مكان',
      animationPath: 'assets/animations/qibla.json',
      icon: Icons.explore_rounded,
      primaryColor: tertiaryBrown,
      secondaryColor: accentGold,
      features: [
        'بوصلة دقيقة للقبلة',
        'معايرة تلقائية',
        'عرض المسافة إلى مكة',
      ],
    ),
    
    // الصفحة الخامسة - التسبيح
    OnboardingPageModel(
      title: 'المسبحة الرقمية',
      description: 'عداد تسبيح ذكي مع إحصائيات وأهداف يومية',
      animationPath: 'assets/animations/tasbih.json',
      icon: Icons.touch_app_rounded,
      primaryColor: primaryGreen,
      secondaryColor: infoBlue,
      features: [
        'عداد رقمي للتسبيح',
        'إحصائيات يومية وشهرية',
        'أهداف قابلة للتخصيص',
      ],
    ),
    
    // الصفحة السادسة - أسماء الله الحسنى
    OnboardingPageModel(
      title: 'أسماء الله الحسنى',
      description: 'الأسماء الـ99 مع شرح معانيها وفضلها',
      animationPath: 'assets/animations/names.json',
      icon: Icons.auto_awesome_rounded,
      primaryColor: accentGold,
      secondaryColor: primaryGreen,
      features: [
        'جميع الأسماء الـ99',
        'شرح مفصل لكل اسم',
        'تصميم إسلامي أنيق',
      ],
    ),
  ];
  
  /// الحصول على صفحة محددة
  static OnboardingPageModel getPage(int index) {
    if (index >= 0 && index < pages.length) {
      return pages[index];
    }
    return pages[0];
  }
  
  /// عدد الصفحات
  static int get pageCount => pages.length;
}