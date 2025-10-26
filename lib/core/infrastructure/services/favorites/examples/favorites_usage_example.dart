// lib/core/infrastructure/services/favorites/examples/favorites_usage_example.dart
// أمثلة على استخدام نظام المفضلة الموحد

import 'package:flutter/material.dart';
import '../favorites_service.dart';
import '../models/favorite_models.dart';
import '../extensions/favorites_extensions.dart';
import '../screens/favorites_screen.dart';

/// مثال على استخدام نظام المفضلة
/// 
/// هذا الملف يحتوي على أمثلة عملية لاستخدام نظام المفضلة الموحد
class FavoritesUsageExample {
  
  // ==================== أمثلة على إضافة عناصر للمفضلة ====================
  
  /// مثال: إضافة دعاء للمفضلة
  static Future<void> addDuaExample(BuildContext context) async {
    // الطريقة 1: باستخدام الإضافة (Extensions) - الطريقة المفضلة
    final success = await context.addDuaToFavorites(
      duaId: 'dua_morning_1',
      title: 'دعاء الصباح',
      arabicText: 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا...',
      translation: 'اللهم بك نبدأ صباحنا وبك نختم مساءنا...',
      virtue: 'من قالها حين يصبح كان له عدل رقبة من ولد إسماعيل',
      source: 'صحيح مسلم',
      reference: '2723',
      categoryId: 'morning',
    );
    
    if (success) {
      print('تمت إضافة الدعاء للمفضلة بنجاح');
    }
    
    // الطريقة 2: مباشرة من FavoritesService
    final item = FavoriteItem.fromDua(
      duaId: 'dua_morning_2',
      title: 'دعاء آخر',
      arabicText: 'النص العربي...',
    );
    
    final service = context.favoritesService;
    await service.addFavorite(item);
  }
  
  /// مثال: إضافة ذكر للمفضلة
  static Future<void> addAthkarExample(BuildContext context) async {
    await context.addAthkarToFavorites(
      athkarId: 'athkar_sabah_1',
      text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      fadl: 'من قالها مائة مرة حين يصبح غفرت خطاياه',
      source: 'صحيح البخاري',
      categoryId: 'morning',
      count: 100,
    );
  }
  
  /// مثال: إضافة اسم من أسماء الله للمفضلة
  static Future<void> addAsmaAllahExample(BuildContext context) async {
    await context.addAsmaAllahToFavorites(
      nameId: 'asma_1',
      arabicName: 'الرَّحْمَنُ',
      explanation: 'ذو الرحمة الواسعة التي وسعت كل شيء',
      transliteration: 'Ar-Rahman',
    );
  }
  
  // ==================== أمثلة على إزالة عناصر من المفضلة ====================
  
  /// مثال: إزالة عنصر من المفضلة
  static Future<void> removeFromFavoritesExample(
    BuildContext context,
    String itemId,
  ) async {
    final success = await context.removeFromFavorites(itemId);
    
    if (success) {
      print('تمت إزالة العنصر من المفضلة');
    }
  }
  
  /// مثال: تبديل حالة المفضلة
  static Future<void> toggleFavoriteExample(
    BuildContext context,
    FavoriteItem item,
  ) async {
    final isNowFavorite = await context.toggleFavorite(item);
    
    if (isNowFavorite) {
      print('تمت الإضافة للمفضلة');
    } else {
      print('تمت الإزالة من المفضلة');
    }
  }
  
  // ==================== أمثلة على الاستعلامات ====================
  
  /// مثال: التحقق من وجود عنصر في المفضلة
  static Future<void> checkIsFavoriteExample(
    BuildContext context,
    String itemId,
  ) async {
    final isFavorite = await context.isFavorite(itemId);
    
    if (isFavorite) {
      print('العنصر موجود في المفضلة');
    } else {
      print('العنصر غير موجود في المفضلة');
    }
  }
  
  /// مثال: الحصول على جميع المفضلات
  static Future<void> getAllFavoritesExample(BuildContext context) async {
    final favorites = await context.getAllFavorites();
    
    print('عدد المفضلات: ${favorites.length}');
    
    for (final item in favorites) {
      print('- ${item.title} (${item.contentType.displayName})');
    }
  }
  
  /// مثال: الحصول على مفضلات نوع معين
  static Future<void> getFavoritesByTypeExample(BuildContext context) async {
    // الحصول على الأدعية المفضلة فقط
    final duas = await context.getFavoritesByType(FavoriteContentType.dua);
    print('عدد الأدعية المفضلة: ${duas.length}');
    
    // الحصول على الأذكار المفضلة فقط
    final athkar = await context.getFavoritesByType(FavoriteContentType.athkar);
    print('عدد الأذكار المفضلة: ${athkar.length}');
    
    // الحصول على أسماء الله المفضلة فقط
    final asmaAllah = await context.getFavoritesByType(FavoriteContentType.asmaAllah);
    print('عدد أسماء الله المفضلة: ${asmaAllah.length}');
  }
  
  /// مثال: البحث في المفضلات
  static Future<void> searchFavoritesExample(
    BuildContext context,
    String query,
  ) async {
    final results = await context.searchFavorites(query);
    
    print('نتائج البحث عن "$query": ${results.length}');
    
    for (final item in results) {
      print('- ${item.title}');
    }
  }
  
  // ==================== أمثلة على الإحصائيات ====================
  
