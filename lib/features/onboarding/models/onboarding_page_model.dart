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
  
  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    this.features,
  });

  /// إنشاء نسخة من الموديل مع إمكانية تعديل بعض القيم
  OnboardingPageModel copyWith({
    String? title,
    String? description,
    Color? primaryColor,
    Color? secondaryColor,
    List<String>? features,
  }) {
    return OnboardingPageModel(
      title: title ?? this.title,
      description: description ?? this.description,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      features: features ?? this.features,
    );
  }
}

/// مجموعة صفحات Onboarding للتطبيق
/// يحتوي على جميع صفحات التعريف بميزات التطبيق
class OnboardingPages {
  // منع إنشاء instance من الكلاس
  OnboardingPages._();
  
  /// قائمة جميع صفحات Onboarding
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
    // الصفحة الثانية - الأذكار اليومية
    // ═══════════════════════════════════════════════════════
    OnboardingPageModel(
      title: 'أذكار المسلم',
      description: 'أذكار لكل وقت من أوقات يومك',
      primaryColor: AppColors.athkarColor,
      secondaryColor: AppColors.accentLight,
      features: [
        'أذكار الصباح والمساء والنوم والصلاة والسفر',
        'تنبيهات ذكية تذكرك بالأذكار في أوقاتها',
        'تتبع تقدمك مع عداد ذكي لكل ذكر',
      ],
    ),
    
    // ═══════════════════════════════════════════════════════
    // الصفحة الثالثة - مواقيت الصلاة
    // ═══════════════════════════════════════════════════════
    OnboardingPageModel(
      title: 'مواقيت الصلاة',
      description: 'مواقيت صلاة دقيقة أينما كنت ترافقك في كل سفر ومكان',
      primaryColor: AppColors.prayerTimesColor,
      secondaryColor: AppColors.primarySoft,
      features: [
        'حساب دقيق للمواقيت بطرق حساب متعددة',
        'تنبيهات قابلة للتخصيص قبل كل أذان',
        'عدّاد زمني يُظهر الوقت المتبقي للصلاة التالية',
      ],
    ),
    
    // ═══════════════════════════════════════════════════════
    // الصفحة الرابعة - أسماء الله الحسنى
    // ═══════════════════════════════════════════════════════
    OnboardingPageModel(
      title: 'أسماء الله الحسنى',
      description: 'تأمّل جمال الأسماء الحسنى، وتعرّف على معانيها العظيمة',
      primaryColor: AppColors.asmaAllahColor,
      secondaryColor: AppColors.tertiaryLight,
      features: [
        'عرض جميع الأسماء الحسنى التسعة والتسعين',
        'شرح مبسط ومعبر لكل اسم',
        'تصميم إسلامي راقي مع خطوط عربية أنيقة',
      ],
    ),
    
    // ═══════════════════════════════════════════════════════
    // الصفحة الخامسة - اتجاه القبلة
    // ═══════════════════════════════════════════════════════
    OnboardingPageModel(
      title: 'اتجاه القبلة',
      description: 'اعرف وجهتك نحو القبلة بسهولة ودقّة أينما كنت',
      primaryColor: AppColors.qiblaColor,
      secondaryColor: AppColors.primary,
      features: [
        'بوصلة ذكية لتحديد اتجاه الكعبة المشرفة',
        'معايرة تلقائية باستخدام حساسات الجهاز',
        'عرض المسافة والاتجاه إلى مكة المكرمة',
      ],
    ),
    
    // ═══════════════════════════════════════════════════════
    // الصفحة السادسة - المسبحة الرقمية
    // ═══════════════════════════════════════════════════════
    OnboardingPageModel(
      title: 'المسبحة الرقمية',
      description: 'سبّح واذكر الله في كل حين',
      primaryColor: AppColors.tasbihColor,
      secondaryColor: AppColors.accent,
      features: [
        'عداد ذكي مع 6 أنماط للتسبيح والذكر',
        'إحصاءات دقيقة لتقدّمك اليومي ',
        'أهداف تسبيح مخصصة تلهمك للاستمرار',
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