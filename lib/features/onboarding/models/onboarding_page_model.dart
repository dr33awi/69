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
    // الصفحة الأولى - الترحيب والمقدمة
    // ═══════════════════════════════════════════════════════
    OnboardingPageModel(
      title: 'مرحباً بك في ذكرني',
      description: 'رفيقك اليومي الذي يذكّرك بالله في كل وقتٍ ومكان',
      primaryColor: AppColors.primary,
      secondaryColor: AppColors.primaryLight,
      features: [
        'مجموعة شاملة من الأذكار والأدعية الصحيحة',
        'واجهة عربية أنيقة وسهلة الاستخدام',
        'يعمل بدون إنترنت لتبقى قريبًا من الذكر دائمًا',
      ],
    ),
    
    // ═══════════════════════════════════════════════════════
    // الصفحة الثانية - الأذكار والأدعية
    // ═══════════════════════════════════════════════════════
    OnboardingPageModel(
      title: 'أذكار وأدعية المسلم',
      description: 'أذكار وأدعية لكل وقت من أوقات يومك من القرآن والسنة',
      primaryColor: AppColors.athkarColor,
      secondaryColor: AppColors.accentLight,
      features: [
        'أذكار الصباح والمساء والنوم والصلاة والسفر',
        'أدعية من القرآن والسنة موثقة المصادر',
        'تنبيهات ذكية تذكرك بالأذكار في أوقاتها',
        'تتبع تقدمك مع عداد ذكي لكل ذكر',
      ],
    ),
    
    // ═══════════════════════════════════════════════════════
    // الصفحة الثالثة - الصلاة والقبلة
    // ═══════════════════════════════════════════════════════
    OnboardingPageModel(
      title: 'مواقيت الصلاة والقبلة',
      description: 'مواقيت دقيقة وبوصلة ذكية لتحديد اتجاه القبلة أينما كنت',
      primaryColor: AppColors.prayerTimesColor,
      secondaryColor: AppColors.primarySoft,
      features: [
        'حساب دقيق للمواقيت بطرق حساب متعددة',
        'تنبيهات قابلة للتخصيص قبل كل أذان',
        'بوصلة ذكية لتحديد اتجاه الكعبة المشرفة',
        'عرض المسافة والاتجاه إلى مكة المكرمة',
      ],
    ),
    
    // ═══════════════════════════════════════════════════════
    // الصفحة الرابعة - المسبحة وأسماء الله
    // ═══════════════════════════════════════════════════════
    OnboardingPageModel(
      title: 'المسبحة وأسماء الله الحسنى',
      description: 'سبّح واذكر الله وتأمّل جمال أسمائه الحسنى',
      primaryColor: AppColors.tasbihColor,
      secondaryColor: AppColors.tertiaryLight,
      features: [
        'عداد ذكي مع 6 أنماط للتسبيح والذكر',
        'إحصاءات دقيقة وأهداف مخصصة للتسبيح',
        'أسماء الله الحسنى التسعة والتسعين',
        'شرح مبسط ومعبر لكل اسم مع تصميم إسلامي راقي',
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