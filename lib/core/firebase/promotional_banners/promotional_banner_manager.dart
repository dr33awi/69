// lib/core/infrastructure/firebase/promotional_banners/promotional_banner_manager.dart
// ✅ ملف كامل مع تتبع التحديثات وجميع الميزات

import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:flutter/foundation.dart';
import '../remote_config_service.dart';
import 'models/promotional_banner_model.dart';

/// مدير البانرات الترويجية
class PromotionalBannerManager {
  static final PromotionalBannerManager _instance = PromotionalBannerManager._internal();
  factory PromotionalBannerManager() => _instance;
  PromotionalBannerManager._internal();

  FirebaseRemoteConfigService? _remoteConfig;
  StorageService? _storage;
  
  bool _isInitialized = false;
  
  // Cache للبانرات
  List<PromotionalBanner> _cachedBanners = [];
  DateTime? _lastCacheUpdate;

  /// تهيئة المدير
  Future<void> initialize({
    required FirebaseRemoteConfigService remoteConfig,
    required StorageService storage,
  }) async {
    if (_isInitialized) {
      debugPrint('✅ PromotionalBannerManager already initialized');
      return;
    }
    
    _remoteConfig = remoteConfig;
    _storage = storage;
    
    try {
      // ✅ التحقق من تهيئة RemoteConfigService أولاً
      if (!_remoteConfig!.isInitialized) {
        debugPrint('⚠️ RemoteConfigService not initialized yet, initializing now...');
        await _remoteConfig!.initialize();
      }
      
      await _loadBanners();
      _isInitialized = true;
      debugPrint('✅ PromotionalBannerManager initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing PromotionalBannerManager: $e');
      _isInitialized = false;
    }
  }

  /// تحميل البانرات من Remote Config
  Future<void> _loadBanners() async {
    // ✅ التحقق من وجود RemoteConfig
    if (_remoteConfig == null) {
      debugPrint('❌ RemoteConfig is null, cannot load banners');
      return;
    }
    
    try {
      final bannersData = _remoteConfig!.promotionalBanners;
      
      if (bannersData.isEmpty) {
        debugPrint('⚠️ No promotional banners found');
        _cachedBanners = [];
        return;
      }

      _cachedBanners = bannersData
          .map((data) {
            try {
              return PromotionalBanner.fromJson(data as Map<String, dynamic>);
            } catch (e) {
              debugPrint('⚠️ Error parsing banner: $e');
              return null;
            }
          })
          .where((banner) => banner != null)
          .cast<PromotionalBanner>()
          .toList();

      // ترتيب حسب الأولوية
      _cachedBanners.sort((a, b) => 
        b.priority.sortOrder.compareTo(a.priority.sortOrder)
      );

      _lastCacheUpdate = DateTime.now();
      
      debugPrint('✅ Loaded ${_cachedBanners.length} promotional banners');
      
    } catch (e) {
      debugPrint('❌ Error loading banners: $e');
      _cachedBanners = [];
    }
  }

  /// تحديث البانرات
  Future<void> refresh() async {
    if (!_isInitialized) {
      debugPrint('⚠️ PromotionalBannerManager not initialized');
      return;
    }

    // ✅ التحقق من وجود RemoteConfig
    if (_remoteConfig == null) {
      debugPrint('❌ RemoteConfig is null, cannot refresh');
      return;
    }

    try {
      debugPrint('🔄 Refreshing promotional banners...');
      
      // ✅ تحديث RemoteConfig أولاً
      await _remoteConfig!.refresh();
      
      // ثم تحميل البانرات
      await _loadBanners();
      
      debugPrint('✅ Banners refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing banners: $e');
    }
  }

  /// الحصول على البانرات النشطة لشاشة معينة
  List<PromotionalBanner> getActiveBannersForScreen(String screenName) {
    if (!_isInitialized) {
      debugPrint('⚠️ PromotionalBannerManager not initialized');
      return [];
    }

    final activeBanners = _cachedBanners
        .where((banner) => 
          banner.isCurrentlyActive && 
          banner.canShowOnScreen(screenName)
        )
        .toList();

    debugPrint('📊 Found ${activeBanners.length} active banners for $screenName');
    return activeBanners;
  }

