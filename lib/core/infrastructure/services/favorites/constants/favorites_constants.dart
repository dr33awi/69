// lib/core/infrastructure/services/favorites/constants/favorites_constants.dart
// الثوابت ومفاتيح التخزين لنظام المفضلة الموحد

/// ثوابت نظام المفضلة الموحد
class FavoritesConstants {
  // منع إنشاء كائن من هذا الكلاس
  FavoritesConstants._();

  // ==================== مفاتيح التخزين الرئيسية ====================

  /// مفتاح تخزين قائمة المفضلات الرئيسية
  static const String mainFavoritesKey = 'unified_favorites';

  /// مفتاح تخزين إعدادات الترتيب والفلترة
  static const String sortOptionsKey = 'favorites_sort_options';

  /// مفتاح تخزين إحصائيات المفضلة
  static const String statisticsKey = 'favorites_statistics';

  /// مفتاح آخر تحديث للمفضلات
  static const String lastSyncKey = 'favorites_last_sync';

  // ==================== مفاتيح التخزين القديمة (للترحيل) ====================

  /// مفاتيح المفضلات القديمة لكل نوع محتوى
  static const Map<String, String> legacyKeys = {
    'dua': 'dua_favorites',
    'athkar': 'athkar_favorites', 
    'asma_allah': 'asma_allah_favorites',
    'tasbih': 'tasbih_favorites',
    'quran': 'quran_favorites',
    'hadith': 'hadith_favorites',
  };

  // ==================== حدود النظام ====================

  /// الحد الأقصى لعدد المفضلات لكل نوع محتوى
  static const int maxFavoritesPerType = 1000;

  /// الحد الأقصى لعدد المفضلات الإجمالي
  static const int maxTotalFavorites = 5000;

  /// الحد الأقصى لطول العنوان
  static const int maxTitleLength = 100;

  /// الحد الأقصى لطول المحتوى في الفهرس
  static const int maxContentPreviewLength = 200;

  // ==================== إعدادات التخزين المؤقت ====================

  /// مدة صلاحية التخزين المؤقت بالدقائق
  static const int cacheValidityMinutes = 60;

  /// عدد العناصر الأقصى في التخزين المؤقت
  static const int maxCacheSize = 500;

  // ==================== إعدادات البحث ====================

  /// الحد الأدنى لطول كلمة البحث
  static const int minSearchLength = 2;

  /// عدد نتائج البحث الأقصى
  static const int maxSearchResults = 50;

  // ==================== إعدادات التصدير ====================

  /// الأنواع المدعومة للتصدير
  static const List<String> supportedExportFormats = ['txt', 'json'];

  /// الحد الأقصى لحجم ملف التصدير (بالميجابايت)
  static const double maxExportFileSizeMB = 10.0;

  // ==================== رسائل النظام ====================

  /// رسائل النجاح
  static const Map<String, String> successMessages = {
    'added': 'تمت الإضافة للمفضلة بنجاح',
    'removed': 'تمت الإزالة من المفضلة بنجاح',
    'imported': 'تم استيراد المفضلات بنجاح',
    'exported': 'تم تصدير المفضلات بنجاح',
    'cleared': 'تم مسح المفضلات بنجاح',
    'migrated': 'تم ترحيل المفضلات بنجاح',
  };

  /// رسائل الخطأ
  static const Map<String, String> errorMessages = {
    'alreadyExists': 'هذا العنصر موجود في المفضلة مسبقاً',
    'notFound': 'لم يتم العثور على هذا العنصر في المفضلة',
    'limitExceeded': 'تم تجاوز الحد الأقصى للمفضلات',
    'invalidData': 'بيانات غير صالحة',
    'storageError': 'خطأ في التخزين',
    'migrationFailed': 'فشل في ترحيل المفضلات',
    'exportFailed': 'فشل في تصدير المفضلات',
    'importFailed': 'فشل في استيراد المفضلات',
  };

  // ==================== التحقق من صحة البيانات ====================

  /// التحقق من صحة معرف العنصر
  static bool isValidId(String? id) {
    return id != null && id.isNotEmpty && id.length <= 100;
  }

  /// التحقق من صحة العنوان
  static bool isValidTitle(String? title) {
    return title != null && 
           title.isNotEmpty && 
           title.length <= maxTitleLength;
  }

  /// التحقق من صحة المحتوى
  static bool isValidContent(String? content) {
    return content != null && content.isNotEmpty;
  }

  /// التحقق من إمكانية إضافة المزيد من المفضلات
  static bool canAddMoreFavorites(int currentCount, [int typeCount = 0]) {
    return currentCount < maxTotalFavorites && 
           typeCount < maxFavoritesPerType;
  }

  // ==================== وظائف مساعدة ====================

  /// تنظيف النص للفهرسة والبحث
  static String cleanTextForSearch(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  /// قطع النص للعرض المختصر
  static String truncateText(String text, [int maxLength = maxContentPreviewLength]) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// إنشاء معرف فريد للعنصر
  static String generateFavoriteId(String contentType, String originalId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${contentType}_${originalId}_$timestamp';
  }

  /// الحصول على أولوية النوع للترتيب
  static int getContentTypePriority(String contentType) {
    const priorities = {
      'dua': 1,
      'athkar': 2,
      'asma_allah': 3,
      'quran': 4,
      'hadith': 5,
      'tasbih': 6,
    };
    return priorities[contentType] ?? 999;
  }
}