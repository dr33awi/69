// lib/features/athkar/services/athkar_service.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import '../../../app/themes/constants/app_constants.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/notifications/notification_manager.dart';
import '../../../core/infrastructure/services/notifications/models/notification_models.dart';
import '../../../core/infrastructure/services/favorites/favorites_service.dart';
import '../../../core/infrastructure/services/favorites/models/favorite_models.dart';
import '../../../app/di/service_locator.dart';
import '../models/athkar_model.dart';
import '../models/athkar_progress.dart';
import '../constants/athkar_constants.dart';

/// خدمة إدارة الأذكار
class AthkarService {
  final StorageService _storage;

  // كاش البيانات
  AthkarData? _athkarDataCache;
  List<AthkarCategory>? _categoriesCache;
  final Map<String, AthkarProgress> _progressCache = {};
  final Map<String, TimeOfDay> _customTimesCache = {};
  DateTime? _lastSyncTime;

  // النظام الموحد للمفضلة
  FavoritesService get _favoritesService => getIt<FavoritesService>();

  AthkarService({
    required StorageService storage,
  }) : _storage = storage {
    _initialize();
  }

  /// تهيئة الخدمة
  void _initialize() {
    _loadCachedData();
  }

  /// تحميل البيانات المخزنة مؤقتاً
  void _loadCachedData() {
    try {
      final syncTimeStr = _storage.getString(AthkarConstants.lastSyncKey);
      if (syncTimeStr != null) {
        _lastSyncTime = DateTime.tryParse(syncTimeStr);
      }

      final customTimes = _storage.getMap(AthkarConstants.customTimesKey);
      if (customTimes != null) {
        customTimes.forEach((categoryId, timeString) {
          final time = AthkarConstants.parseTimeOfDay(timeString);
          if (time != null) {
            _customTimesCache[categoryId] = time;
          }
        });
      }
    } catch (e) {
    }
  }

  // ==================== إدارة الفئات ====================

  /// تحميل جميع فئات الأذكار
  Future<List<AthkarCategory>> loadCategories() async {
    try {
      // التحقق من الكاش أولاً
      if (_categoriesCache != null) {
        return _categoriesCache!;
      }

      // محاولة التحميل من التخزين المحلي
      final cachedData = _storage.getMap(AthkarConstants.categoriesKey);
      if (cachedData != null && _isCacheValid(cachedData)) {
        _athkarDataCache = AthkarData.fromJson(cachedData);
        _categoriesCache = _athkarDataCache!.categories;
        return _categoriesCache!;
      }

      // التحميل من ملف الأصول
      final jsonStr = await rootBundle.loadString(AppConstants.athkarDataFile);
      final Map<String, dynamic> data = json.decode(jsonStr);
      
      // تحليل البيانات
      _athkarDataCache = AthkarData.fromJson(data);
      _categoriesCache = _athkarDataCache!.categories;
      
      // إضافة معلومات الكاش
      data['cached_at'] = DateTime.now().toIso8601String();
      data['cache_version'] = AthkarConstants.currentSettingsVersion;
      
      // حفظ في التخزين المحلي
      await _storage.setMap(AthkarConstants.categoriesKey, data);
      // طباعة أسماء الفئات للتأكد
      for (final category in _categoriesCache!) {
      }
      
      return _categoriesCache!;
    } catch (e, stackTrace) {
      throw Exception('Failed to load athkar data: $e');
    }
  }

  /// التحقق من صلاحية الكاش
  bool _isCacheValid(Map<String, dynamic> cachedData) {
    try {
      final cachedAtStr = cachedData['cached_at'] as String?;
      final version = cachedData['cache_version'] as int?;
      
      if (cachedAtStr == null || version == null) return false;
      if (version < AthkarConstants.minimumSupportedVersion) return false;
      
      final cachedAt = DateTime.parse(cachedAtStr);
      return AthkarConstants.isCacheValid(cachedAt);
    } catch (e) {
      return false;
    }
  }

