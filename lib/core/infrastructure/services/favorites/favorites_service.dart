// lib/core/infrastructure/services/favorites/favorites_service.dart
// خدمة المفضلة الموحدة لجميع أنواع المحتوى في التطبيق

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';
import 'models/favorite_models.dart';
import 'constants/favorites_constants.dart';

/// خدمة إدارة المفضلة الموحدة
/// 
/// توفر إدارة شاملة للمفضلات عبر جميع أنواع المحتوى:
/// - الأدعية، الأذكار، أسماء الله، التسبيح، القرآن، الأحاديث
/// - البحث والفلترة والترتيب
/// - الاستيراد والتصدير
/// - التزامن والتخزين المؤقت
class FavoritesService extends ChangeNotifier {
  final StorageService _storage;

  // التخزين المؤقت
  List<FavoriteItem>? _favoritesCache;
  FavoritesSortOptions _sortOptions = const FavoritesSortOptions();
  FavoritesStatistics? _statisticsCache;
  DateTime? _lastCacheUpdate;

  // حالة الخدمة
  bool _isInitialized = false;
  bool _isMigrating = false;
  final Set<String> _favoritesIndex = {}; // فهرس سريع للتحقق من الوجود

  FavoritesService({required StorageService storage}) : _storage = storage;

  // ==================== التهيئة والإعداد ====================

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تحميل إعدادات الترتيب
      await _loadSortOptions();
      
      // ترحيل المفضلات القديمة إذا لزم الأمر
      await _migrateIfNeeded();
      
