// lib/core/infrastructure/services/favorites/extensions/favorites_extensions.dart
// امتدادات لسهولة الوصول لخدمة المفضلة الموحدة من أي مكان في التطبيق

import 'package:flutter/material.dart';
import '../../../../../app/di/service_locator.dart';
import '../favorites_service.dart';
import '../models/favorite_models.dart';
import '../../text/models/text_settings_models.dart' as text_models;

/// امتدادات BuildContext للوصول السهل لخدمة المفضلة
extension FavoritesContextExtensions on BuildContext {
  /// الحصول على خدمة المفضلة
  FavoritesService get favoritesService => getIt<FavoritesService>();

  // ==================== العمليات السريعة ====================

  /// إضافة عنصر للمفضلة بسرعة
  Future<bool> addToFavorites(FavoriteItem item) async {
    return await favoritesService.addFavorite(item);
  }

  /// إزالة عنصر من المفضلة بسرعة
  Future<bool> removeFromFavorites(String itemId) async {
    return await favoritesService.removeFavorite(itemId);
  }

  /// تبديل حالة المفضلة
  Future<bool> toggleFavorite(FavoriteItem item) async {
    return await favoritesService.toggleFavorite(item);
  }

  /// التحقق من وجود عنصر في المفضلة
  Future<bool> isFavorite(String itemId) async {
    return await favoritesService.isFavorite(itemId);
  }

  // ==================== عمليات الأدعية ====================

  /// إضافة دعاء للمفضلة
  Future<bool> addDuaToFavorites({
    required String duaId,
    required String title,
    required String arabicText,
    String? transliteration,
    String? translation,
    String? virtue,
    String? source,
    String? reference,
    String? categoryId,
  }) async {
    final favoriteItem = FavoriteItem.fromDua(
      duaId: duaId,
      title: title,
      arabicText: arabicText,
      transliteration: transliteration,
      translation: translation,
      virtue: virtue,
      source: source,
      reference: reference,
      categoryId: categoryId,
    );

    final success = await addToFavorites(favoriteItem);
    
    if (success) {
      _showSuccessMessage('تمت إضافة الدعاء للمفضلة');
    }
    
    return success;
  }

  /// إزالة دعاء من المفضلة
  Future<bool> removeDuaFromFavorites(String duaId) async {
    final success = await removeFromFavorites(duaId);
    
    if (success) {
      _showSuccessMessage('تمت إزالة الدعاء من المفضلة');
    }
    
    return success;
  }

  // ==================== عمليات الأذكار ====================

  /// إضافة ذكر للمفضلة
  Future<bool> addAthkarToFavorites({
    required String athkarId,
    required String text,
    String? fadl,
    String? source,
    String? categoryId,
    int? count,
  }) async {
    final favoriteItem = FavoriteItem.fromAthkar(
      athkarId: athkarId,
      text: text,
      fadl: fadl,
      source: source,
      categoryId: categoryId,
      count: count,
    );

    final success = await addToFavorites(favoriteItem);
    
    if (success) {
      _showSuccessMessage('تمت إضافة الذكر للمفضلة');
    }
    
    return success;
  }

  /// إزالة ذكر من المفضلة
  Future<bool> removeAthkarFromFavorites(String athkarId) async {
    final success = await removeFromFavorites(athkarId);
    
    if (success) {
      _showSuccessMessage('تمت إزالة الذكر من المفضلة');
    }
    
    return success;
  }

  // ==================== عمليات أسماء الله الحسنى ====================

  /// إضافة اسم من أسماء الله للمفضلة
  Future<bool> addAsmaAllahToFavorites({
    required String nameId,
    required String arabicName,
    required String meaning,
    required String explanation,
    String? transliteration,
  }) async {
    final favoriteItem = FavoriteItem.fromAsmaAllah(
      nameId: nameId,
      arabicName: arabicName,
      meaning: meaning,
      explanation: explanation,
      transliteration: transliteration,
    );

    final success = await addToFavorites(favoriteItem);
    
    if (success) {
      _showSuccessMessage('تمت إضافة الاسم للمفضلة');
    }
    
    return success;
  }

  /// إزالة اسم من أسماء الله من المفضلة
  Future<bool> removeAsmaAllahFromFavorites(String nameId) async {
    final success = await removeFromFavorites(nameId);
    
    if (success) {
      _showSuccessMessage('تمت إزالة الاسم من المفضلة');
    }
    
    return success;
  }

  // ==================== عمليات التسبيح ====================

  /// إضافة ذكر التسبيح للمفضلة
  Future<bool> addTasbihToFavorites({
    required String dhikrId,
    required String text,
    String? virtue,
    int? recommendedCount,
    String? category,
  }) async {
    final favoriteItem = FavoriteItem.fromTasbih(
      dhikrId: dhikrId,
      text: text,
      virtue: virtue,
      recommendedCount: recommendedCount,
      category: category,
    );

    final success = await addToFavorites(favoriteItem);
    
    if (success) {
      _showSuccessMessage('تمت إضافة الذكر للمفضلة');
    }
    
    return success;
  }

  /// إزالة ذكر التسبيح من المفضلة
  Future<bool> removeTasbihFromFavorites(String dhikrId) async {
    final success = await removeFromFavorites(dhikrId);
    
    if (success) {
      _showSuccessMessage('تمت إزالة الذكر من المفضلة');
    }
    
    return success;
  }

  // ==================== الاستعلامات ====================

  /// الحصول على جميع المفضلات
  Future<List<FavoriteItem>> getAllFavorites() async {
    return await favoritesService.getAllFavorites();
  }

