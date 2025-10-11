// lib/features/dua/services/dua_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../models/dua_model.dart';

class DuaService {
  final StorageService _storage;
  
  // مفاتيح التخزين
  static const String _favoritesKey = 'dua_favorites';
  static const String _fontSizeKey = 'dua_font_size';
  static const String _lastViewedKey = 'dua_last_viewed';
  static const String _readDuasKey = 'dua_read_items';
  static const String _searchHistoryKey = 'dua_search_history';
  
  // Cache
  List<DuaCategory>? _categoriesCache;
  Map<String, List<DuaItem>>? _duasCache;
  Set<String>? _favoritesCache;
  Set<String>? _readDuasCache;
  
  DuaService({required StorageService storage}) : _storage = storage {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadFavorites();
    await _loadReadDuas();
  }

  /// تحميل الفئات من ملف JSON
  Future<List<DuaCategory>> loadCategories() async {
    try {
      if (_categoriesCache != null) {
        return _categoriesCache!;
      }

      final String jsonString = await rootBundle.loadString('assets/data/duas_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> categoriesJson = jsonData['categories'] ?? [];
      final Map<String, dynamic> duasJson = jsonData['duas'] ?? {};
      
      final categories = categoriesJson.map((json) {
        final category = DuaCategory.fromJson(json);
        final categoryDuas = duasJson[category.id] as List<dynamic>? ?? [];
        return category.copyWith(duasCount: categoryDuas.length);
      }).toList();
      
      _categoriesCache = categories;
      return categories;
      
    } catch (e) {
      debugPrint('Error loading dua categories: $e');
      return [];
    }
  }

  /// الحصول على أدعية فئة معينة
  Future<List<DuaItem>> getDuasByCategory(String categoryId) async {
    try {
      // التحقق من الـ Cache
      if (_duasCache != null && _duasCache!.containsKey(categoryId)) {
        return _duasCache![categoryId]!;
      }

      final String jsonString = await rootBundle.loadString('assets/data/duas_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final Map<String, dynamic> duasJson = jsonData['duas'] ?? {};
      final List<dynamic> categoryDuas = duasJson[categoryId] ?? [];
      
      final duas = categoryDuas.map((json) {
        final dua = DuaItem.fromJson(json);
        final isFavorite = _favoritesCache?.contains(dua.id) ?? false;
        return dua.copyWith(isFavorite: isFavorite);
      }).toList();
      
      // حفظ في الـ Cache
      _duasCache ??= {};
      _duasCache![categoryId] = duas;
      
      return duas;
      
    } catch (e) {
      debugPrint('Error loading duas for category $categoryId: $e');
      return [];
    }
  }

  /// الحصول على جميع الأدعية
  Future<List<DuaItem>> getAllDuas() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/duas_data.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final Map<String, dynamic> duasJson = jsonData['duas'] ?? {};
      final List<DuaItem> allDuas = [];
      
      for (final categoryDuas in duasJson.values) {
        if (categoryDuas is List) {
          for (final duaJson in categoryDuas) {
            final dua = DuaItem.fromJson(duaJson);
            final isFavorite = _favoritesCache?.contains(dua.id) ?? false;
            allDuas.add(dua.copyWith(isFavorite: isFavorite));
          }
        }
      }
      
      return allDuas;
      
    } catch (e) {
      debugPrint('Error loading all duas: $e');
      return [];
    }
  }

