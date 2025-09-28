// lib/features/onboarding/data/onboarding_data.dart - مع دعم Lottie
import 'package:flutter/material.dart';
import '../models/onboarding_item.dart';
import '../../../app/themes/app_theme.dart';

class OnboardingData {
  static List<OnboardingItem> get items => [
    // الشاشة الأولى - مرحباً
    OnboardingItem(
      title: 'حصن المسلم',
      lottiePath: 'assets/animations/mosque_welcome.json',
      useLottie: true,
      primaryColor: AppColors.primary,
      secondaryColor: AppColors.primaryLight,
      darkColor: AppColors.primaryDark,
      emoji: '🕌',
      iconData: Icons.mosque,
      animationType: OnboardingAnimationType.welcome,
    ),
    
    // الشاشة الثانية - الأذكار اليومية
    OnboardingItem(
      title: '🌅 الأذكار اليومية',
      lottiePath: 'assets/animations/book_reading.json',
      useLottie: true,
      primaryColor: AppColors.getCategoryGradient('athkar').colors[0],
      secondaryColor: AppColors.getCategoryGradient('athkar').colors[1],
      darkColor: AppColors.getCategoryGradient('athkar').colors[1],
      emoji: '🌅',
      iconData: Icons.wb_sunny_rounded,
      animationType: OnboardingAnimationType.dailyAthkar,
      features: [
        'أذكار الصباح والمساء',
        'أذكار النوم والاستيقاظ',
        'أذكار متنوعة للمناسبات',
        'تتبع التقدم اليومي',
        'تذكيرات مخصصة',
      ],
    ),
    
    // الشاشة الثالثة - الأدعية الإسلامية
    OnboardingItem(
      title: '🤲 الأدعية الإسلامية',
      lottiePath: 'assets/animations/book_reading.json',
      useLottie: true,
      primaryColor: AppColors.getCategoryGradient('dua').colors[0],
      secondaryColor: AppColors.getCategoryGradient('dua').colors[1],
      darkColor: AppColors.getCategoryGradient('dua').colors[1],
      emoji: '🤲',
      iconData: Icons.menu_book_rounded,
      animationType: OnboardingAnimationType.islamicDuaa,
      features: [
        'أدعية مصنفة حسب الموضوع',
        'أدعية من القرآن والسنة',
        'بحث متقدم في الأدعية',
        'حفظ الأدعية المفضلة',
        'مصادر موثقة',
      ],
    ),
    
    // الشاشة الرابعة - التسبيح الرقمي
    OnboardingItem(
      title: '📿 التسبيح الرقمي',
      lottiePath: 'assets/animations/tasbih_beads.json',
      useLottie: true,
      primaryColor: AppColors.getCategoryGradient('tasbih').colors[0],
      secondaryColor: AppColors.getCategoryGradient('tasbih').colors[1],
      darkColor: AppColors.getCategoryGradient('tasbih').colors[1],
      emoji: '📿',
      iconData: Icons.radio_button_checked_rounded,
      animationType: OnboardingAnimationType.digitalTasbih,
      features: [
        'عداد تسبيح ذكي',
        'أنماط متعددة للتسبيح',
        'إحصائيات يومية وشهرية',
        'أصوات تفاعلية',
        'أهداف قابلة للتخصيص',
      ],
    ),
    
    // الشاشة الخامسة - اتجاه القبلة
    OnboardingItem(
      title: '🧭 اتجاه القبلة',
      lottiePath: 'assets/animations/compass_qibla.json',
      useLottie: true,
      primaryColor: AppColors.getCategoryGradient('qibla').colors[0],
      secondaryColor: AppColors.getCategoryGradient('qibla').colors[1],
      darkColor: AppColors.getCategoryGradient('qibla').colors[1],
      emoji: '🧭',
      iconData: Icons.explore_rounded,
      animationType: OnboardingAnimationType.qiblaDirection,
      features: [
        'بوصلة دقيقة للقبلة',
        'واجهة بصرية واضحة',
        'معايرة تلقائية',
        'عرض المسافة لمكة',
        'يعمل في جميع الأماكن',
      ],
    ),
    
    // الشاشة السادسة - أوقات الصلاة
    OnboardingItem(
      title: '🕐 أوقات الصلاة',
      lottiePath: 'assets/animations/clock_prayer.json',
      useLottie: true,
      primaryColor: AppColors.getCategoryGradient('prayer_times').colors[0],
      secondaryColor: AppColors.getCategoryGradient('prayer_times').colors[1],
      darkColor: AppColors.getCategoryGradient('prayer_times').colors[1],
      emoji: '🕐',
      iconData: Icons.access_time_rounded,
      animationType: OnboardingAnimationType.prayerTimes,
      features: [
        'أوقات دقيقة للصلاة',
        'تحديد الموقع التلقائي',
        'تذكيرات مخصصة',
        'عد تنازلي للصلاة القادمة',
        'أصوات أذان متنوعة',
      ],
    ),
    
    // الشاشة السابعة - أسماء الله الحسنى
    OnboardingItem(
      title: '🌟 أسماء الله الحسنى',
      lottiePath: 'assets/animations/star_names.json',
      useLottie: true,
      primaryColor: AppColors.getCategoryGradient('asma_allah').colors[0],
      secondaryColor: AppColors.getCategoryGradient('asma_allah').colors[1],
      darkColor: AppColors.getCategoryGradient('asma_allah').colors[1],
      emoji: '🌟',
      iconData: Icons.star_rounded,
      animationType: OnboardingAnimationType.asmaAlHusna,
      features: [
        'الأسماء الـ99 كاملة',
        'شرح معنى كل اسم',
        'تصميم إسلامي أنيق',
        'إمكانية الاستماع',
        'حفظ الأسماء المفضلة',
      ],
    ),
    
    // الشاشة الأخيرة - الأذونات
    OnboardingItem(
      title: 'أذونات مطلوبة',
      lottiePath: 'assets/animations/security_shield.json',
      useLottie: true,
      primaryColor: AppColors.info,
      secondaryColor: Colors.blue.shade300,
      darkColor: Colors.blue.shade700,
      emoji: '🔐',
      iconData: Icons.security_rounded,
      animationType: OnboardingAnimationType.permissions,
    ),
  ];
  