  /// مثال: الحصول على الإحصائيات
  static Future<void> getStatisticsExample(BuildContext context) async {
    final stats = await context.getFavoritesStatistics();
    
    print('إحصائيات المفضلة:');
    print('- إجمالي العدد: ${stats.totalCount}');
    print('- الأدعية: ${stats.getCountForType(FavoriteContentType.dua)}');
    print('- الأذكار: ${stats.getCountForType(FavoriteContentType.athkar)}');
    print('- أسماء الله: ${stats.getCountForType(FavoriteContentType.asmaAllah)}');
    
    if (stats.mostFavoriteType != null) {
      print('- النوع الأكثر استخداماً: ${stats.mostFavoriteType!.displayName}');
    }
    
    if (stats.lastAddedAt != null) {
      print('- آخر إضافة: ${stats.lastAddedAt}');
    }
  }
  
  /// مثال: الحصول على عدد المفضلات
  static Future<void> getCountExample(BuildContext context) async {
    // العدد الإجمالي
    final totalCount = await context.getTotalFavoritesCount();
    print('إجمالي المفضلات: $totalCount');
    
    // عدد نوع معين
    final duaCount = await context.getFavoritesCountByType(FavoriteContentType.dua);
    print('الأدعية المفضلة: $duaCount');
  }
  
  // ==================== أمثلة على التنقل ====================
  
  /// مثال: فتح شاشة المفضلات
  static Future<void> openFavoritesScreenExample(BuildContext context) async {
    // فتح الشاشة بدون تحديد نوع معين (عرض الكل)
    await context.openFavoritesScreen();
  }
  
  /// مثال: فتح شاشة المفضلات لنوع معين
  static Future<void> openFavoritesScreenWithTypeExample(
    BuildContext context,
  ) async {
    // فتح شاشة المفضلات وعرض الأدعية
    await context.openFavoritesScreen(FavoriteContentType.dua);
  }
  
  /// مثال: فتح الشاشة بطريقة مباشرة
  static void navigateToFavoritesExample(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedFavoritesScreen(
          initialType: FavoriteContentType.athkar,
        ),
      ),
    );
  }
  
  // ==================== أمثلة على العمليات المتقدمة ====================
  
  /// مثال: تحديث إعدادات الترتيب
  static Future<void> updateSortOptionsExample(BuildContext context) async {
    // ترتيب حسب العنوان تصاعدياً
    final options = FavoritesSortOptions(
      sortBy: SortBy.title,
      sortOrder: SortOrder.ascending,
    );
    
    await context.updateFavoritesSortOptions(options);
    print('تم تحديث إعدادات الترتيب');
  }
  
  /// مثال: فلترة حسب النوع مع الترتيب
  static Future<void> filterAndSortExample(BuildContext context) async {
    // فلترة الأدعية وترتيبها حسب تاريخ الإضافة (الأحدث أولاً)
    final options = FavoritesSortOptions(
      sortBy: SortBy.dateAdded,
      sortOrder: SortOrder.descending,
      filterByType: FavoriteContentType.dua,
    );
    
    await context.updateFavoritesSortOptions(options);
  }
  
  /// مثال: مسح جميع المفضلات مع تأكيد
  static Future<void> clearAllWithConfirmationExample(
    BuildContext context,
  ) async {
    await context.clearAllFavoritesWithConfirmation();
  }
  
  /// مثال: مسح مفضلات نوع معين
  static Future<void> clearTypeWithConfirmationExample(
    BuildContext context,
  ) async {
    await context.clearFavoritesByTypeWithConfirmation(
      FavoriteContentType.dua,
    );
  }
  
  // ==================== أمثلة على الاستخدام مع القوائم ====================
  
  /// مثال: استخدام الإضافات مع القوائم
  static void listExtensionsExample() {
    final favorites = <FavoriteItem>[
      // ... قائمة المفضلات
    ];
    
    // فلترة حسب النوع
    final duas = favorites.filterByType(FavoriteContentType.dua);
    
    // فلترة حسب التاريخ
    final recent = favorites.addedAfter(
      DateTime.now().subtract(Duration(days: 7)),
    );
    
    // البحث
    final searchResults = favorites.search('صباح');
    
    // الترتيب
    final sortedByNewest = favorites.sortByNewest();
    final sortedByTitle = favorites.sortByTitle();
    
    // التجميع حسب النوع
    final grouped = favorites.groupByType();
    
    // الإحصائيات السريعة
    final stats = favorites.getQuickStats();
    print('إحصائيات سريعة: $stats');
  }
  
  // ==================== مثال كامل على زر المفضلة ====================
  
  /// مثال: بناء زر مفضلة تفاعلي
  static Widget buildFavoriteButton({
    required BuildContext context,
    required FavoriteItem item,
    required bool isFavorite,
    required Function(bool) onChanged,
  }) {
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        color: isFavorite ? Colors.amber : Colors.grey,
      ),
      onPressed: () async {
        final newState = await context.toggleFavorite(item);
        onChanged(newState);
      },
      tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
    );
  }
  
  // ==================== مثال على عرض قائمة المفضلات ====================
  
  /// مثال: بناء قائمة مفضلات بسيطة
  static Widget buildFavoritesList({
    required BuildContext context,
    required List<FavoriteItem> favorites,
  }) {
    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final item = favorites[index];
        
        return ListTile(
          leading: Icon(item.contentType.icon),
          title: Text(item.title),
          subtitle: Text(item.content),
          trailing: IconButton(
            icon: Icon(Icons.bookmark_rounded),
            onPressed: () async {
              await context.removeFromFavorites(item.id);
            },
          ),
        );
      },
    );
  }
}
