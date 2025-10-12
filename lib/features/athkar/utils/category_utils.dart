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
      case 'صباح':
        return FlutterIslamicIcons.solidPrayer; // صلاة الصباح
        
      case 'evening':
      case 'المساء':
      case 'مساء':
        return FlutterIslamicIcons.solidCrescentMoon; // هلال المساء
        
      case 'sleep':
      case 'النوم':
      case 'نوم':
        return FlutterIslamicIcons.crescentMoon; // هلال النوم (خطي)
        
      case 'wakeup':
      case 'wake_up':
      case 'الاستيقاظ':
      case 'استيقاظ':
      case 'wake':
        return FlutterIslamicIcons.solidPrayingPerson; // شخص يصلي
      
      // ===== أذكار المنزل =====
      case 'leaving_home':
      case 'خروج':
      case 'الخروج':
      case 'خروج المنزل':
      case 'الخروج من المنزل':
        return FlutterIslamicIcons.solidMuslim; // مسلم يخرج
        
      case 'entering_home':
      case 'دخول':
      case 'الدخول':
      case 'دخول المنزل':
      case 'الدخول إلى المنزل':
        return FlutterIslamicIcons.solidFamily; // عائلة في المنزل
      
      // ===== أذكار الصلاة =====
      case 'adhan':
      case 'azan':
      case 'الأذان':
      case 'أذان':
        return FlutterIslamicIcons.solidMinaret; // مئذنة الأذان
        
      case 'after_prayer':
      case 'بعد الصلاة':
      case 'بعد السلام':
      case 'السلام من الصلاة':
        return FlutterIslamicIcons.solidTasbih2; // مسبحة مملوءة
        
      case 'prayer':
      case 'الصلاة':
      case 'صلاة':
      case 'prayers':
        return FlutterIslamicIcons.solidSajadah; // سجادة صلاة مملوءة
      
      // ===== الأكل =====
      case 'eating':
      case 'food':
      case 'الطعام':
      case 'طعام':
      case 'الأكل':
      case 'أكل':
        return FlutterIslamicIcons.solidIftar; // إفطار
        
      // ===== المنزل =====
      case 'home':
      case 'house':
      case 'المنزل':
      case 'منزل':
      case 'البيت':
      case 'بيت':
        return FlutterIslamicIcons.solidFamily; // عائلة
        
      // ===== السفر =====
      case 'travel':
      case 'السفر':
      case 'سفر':
        return FlutterIslamicIcons.solidHadji; // حاج مسافر
        
      // ===== عام =====
      case 'general':
      case 'عامة':
      case 'عام':
        return FlutterIslamicIcons.tasbih2; // مسبحة (خطي)
        
      // ===== القرآن =====
      case 'quran':
      case 'القرآن':
      case 'قرآن':
        return FlutterIslamicIcons.solidQuran2; // مصحف مملوء
        
      // ===== التسبيح =====
      case 'tasbih':
      case 'التسبيح':
      case 'تسبيح':
        return FlutterIslamicIcons.solidTasbih3; // مسبحة ثلاثية
        
      // ===== الدعاء =====
      case 'dua':
      case 'الدعاء':
      case 'دعاء':
        return FlutterIslamicIcons.solidTasbihHand; // يد دعاء
        
      // ===== الاستغفار =====
      case 'istighfar':
      case 'الاستغفار':
      case 'استغفار':
        return FlutterIslamicIcons.solidPrayingPerson; // شخص يدعو
        
      // ===== الجمعة =====
      case 'friday':
      case 'الجمعة':
      case 'جمعة':
        return FlutterIslamicIcons.solidMosque; // مسجد مملوء
        
      // ===== الحج =====
      case 'hajj':
      case 'الحج':
      case 'حج':
        return FlutterIslamicIcons.solidKaaba; // كعبة
        
      // ===== رمضان =====
      case 'ramadan':
      case 'رمضان':
        return FlutterIslamicIcons.solidLantern; // فانوس رمضان
        
      // ===== العيد =====
      case 'eid':
      case 'العيد':
      case 'عيد':
        return FlutterIslamicIcons.solidTakbir; // تكبير العيد
        
      // ===== المرض =====
      case 'illness':
      case 'المرض':
      case 'مرض':
        return FlutterIslamicIcons.solidWudhu; // وضوء/طهارة
        
      // ===== المطر =====
      case 'rain':
      case 'المطر':
      case 'مطر':
        return FlutterIslamicIcons.solidWudhu; // ماء
        
      // ===== الرياح =====
      case 'wind':
      case 'الرياح':
      case 'رياح':
        return FlutterIslamicIcons.solidCrescentMoon; // هلال
        
      // ===== العمل =====
      case 'work':
      case 'العمل':
      case 'عمل':
        return FlutterIslamicIcons.solidCommunity; // مجتمع/عمل
        
      // ===== الدراسة =====
      case 'study':
      case 'الدراسة':
      case 'دراسة':
        return FlutterIslamicIcons.quran2; // مصحف (خطي)
        
      // ===== القلق =====
      case 'anxiety':
      case 'القلق':
      case 'قلق':
        return FlutterIslamicIcons.solidPrayingPerson; // دعاء
        
      // ===== الشكر =====
      case 'gratitude':
      case 'الشكر':
      case 'شكر':
        return FlutterIslamicIcons.solidKowtow; // سجود شكر
        
      // ===== الحماية =====
      case 'protection':
      case 'الحماية':
      case 'حماية':
        return FlutterIslamicIcons.solidAllah; // لفظ الجلالة
        
      // ===== الهداية =====
      case 'guidance':
      case 'الهداية':
      case 'هداية':
        return FlutterIslamicIcons.solidQibla2; // قبلة
        
      // ===== المغفرة =====
      case 'forgiveness':
      case 'المغفرة':
      case 'مغفرة':
        return FlutterIslamicIcons.solidKowtow; // سجود
        
      // ===== النجاح =====
      case 'success':
      case 'النجاح':
      case 'نجاح':
        return FlutterIslamicIcons.solidTawhid; // توحيد
        
      // ===== الصبر =====
      case 'patience':
      case 'الصبر':
      case 'صبر':
        return FlutterIslamicIcons.tasbih3; // مسبحة
        
      // ===== العلم =====
      case 'knowledge':
      case 'العلم':
      case 'علم':
        return FlutterIslamicIcons.quran; // مصحف
        
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
      case 'صباح':
        return const Color(0xFFDAA520); // ذهبي دافئ - شروق الشمس
        
      case 'evening':
      case 'المساء':
      case 'مساء':
        return const Color(0xFF8B6F47); // بني دافئ - غروب الشمس
        
      case 'sleep':
      case 'النوم':
      case 'نوم':
        return const Color(0xFF6B7A8A); // رمادي مزرق هادئ - سكون الليل
        
      case 'wakeup':
      case 'wake_up':
      case 'الاستيقاظ':
      case 'استيقاظ':
      case 'wake':
        return const Color(0xFFD4A574); // بيج ذهبي - فجر جديد
      
      // ===== أذكار المنزل - نمط ترابي =====
      case 'leaving_home':
      case 'خروج':
      case 'الخروج':
      case 'خروج المنزل':
      case 'الخروج من المنزل':
        return const Color(0xFF7A8B9A); // رمادي مزرق - انطلاق هادئ
        
      case 'entering_home':
      case 'دخول':
      case 'الدخول':
      case 'دخول المنزل':
      case 'الدخول إلى المنزل':
        return const Color(0xFF8B7355); // بني دافئ - دفء المنزل
      
      // ===== أذكار الصلاة - نمط ترابي =====
      case 'adhan':
      case 'azan':
      case 'الأذان':
      case 'أذان':
        return const Color(0xFF7A6B8F); // بنفسجي ترابي - نداء مقدس
        
      case 'after_prayer':
      case 'بعد الصلاة':
      case 'بعد السلام':
      case 'السلام من الصلاة':
        return const Color(0xFF6B8B7A); // أخضر ترابي - سكينة بعد الصلاة
        
      case 'prayer':
      case 'الصلاة':
      case 'صلاة':
      case 'prayers':
        return const Color(0xFF5D7052); // أخضر زيتوني - خشوع
      
      // ===== باقي الفئات - نمط ترابي موحد =====
      case 'eating':
      case 'food':
      case 'الطعام':
      case 'طعام':
      case 'الأكل':
      case 'أكل':
        return const Color(0xFF8B7A5B); // بني فاتح - طعام طبيعي
        
      case 'home':
      case 'house':
      case 'المنزل':
      case 'منزل':
      case 'البيت':
      case 'بيت':
        return const Color(0xFF8B7355); // بني دافئ
        
      case 'travel':
      case 'السفر':
      case 'سفر':
        return const Color(0xFF7A8B8A); // رمادي مخضر - رحلة
        
      case 'general':
      case 'عامة':
      case 'عام':
        return const Color(0xFF8B8B7A); // بيج رمادي - متوازن
        
      case 'quran':
      case 'القرآن':
      case 'قرآن':
        return const Color(0xFF704214); // بني داكن - مصحف
        
      case 'tasbih':
      case 'التسبيح':
      case 'تسبيح':
        return const Color(0xFF6B7A6B); // أخضر رمادي - تسبيح
        
      case 'dua':
      case 'الدعاء':
      case 'دعاء':
        return const Color(0xFF7A6B7A); // بنفسجي رمادي - دعاء
        
      case 'istighfar':
      case 'الاستغفار':
      case 'استغفار':
        return const Color(0xFF8B6B7A); // وردي ترابي - توبة
        
      case 'friday':
      case 'الجمعة':
      case 'جمعة':
        return const Color(0xFF6B7A5B); // أخضر زيتوني - جمعة مباركة
        
      case 'hajj':
      case 'الحج':
      case 'حج':
        return const Color(0xFF6B6B6B); // رمادي - كعبة
        
      case 'ramadan':
      case 'رمضان':
        return const Color(0xFF6B5B7A); // بنفسجي داكن - رمضان
        
      case 'eid':
      case 'العيد':
      case 'عيد':
        return const Color(0xFFB8860B); // ذهبي - عيد
        
      case 'illness':
      case 'المرض':
      case 'مرض':
        return const Color(0xFF7A8B6B); // أخضر هادئ - شفاء
        
      case 'rain':
      case 'المطر':
      case 'مطر':
        return const Color(0xFF6B7A8A); // رمادي مزرق - مطر
        
      case 'wind':
      case 'الرياح':
      case 'رياح':
        return const Color(0xFF7A8A8A); // رمادي فاتح - رياح
        
      case 'work':
      case 'العمل':
      case 'عمل':
        return const Color(0xFF8B7A4F); // بني ذهبي - عمل
        
      case 'study':
      case 'الدراسة':
      case 'دراسة':
        return const Color(0xFF5B6B7A); // أزرق رمادي - دراسة
        
      case 'anxiety':
      case 'القلق':
      case 'قلق':
        return const Color(0xFF6B8A7A); // تركوازي ترابي - طمأنينة
        
      case 'gratitude':
      case 'الشكر':
      case 'شكر':
        return const Color(0xFF9B8B5D); // أصفر ترابي - شكر
        
      case 'protection':
      case 'الحماية':
      case 'حماية':
        return const Color(0xFF6B7A5B); // أخضر زيتوني - حماية
        
      case 'guidance':
      case 'الهداية':
      case 'هداية':
        return const Color(0xFF6B5B6B); // بنفسجي رمادي - هداية
        
      case 'forgiveness':
      case 'المغفرة':
      case 'مغفرة':
        return const Color(0xFF8B6B7A); // وردي ترابي - مغفرة
        
      case 'success':
      case 'النجاح':
      case 'نجاح':
        return const Color(0xFF6B7A5B); // أخضر ترابي - نجاح
        
      case 'patience':
      case 'الصبر':
      case 'صبر':
        return const Color(0xFF6B7A7A); // رمادي - صبر
        
      case 'knowledge':
      case 'العلم':
      case 'علم':
        return const Color(0xFF5B6B7A); // أزرق رمادي - علم
        
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
      case 'استيقاظ':
      case 'wake':
        return 'استيقظ بحمد الله وشكره';
      case 'leaving_home':
      case 'خروج':
      case 'الخروج':
      case 'خروج المنزل':
      case 'الخروج من المنزل':
        return 'اخرج بحفظ الله وتوفيقه';
      case 'entering_home':
      case 'دخول':
      case 'الدخول':
      case 'دخول المنزل':
      case 'الدخول إلى المنزل':
        return 'ادخل منزلك بالبركة والسلام';
      case 'adhan':
      case 'azan':
      case 'الأذان':
      case 'أذان':
        return 'أذكار وأدعية سماع الأذان';
      case 'after_prayer':
      case 'بعد الصلاة':
      case 'بعد السلام':
      case 'السلام من الصلاة':
        return 'أذكار التسبيح بعد الصلاة';
      case 'prayer':
      case 'الصلاة':
        return 'أذكار قبل وبعد الصلاة';
      case 'eating':
      case 'الطعام':
        return 'بارك في طعامك وشرابك';
      case 'travel':
      case 'السفر':
        return 'استعن بالله في سفرك';
      case 'general':
      case 'عامة':
        return 'أذكار متنوعة لكل وقت';
      case 'quran':
      case 'القرآن':
        return 'آيات كريمة للحفظ والأمان';
      case 'tasbih':
      case 'التسبيح':
        return 'سبح الله في كل وقت';
      case 'dua':
      case 'الدعاء':
        return 'ادع الله بخير الدعاء';
      case 'istighfar':
      case 'الاستغفار':
        return 'استغفر الله من كل ذنب';
      case 'friday':
      case 'الجمعة':
        return 'بركات يوم الجمعة المبارك';
      case 'hajj':
      case 'الحج':
        return 'أذكار الحج والعمرة';
      case 'ramadan':
      case 'رمضان':
        return 'أذكار الشهر الكريم';
      case 'eid':
      case 'العيد':
        return 'فرحة العيد بالذكر';
      case 'illness':
      case 'المرض':
        return 'الدعاء للشفاء والعافية';
      case 'rain':
      case 'المطر':
        return 'استبشر بالمطر والرحمة';
      case 'wind':
      case 'الرياح':
        return 'استعذ من شر الرياح';
      case 'work':
      case 'العمل':
        return 'بارك الله في عملك';
      case 'study':
      case 'الدراسة':
        return 'ادع الله بالتوفيق في العلم';
      case 'anxiety':
      case 'القلق':
        return 'اطمئن بذكر الله';
      case 'gratitude':
      case 'الشكر':
        return 'احمد الله على نعمه';
      case 'protection':
      case 'الحماية':
        return 'احتم بحفظ الله ورعايته';
      case 'guidance':
      case 'الهداية':
        return 'اطلب الهداية من الله';
      case 'forgiveness':
      case 'المغفرة':
        return 'اطلب المغفرة والرحمة';
      case 'success':
      case 'النجاح':
        return 'ادع الله بالتوفيق والنجاح';
      case 'patience':
      case 'الصبر':
        return 'اصبر واحتسب الأجر';
      case 'knowledge':
      case 'العلم':
        return 'اطلب من الله العلم النافع';
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

  /// الحصول على أولوية العرض للفئة (أقل رقم = أولوية أعلى)
  static int getCategoryPriority(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'morning':
      case 'الصباح':
        return 1;
      case 'evening':
      case 'المساء':
        return 2;
      case 'prayer':
      case 'الصلاة':
        return 3;
      case 'after_prayer':
      case 'بعد الصلاة':
      case 'بعد السلام':
      case 'السلام من الصلاة':
        return 4;
      case 'adhan':
      case 'azan':
      case 'الأذان':
      case 'أذان':
        return 4;
      case 'sleep':
      case 'النوم':
        return 5;
      case 'wakeup':
      case 'wake_up':
      case 'الاستيقاظ':
      case 'استيقاظ':
      case 'wake':
        return 6;
      case 'leaving_home':
      case 'خروج':
      case 'الخروج':
      case 'خروج المنزل':
      case 'الخروج من المنزل':
        return 7;
      case 'entering_home':
      case 'دخول':
      case 'الدخول':
      case 'دخول المنزل':
      case 'الدخول إلى المنزل':
        return 8;
      case 'eating':
      case 'الطعام':
        return 9;
      case 'quran':
      case 'القرآن':
        return 10;
      case 'tasbih':
      case 'التسبيح':
        return 11;
      case 'dua':
      case 'الدعاء':
        return 12;
      case 'istighfar':
      case 'الاستغفار':
        return 13;
      case 'friday':
      case 'الجمعة':
        return 14;
      case 'travel':
      case 'السفر':
        return 15;
      case 'ramadan':
      case 'رمضان':
        return 16;
      case 'hajj':
      case 'الحج':
        return 17;
      case 'eid':
      case 'العيد':
        return 18;
      case 'illness':
      case 'المرض':
        return 19;
      case 'rain':
      case 'المطر':
        return 20;
      case 'wind':
      case 'الرياح':
        return 21;
      case 'general':
      case 'عامة':
        return 22;
      default:
        return 99;
    }
  }
}