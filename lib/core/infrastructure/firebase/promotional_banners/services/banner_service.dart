// lib/core/infrastructure/firebase/promotional_banners/services/banner_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../remote_config_service.dart';
import '../../../services/storage/storage_service.dart';
import '../models/promotional_banner_model.dart';

/// خدمة إدارة البانرات الترويجية
class BannerService {
  static final BannerService _instance = BannerService._internal();
  factory BannerService() => _instance;
  BannerService._internal();

  final GetIt _getIt = GetIt.instance;
  
  FirebaseRemoteConfigService? _remoteConfig;
  StorageService? _storage;
  
  bool _isInitialized = false;
  List<PromotionalBanner> _cachedBanners = [];
  
  // مفاتيح التخزين
  static const String _keyBannersData = 'promotional_banners';
  static const String _keyBannerStats = 'banner_statistics';
  static const String _keyLastFetch = 'banners_last_fetch';
  
  /// تهيئة الخدمة
  Future<void> initialize({
    FirebaseRemoteConfigService? remoteConfig,
    StorageService? storage,
  }) async {
    if (_isInitialized) {
      debugPrint('✅ BannerService already initialized');
      return;
    }

    _remoteConfig = remoteConfig ?? _tryGetRemoteConfig();
    _storage = storage ?? _tryGetStorage();

    if (_remoteConfig == null || _storage == null) {
      debugPrint('❌ BannerService: Required services not available');
      return;
    }

    await _loadBanners();
    _isInitialized = true;
    
    debugPrint('✅ BannerService initialized with ${_cachedBanners.length} banners');
  }

  /// محاولة الحصول على Remote Config
  FirebaseRemoteConfigService? _tryGetRemoteConfig() {
    try {
      if (_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        return _getIt<FirebaseRemoteConfigService>();
      }
    } catch (e) {
      debugPrint('⚠️ Could not get FirebaseRemoteConfigService: $e');
    }
    return null;
  }

  /// محاولة الحصول على Storage
  StorageService? _tryGetStorage() {
    try {
      if (_getIt.isRegistered<StorageService>()) {
        return _getIt<StorageService>();
      }
    } catch (e) {
      debugPrint('⚠️ Could not get StorageService: $e');
    }
    return null;
  }

  /// تحميل البانرات من Remote Config
  Future<void> _loadBanners() async {
    try {
      // محاولة التحميل من Remote Config
      final bannersData = await _fetchFromRemoteConfig();
      
      if (bannersData != null && bannersData.isNotEmpty) {
        _cachedBanners = _parseBanners(bannersData);
        await _saveBannersToCache(bannersData);
        debugPrint('📊 Loaded ${_cachedBanners.length} banners from Remote Config');
      } else {
        // التحميل من الكاش المحلي
        await _loadFromCache();
      }
    } catch (e) {
      debugPrint('❌ Error loading banners: $e');
      await _loadFromCache();
    }
  }