  /// الحصول على البانرات التي يجب عرضها (بناءً على التكرار)
  Future<List<PromotionalBanner>> getBannersToShow(String screenName) async {
    if (!_isInitialized) {
      debugPrint('⚠️ PromotionalBannerManager not initialized');
      return [];
    }
    
    // ✅ التحقق من Storage
    if (_storage == null) {
      debugPrint('❌ Storage is null');
      return [];
    }
    
    final activeBanners = getActiveBannersForScreen(screenName);
    
    if (activeBanners.isEmpty) {
      return [];
    }

    final bannersToShow = <PromotionalBanner>[];
    
    for (final banner in activeBanners) {
      final shouldShow = await _shouldShowBanner(banner);
      if (shouldShow) {
        bannersToShow.add(banner);
      }
    }

    debugPrint('🎯 ${bannersToShow.length} banners ready to show on $screenName');
    return bannersToShow;
  }

  /// هل يجب عرض البانر؟ (حسب التكرار والإخفاء)
  Future<bool> _shouldShowBanner(PromotionalBanner banner) async {
    // ✅ التحقق من Storage
    if (_storage == null) {
      debugPrint('❌ Storage is null, allowing banner to show');
      return true;
    }
    
    try {
      // ✅ التحقق من الإخفاء النهائي
      if (isBannerDismissedForever(banner.id)) {
        debugPrint('🚫 Banner ${banner.id} is dismissed forever');
        return false;
      }
      
      // ✅ بالنسبة لبانرات التحديث، التحقق من النقر
      if (banner.bannerType == BannerType.update && isUpdateBannerActioned(banner.id)) {
        debugPrint('✅ Update banner ${banner.id} already actioned');
        return false;
      }
      
      final lastShownKey = 'banner_last_shown_${banner.id}';
      final lastShownString = _storage!.getString(lastShownKey);
      
      if (lastShownString == null) {
        // لم يتم عرضه من قبل
        return true;
      }

      final lastShown = DateTime.tryParse(lastShownString);
      if (lastShown == null) {
        return true;
      }

      final hoursSinceLastShown = DateTime.now().difference(lastShown).inHours;
      
      final shouldShow = hoursSinceLastShown >= banner.displayFrequencyHours;
      
      debugPrint('📅 Banner ${banner.id}: Last shown $hoursSinceLastShown hours ago (frequency: ${banner.displayFrequencyHours}h) - Show: $shouldShow');
      
      return shouldShow;
      
    } catch (e) {
      debugPrint('⚠️ Error checking banner display frequency: $e');
      return false;
    }
  }

  /// تسجيل عرض البانر
  Future<void> markBannerAsShown(String bannerId) async {
    // ✅ التحقق من Storage
    if (_storage == null) {
      debugPrint('❌ Storage is null, cannot mark banner as shown');
      return;
    }
    
    try {
      final key = 'banner_last_shown_$bannerId';
      await _storage!.setString(key, DateTime.now().toIso8601String());
      
      // تسجيل عدد مرات العرض
      final countKey = 'banner_show_count_$bannerId';
      final currentCount = _storage!.getInt(countKey) ?? 0;
      await _storage!.setInt(countKey, currentCount + 1);
      
      debugPrint('✅ Banner $bannerId marked as shown (count: ${currentCount + 1})');
      
    } catch (e) {
      debugPrint('❌ Error marking banner as shown: $e');
    }
  }

  /// تسجيل نقر على البانر
  Future<void> trackBannerClick(String bannerId) async {
    // ✅ التحقق من Storage
    if (_storage == null) {
      debugPrint('❌ Storage is null, cannot track banner click');
      return;
    }
    
    try {
      final key = 'banner_click_count_$bannerId';
      final currentCount = _storage!.getInt(key) ?? 0;
      await _storage!.setInt(key, currentCount + 1);
      
      debugPrint('📊 Banner $bannerId clicked (count: ${currentCount + 1})');
      
    } catch (e) {
      debugPrint('❌ Error tracking banner click: $e');
    }
  }