  /// الحصول على فئة بمعرفها
  Future<AthkarCategory?> getCategoryById(String id) async {
    try {
      final categories = await loadCategories();
      
      // البحث عن الفئة بالمعرف
      for (final category in categories) {
        if (category.id == id) {
          return category;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// مسح الكاش وإعادة التحميل
  Future<void> refreshCategories() async {
    _categoriesCache = null;
    _athkarDataCache = null;
    await _storage.remove(AthkarConstants.categoriesKey);
    await loadCategories();
  }

  // ==================== إدارة حجم الخط ====================

  /// حفظ حجم الخط المفضل
  Future<void> saveFontSize(double fontSize) async {
    try {
      final clampedSize = fontSize.clamp(
        AthkarConstants.minFontSize,
        AthkarConstants.maxFontSize,
      );
      
      await _storage.setDouble(AthkarConstants.fontSizeKey, clampedSize);
    } catch (e) {
    }
  }

  /// الحصول على حجم الخط المحفوظ
  Future<double> getSavedFontSize() async {
    try {
      return _storage.getDouble(AthkarConstants.fontSizeKey) ?? 
             AthkarConstants.defaultFontSize;
    } catch (e) {
      return AthkarConstants.defaultFontSize;
    }
  }

  // ==================== إدارة التذكيرات ====================

  /// الحصول على الفئات المفعلة للتذكير
  List<String> getEnabledReminderCategories() {
    return _storage.getStringList(AthkarConstants.reminderKey) ?? [];
  }

  /// تعيين الفئات المفعلة للتذكير
  Future<void> setEnabledReminderCategories(List<String> enabledIds) async {
    try {
      await _storage.setStringList(AthkarConstants.reminderKey, enabledIds);
      await _updateLastSyncTime();
    } catch (e) {
      rethrow;
    }
  }

  /// حفظ الأوقات المخصصة
  Future<void> saveCustomTimes(Map<String, TimeOfDay> customTimes) async {
    try {
      final timesMap = <String, String>{};
      
      customTimes.forEach((categoryId, time) {
        timesMap[categoryId] = AthkarConstants.timeOfDayToString(time);
      });
      
      await _storage.setMap(AthkarConstants.customTimesKey, timesMap);
      
      _customTimesCache.clear();
      _customTimesCache.addAll(customTimes);
    } catch (e) {
      rethrow;
    }
  }

  /// الحصول على الأوقات المخصصة
  Map<String, TimeOfDay> getCustomTimes() {
    return Map.from(_customTimesCache);
  }

  /// الحصول على الوقت المخصص لفئة معينة
  TimeOfDay? getCustomTimeForCategory(String categoryId) {
    return _customTimesCache[categoryId];
  }

  /// جدولة تذكيرات الأذكار
  Future<void> scheduleCategoryReminders() async {
    try {
      final categories = await loadCategories();
      final enabledIds = getEnabledReminderCategories();
      
      if (enabledIds.isEmpty) {
        return;
      }

      final notificationManager = NotificationManager.instance;
      int scheduledCount = 0;

      // إلغاء جميع التذكيرات القديمة
      await notificationManager.cancelAllAthkarReminders();

      for (final category in categories) {
        if (!enabledIds.contains(category.id)) continue;
        
        // الحصول على الوقت المناسب
        final time = _customTimesCache[category.id] ?? 
                    category.notifyTime ?? 
                    AthkarConstants.getDefaultTimeForCategory(category.id);
        
        // جدولة التذكير
        await notificationManager.scheduleAthkarReminder(
          categoryId: category.id,
          categoryName: category.title,
          time: time,
          repeat: NotificationRepeat.daily,
        );
        
        scheduledCount++;
      }
      await _updateLastSyncTime();
      
    } catch (e) {
      rethrow;
    }
  }

  /// تحديث إعدادات التذكير
  Future<void> updateReminderSettings({
    required Map<String, bool> enabledMap,
    Map<String, TimeOfDay>? customTimes,
  }) async {
    try {
      // استخراج المعرفات المفعلة
      final enabledIds = enabledMap.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      
      // حفظ الإعدادات
      await setEnabledReminderCategories(enabledIds);
      
      if (customTimes != null) {
        await saveCustomTimes(customTimes);
      }

      // إعادة جدولة التذكيرات
      await scheduleCategoryReminders();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== دوال مساعدة ====================

  /// تحديث آخر وقت مزامنة
  Future<void> _updateLastSyncTime() async {
    _lastSyncTime = DateTime.now();
    await _storage.setString(
      AthkarConstants.lastSyncKey,
      _lastSyncTime!.toIso8601String(),
    );
  }

  /// الحصول على آخر وقت مزامنة
  DateTime? getLastSyncTime() {
    return _lastSyncTime;
  }

  /// الحصول على معلومات البيانات
  AthkarData? getAthkarData() {
    return _athkarDataCache;
  }

  // ==================== إدارة المفضلة ====================

  /// إضافة ذكر إلى المفضلة
  Future<bool> addToFavorites({
    required String athkarId,
    required String text,
    String? fadl,
    String? source,
    String? categoryId,
    int? count,
  }) async {
    try {
      final favoriteItem = FavoriteItem.fromAthkar(
        athkarId: athkarId,
        text: text,
        fadl: fadl,
        source: source,
        categoryId: categoryId,
        count: count,
      );

      return await _favoritesService.addFavorite(favoriteItem);
    } catch (e) {
      return false;
    }
  }

  /// إزالة ذكر من المفضلة
  Future<bool> removeFromFavorites(String athkarId) async {
    try {
      return await _favoritesService.removeFavorite(athkarId);
    } catch (e) {
      return false;
    }
  }

  /// تبديل حالة المفضلة للذكر
  Future<bool> toggleFavorite({
    required String athkarId,
    required String text,
    String? fadl,
    String? source,
    String? categoryId,
    int? count,
  }) async {
    try {
      final favoriteItem = FavoriteItem.fromAthkar(
        athkarId: athkarId,
        text: text,
        fadl: fadl,
        source: source,
        categoryId: categoryId,
        count: count,
      );

      await _favoritesService.toggleFavorite(favoriteItem);
      return await _favoritesService.isFavorite(athkarId);
    } catch (e) {
      return false;
    }
  }

  /// التحقق من وجود ذكر في المفضلة
  Future<bool> isFavorite(String athkarId) async {
    return await _favoritesService.isFavorite(athkarId);
  }

  /// الحصول على الأذكار المفضلة
  Future<List<FavoriteItem>> getFavoriteAthkar() async {
    try {
      return await _favoritesService.getFavoritesByType(FavoriteContentType.athkar);
    } catch (e) {
      return [];
    }
  }

  /// الحصول على عدد الأذكار المفضلة
  Future<int> getFavoritesCount() async {
    try {
      return await _favoritesService.getCountByType(FavoriteContentType.athkar);
    } catch (e) {
      return 0;
    }
  }

  // ==================== التنظيف ====================

  /// تنظيف الموارد
  void dispose() {
    _progressCache.clear();
    _customTimesCache.clear();
    _categoriesCache = null;
    _athkarDataCache = null;
    _lastSyncTime = null;
  }

  /// مسح جميع البيانات
  Future<void> clearAllData() async {
    try {
      // مسح البيانات المحفوظة
      await _storage.remove(AthkarConstants.categoriesKey);
      await _storage.remove(AthkarConstants.reminderKey);
      await _storage.remove(AthkarConstants.customTimesKey);
      await _storage.remove(AthkarConstants.fontSizeKey);
      await _storage.remove(AthkarConstants.lastSyncKey);
      
      // مسح تقدم كل فئة
      final categories = await loadCategories();
      for (final category in categories) {
        final key = AthkarConstants.getProgressKey(category.id);
        await _storage.remove(key);
      }
      
      // مسح الكاش
      _progressCache.clear();
      _customTimesCache.clear();
      _categoriesCache = null;
      _athkarDataCache = null;
      _lastSyncTime = null;
      
      // إلغاء التذكيرات
      await NotificationManager.instance.cancelAllAthkarReminders();
    } catch (e) {
      rethrow;
    }
  }
}