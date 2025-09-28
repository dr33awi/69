// lib/features/onboarding/data/onboarding_screens_data.dart
import 'package:flutter/material.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import '../models/onboarding_data.dart';

class OnboardingScreensData {
  static List<OnboardingScreen> getScreens() {
    return [
      // الشاشة الأولى: الترحيب
      OnboardingScreen(
        id: 1,
        title: "أهلاً بك في حصن المسلم",
        subtitle: "رفيقك الروحاني اليومي",
        description: "تطبيق شامل للأذكار والأدعية الإسلامية، مصمم ليكون عونك في التقرب إلى الله والمحافظة على الأذكار اليومية",
        icon: Icons.star_purple500_outlined,
        gradient: [AppColors.primary, AppColors.primaryLight],
        features: [
          "أذكار الصباح والمساء",
          "أدعية من القرآن والسنة", 
          "تسبيح رقمي ذكي",
          "أوقات الصلاة الدقيقة"
        ],
        patternType: "spiritual",
      ),

      // الشاشة الثانية: الأذكار والتذكيرات
      OnboardingScreen(
        id: 2,
        title: "أذكارك في جيبك",
        subtitle: "لا تنس ذكر الله أبداً",
        description: "احصل على تذكيرات ذكية لأذكار الصباح والمساء، مع إمكانية تتبع تقدمك وتخصيص أوقاتك المفضلة",
        icon: Icons.notifications_active,
        gradient: [AppColors.accent, AppColors.accentLight],
        features: [
          "تذكيرات مخصصة",
          "تتبع التقدم اليومي",
          "أذكار مصنفة ومنظمة", 
          "إحصائيات شخصية"
        ],
        patternType: "notifications",
      ),

      // الشاشة الثالثة: الصلاة والقبلة
      OnboardingScreen(
        id: 3,
        title: "صلاتك في وقتها",
        subtitle: "لن تفوت صلاة بعد اليوم",
        description: "أوقات صلاة دقيقة مع تحديد موقعك تلقائياً، واتجاه القبلة المضبوط، وتذكيرات للصلوات",
        icon: Icons.explore,
        gradient: [AppColors.tertiary, AppColors.tertiaryLight],
        features: [
          "أوقات صلاة دقيقة",
          "اتجاه القبلة",
          "تذكيرات الصلاة",
          "أذان بأصوات متعددة"
        ],
        patternType: "prayer",
      ),

      // الشاشة الرابعة: الأذونات
      OnboardingScreen(
        id: 4,
        title: "جاهز للبدء؟",
        subtitle: "فعّل الأذونات للحصول على أفضل تجربة",
        description: "نحتاج بعض الأذونات البسيطة لنقدم لك تجربة مثالية في التذكير والتوجيه",
        icon: Icons.check_circle_outline,
        gradient: [AppColors.primary, AppColors.accent],
        permissions: [
          OnboardingPermission(
            icon: Icons.notifications_active,
            title: "الإشعارات",
            description: "لتذكيرك بأوقات الصلاة والأذكار",
            isRequired: true,
            permissionType: AppPermissionType.notification,
          ),
          OnboardingPermission(
            icon: Icons.location_on,
            title: "الموقع",
            description: "لحساب أوقات الصلاة واتجاه القبلة",
            isRequired: true,
            permissionType: AppPermissionType.location,
          ),
          OnboardingPermission(
            icon: Icons.battery_charging_full,
            title: "تحسين البطارية",
            description: "لضمان عمل التذكيرات في الخلفية",
            isRequired: false,
            permissionType: AppPermissionType.batteryOptimization,
          ),
        ],
        patternType: "final",
      ),
    ];
  }
}