  /// ✅ إخفاء البانر نهائياً
  Future<void> dismissBannerForever(String bannerId) async {
    if (_storage == null) {
      debugPrint('❌ Storage is null, cannot dismiss banner forever');
      return;
    }
    
    try {
      final key = 'banner_dismissed_forever_$bannerId';
      await _storage!.setBool(key, true);
      
      debugPrint('🚫 Banner $bannerId dismissed forever');
      
    } catch (e) {
      debugPrint('❌ Error dismissing banner forever: $e');
    }
  }

  /// ✅ التحقق من أن البانر مُخفى نهائياً
  bool isBannerDismissedForever(String bannerId) {
    if (_storage == null) return false;
    
    try {
      final key = 'banner_dismissed_forever_$bannerId';
      return _storage!.getBool(key) ?? false;
    } catch (e) {
      debugPrint('❌ Error checking dismissed forever: $e');
      return false;
    }
  }

  /// ✅ تسجيل أن المستخدم نقر على زر التحديث
  Future<void> markUpdateBannerAsActioned(String bannerId) async {
    if (_storage == null) {
      debugPrint('❌ Storage is null');
      return;
    }
    
    try {
      final key = 'banner_update_actioned_$bannerId';
      await _storage!.setBool(key, true);
      await _storage!.setString(
        'banner_update_actioned_time_$bannerId',
        DateTime.now().toIso8601String(),
      );
      
      debugPrint('✅ Update banner $bannerId marked as actioned');
      
    } catch (e) {
      debugPrint('❌ Error marking update banner: $e');
    }
  }

  /// ✅ التحقق من أن المستخدم نقر على التحديث
  bool isUpdateBannerActioned(String bannerId) {
    if (_storage == null) return false;
    
    try {
      final key = 'banner_update_actioned_$bannerId';
      return _storage!.getBool(key) ?? false;
    } catch (e) {
      debugPrint('❌ Error checking update actioned: $e');
      return false;
    }
  }

  /// ✅ استعادة بانر مُخفى (للاختبار)
  Future<void> restoreBanner(String bannerId) async {
    if (_storage == null) {
      debugPrint('❌ Storage is null');
      return;
    }
    
    try {
      await _storage!.remove('banner_dismissed_forever_$bannerId');
      await _storage!.remove('banner_update_actioned_$bannerId');
      await _storage!.remove('banner_update_actioned_time_$bannerId');
      
      debugPrint('♻️ Banner $bannerId restored');
    } catch (e) {
      debugPrint('❌ Error restoring banner: $e');
    }
  }

  /// الحصول على إحصائيات البانر
  Map<String, dynamic> getBannerStats(String bannerId) {
    // ✅ التحقق من Storage
    if (_storage == null) {
      debugPrint('❌ Storage is null');
      return {};
    }
    
    try {
      final showCount = _storage!.getInt('banner_show_count_$bannerId') ?? 0;
      final clickCount = _storage!.getInt('banner_click_count_$bannerId') ?? 0;
      final lastShownString = _storage!.getString('banner_last_shown_$bannerId');
      final isDismissed = isBannerDismissedForever(bannerId);
      final isActioned = isUpdateBannerActioned(bannerId);
      
      return {
        'banner_id': bannerId,
        'show_count': showCount,
        'click_count': clickCount,
        'last_shown': lastShownString,
        'click_rate': showCount > 0 ? (clickCount / showCount * 100).toStringAsFixed(1) : '0.0',
        'is_dismissed_forever': isDismissed,
        'is_update_actioned': isActioned,
      };
    } catch (e) {
      debugPrint('⚠️ Error getting banner stats: $e');
      return {};
    }
  }

