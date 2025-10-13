// lib/core/infrastructure/services/notifications/constants/notification_messages.dart

import 'dart:math';

/// ثوابت رسائل الإشعارات
/// يحتوي على جميع النصوص المستخدمة في الإشعارات لسهولة الصيانة والتعديل
class NotificationMessages {
  NotificationMessages._();

  // ==================== إشعارات الصلاة ====================
  
  /// رسائل التنبيه قبل وقت الصلاة
  static const Map<String, String> prayerReminders = {
    'الفجر': 'استعد للصلاة، بارك الله في صباحك 🌅',
    'الظهر': 'حان وقت الاستعداد لصلاة الظهر ☀️',
    'العصر': 'استعد لصلاة العصر، لا تفوت الوقت 🌤️',
    'المغرب': 'حان وقت الصلاة 🌆',
    'العشاء': 'آخر صلاة في اليوم، استعد 🌙',
  };
  
  /// رسائل عند حلول وقت الصلاة
  static const Map<String, String> prayerTimes = {
    'الفجر': 'الصلاة خير من النوم 🌅',
    'الظهر': 'توقف قليلاً وصلِّ ☀️',
    'العصر': 'وقت صلاة العصر المباركة 🌤️',
    'المغرب': 'أذان المغرب، حان وقت الصلاة 🌆',
    'العشاء': 'ختام يومك بالصلاة 🌙',
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
    'اذكر الله يذكرك 💚',
    'لا تنسَ نصيبك من الذكر اليوم 📿',
    'دقيقة واحدة من وقتك لذكر الله ✨',
    'البركة في الذكر والدعاء 🤲',
    'اجعل لسانك رطباً بذكر الله 🌟',
    'الذكر راحة للقلب وطمأنينة للنفس 💫',
    'من أذكار اليوم تبدأ البركات 🌸',
    'ذكر الله أمان وسكينة ✨',
    'لحظات مع الله تملأ القلب نوراً 🕯️',
    'الذكر غذاء الروح 🌺',
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

  // ==================== الرموز التعبيرية للفئات ====================
  
  /// رموز تعبيرية للصلوات
  static const Map<String, String> prayerEmojis = {
    'fajr': '🌅',
    'sunrise': '🌄',
    'dhuhr': '☀️',
    'asr': '🌤️',
    'maghrib': '🌆',
    'isha': '🌙',
  };
  
  /// رموز تعبيرية لفئات الأذكار
  static const Map<String, String> athkarEmojis = {
    'morning': '🌅',
    'evening': '🌆',
    'sleep': '🌙',
    'wakeup': '☀️',
    'prayer': '🤲',
    'general': '📿',
    'friday': '🕌',
    'quran': '📖',
    'eating': '🍽️',
    'travel': '✈️',
  };
  
  /// الحصول على رمز تعبيري للصلاة
  static String getPrayerEmoji(String prayerId) {
    return prayerEmojis[prayerId] ?? '🕌';
  }
  
  /// الحصول على رمز تعبيري للذكر
  static String getAthkarEmoji(String categoryId) {
    return athkarEmojis[categoryId] ?? '📿';
  }

  // ==================== رسائل النظام ====================
  
  /// رسائل نجاح العمليات
  static const Map<String, String> successMessages = {
    'notification_enabled': 'تم تفعيل الإشعارات بنجاح ✅',
    'settings_saved': 'تم حفظ الإعدادات بنجاح ✅',
    'reminder_scheduled': 'تم جدولة التذكير بنجاح ✅',
    'data_synced': 'تم تحديث البيانات بنجاح ✅',
  };
  
  /// رسائل الأخطاء
  static const Map<String, String> errorMessages = {
    'permission_denied': 'تم رفض إذن الإشعارات ❌',
    'save_failed': 'فشل حفظ الإعدادات ❌',
    'location_error': 'خطأ في تحديد الموقع ❌',
    'network_error': 'تحقق من اتصال الإنترنت ❌',
  };
  
  /// رسائل تحذيرية
  static const Map<String, String> warningMessages = {
    'enable_notifications': 'يجب تفعيل أذونات الإشعارات أولاً ⚠️',
    'unsaved_changes': 'لديك تغييرات غير محفوظة ⚠️',
    'location_required': 'الموقع مطلوب لحساب مواقيت الصلاة ⚠️',
  };

  // ==================== رسائل معلوماتية ====================
  
  /// نصائح وإرشادات
  static const List<String> tips = [
    'يمكنك تخصيص أوقات التذكيرات من الإعدادات 💡',
    'فعّل الاهتزاز للحصول على تنبيهات أفضل 📳',
    'يمكنك تفعيل إشعارات صلوات معينة فقط ⚙️',
    'راجع إعدادات الإشعارات للتخصيص الكامل 🎯',
    'تأكد من تفعيل البطارية التلقائية للتطبيق 🔋',
  ];
  
  /// الحصول على نصيحة عشوائية
  static String getRandomTip() {
    final random = Random();
    return tips[random.nextInt(tips.length)];
  }
  
  /// رسائل الترحيب
  static const Map<String, String> welcomeMessages = {
    'first_launch': 'مرحباً بك في تطبيقك الإسلامي 🌟',
    'good_morning': 'صباح الخير، بارك الله في يومك 🌅',
    'good_evening': 'مساء الخير، تقبل الله منك 🌆',
    'good_night': 'تصبح على خير، في رعاية الله 🌙',
  };

  // ==================== رسائل الإنجازات ====================
  
  /// رسائل تشجيعية عند إتمام الأذكار
  static const List<String> completionMessages = [
    'بارك الله فيك! أتممت الأذكار 🎉',
    'أحسنت! تقبل الله منك 💚',
    'ما شاء الله، واصل التميز ⭐',
    'رائع! زادك الله من فضله 🌟',
    'ممتاز! الله يجزيك خيراً 💫',
  ];
  
  /// الحصول على رسالة إنجاز عشوائية
  static String getRandomCompletionMessage() {
    final random = Random();
    return completionMessages[random.nextInt(completionMessages.length)];
  }

  // ==================== رسائل مخصصة حسب الوقت ====================
  
  /// الحصول على رسالة ترحيب حسب الوقت
  static String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return welcomeMessages['good_morning']!;
    } else if (hour >= 12 && hour < 18) {
      return 'طابت أوقاتك 🌤️';
    } else if (hour >= 18 && hour < 21) {
      return welcomeMessages['good_evening']!;
    } else {
      return welcomeMessages['good_night']!;
    }
  }
  
  /// رسالة تذكير حسب عدد الأذكار المتبقية
  static String getRemainingAthkarMessage(int remaining) {
    if (remaining == 0) {
      return getRandomCompletionMessage();
    } else if (remaining == 1) {
      return 'ذكر واحد فقط وتنتهي! 🎯';
    } else if (remaining <= 3) {
      return 'باقي $remaining أذكار فقط 💪';
    } else if (remaining <= 5) {
      return 'باقي $remaining أذكار، واصل 📿';
    } else {
      return 'باقي $remaining ذكر، بالتوفيق ✨';
    }
  }

  // ==================== دوال مساعدة ====================
  
  /// تنسيق وقت الصلاة في الرسالة
  static String formatPrayerTimeMessage(String prayerName, String timeStr) {
    return 'موعد $prayerName: $timeStr';
  }
  
  /// رسالة عدد الدقائق المتبقية
  static String getMinutesRemainingMessage(int minutes) {
    if (minutes <= 0) {
      return 'حان الآن';
    } else if (minutes == 1) {
      return 'بعد دقيقة واحدة';
    } else if (minutes == 2) {
      return 'بعد دقيقتين';
    } else if (minutes <= 10) {
      return 'بعد $minutes دقائق';
    } else {
      return 'بعد $minutes دقيقة';
    }
  }
  
  /// رسالة تذكير بعدد مرات التكرار
  static String getRepetitionMessage(int current, int total) {
    if (current >= total) {
      return 'تم الإنهاء! 🎉';
    }
    return '$current من $total';
  }
}