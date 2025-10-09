// lib/features/dua/services/dua_service.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../models/dua_model.dart';
import '../data/dua_data.dart';

/// خدمة إدارة الأدعية
class DuaService {
  final StorageService _storage;

  // مفاتيح التخزين
  static const String _favoriteDuasKey = 'favorite_duas';
  static const String _duaReadCountPrefix = 'dua_read_count_';
  static const String _duaLastReadPrefix = 'last_read_';
  static const String _lastReadDuaKey = 'last_read_dua';
  static const String _fontSizeKey = 'dua_font_size';
  static const double _defaultFontSize = 18.0;

  DuaService({
    required StorageService storage,
  }) : _storage = storage;

  /// الحصول على جميع فئات الأدعية
  Future<List<DuaCategory>> getCategories() async {
    try {
      return await DuaData.getCategories();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على فئات الأدعية: $e');
      return [];
    }
  }

  /// الحصول على الأدعية حسب الفئة
  Future<List<Dua>> getDuasByCategory(String categoryId) async {
    try {
      final duas = await DuaData.getDuasByCategory(categoryId);
      return _enrichDuasWithLocalData(duas);
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الأدعية للفئة $categoryId: $e');
      return [];
    }
  }

  /// الحصول على جميع الأدعية
  Future<List<Dua>> getAllDuas() async {
    try {
      final allDuas = await DuaData.getAllDuas();
      return _enrichDuasWithLocalData(allDuas);
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على جميع الأدعية: $e');
      return [];
    }
  }

