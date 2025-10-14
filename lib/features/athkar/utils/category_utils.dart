import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import '../../../app/themes/app_theme.dart';

/// أدوات مساعدة لفئات الأذكار - نمط ألوان موحد مع أيقونات إسلامية
class CategoryUtils {
  /// الحصول على أيقونة إسلامية مناسبة لكل فئة
  static IconData getCategoryIcon(String categoryId) {
    switch (categoryId.toLowerCase()) {
      // ===== أذكار الأوقات =====
      case 'morning':
      case 'الصباح':
        return FlutterIslamicIcons.solidPrayer; // صلاة الصباح
        
      case 'evening':
      case 'المساء':
        return FlutterIslamicIcons.solidCrescentMoon; // هلال المساء
        
      case 'sleep':
      case 'النوم':
        return FlutterIslamicIcons.crescentMoon; // هلال النوم (خطي)
        
      case 'wakeup':
      case 'wake_up':
      case 'الاستيقاظ':
        return FlutterIslamicIcons.solidPrayingPerson; // شخص يصلي
      
      // ===== أذكار المنزل =====
      case 'leaving_home':
      case 'الخروج':
      case 'خروج المنزل':
        return FlutterIslamicIcons.solidMuslim; // مسلم يخرج
        
      case 'entering_home':
      case 'الدخول':
      case 'دخول المنزل':
        return FlutterIslamicIcons.solidFamily; // عائلة في المنزل
      
      // ===== أذكار الصلاة =====
      case 'adhan':
      case 'الأذان':
        return FlutterIslamicIcons.solidMinaret; // مئذنة الأذان
        
      case 'after_prayer':
      case 'بعد الصلاة':
        return FlutterIslamicIcons.solidTasbih2; // مسبحة مملوءة
        
      default:
        return FlutterIslamicIcons.solidTasbih2; // الأيقونة الافتراضية
    }
  }

  /// الحصول على لون من الثيم - نمط ترابي موحد 🎨
  static Color getCategoryThemeColor(String categoryId) {
    switch (categoryId.toLowerCase()) {
      // ===== أذكار الأوقات - نمط ترابي دافئ =====
      case 'morning':
      case 'الصباح':
        return const Color(0xFFDAA520); // ذهبي دافئ - شروق الشمس
        
      case 'evening':
      case 'المساء':
        return const Color(0xFF8B6F47); // بني دافئ - غروب الشمس
        
      case 'sleep':
      case 'النوم':
        return const Color(0xFF6B7A8A); // رمادي مزرق هادئ - سكون الليل
        
      case 'wakeup':
      case 'wake_up':
      case 'الاستيقاظ':
        return const Color(0xFFD4A574); // بيج ذهبي - فجر جديد
      
      // ===== أذكار المنزل - نمط ترابي =====
      case 'leaving_home':
      case 'الخروج':
      case 'خروج المنزل':
        return const Color(0xFF7A8B9A); // رمادي مزرق - انطلاق هادئ
        
      case 'entering_home':
      case 'الدخول':
      case 'دخول المنزل':
        return const Color(0xFF8B7355); // بني دافئ - دفء المنزل
      
      // ===== أذكار الصلاة - نمط ترابي =====
      case 'adhan':
      case 'الأذان':
        return const Color(0xFF7A6B8F); // بنفسجي ترابي - نداء مقدس
        
      case 'after_prayer':
      case 'بعد الصلاة':
        return const Color(0xFF6B8B7A); // أخضر ترابي - سكينة بعد الصلاة
        
      default:
        return const Color(0xFF5D7052); // اللون الأساسي
    }
  }

  /// الحصول على تدرج لوني مناسب لكل فئة
  static LinearGradient getCategoryGradient(String categoryId) {
    final baseColor = getCategoryThemeColor(categoryId);
    return LinearGradient(
      colors: [
        baseColor.withOpacity(0.8),
        baseColor,
        baseColor.darken(0.1),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// الحصول على وصف مناسب لكل فئة
  static String getCategoryDescription(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'morning':
      case 'الصباح':
        return 'ابدأ يومك بالأذكار المباركة';
      case 'evening':
      case 'المساء':
        return 'اختتم نهارك بالذكر والدعاء';
      case 'sleep':
      case 'النوم':
        return 'نم آمناً في حفظ الله';
      case 'wakeup':
      case 'wake_up':
      case 'الاستيقاظ':
        return 'استيقظ بحمد الله وشكره';
      case 'leaving_home':
      case 'الخروج':
      case 'خروج المنزل':
        return 'اخرج بحفظ الله وتوفيقه';
      case 'entering_home':
      case 'الدخول':
      case 'دخول المنزل':
        return 'ادخل منزلك بالبركة والسلام';
      case 'adhan':
      case 'الأذان':
        return 'أذكار وأدعية سماع الأذان';
      case 'after_prayer':
      case 'بعد الصلاة':
        return 'أذكار التسبيح بعد الصلاة';
      default:
        return 'أذكار وأدعية من السنة النبوية';
    }
  }

  /// التحقق من أن الفئة من الفئات الأساسية
  static bool isEssentialCategory(String categoryId) {
    const essentialCategories = {
      'morning',
      'الصباح',
      'evening', 
      'المساء',
      'sleep',
      'النوم',
      'prayer',
      'الصلاة',
    };
    return essentialCategories.contains(categoryId.toLowerCase());
  }

  /// تحديد ما إذا كان يجب عرض الوقت للفئة
  static bool shouldShowTime(String categoryId) {
    const hiddenTimeCategories = {
      'morning',
      'الصباح',
      'evening', 
      'المساء',
      'sleep',
      'النوم',
    };
    return !hiddenTimeCategories.contains(categoryId.toLowerCase());
  }
}