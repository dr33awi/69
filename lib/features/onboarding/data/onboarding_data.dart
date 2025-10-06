// lib/features/onboarding/data/onboarding_data.dart - مع دعم Lottie محدث
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
    
    // الشاشة الأخيرة - الأذونات المطلوبة
    OnboardingItem(
      title: '🔐 أذونات مطلوبة',
      lottiePath: 'assets/animations/security_shield.json',
      useLottie: true,
      primaryColor: AppColors.info,
      secondaryColor: Colors.blue.shade300,
      darkColor: Colors.blue.shade700,
      emoji: '🔐',
      iconData: Icons.security_rounded,
      animationType: OnboardingAnimationType.permissions,
      features: [
        'الإشعارات - لإرسال تنبيهات الصلاة والأذكار',
        'الموقع - لحساب أوقات الصلاة بدقة واتجاه القبلة',
        'تحسين البطارية - لضمان عمل التذكيرات في الخلفية',
      ],
    ),
  ];
  
  /// الحصول على عدد شاشات الفئات (بدون شاشة الترحيب والأذونات)
  static int get categoryItemsCount => items.length - 2;
  
  /// الحصول على شاشات الفئات فقط
  static List<OnboardingItem> get categoryItems => 
      items.where((item) => item.features != null && item.features!.length > 3).toList();
  
  /// إعدادات خاصة لكل نوع من أنواع Lottie
  static Map<OnboardingAnimationType, LottieConfig> get lottieConfigs => {
    OnboardingAnimationType.welcome: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 0.8,
      frameRate: 60,
      enableMergePaths: true,
    ),
    OnboardingAnimationType.dailyAthkar: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 1.0,
      frameRate: 30,
      enableMergePaths: true,
    ),
    OnboardingAnimationType.islamicDuaa: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 0.9,
      frameRate: 30,
      enableMergePaths: true,
    ),
    OnboardingAnimationType.digitalTasbih: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 1.2,
      frameRate: 30,
      enableMergePaths: true,
    ),
    OnboardingAnimationType.qiblaDirection: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 0.6,
      frameRate: 24,
      enableMergePaths: true,
    ),
    OnboardingAnimationType.prayerTimes: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 1.0,
      frameRate: 30,
      enableMergePaths: true,
    ),
    OnboardingAnimationType.asmaAlHusna: const LottieConfig(
      repeat: true,
      autoStart: true,
      speed: 0.7,
      frameRate: 24,
      enableMergePaths: true,
    ),
    OnboardingAnimationType.permissions: const LottieConfig(
      repeat: false,
      autoStart: true,
      speed: 1.0,
      frameRate: 30,
      enableMergePaths: true,
    ),
  };
  
  /// إعدادات الألوان المخصصة لكل أنيميشن
  static Map<OnboardingAnimationType, List<Color>> get animationColors => {
    OnboardingAnimationType.welcome: [
      Colors.white,
      Colors.amber.shade100,
    ],
    OnboardingAnimationType.dailyAthkar: [
      Colors.white,
      Colors.orange.shade100,
    ],
    OnboardingAnimationType.islamicDuaa: [
      Colors.white,
      Colors.blue.shade100,
    ],
    OnboardingAnimationType.digitalTasbih: [
      Colors.white,
      Colors.green.shade100,
    ],
    OnboardingAnimationType.qiblaDirection: [
      Colors.white,
      Colors.purple.shade100,
    ],
    OnboardingAnimationType.prayerTimes: [
      Colors.white,
      Colors.teal.shade100,
    ],
    OnboardingAnimationType.asmaAlHusna: [
      Colors.white,
      Colors.yellow.shade100,
    ],
    OnboardingAnimationType.permissions: [
      Colors.white,
      Colors.blue.shade100,
    ],
  };
  
  /// التحقق من صحة ملف Lottie
  static bool isValidLottieFile(String? path) {
    return path != null && 
           path.isNotEmpty && 
           path.endsWith('.json') &&
           path.startsWith('assets/animations/');
  }
  
  /// الحصول على مسار الأنيميشن الاحتياطي
  static String getFallbackIconPath(OnboardingAnimationType type) {
    switch (type) {
      case OnboardingAnimationType.welcome:
        return 'assets/icons/mosque.svg';
      case OnboardingAnimationType.dailyAthkar:
        return 'assets/icons/sun.svg';
      case OnboardingAnimationType.islamicDuaa:
        return 'assets/icons/hands.svg';
      case OnboardingAnimationType.digitalTasbih:
        return 'assets/icons/beads.svg';
      case OnboardingAnimationType.qiblaDirection:
        return 'assets/icons/compass.svg';
      case OnboardingAnimationType.prayerTimes:
        return 'assets/icons/clock.svg';
      case OnboardingAnimationType.asmaAlHusna:
        return 'assets/icons/star.svg';
      case OnboardingAnimationType.permissions:
        return 'assets/icons/shield.svg';
      default:
        return 'assets/icons/default.svg';
    }
  }
}

/// فئة إعدادات Lottie محدثة
class LottieConfig {
  final bool repeat;
  final bool autoStart;
  final double speed;
  final Duration? duration;
  final int frameRate;
  final bool enableMergePaths;
  final bool enableApplyingOpacityToLayers;
  
  const LottieConfig({
    this.repeat = true,
    this.autoStart = true,
    this.speed = 1.0,
    this.duration,
    this.frameRate = 30,
    this.enableMergePaths = true,
    this.enableApplyingOpacityToLayers = false,
  });
  
  /// تحويل إلى LottieOptions
  LottieOptions toLottieOptions() {
    return LottieOptions(
      enableMergePaths: enableMergePaths,
      enableApplyingOpacityToLayers: enableApplyingOpacityToLayers,
    );
  }
}