  /// البحث في الأدعية
  Future<List<DuaItem>> searchDuas(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final allDuas = await getAllDuas();
      final normalizedQuery = query.toLowerCase().trim();
      
      // حفظ في سجل البحث
      await _saveSearchHistory(query);
      
      return allDuas.where((dua) {
        final titleMatch = dua.title.toLowerCase().contains(normalizedQuery);
        final textMatch = dua.arabicText.contains(query); // البحث في النص العربي
        final tagsMatch = dua.tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
        final sourceMatch = dua.source.toLowerCase().contains(normalizedQuery);
        
        return titleMatch || textMatch || tagsMatch || sourceMatch;
      }).toList();
      
    } catch (e) {
      debugPrint('Error searching duas: $e');
      return [];
    }
  }

  /// الحصول على الأدعية المفضلة
  Future<List<DuaItem>> getFavoriteDuas() async {
    try {
      await _loadFavorites();
      
      if (_favoritesCache == null || _favoritesCache!.isEmpty) {
        return [];
      }
      
      final allDuas = await getAllDuas();
      return allDuas.where((dua) => _favoritesCache!.contains(dua.id)).toList();
      
    } catch (e) {
      debugPrint('Error getting favorite duas: $e');
      return [];
    }
  }

  /// إضافة/إزالة من المفضلة
  Future<bool> toggleFavorite(String duaId) async {
    try {
      await _loadFavorites();
      
      _favoritesCache ??= {};
      
      if (_favoritesCache!.contains(duaId)) {
        _favoritesCache!.remove(duaId);
      } else {
        _favoritesCache!.add(duaId);
      }
      
      // حفظ في التخزين
      await _storage.setStringList(_favoritesKey, _favoritesCache!.toList());
      
      // تحديث الـ Cache
      if (_duasCache != null) {
        for (final categoryDuas in _duasCache!.values) {
          final duaIndex = categoryDuas.indexWhere((d) => d.id == duaId);
          if (duaIndex != -1) {
            categoryDuas[duaIndex] = categoryDuas[duaIndex].copyWith(
              isFavorite: _favoritesCache!.contains(duaId),
            );
          }
        }
      }
      
      return _favoritesCache!.contains(duaId);
      
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  /// التحقق من المفضلة
  Future<bool> isFavorite(String duaId) async {
    await _loadFavorites();
    return _favoritesCache?.contains(duaId) ?? false;
  }

  /// تحميل المفضلات
  Future<void> _loadFavorites() async {
    try {
      if (_favoritesCache != null) return;
      
      final favorites = _storage.getStringList(_favoritesKey) ?? [];
      _favoritesCache = favorites.toSet();
      
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _favoritesCache = {};
    }
  }

  /// تحديد دعاء كمقروء
  Future<void> markAsRead(String duaId) async {
    try {
      _readDuasCache ??= {};
      _readDuasCache!.add(duaId);
      
      await _storage.setStringList(_readDuasKey, _readDuasCache!.toList());
      
    } catch (e) {
      debugPrint('Error marking dua as read: $e');
    }
  }

  /// تحميل الأدعية المقروءة
  Future<void> _loadReadDuas() async {
    try {
      if (_readDuasCache != null) return;
      
      final readDuas = _storage.getStringList(_readDuasKey) ?? [];
      _readDuasCache = readDuas.toSet();
      
    } catch (e) {
      debugPrint('Error loading read duas: $e');
      _readDuasCache = {};
    }
  }

  /// التحقق من قراءة الدعاء
  bool isRead(String duaId) {
    return _readDuasCache?.contains(duaId) ?? false;
  }

  /// الحصول على حجم الخط المحفوظ
  Future<double> getSavedFontSize() async {
    try {
      return _storage.getDouble(_fontSizeKey) ?? 18.0;
    } catch (e) {
      debugPrint('Error getting font size: $e');
      return 18.0;
    }
  }

  /// حفظ حجم الخط
  Future<void> saveFontSize(double size) async {
    try {
      await _storage.setDouble(_fontSizeKey, size);
    } catch (e) {
      debugPrint('Error saving font size: $e');
    }
  }

  /// حفظ آخر دعاء تم عرضه
  Future<void> saveLastViewed(String duaId, String categoryId) async {
    try {
      final data = {
        'duaId': duaId,
        'categoryId': categoryId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _storage.setMap(_lastViewedKey, data);
      
    } catch (e) {
      debugPrint('Error saving last viewed: $e');
    }
  }

  /// الحصول على آخر دعاء تم عرضه
  Future<Map<String, dynamic>?> getLastViewed() async {
    try {
      return _storage.getMap(_lastViewedKey);
    } catch (e) {
      debugPrint('Error getting last viewed: $e');
      return null;
    }
  }

  /// حفظ سجل البحث
  Future<void> _saveSearchHistory(String query) async {
    try {
      final history = _storage.getStringList(_searchHistoryKey) ?? [];
      
      // إزالة التكرار
      history.remove(query);
      
      // إضافة في البداية
      history.insert(0, query);
      
      // الاحتفاظ بآخر 10 عمليات بحث فقط
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }
      
      await _storage.setStringList(_searchHistoryKey, history);
      
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  /// الحصول على سجل البحث
  Future<List<String>> getSearchHistory() async {
    try {
      return _storage.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      debugPrint('Error getting search history: $e');
      return [];
    }
  }

  /// مسح سجل البحث
  Future<void> clearSearchHistory() async {
    try {
      await _storage.remove(_searchHistoryKey);
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  /// الحصول على إحصائيات الأدعية
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final allDuas = await getAllDuas();
      final categories = await loadCategories();
      
      await _loadFavorites();
      await _loadReadDuas();
      
      return {
        'totalDuas': allDuas.length,
        'totalCategories': categories.length,
        'favoritesCount': _favoritesCache?.length ?? 0,
        'readCount': _readDuasCache?.length ?? 0,
        'unreadCount': allDuas.length - (_readDuasCache?.length ?? 0),
        'readPercentage': allDuas.isNotEmpty 
            ? ((_readDuasCache?.length ?? 0) / allDuas.length * 100).round()
            : 0,
      };
      
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {};
    }
  }

  /// تنظيف الذاكرة
  void dispose() {
    _categoriesCache = null;
    _duasCache = null;
    _favoritesCache = null;
    _readDuasCache = null;
  }
}