  /// الحصول على مفضلات نوع معين
  Future<List<FavoriteItem>> getFavoritesByType(FavoriteContentType type) async {
    return await favoritesService.getFavoritesByType(type);
  }

  /// البحث في المفضلات
  Future<List<FavoriteItem>> searchFavorites(String query) async {
    return await favoritesService.searchFavorites(query);
  }

  /// الحصول على إحصائيات المفضلة
  Future<FavoritesStatistics> getFavoritesStatistics() async {
    return await favoritesService.getStatistics();
  }

  /// الحصول على عدد المفضلات حسب النوع
  Future<int> getFavoritesCountByType(FavoriteContentType type) async {
    return await favoritesService.getCountByType(type);
  }

  /// الحصول على العدد الإجمالي للمفضلات
  Future<int> getTotalFavoritesCount() async {
    return await favoritesService.getTotalCount();
  }

  // ==================== العرض والتنقل ====================

  /// فتح شاشة المفضلات الموحدة
  Future<void> openFavoritesScreen([FavoriteContentType? initialType]) async {
    // TODO: سيتم تنفيذه عند إنشاء الشاشة
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => UnifiedFavoritesScreen(initialType: initialType),
    // ));
  }

  /// فتح شاشة البحث في المفضلات
  Future<void> openFavoritesSearch() async {
    // TODO: سيتم تنفيذه عند إنشاء شاشة البحث
  }

  // ==================== عمليات متقدمة ====================

  /// مسح جميع المفضلات (مع تأكيد)
  Future<void> clearAllFavoritesWithConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: const Text('مسح جميع المفضلات'),
        content: const Text('هل أنت متأكد من حذف جميع المفضلات؟\nهذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await favoritesService.clearAllFavorites();
      _showSuccessMessage('تم حذف جميع المفضلات');
    }
  }

  /// مسح مفضلات نوع معين (مع تأكيد)
  Future<void> clearFavoritesByTypeWithConfirmation(FavoriteContentType type) async {
    final confirmed = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text('مسح ${type.displayName}'),
        content: Text('هل أنت متأكد من حذف جميع ${type.displayName} المفضلة؟\nهذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await favoritesService.clearFavoritesByType(type);
      _showSuccessMessage('تم حذف جميع ${type.displayName} المفضلة');
    }
  }

  /// تحديث إعدادات الترتيب
  Future<void> updateFavoritesSortOptions(FavoritesSortOptions options) async {
    await favoritesService.updateSortOptions(options);
  }

  /// الحصول على إعدادات الترتيب الحالية
  FavoritesSortOptions getFavoritesSortOptions() {
    return favoritesService.sortOptions;
  }

  // ==================== وظائف مساعدة ====================

  /// عرض رسالة نجاح
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }


}

/// امتدادات لتحويل أنواع المحتوى
extension FavoriteContentTypeExtensions on FavoriteContentType {
  /// تحويل إلى ContentType لنظام إعدادات النصوص
  text_models.ContentType get toTextContentType {
    switch (this) {
      case FavoriteContentType.dua:
        return text_models.ContentType.dua;
      case FavoriteContentType.athkar:
        return text_models.ContentType.athkar;
      case FavoriteContentType.asmaAllah:
        return text_models.ContentType.asmaAllah;
      case FavoriteContentType.tasbih:
        // التسبيح يمكن أن يستخدم إعدادات الأذكار
        return text_models.ContentType.athkar;
    }
  }
}

/// امتدادات للقوائم
extension FavoriteItemListExtensions on List<FavoriteItem> {
  /// فلترة حسب النوع
  List<FavoriteItem> filterByType(FavoriteContentType type) {
    return where((item) => item.contentType == type).toList();
  }

  /// فلترة حسب تاريخ الإضافة
  List<FavoriteItem> addedAfter(DateTime date) {
    return where((item) => item.addedAt.isAfter(date)).toList();
  }

  /// فلترة حسب آخر دخول
  List<FavoriteItem> accessedAfter(DateTime date) {
    return where((item) => 
        item.lastAccessedAt != null && 
        item.lastAccessedAt!.isAfter(date)
    ).toList();
  }

  /// البحث في العناوين والمحتوى
  List<FavoriteItem> search(String query) {
    final searchQuery = query.toLowerCase().trim();
    if (searchQuery.isEmpty) return this;

    return where((item) =>
        item.title.toLowerCase().contains(searchQuery) ||
        item.content.toLowerCase().contains(searchQuery) ||
        (item.subtitle != null && item.subtitle!.toLowerCase().contains(searchQuery))
    ).toList();
  }

  /// ترتيب حسب تاريخ الإضافة (الأحدث أولاً)
  List<FavoriteItem> sortByNewest() {
    final sorted = List<FavoriteItem>.from(this);
    sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted;
  }

  /// ترتيب حسب العنوان
  List<FavoriteItem> sortByTitle() {
    final sorted = List<FavoriteItem>.from(this);
    sorted.sort((a, b) => a.title.compareTo(b.title));
    return sorted;
  }

  /// تجميع حسب النوع
  Map<FavoriteContentType, List<FavoriteItem>> groupByType() {
    final grouped = <FavoriteContentType, List<FavoriteItem>>{};
    
    for (final item in this) {
      grouped[item.contentType] ??= [];
      grouped[item.contentType]!.add(item);
    }
    
    return grouped;
  }

  /// الحصول على إحصائيات سريعة
  Map<String, int> getQuickStats() {
    final stats = <String, int>{};
    
    stats['total'] = length;
    
    for (final type in FavoriteContentType.values) {
      stats[type.key] = filterByType(type).length;
    }
    
    return stats;
  }
}