  /// مسح بيانات البانر (للاختبار)
  Future<void> clearBannerData(String bannerId) async {
    // ✅ التحقق من Storage
    if (_storage == null) {
      debugPrint('❌ Storage is null, cannot clear banner data');
      return;
    }
    
    try {
      await _storage!.remove('banner_last_shown_$bannerId');
      await _storage!.remove('banner_show_count_$bannerId');
      await _storage!.remove('banner_click_count_$bannerId');
      await _storage!.remove('banner_dismissed_forever_$bannerId');
      await _storage!.remove('banner_update_actioned_$bannerId');
      await _storage!.remove('banner_update_actioned_time_$bannerId');
      
      debugPrint('🧹 Banner data cleared for: $bannerId');
    } catch (e) {
      debugPrint('❌ Error clearing banner data: $e');
    }
  }

  /// مسح جميع بيانات البانرات
  Future<void> clearAllBannerData() async {
    try {
      for (final banner in _cachedBanners) {
        await clearBannerData(banner.id);
      }
      debugPrint('🧹 All banner data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all banner data: $e');
    }
  }

  // ==================== Getters ====================

  bool get isInitialized => _isInitialized;
  
  List<PromotionalBanner> get allBanners => List.unmodifiable(_cachedBanners);
  
  int get activeBannersCount => _cachedBanners
      .where((banner) => banner.isCurrentlyActive)
      .length;

  DateTime? get lastCacheUpdate => _lastCacheUpdate;

  /// معلومات التصحيح
  Map<String, dynamic> get debugInfo {
    // ✅ التحقق من null قبل الوصول
    if (!_isInitialized || _storage == null) {
      return {
        'is_initialized': _isInitialized,
        'storage_available': _storage != null,
        'remote_config_available': _remoteConfig != null,
        'error': 'Manager not properly initialized',
      };
    }
    
    return {
      'is_initialized': _isInitialized,
      'total_banners': _cachedBanners.length,
      'active_banners': activeBannersCount,
      'last_cache_update': _lastCacheUpdate?.toIso8601String(),
      'banners': _cachedBanners.map((b) => {
        'id': b.id,
        'title': b.title,
        'type': b.bannerType.displayName,
        'priority': b.priority.displayName,
        'is_active': b.isCurrentlyActive,
        'target_screens': b.targetScreens,
        'stats': getBannerStats(b.id),
      }).toList(),
    };
  }

  /// طباعة الحالة
  void printStatus() {
    debugPrint('========== Promotional Banner Manager Status ==========');
    debugPrint('Initialized: $_isInitialized');
    debugPrint('Storage Available: ${_storage != null}');
    debugPrint('RemoteConfig Available: ${_remoteConfig != null}');
    
    if (!_isInitialized) {
      debugPrint('⚠️ Manager is not initialized properly');
      debugPrint('====================================================');
      return;
    }
    
    debugPrint('Total Banners: ${_cachedBanners.length}');
    debugPrint('Active Banners: $activeBannersCount');
    debugPrint('Last Update: $_lastCacheUpdate');
    debugPrint('--- Banners ---');
    
    for (final banner in _cachedBanners) {
      debugPrint('  - ${banner.title} (${banner.id})');
      debugPrint('    Type: ${banner.bannerType.displayName}');
      debugPrint('    Priority: ${banner.priority.displayName}');
      debugPrint('    Active: ${banner.isCurrentlyActive}');
      debugPrint('    Screens: ${banner.targetScreens.join(", ")}');
      
      if (_storage != null) {
        final stats = getBannerStats(banner.id);
        debugPrint('    Stats: ${stats["show_count"]} shows, ${stats["click_count"]} clicks');
        debugPrint('    Dismissed: ${stats["is_dismissed_forever"]}');
        if (banner.bannerType == BannerType.update) {
          debugPrint('    Update Actioned: ${stats["is_update_actioned"]}');
        }
      }
    }
    debugPrint('====================================================');
  }

  /// تنظيف
  void dispose() {
    _isInitialized = false;
    _cachedBanners = [];
    _lastCacheUpdate = null;
    _remoteConfig = null;
    _storage = null;
    debugPrint('🧹 PromotionalBannerManager disposed');
  }
}