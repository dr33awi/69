// lib/features/onboarding/models/onboarding_page_model.dart

import 'package:flutter/material.dart';
import '../../../app/themes/core/color_helper.dart';

/// نموذج صفحة Onboarding
/// يحتوي على جميع البيانات اللازمة لعرض صفحة واحدة من صفحات التعريف بالتطبيق
class OnboardingPageModel {
  /// عنوان الصفحة الرئيسي
  final String title;
  
  /// الوصف التفصيلي للصفحة
  final String description;
  
  /// اللون الأساسي للصفحة
  final Color primaryColor;
  
  /// اللون الثانوي للصفحة
  final Color secondaryColor;
  
  /// قائمة الميزات (اختيارية)
  final List<String>? features;
  
  /// مسار الرسوم المتحركة (اختياري)
  final String? animationPath;
  
  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    this.features,
    this.animationPath,
  });

  /// إنشاء نسخة من الموديل مع إمكانية تعديل بعض القيم
  OnboardingPageModel copyWith({
    String? title,
    String? description,
    Color? primaryColor,
    Color? secondaryColor,
    List<String>? features,
    String? animationPath,
  }) {
    return OnboardingPageModel(
      title: title ?? this.title,
      description: description ?? this.description,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      features: features ?? this.features,
      animationPath: animationPath ?? this.animationPath,
    );
  }
}

/// مجموعة صفحات Onboarding للتطبيق
/// يحتوي على جميع صفحات التعريف بميزات التطبيق
class OnboardingPages {
  // منع إنشاء instance من الكلاس
  OnboardingPages._();
  
  /// قائمة جميع صفحات Onboarding (مُحسَّنة إلى 4 صفحات)
  static final List<OnboardingPageModel> pages = [
    // ═══════════════════════════════════════════════════════
// الصفحة الأولى - الترحيب
OnboardingPageModel(
  title: '🌟 أهلاً بك في ذكرني',
  description: 'رفيقك الأمثل للتقرّب من الله',
  primaryColor: AppColors.primary,
  secondaryColor: AppColors.primaryLight,
  features: [
    '📖 أذكار وأدعية من القرآن والسنة',
    '✨ تصميم عربي أنيق وسهل الاستخدام',
    '📱 تطبيق كامل بدون الحاجة للإنترنت',
    '💚 مجاني تمامًا وبدون إعلانات',
    '🤝 صدقة جارية وليس تطبيق ربحي',
  ],
),

// الصفحة الثانية - الأذكار والأدعية
OnboardingPageModel(
  title: '📿 كنز من الأذكار',
  description: 'أذكار يومية تحفظك وترافقك',
  primaryColor: AppColors.athkarColor,
  secondaryColor: AppColors.accentLight,
  features: [
    '🌅 أذكار الصباح والمساء',
    '🛌 أذكار النوم والاستيقاظ',
    '🔔 تنبيهات ذكية لا تفوتك أي ذكر',

  ],
),

// الصفحة الثالثة - الصلاة والقبلة
OnboardingPageModel(
  title: '🕌 صلاتك في موعدها دائمًا',
  description: 'مواقيت دقيقة وبوصلة ذكية',
  primaryColor: AppColors.prayerTimesColor,
  secondaryColor: AppColors.primarySoft,
  features: [
    '⏰ حساب دقيق لمواقيت الصلاة ',
    '🧭 بوصلة ذكية تحدد اتجاه القبلة',
    '📍 احسب المسافة إلى الكعبة المشرفة',
  ],
),

// الصفحة الرابعة - المسبحة وأسماء الله
OnboardingPageModel(
  title: '✨ سبّح في أسماء الله الحسنى',
  description: 'مسبحة إلكترونية مع أسماء الله الـ 99',
  primaryColor: AppColors.tasbihColor,
  secondaryColor: AppColors.tertiaryLight,
  features: [
    '📿 مسبحة رقمية بـ 6 أنماط مختلفة',
    '🌙 أسماء الله الحسنى الـ 99 كاملة',
    '💎 شرح معاني الأسماء بأسلوب سهل',
      ],
    ),
  ];
  
  /// الحصول على صفحة محددة بناءً على الفهرس
  /// يُرجع الصفحة الأولى في حالة فهرس غير صحيح
  static OnboardingPageModel getPage(int index) {
    if (index >= 0 && index < pages.length) {
      return pages[index];
    }
    return pages[0];
  }
  
  /// الحصول على عدد صفحات Onboarding
  static int get pageCount => pages.length;
  
  /// التحقق من وجود صفحة بفهرس معين
  static bool isValidIndex(int index) {
    return index >= 0 && index < pages.length;
  }
  
  /// الحصول على أول صفحة
  static OnboardingPageModel get firstPage => pages.first;
  
  /// الحصول على آخر صفحة
  static OnboardingPageModel get lastPage => pages.last;
}