  /// جلب من Remote Config
  Future<List<dynamic>?> _fetchFromRemoteConfig() async {
    if (_remoteConfig == null || !_remoteConfig!.isInitialized) {
      return null;
    }

    try {
      final jsonString = _remoteConfig!.getString(_keyBannersData);
      if (jsonString.isEmpty) return null;

      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        await _storage?.setString(_keyLastFetch, DateTime.now().toIso8601String());
        return decoded;
      }
    } catch (e) {
      debugPrint('❌ Error fetching banners from Remote Config: $e');
    }
    return null;
  }

  /// تحليل البانرات
  List<PromotionalBanner> _parseBanners(List<dynamic> data) {
    final banners = <PromotionalBanner>[];
    
    for (final item in data) {
      try {
        if (item is Map<String, dynamic>) {
          final banner = PromotionalBanner.fromMap(item);
          banners.add(banner);
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing banner: $e');
      }
    }
    
    return banners;
  }

  /// حفظ في الكاش
  Future<void> _saveBannersToCache(List<dynamic> data) async {
    try {
      await _storage?.setString(_keyBannersData, jsonEncode(data));
    } catch (e) {
      debugPrint('❌ Error saving banners to cache: $e');
    }
  }

  /// تحميل من الكاش
  Future<void> _loadFromCache() async {
    try {
      final cachedData = _storage?.getString(_keyBannersData);
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData) as List;
        _cachedBanners = _parseBanners(decoded);
        debugPrint('📦 Loaded ${_cachedBanners.length} banners from cache');
      }
    } catch (e) {
      debugPrint('❌ Error loading from cache: $e');
      _cachedBanners = [];
    }
  }

  /// الحصول على البانرات النشطة
  List<PromotionalBanner> getActiveBanners({
    String? screenName,
    String? countryCode,
    BannerType? type,
  }) {
    if (!_isInitialized) {
      debugPrint('⚠️ BannerService not initialized');
      return [];
    }

    return _cachedBanners
        .where((banner) => banner.isActive)
        .where((banner) => banner.isTargetingScreen(screenName))
        .where((banner) => banner.isTargetingCountry(countryCode))
        .where((banner) => type == null || banner.type == type)
        .where((banner) => _canDisplayBanner(banner))
        .toList()
      ..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
  }

  /// هل يمكن عرض هذا البانر؟
  bool _canDisplayBanner(PromotionalBanner banner) {
    final stats = _getBannerStats(banner.id);
    
    // التحقق من عدد مرات العرض
    if (stats['display_count'] >= banner.maxDisplayCount) {
      return false;
    }
    
    // التحقق من الفترة الزمنية
    final lastDisplay = stats['last_display'] as DateTime?;
    if (lastDisplay != null) {
      final timeSinceLastDisplay = DateTime.now().difference(lastDisplay);
      if (timeSinceLastDisplay < banner.minDisplayInterval) {
        return false;
      }
    }
    
    return true;
  }

  /// الحصول على إحصائيات البانر
  Map<String, dynamic> _getBannerStats(String bannerId) {
    try {
      final allStats = _storage?.getString(_keyBannerStats);
      if (allStats == null) return {'display_count': 0};
      
      final stats = jsonDecode(allStats) as Map<String, dynamic>;
      final bannerStats = stats[bannerId] as Map<String, dynamic>?;
      
      if (bannerStats == null) {
        return {'display_count': 0};
      }
      
      return {
        'display_count': bannerStats['display_count'] ?? 0,
        'last_display': bannerStats['last_display'] != null
            ? DateTime.parse(bannerStats['last_display'])
            : null,
        'click_count': bannerStats['click_count'] ?? 0,
        'dismiss_count': bannerStats['dismiss_count'] ?? 0,
      };
    } catch (e) {
      return {'display_count': 0};
    }
  }

  /// تسجيل عرض البانر
  Future<void> recordBannerDisplay(String bannerId) async {
    try {
      final stats = _getBannerStats(bannerId);
      stats['display_count'] = (stats['display_count'] as int) + 1;
      stats['last_display'] = DateTime.now().toIso8601String();
      
      await _saveBannerStats(bannerId, stats);
      debugPrint('📊 Banner displayed: $bannerId (count: ${stats['display_count']})');
    } catch (e) {
      debugPrint('❌ Error recording display: $e');
    }
  }

  /// تسجيل نقر البانر
  Future<void> recordBannerClick(String bannerId) async {
    try {
      final stats = _getBannerStats(bannerId);
      stats['click_count'] = (stats['click_count'] as int? ?? 0) + 1;
      
      await _saveBannerStats(bannerId, stats);
      debugPrint('👆 Banner clicked: $bannerId');
    } catch (e) {
      debugPrint('❌ Error recording click: $e');
    }
  }

  /// تسجيل إغلاق البانر
  Future<void> recordBannerDismiss(String bannerId) async {
    try {
      final stats = _getBannerStats(bannerId);
      stats['dismiss_count'] = (stats['dismiss_count'] as int? ?? 0) + 1;
      
      await _saveBannerStats(bannerId, stats);
      debugPrint('❌ Banner dismissed: $bannerId');
    } catch (e) {
      debugPrint('❌ Error recording dismiss: $e');
    }
  }

  /// حفظ إحصائيات البانر
  Future<void> _saveBannerStats(String bannerId, Map<String, dynamic> stats) async {
    try {
      final allStatsStr = _storage?.getString(_keyBannerStats);
      final allStats = allStatsStr != null
          ? jsonDecode(allStatsStr) as Map<String, dynamic>
          : <String, dynamic>{};
      
      allStats[bannerId] = stats;
      await _storage?.setString(_keyBannerStats, jsonEncode(allStats));
    } catch (e) {
      debugPrint('❌ Error saving banner stats: $e');
    }
  }

  /// تحديث البانرات يدوياً
  Future<void> refresh() async {
    if (!_isInitialized) return;
    
    debugPrint('🔄 Refreshing banners...');
    await _remoteConfig?.refresh();
    await _loadBanners();
  }

  /// الحصول على بانر واحد حسب ID
  PromotionalBanner? getBannerById(String id) {
    return _cachedBanners.firstWhere(
      (banner) => banner.id == id,
      orElse: () => _cachedBanners.first,
    );
  }

  /// مسح الإحصائيات
  Future<void> clearStatistics() async {
    await _storage?.remove(_keyBannerStats);
    debugPrint('🧹 Banner statistics cleared');
  }

  /// معلومات التصحيح
  Map<String, dynamic> get debugInfo => {
    'is_initialized': _isInitialized,
    'total_banners': _cachedBanners.length,
    'active_banners': _cachedBanners.where((b) => b.isActive).length,
    'last_fetch': _storage?.getString(_keyLastFetch),
    'banners': _cachedBanners.map((b) => {
      'id': b.id,
      'title': b.title,
      'is_active': b.isActive,
      'priority': b.priority.name,
      'stats': _getBannerStats(b.id),
    }).toList(),
  };

  /// التنظيف
  void dispose() {
    _cachedBanners.clear();
    _isInitialized = false;
    debugPrint('🧹 BannerService disposed');
  }

  bool get isInitialized => _isInitialized;
  int get bannersCount => _cachedBanners.length;
}