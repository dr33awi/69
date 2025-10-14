// lib/core/infrastructure/services/notifications/constants/notification_messages.dart

import 'dart:math';

/// ثوابت رسائل الإشعارات
/// يحتوي على النصوص المستخدمة فعلياً في نظام الإشعارات
class NotificationMessages {
  NotificationMessages._();

  // ==================== إشعارات الصلاة ====================
  
  /// رسائل التنبيه قبل وقت الصلاة
  static const Map<String, String> prayerReminders = {
    'الفجر': 'قُم إلى الفلاح، فالصلاة خير من النوم 🌅',
    'الظهر': 'اترك الدنيا قليلاً واسعَ إلى ذكر الله ☀️',
    'العصر': 'حافظوا على الصلوات والصلاة الوسطى 🌤️',
    'المغرب': 'أقبِل على ربك، فقد آن وقت اللقاء 🌆',
    'العشاء': 'اختم يومك بالوقوف بين يدي الله 🌙',
  };
  
  /// رسائل عند حلول وقت الصلاة
  static const Map<String, String> prayerTimes = {
    'الفجر': 'الله أكبر، الصلاة خير من النوم 🌅',
    'الظهر': 'حي على الصلاة، حي على الفلاح ☀️',
    'العصر': 'إن الصلاة كانت على المؤمنين كتاباً موقوتاً 🌤️',
    'المغرب': 'الله أكبر، أجِب نداء ربك 🌆',
    'العشاء': 'وأقم الصلاة، إن الصلاة تنهى عن الفحشاء والمنكر 🌙',
  };
  
  /// عناوين إشعارات الصلاة - قبل الوقت
  static String getPrayerReminderTitle(String prayerName, int minutesBefore) {
    return '🕌 تنبيه: $prayerName بعد $minutesBefore دقيقة';
  }
  
  /// عناوين إشعارات الصلاة - وقت الصلاة
  static String getPrayerTimeTitle(String prayerName) {
    return '🕌 حان وقت $prayerName';
  }
  
  /// محتوى إشعار التنبيه قبل الصلاة
  static String getPrayerReminderBody(String prayerName) {
    return prayerReminders[prayerName] ?? 'استعد لأداء الصلاة';
  }
  
  /// محتوى إشعار وقت الصلاة
  static String getPrayerTimeBody(String prayerName) {
    return prayerTimes[prayerName] ?? 'حان الآن موعد الصلاة';
  }

  // ==================== إشعارات الأذكار ====================
  
  /// رسائل الأذكار المخصصة حسب الفئة
  static const Map<String, Map<String, String>> athkarMessages = {
    'morning': {
      'title': '🌅 أذكار الصباح',
      'body': 'ابدأ يومك بذكر الله، صباح مبارك',
    },
    'evening': {
      'title': '🌆 أذكار المساء',
      'body': 'اختم يومك بالأذكار، مساء النور',
    },
    'sleep': {
      'title': '🌙 أذكار النوم',
      'body': 'لا تنسَ أذكارك قبل النوم',
    },
    'wakeup': {
      'title': '☀️ أذكار الاستيقاظ',
      'body': 'الحمد لله الذي أحيانا بعد ما أماتنا',
    },
    'prayer': {
      'title': '🤲 أذكار بعد الصلاة',
      'body': 'تذكر الأذكار بعد الصلاة',
    },
    'general': {
      'title': '📿 أذكار عامة',
      'body': 'وقت الذكر والدعاء',
    },
    'friday': {
      'title': '🕌 أذكار يوم الجمعة',
      'body': 'بارك الله في جمعتك',
    },
    'quran': {
      'title': '📖 أذكار القرآن',
      'body': 'وقت قراءة القرآن والتدبر',
    },
    'eating': {
      'title': '🍽️ أذكار الطعام',
      'body': 'تذكر أذكار الطعام',
    },
    'travel': {
      'title': '✈️ أذكار السفر',
      'body': 'أذكار المسافر والدعاء',
    },
  };
  
  /// رسائل تحفيزية متنوعة للأذكار
  static const List<String> motivationalQuotes = [
    'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ 💚',
    'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ 📿',
    'وَالذَّاكِرِينَ اللَّهَ كَثِيرًا وَالذَّاكِرَاتِ أَعَدَّ اللَّهُ لَهُم مَّغْفِرَةً وَأَجْرًا عَظِيمًا ✨',
    'سبحان الله وبحمده، سبحان الله العظيم 🤲',
    'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير 🌟',
    'اللهم صل وسلم على نبينا محمد 💫',
    'الحمد لله الذي بنعمته تتم الصالحات 🌸',
    'لا حول ولا قوة إلا بالله العلي العظيم ✨',
    'أستغفر الله العظيم وأتوب إليه 🕯️',
    'رب اغفر لي ولوالدي وللمؤمنين يوم يقوم الحساب 🌺',
  ];
  
  /// الحصول على رسالة تحفيزية عشوائية
  static String getRandomMotivation() {
    final random = Random();
    return motivationalQuotes[random.nextInt(motivationalQuotes.length)];
  }
  
  /// الحصول على رسالة الأذكار حسب المعرف
  static Map<String, String> getAthkarMessage(String categoryId, String categoryName) {
    // البحث عن رسالة مخصصة
    if (athkarMessages.containsKey(categoryId)) {
      return athkarMessages[categoryId]!;
    }
    
    // رسالة افتراضية مع رمز تعبيري
    return {
      'title': '📿 $categoryName',
      'body': 'وقت قراءة $categoryName',
    };
  }
  
  /// عنوان إشعار الأذكار
  static String getAthkarTitle(String categoryId, String categoryName) {
    return getAthkarMessage(categoryId, categoryName)['title']!;
  }
  
  /// محتوى إشعار الأذكار
  static String getAthkarBody(String categoryId, String categoryName) {
    return getAthkarMessage(categoryId, categoryName)['body']!;
  }
}