      // تحميل المفضلات
      await _loadFavorites();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('FavoritesService: خطأ في التهيئة: $e');
      rethrow;
    }
  }

  /// التأكد من التهيئة
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ==================== العمليات الأساسية ====================

  /// إضافة عنصر للمفضلة
  Future<bool> addFavorite(FavoriteItem item) async {
    try {
      await _ensureInitialized();

      // التحقق من صحة البيانات
      if (!_validateFavoriteItem(item)) {
        throw Exception(FavoritesConstants.errorMessages['invalidData']);
      }

      // التحقق من عدم وجود العنصر مسبقاً
      if (_favoritesIndex.contains(item.id)) {
        return false; // موجود مسبقاً
      }

      // التحقق من الحدود
      final currentCount = _favoritesCache?.length ?? 0;
      final typeCount = await getCountByType(item.contentType);
      
      if (!FavoritesConstants.canAddMoreFavorites(currentCount, typeCount)) {
        throw Exception(FavoritesConstants.errorMessages['limitExceeded']);
      }

      // إضافة العنصر
      _favoritesCache ??= [];
      _favoritesCache!.add(item);
      _favoritesIndex.add(item.id);

      // حفظ في التخزين
      await _saveFavorites();

      // تحديث الإحصائيات
      await _updateStatistics();

      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('FavoritesService: خطأ في إضافة المفضلة: $e');
      return false;
    }
  }

  /// إزالة عنصر من المفضلة
  Future<bool> removeFavorite(String itemId) async {
    try {
      await _ensureInitialized();

      if (_favoritesCache == null || !_favoritesIndex.contains(itemId)) {
        return false; // غير موجود
      }

      // إزالة العنصر
      _favoritesCache!.removeWhere((item) => item.id == itemId);
      _favoritesIndex.remove(itemId);

      // حفظ في التخزين
      await _saveFavorites();

      // تحديث الإحصائيات
      await _updateStatistics();

      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('FavoritesService: خطأ في إزالة المفضلة: $e');
      return false;
    }
  }

  /// تبديل حالة المفضلة (إضافة/إزالة)
  Future<bool> toggleFavorite(FavoriteItem item) async {
    final isCurrentlyFavorite = await isFavorite(item.id);
    
    if (isCurrentlyFavorite) {
      return !(await removeFavorite(item.id));
    } else {
      return await addFavorite(item);
    }
  }

  /// التحقق من وجود عنصر في المفضلة
  Future<bool> isFavorite(String itemId) async {
    await _ensureInitialized();
    return _favoritesIndex.contains(itemId);
  }

  // ==================== الاستعلامات والبحث ====================

  /// الحصول على جميع المفضلات
  Future<List<FavoriteItem>> getAllFavorites() async {
    await _ensureInitialized();
    final favorites = List<FavoriteItem>.from(_favoritesCache ?? []);
    return _applySortingAndFiltering(favorites);
  }

  /// الحصول على مفضلات نوع معين
  Future<List<FavoriteItem>> getFavoritesByType(FavoriteContentType type) async {
    await _ensureInitialized();
    final allFavorites = _favoritesCache ?? [];
    final typeFilteredFavorites = allFavorites
        .where((item) => item.contentType == type)
        .toList();
    
    return _applySortingAndFiltering(typeFilteredFavorites);
  }

  /// البحث في المفضلات
  Future<List<FavoriteItem>> searchFavorites(String query) async {
    await _ensureInitialized();

    if (query.length < FavoritesConstants.minSearchLength) {
      return [];
    }

    final allFavorites = _favoritesCache ?? [];
    final searchQuery = FavoritesConstants.cleanTextForSearch(query);
    
    final results = allFavorites.where((item) {
      final titleMatch = FavoritesConstants.cleanTextForSearch(item.title).contains(searchQuery);
      final contentMatch = FavoritesConstants.cleanTextForSearch(item.content).contains(searchQuery);
      final subtitleMatch = item.subtitle != null && 
          FavoritesConstants.cleanTextForSearch(item.subtitle!).contains(searchQuery);
      
      return titleMatch || contentMatch || subtitleMatch;
    }).toList();

    // ترتيب النتائج حسب الصلة
    results.sort((a, b) {
      // أولوية للعنوان، ثم المحتوى
      final aScore = _calculateRelevanceScore(a, searchQuery);
      final bScore = _calculateRelevanceScore(b, searchQuery);
      return bScore.compareTo(aScore);
    });

    return results.take(FavoritesConstants.maxSearchResults).toList();
  }

  /// حساب نقاط الصلة للبحث
  int _calculateRelevanceScore(FavoriteItem item, String query) {
    int score = 0;
    final titleText = FavoritesConstants.cleanTextForSearch(item.title);
    final contentText = FavoritesConstants.cleanTextForSearch(item.content);
    
    // نقاط إضافية للعنوان
    if (titleText.contains(query)) score += 10;
    if (titleText.startsWith(query)) score += 5;
    
    // نقاط للمحتوى
    if (contentText.contains(query)) score += 3;
    
    // نقاط للعناصر المضافة حديثاً
    final daysSinceAdded = DateTime.now().difference(item.addedAt).inDays;
    if (daysSinceAdded < 7) score += 2;
    
    return score;
  }

  // ==================== الإحصائيات والمعلومات ====================

  /// الحصول على إحصائيات المفضلة
  Future<FavoritesStatistics> getStatistics() async {
    await _ensureInitialized();
    
    if (_statisticsCache != null) {
      return _statisticsCache!;
    }

    await _updateStatistics();
    return _statisticsCache ?? const FavoritesStatistics.empty();
  }

  /// الحصول على عدد المفضلات حسب النوع
  Future<int> getCountByType(FavoriteContentType type) async {
    await _ensureInitialized();
    return (_favoritesCache ?? [])
        .where((item) => item.contentType == type)
        .length;
  }

  /// الحصول على العدد الإجمالي للمفضلات
  Future<int> getTotalCount() async {
    await _ensureInitialized();
    return _favoritesCache?.length ?? 0;
  }

  // ==================== الترتيب والفلترة ====================

  /// تطبيق خيارات الترتيب والفلترة
  List<FavoriteItem> _applySortingAndFiltering(List<FavoriteItem> items) {
    var filteredItems = List<FavoriteItem>.from(items);

    // تطبيق الفلتر
    if (_sortOptions.filterByType != null) {
      filteredItems = filteredItems
          .where((item) => item.contentType == _sortOptions.filterByType)
          .toList();
    }

    // تطبيق الترتيب
    switch (_sortOptions.sortBy) {
      case SortBy.dateAdded:
        filteredItems.sort((a, b) => 
            _sortOptions.sortOrder == SortOrder.descending
                ? b.addedAt.compareTo(a.addedAt)
                : a.addedAt.compareTo(b.addedAt));
        break;

      case SortBy.lastAccessed:
        filteredItems.sort((a, b) {
          final aTime = a.lastAccessedAt ?? a.addedAt;
          final bTime = b.lastAccessedAt ?? b.addedAt;
          return _sortOptions.sortOrder == SortOrder.descending
              ? bTime.compareTo(aTime)
              : aTime.compareTo(bTime);
        });
        break;

      case SortBy.title:
        filteredItems.sort((a, b) => 
            _sortOptions.sortOrder == SortOrder.descending
                ? b.title.compareTo(a.title)
                : a.title.compareTo(b.title));
        break;

      case SortBy.contentType:
        filteredItems.sort((a, b) {
          final aPriority = FavoritesConstants.getContentTypePriority(a.contentType.key);
          final bPriority = FavoritesConstants.getContentTypePriority(b.contentType.key);
          return _sortOptions.sortOrder == SortOrder.descending
              ? bPriority.compareTo(aPriority)
              : aPriority.compareTo(bPriority);
        });
        break;
    }

    return filteredItems;
  }

  /// تحديث خيارات الترتيب
  Future<void> updateSortOptions(FavoritesSortOptions options) async {
    _sortOptions = options;
    await _saveSortOptions();
    notifyListeners();
  }

  /// الحصول على خيارات الترتيب الحالية
  FavoritesSortOptions get sortOptions => _sortOptions;

  // ==================== العمليات المتقدمة ====================

  /// تحديث وقت آخر دخول لعنصر
  Future<void> markAsAccessed(String itemId) async {
    await _ensureInitialized();
    
    if (_favoritesCache == null) return;

    final index = _favoritesCache!.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _favoritesCache![index] = _favoritesCache![index].markAsAccessed();
      await _saveFavorites();
    }
  }

  /// مسح جميع المفضلات
  Future<void> clearAllFavorites() async {
    await _ensureInitialized();
    
    _favoritesCache = [];
    _favoritesIndex.clear();
    _statisticsCache = null;

    await _saveFavorites();
    await _updateStatistics();
    
    notifyListeners();
  }

  /// مسح مفضلات نوع معين
  Future<void> clearFavoritesByType(FavoriteContentType type) async {
    await _ensureInitialized();
    
    if (_favoritesCache == null) return;

    // إزالة العناصر من النوع المحدد
    final itemsToRemove = _favoritesCache!
        .where((item) => item.contentType == type)
        .map((item) => item.id)
        .toList();

    _favoritesCache!.removeWhere((item) => item.contentType == type);
    
    for (final id in itemsToRemove) {
      _favoritesIndex.remove(id);
    }

    await _saveFavorites();
    await _updateStatistics();
    
    notifyListeners();
  }

  // ==================== التخزين والتحميل ====================

  /// تحميل المفضلات من التخزين
  Future<void> _loadFavorites() async {
    try {
      final favoritesJson = _storage.getStringList(FavoritesConstants.mainFavoritesKey);
      
      if (favoritesJson != null && favoritesJson.isNotEmpty) {
        _favoritesCache = favoritesJson
            .map((jsonStr) => FavoriteItem.fromJson(json.decode(jsonStr)))
            .toList();
        
        // بناء الفهرس
        _favoritesIndex.clear();
        for (final item in _favoritesCache!) {
          _favoritesIndex.add(item.id);
        }
      } else {
        _favoritesCache = [];
      }

      _lastCacheUpdate = DateTime.now();

    } catch (e) {
      debugPrint('FavoritesService: خطأ في تحميل المفضلات: $e');
      _favoritesCache = [];
    }
  }

  /// حفظ المفضلات في التخزين
  Future<void> _saveFavorites() async {
    try {
      if (_favoritesCache == null) return;

      final favoritesJson = _favoritesCache!
          .map((item) => json.encode(item.toJson()))
          .toList();

      await _storage.setStringList(FavoritesConstants.mainFavoritesKey, favoritesJson);
      await _storage.setString(FavoritesConstants.lastSyncKey, DateTime.now().toIso8601String());

      _lastCacheUpdate = DateTime.now();

    } catch (e) {
      debugPrint('FavoritesService: خطأ في حفظ المفضلات: $e');
      rethrow;
    }
  }

  /// تحميل خيارات الترتيب
  Future<void> _loadSortOptions() async {
    try {
      final optionsJson = _storage.getMap(FavoritesConstants.sortOptionsKey);
      
      if (optionsJson != null) {
        _sortOptions = FavoritesSortOptions.fromJson(optionsJson);
      }

    } catch (e) {
      debugPrint('FavoritesService: خطأ في تحميل خيارات الترتيب: $e');
    }
  }

  /// حفظ خيارات الترتيب
  Future<void> _saveSortOptions() async {
    try {
      await _storage.setMap(FavoritesConstants.sortOptionsKey, _sortOptions.toJson());
    } catch (e) {
      debugPrint('FavoritesService: خطأ في حفظ خيارات الترتيب: $e');
    }
  }

  /// تحديث الإحصائيات
  Future<void> _updateStatistics() async {
    try {
      final favorites = _favoritesCache ?? [];
      final countByType = <FavoriteContentType, int>{};

      // حساب العدد لكل نوع
      for (final type in FavoriteContentType.values) {
        countByType[type] = favorites
            .where((item) => item.contentType == type)
            .length;
      }

      // العثور على النوع الأكثر استخداماً
      FavoriteContentType? mostFavoriteType;
      int maxCount = 0;
      for (final entry in countByType.entries) {
        if (entry.value > maxCount) {
          maxCount = entry.value;
          mostFavoriteType = entry.key;
        }
      }

      _statisticsCache = FavoritesStatistics(
        totalCount: favorites.length,
        countByType: countByType,
        lastAddedAt: favorites.isNotEmpty 
            ? favorites.map((f) => f.addedAt).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
        lastAccessedAt: favorites.isNotEmpty 
            ? favorites
                .where((f) => f.lastAccessedAt != null)
                .map((f) => f.lastAccessedAt!)
                .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a)
            : null,
        mostFavoriteType: maxCount > 0 ? mostFavoriteType : null,
      );

      // حفظ الإحصائيات
      await _storage.setMap(FavoritesConstants.statisticsKey, {
        'totalCount': _statisticsCache!.totalCount,
        'countByType': _statisticsCache!.countByType.map(
          (key, value) => MapEntry(key.key, value),
        ),
        'lastAddedAt': _statisticsCache!.lastAddedAt?.toIso8601String(),
        'lastAccessedAt': _statisticsCache!.lastAccessedAt?.toIso8601String(),
        'mostFavoriteType': _statisticsCache!.mostFavoriteType?.key,
        'updatedAt': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      debugPrint('FavoritesService: خطأ في تحديث الإحصائيات: $e');
    }
  }

  // ==================== الترحيل والتوافق ====================

  /// ترحيل المفضلات من النظام القديم
  Future<void> _migrateIfNeeded() async {
    if (_isMigrating) return;

    try {
      _isMigrating = true;

      // التحقق من وجود مفضلات جديدة
      final hasNewFavorites = _storage.getStringList(FavoritesConstants.mainFavoritesKey) != null;
      if (hasNewFavorites) {
        return; // لا حاجة للترحيل
      }

      int migratedCount = 0;
      _favoritesCache ??= [];

      // ترحيل كل نوع من الأنواع القديمة
      for (final entry in FavoritesConstants.legacyKeys.entries) {
        final contentTypeKey = entry.key;
        final legacyKey = entry.value;
        
        final legacyFavorites = _storage.getStringList(legacyKey);
        if (legacyFavorites != null && legacyFavorites.isNotEmpty) {
          for (final favoriteId in legacyFavorites) {
            if (!_favoritesIndex.contains(favoriteId)) {
              // إنشاء عنصر مفضلة موحد من البيانات القديمة
              final migratedItem = await _createMigratedFavoriteItem(
                favoriteId, 
                contentTypeKey,
              );
              
              if (migratedItem != null) {
                _favoritesCache!.add(migratedItem);
                _favoritesIndex.add(migratedItem.id);
                migratedCount++;
              }
            }
          }
        }
      }

      if (migratedCount > 0) {
        await _saveFavorites();
        await _updateStatistics();
        debugPrint('FavoritesService: تم ترحيل $migratedCount عنصر مفضلة');
      }

    } catch (e) {
      debugPrint('FavoritesService: خطأ في الترحيل: $e');
    } finally {
      _isMigrating = false;
    }
  }

  /// إنشاء عنصر مفضلة من البيانات المرحلة
  Future<FavoriteItem?> _createMigratedFavoriteItem(String id, String contentType) async {
    try {
      final type = FavoriteContentType.fromKey(contentType);
      
      // هنا يمكن إضافة منطق لاستخراج البيانات من الخدمات المختلفة
      // بناءً على النوع والمعرف
      
      return FavoriteItem(
        id: id,
        contentType: type,
        title: 'عنصر مرحل', // سيتم تحديثه لاحقاً
        content: 'محتوى مرحل',
        addedAt: DateTime.now(),
        metadata: {'migrated': true},
      );

    } catch (e) {
      debugPrint('FavoritesService: خطأ في إنشاء عنصر مرحل: $e');
      return null;
    }
  }

  // ==================== التحقق من صحة البيانات ====================

  /// التحقق من صحة عنصر المفضلة
  bool _validateFavoriteItem(FavoriteItem item) {
    return FavoritesConstants.isValidId(item.id) &&
           FavoritesConstants.isValidTitle(item.title) &&
           FavoritesConstants.isValidContent(item.content);
  }

  // ==================== تنظيف الموارد ====================

  @override
  void dispose() {
    _favoritesCache?.clear();
    _favoritesIndex.clear();
    _statisticsCache = null;
    super.dispose();
  }
}