  /// إثراء الأدعية ببيانات محلية (المفضلة، عدد القراءات، إلخ)
  List<Dua> _enrichDuasWithLocalData(List<Dua> duas) {
    try {
      final favoriteDuas = getFavoriteDuas();
      
      return duas.map((dua) {
        final isFavorite = favoriteDuas.contains(dua.id);
        final readCount = getDuaReadCount(dua.id);
        final lastRead = getLastReadDate(dua.id);
        
        return dua.copyWith(
          isFavorite: isFavorite,
          readCount: readCount,
          lastRead: lastRead,
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ خطأ في إثراء البيانات المحلية: $e');
      return duas;
    }
  }

  /// البحث في الأدعية
  Future<List<Dua>> searchDuas(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final allDuas = await getAllDuas();
      final lowerQuery = query.toLowerCase().trim();
      
      return allDuas.where((dua) {
        return dua.title.toLowerCase().contains(lowerQuery) ||
               dua.arabicText.contains(query) ||
               (dua.translation?.toLowerCase().contains(lowerQuery) ?? false) ||
               dua.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      debugPrint('❌ خطأ في البحث عن الأدعية: $e');
      return [];
    }
  }

  /// الحصول على الأدعية المفضلة
  List<String> getFavoriteDuas() {
    try {
      return _storage.getStringList(_favoriteDuasKey) ?? [];
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الأدعية المفضلة: $e');
      return [];
    }
  }

  /// إضافة/إزالة دعاء من المفضلة
  Future<bool> toggleFavorite(String duaId) async {
    try {
      final favorites = getFavoriteDuas();
      final isFavorite = favorites.contains(duaId);
      
      if (isFavorite) {
        favorites.remove(duaId);
      } else {
        favorites.add(duaId);
      }
      
      await _storage.setStringList(_favoriteDuasKey, favorites);
      debugPrint('✅ تم تحديث حالة المفضلة للدعاء: $duaId');
      return !isFavorite;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث المفضلة للدعاء $duaId: $e');
      return false;
    }
  }

  /// الحصول على الأدعية المفضلة مع التفاصيل
  Future<List<Dua>> getFavoriteDuasWithDetails() async {
    try {
      final favoriteIds = getFavoriteDuas();
      if (favoriteIds.isEmpty) return [];
      
      final allDuas = await getAllDuas();
      
      return allDuas
          .where((dua) => favoriteIds.contains(dua.id))
          .toList();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على تفاصيل الأدعية المفضلة: $e');
      return [];
    }
  }

  /// تسجيل قراءة دعاء
  Future<void> markDuaAsRead(String duaId) async {
    try {
      // زيادة عدد القراءات
      final currentCount = getDuaReadCount(duaId);
      await _storage.setInt('$_duaReadCountPrefix$duaId', currentCount + 1);
      
      // تحديث تاريخ آخر قراءة
      await _storage.setString(
        '$_duaLastReadPrefix$duaId',
        DateTime.now().toIso8601String(),
      );
      
      // تحديث آخر دعاء مقروء
      await _storage.setString(_lastReadDuaKey, duaId);
      
      debugPrint('✅ تم تسجيل قراءة الدعاء: $duaId');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل قراءة الدعاء $duaId: $e');
      rethrow;
    }
  }

  /// الحصول على عدد قراءات دعاء
  int getDuaReadCount(String duaId) {
    try {
      return _storage.getInt('$_duaReadCountPrefix$duaId') ?? 0;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على عدد قراءات الدعاء $duaId: $e');
      return 0;
    }
  }

  /// الحصول على تاريخ آخر قراءة لدعاء
  DateTime? getLastReadDate(String duaId) {
    try {
      final dateString = _storage.getString('$_duaLastReadPrefix$duaId');
      return dateString != null ? DateTime.parse(dateString) : null;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على تاريخ آخر قراءة للدعاء $duaId: $e');
      return null;
    }
  }

  /// تصفير عداد قراءة دعاء معين
  Future<void> resetDuaReadCount(String duaId) async {
    try {
      await _storage.remove('$_duaReadCountPrefix$duaId');
      await _storage.remove('$_duaLastReadPrefix$duaId');
      
      debugPrint('✅ تم تصفير عداد الدعاء: $duaId');
    } catch (e) {
      debugPrint('❌ خطأ في تصفير عداد الدعاء $duaId: $e');
    }
  }

  /// تصفير عداد القراءة لجميع الأدعية في فئة معينة
  Future<void> resetCategoryReadCount(String categoryId) async {
    try {
      final duas = await getDuasByCategory(categoryId);
      
      for (final dua in duas) {
        await resetDuaReadCount(dua.id);
      }
      
      debugPrint('✅ تم تصفير عداد الفئة: $categoryId');
    } catch (e) {
      debugPrint('❌ خطأ في تصفير عداد الفئة $categoryId: $e');
    }
  }

  /// حفظ حجم الخط المختار
  Future<void> saveFontSize(double fontSize) async {
    try {
      await _storage.setDouble(_fontSizeKey, fontSize);
      debugPrint('✅ تم حفظ حجم الخط: $fontSize');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ حجم الخط: $e');
    }
  }

  /// الحصول على حجم الخط المحفوظ
  Future<double> getSavedFontSize() async {
    try {
      return _storage.getDouble(_fontSizeKey) ?? _defaultFontSize;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على حجم الخط المحفوظ: $e');
      return _defaultFontSize;
    }
  }

  /// الحصول على دعاء عشوائي
  Future<Dua?> getRandomDua({DuaType? type}) async {
    try {
      final allDuas = type != null 
          ? (await getAllDuas()).where((dua) => dua.type == type).toList()
          : await getAllDuas();
      
      if (allDuas.isEmpty) return null;
      
      final random = math.Random();
      final randomIndex = random.nextInt(allDuas.length);
      
      return allDuas[randomIndex];
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على دعاء عشوائي: $e');
      return null;
    }
  }

  /// الحصول على دعاء بالمعرف
  Future<Dua?> getDuaById(String duaId) async {
    try {
      final allDuas = await getAllDuas();
      
      return allDuas.firstWhere(
        (dua) => dua.id == duaId,
        orElse: () => throw Exception('الدعاء غير موجود'),
      );
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الدعاء $duaId: $e');
      return null;
    }
  }

  /// الحصول على التوصيات الذكية (مُصلح)
  Future<List<Dua>> getRecommendations() async {
    try {
      final now = DateTime.now();
      final hour = now.hour;
      
      // تحديد النوع المناسب حسب الوقت
      DuaType targetType;
      if (hour >= 6 && hour < 12) {
        targetType = DuaType.morning;
      } else if (hour >= 12 && hour < 18) {
        targetType = DuaType.general;
      } else if (hour >= 18 && hour < 22) {
        targetType = DuaType.evening;
      } else {
        targetType = DuaType.sleep;
      }
      
      // الحصول على الأدعية من النوع المحدد
      final allDuas = await getAllDuas();
      final filteredDuas = allDuas
          .where((dua) => dua.type == targetType)
          .toList();
      
      // إرجاع أول 3 أدعية أو كل ما هو متاح
      return filteredDuas.take(3).toList();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على التوصيات: $e');
      return [];
    }
  }

  /// الحصول على إحصائيات الأدعية
  Future<DuaStats> getStats() async {
    try {
      final allDuas = await getAllDuas();
      final favorites = getFavoriteDuas();
      
      final readDuas = allDuas.where((dua) => dua.readCount > 0).length;
      
      final Map<DuaType, int> duasByType = {};
      for (final dua in allDuas) {
        duasByType[dua.type] = (duasByType[dua.type] ?? 0) + 1;
      }
      
      return DuaStats(
        totalDuas: allDuas.length,
        favoriteDuas: favorites.length,
        readDuas: readDuas,
        duasByType: duasByType,
      );
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الإحصائيات: $e');
      return const DuaStats();
    }
  }

  /// مسح جميع البيانات
  Future<void> clearAllData() async {
    try {
      // مسح المفاتيح الرئيسية
      await _storage.remove(_favoriteDuasKey);
      await _storage.remove(_lastReadDuaKey);
      await _storage.remove(_fontSizeKey);
      
      // مسح عدادات القراءة لجميع الأدعية
      final allDuas = await DuaData.getAllDuas();
      for (final dua in allDuas) {
        await _storage.remove('$_duaReadCountPrefix${dua.id}');
        await _storage.remove('$_duaLastReadPrefix${dua.id}');
      }
      
      debugPrint('✅ تم مسح جميع بيانات الأدعية');
    } catch (e) {
      debugPrint('❌ خطأ في مسح بيانات الأدعية: $e');
      rethrow;
    }
  }
}