  /// الحصول على عدد شاشات الفئات (بدون شاشة الترحيب والأذونات)
  static int get categoryItemsCount => items.length - 2;
  
  /// الحصول على شاشات الفئات فقط
  static List<OnboardingItem> get categoryItems => 
      items.where((item) => item.features != null).toList();
  
  /// إعدادات خاصة لكل نوع من أنواع Lottie
  static Map<OnboardingAnimationType, LottieConfig> get lottieConfigs => {
    OnboardingAnimationType.welcome: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 0.8,
    ),
    OnboardingAnimationType.dailyAthkar: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 1.0,
    ),
    OnboardingAnimationType.islamicDuaa: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 1.0,
    ),
    OnboardingAnimationType.digitalTasbih: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 1.2,
    ),
    OnboardingAnimationType.qiblaDirection: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 0.6, // بطء أكثر للبوصلة
    ),
    OnboardingAnimationType.prayerTimes: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 1.0,
    ),
    OnboardingAnimationType.asmaAlHusna: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 0.7,
    ),
    OnboardingAnimationType.permissions: const LottieConfig(
      repeat: false,
      autoStart: true,
      speed: 1.0,
    ),
  };
}

/// فئة إعدادات Lottie
class LottieConfig {
  final bool repeat;
  final bool autoStart;
  final double speed;
  final Duration? duration;
  
  const LottieConfig({
    this.repeat = true,
    this.autoStart = true,
    this.speed = 1.0,
    this.duration,
  });
}