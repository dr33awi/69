// lib/app/di/service_locator.dart - محدث مع تهيئة سريعة للبانرات و In-App Messaging
import 'package:athkar_app/app/themes/core/theme_notifier.dart';
import 'package:athkar_app/core/error/error_handler.dart';
import 'package:athkar_app/core/firebase/firebase_messaging_service.dart';
import 'package:athkar_app/core/firebase/remote_config_manager.dart';
import 'package:athkar_app/core/firebase/remote_config_service.dart';
import 'package:athkar_app/core/firebase/analytics/analytics_service.dart';
import 'package:athkar_app/core/firebase/performance/performance_service.dart';
import 'package:athkar_app/core/firebase/messaging/in_app_messaging_service.dart';
import 'package:athkar_app/core/infrastructure/services/device/battery/battery_service.dart';
import 'package:athkar_app/core/infrastructure/services/device/battery/battery_service_impl.dart';
import 'package:athkar_app/core/infrastructure/services/notifications/notification_manager.dart';
import 'package:athkar_app/core/infrastructure/services/notifications/notification_service.dart';
import 'package:athkar_app/core/infrastructure/services/notifications/notification_service_impl.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_manager.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service_impl.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service_impl.dart';
import 'package:athkar_app/core/infrastructure/services/logger/app_logger.dart';
import 'package:athkar_app/core/infrastructure/services/performance/performance_monitor.dart';
import 'package:athkar_app/core/infrastructure/services/memory/leak_tracker_service.dart';
import 'package:athkar_app/core/infrastructure/services/share/share_service.dart';
import 'package:athkar_app/core/infrastructure/services/review/review_service.dart';
import 'package:athkar_app/core/infrastructure/services/review/review_manager.dart';
import 'package:athkar_app/features/athkar/services/athkar_service.dart';
import 'package:athkar_app/features/dua/services/dua_service.dart';
import 'package:athkar_app/features/prayer_times/services/prayer_times_service.dart';
import 'package:athkar_app/features/qibla/services/qibla_service_v3.dart';
import 'package:athkar_app/features/settings/services/settings_services_manager.dart';
import 'package:athkar_app/features/tasbih/services/tasbih_service.dart';
import 'package:athkar_app/core/firebase/promotional_banners/promotional_banner_manager.dart';
import 'package:athkar_app/core/firebase/promotional_banners/utils/banner_helpers.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_core/firebase_core.dart';

final getIt = GetIt.instance;

/// Service Locator محسن مع تهيئة سريعة للبانرات و In-App Messaging
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  bool _isEssentialInitialized = false;
  bool _isFeatureServicesRegistered = false;
  bool _firebaseAvailable = false;
  bool _advancedFirebaseInitialized = false;
  
  static const String _keyLastInitTime = 'last_init_time';
  static const String _keyFeatureServicesRegistered = 'feature_services_registered';
  static const String _keyFirebaseAvailable = 'firebase_available';

  /// تهيئة سريعة - خدمات أساسية فقط
  static Future<void> initEssential() async {
    await _instance._initializeEssentialOnly();
  }

  /// تسجيل خدمات الميزات
  static Future<void> registerFeatureServices() async {
    await _instance._registerFeatureServicesIfNeeded();
  }

  static bool get isEssentialReady => _instance._isEssentialInitialized;
  static bool get areFeatureServicesRegistered => _instance._isFeatureServicesRegistered;
  static bool get isFirebaseAvailable => _instance._firebaseAvailable;

  /// تهيئة الخدمات الأساسية
  Future<void> _initializeEssentialOnly() async {
    if (_isEssentialInitialized) {
      return;
    }

    try {
      final stopwatch = Stopwatch()..start();

      await _registerCoreServices();
      await _registerStorageServices();
      await _loadSavedState();
      
      // ✅ فحص وتسجيل Firebase مبكراً
      await _checkFirebaseAvailability();
      if (_firebaseAvailable) {
        _registerFirebaseServices();
      }
      
      _registerDevelopmentServices();
      _registerThemeServices();
      _registerPermissionServices();
      await _registerNotificationServices();
      _registerDeviceServices();
      _registerErrorHandler();
      _registerShareService();
      _registerReviewServices();
      _registerPrayerTimesService();

      _isEssentialInitialized = true;
      stopwatch.stop();
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  Future<void> _registerFeatureServicesIfNeeded() async {
    if (_isFeatureServicesRegistered) {
      return;
    }

    try {
      _registerFeatureServicesLazy();
      _isFeatureServicesRegistered = true;
      await _saveRegistrationState();
    } catch (e) {
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = getIt<SharedPreferences>();
      final lastInitTime = prefs.getInt(_keyLastInitTime) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final dayInMillis = 24 * 60 * 60 * 1000;
      
      if (now - lastInitTime > dayInMillis) {
        await _resetSavedState();
        return;
      }

      _isFeatureServicesRegistered = prefs.getBool(_keyFeatureServicesRegistered) ?? false;
      _firebaseAvailable = prefs.getBool(_keyFirebaseAvailable) ?? false;
      
      if (_isFeatureServicesRegistered) {
        _registerFeatureServicesLazy();
      }

    } catch (e) {
      await _resetSavedState();
    }
  }

  Future<void> _saveRegistrationState() async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.setInt(_keyLastInitTime, DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool(_keyFeatureServicesRegistered, _isFeatureServicesRegistered);
      await prefs.setBool(_keyFirebaseAvailable, _firebaseAvailable);
    } catch (e) {
    }
  }

  Future<void> _resetSavedState() async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.remove(_keyLastInitTime);
      await prefs.remove(_keyFeatureServicesRegistered);
      await prefs.remove(_keyFirebaseAvailable);
      _isFeatureServicesRegistered = false;
      _firebaseAvailable = false;
    } catch (e) {
    }
  }

  // ==================== تسجيل الخدمات الأساسية ====================

  Future<void> _registerCoreServices() async {
    if (!getIt.isRegistered<SharedPreferences>()) {
      final sharedPreferences = await SharedPreferences.getInstance();
      getIt.registerSingleton<SharedPreferences>(sharedPreferences);
    }

    if (!getIt.isRegistered<Battery>()) {
      getIt.registerLazySingleton<Battery>(() => Battery());
    }

    if (!getIt.isRegistered<FlutterLocalNotificationsPlugin>()) {
      getIt.registerLazySingleton<FlutterLocalNotificationsPlugin>(
        () => FlutterLocalNotificationsPlugin(),
      );
    }
  }

  Future<void> _registerStorageServices() async {
    if (!getIt.isRegistered<StorageService>()) {
      getIt.registerLazySingleton<StorageService>(
        () => StorageServiceImpl(getIt<SharedPreferences>()),
      );
    }
  }

  void _registerThemeServices() {
    if (!getIt.isRegistered<ThemeNotifier>()) {
      getIt.registerLazySingleton<ThemeNotifier>(
        () => ThemeNotifier(getIt<StorageService>()),
      );
    }
  }

  void _registerPermissionServices() {
    if (!getIt.isRegistered<PermissionService>()) {
      getIt.registerLazySingleton<PermissionService>(
        () => PermissionServiceImpl(storage: getIt<StorageService>()),
      );
    }

    if (!getIt.isRegistered<UnifiedPermissionManager>()) {
      getIt.registerLazySingleton<UnifiedPermissionManager>(
        () => UnifiedPermissionManager.getInstance(
          permissionService: getIt<PermissionService>(),
          storage: getIt<StorageService>(),
        ),
      );
    }
  }

  Future<void> _registerNotificationServices() async {
    if (!getIt.isRegistered<NotificationService>()) {
      getIt.registerLazySingleton<NotificationService>(
        () => NotificationServiceImpl(
          prefs: getIt<SharedPreferences>(),
          plugin: getIt<FlutterLocalNotificationsPlugin>(),
          battery: getIt<Battery>(),
        ),
      );
    }

    try {
      await NotificationManager.initialize(getIt<NotificationService>());
    } catch (e) {
    }
  }

  void _registerDeviceServices() {
    if (!getIt.isRegistered<BatteryService>()) {
      getIt.registerLazySingleton<BatteryService>(
        () => BatteryServiceImpl(battery: getIt<Battery>()),
      );
    }
  }

  void _registerErrorHandler() {
    if (!getIt.isRegistered<AppErrorHandler>()) {
      getIt.registerLazySingleton<AppErrorHandler>(() => AppErrorHandler());
    }
  }

  void _registerDevelopmentServices() {
    try {
      if (!getIt.isRegistered<AppLogger>()) {
        getIt.registerSingleton<AppLogger>(AppLogger.instance);
        AppLogger.info('AppLogger service registered');
      }

      if (!getIt.isRegistered<PerformanceMonitor>()) {
        getIt.registerSingleton<PerformanceMonitor>(PerformanceMonitor.instance);
        AppLogger.info('PerformanceMonitor service registered');
      }

      if (!getIt.isRegistered<LeakTrackerService>()) {
        getIt.registerSingleton<LeakTrackerService>(LeakTrackerService.instance);
        LeakTrackerService.instance.initialize();
        AppLogger.info('LeakTrackerService initialized and registered');
      }
    } catch (e) {
    }
  }

  void _registerShareService() {
    try {
      if (!getIt.isRegistered<ShareService>()) {
        getIt.registerLazySingleton<ShareService>(() => ShareService());
      }
    } catch (e) {
    }
  }

  void _registerReviewServices() {
    try {
      if (!getIt.isRegistered<ReviewService>()) {
        getIt.registerLazySingleton<ReviewService>(
          () => ReviewService(prefs: getIt<SharedPreferences>()),
        );
      }
      
      if (!getIt.isRegistered<ReviewManager>()) {
        getIt.registerLazySingleton<ReviewManager>(
          () => ReviewManager(reviewService: getIt<ReviewService>()),
        );
      }
    } catch (e) {
    }
  }

  void _registerPrayerTimesService() {
    if (!getIt.isRegistered<PrayerTimesService>()) {
      getIt.registerLazySingleton<PrayerTimesService>(
        () {
          return PrayerTimesService(
            storage: getIt<StorageService>(),
            permissionService: getIt<PermissionService>(),
          );
        },
      );
    }
  }

  void _registerFeatureServicesLazy() {
    if (!getIt.isRegistered<AthkarService>()) {
      getIt.registerLazySingleton<AthkarService>(
        () {
          return AthkarService(storage: getIt<StorageService>());
        },
      );
    }

    if (!getIt.isRegistered<DuaService>()) {
      getIt.registerLazySingleton<DuaService>(
        () {
          return DuaService(storage: getIt<StorageService>());
        },
      );
    }

    if (!getIt.isRegistered<TasbihService>()) {
      getIt.registerFactory<TasbihService>(
        () {
          return TasbihService(storage: getIt<StorageService>());
        },
      );
    }
    
    if (!getIt.isRegistered<QiblaServiceV3>()) {
      getIt.registerFactory<QiblaServiceV3>(
        () {
          return QiblaServiceV3(
            storage: getIt<StorageService>(),
            permissionService: getIt<PermissionService>(),
          );
        },
      );
    }

    if (!getIt.isRegistered<SettingsServicesManager>()) {
      getIt.registerLazySingleton<SettingsServicesManager>(
        () {
          return SettingsServicesManager(
            storage: getIt<StorageService>(),
            permissionService: getIt<PermissionService>(),
            themeNotifier: getIt<ThemeNotifier>(),
          );
        },
      );
    }
  }
  
  // ==================== Firebase Services ====================

  static Future<void> initializeFirebaseInBackground() async {
    await _instance._safeInitializeFirebase();
  }

  Future<void> _safeInitializeFirebase() async {
    if (_firebaseAvailable) {
      if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
        await _initializeFirebaseServices();
      } else {
        _registerFirebaseServices();
        await _initializeFirebaseServices();
      }
      return;
    }

    try {
      await _checkFirebaseAvailability();
      
      if (_firebaseAvailable) {
        _registerFirebaseServices();
        await _initializeFirebaseServices();
        await _saveRegistrationState();
      }
      
    } catch (e) {
      _firebaseAvailable = false;
    }
  }

  Future<void> _checkFirebaseAvailability() async {
    try {
      final List<FirebaseApp> apps = Firebase.apps;
      
      if (apps.isNotEmpty) {
        _firebaseAvailable = true;
      } else {
        _firebaseAvailable = false;
      }
    } catch (e) {
      _firebaseAvailable = false;
    }
  }

  void _registerFirebaseServices() {
    if (!_firebaseAvailable) {
      return;
    }
    
    try {
      if (!getIt.isRegistered<FirebaseRemoteConfigService>()) {
        getIt.registerLazySingleton<FirebaseRemoteConfigService>(
          () {
            return FirebaseRemoteConfigService();
          },
        );
      }
      
      if (!getIt.isRegistered<RemoteConfigManager>()) {
        getIt.registerLazySingleton<RemoteConfigManager>(
          () {
            return RemoteConfigManager();
          },
        );
      }
      
      if (!getIt.isRegistered<PromotionalBannerManager>()) {
        getIt.registerLazySingleton<PromotionalBannerManager>(
          () {
            return PromotionalBannerManager();
          },
        );
      }
      
      if (!getIt.isRegistered<FirebaseMessagingService>()) {
        getIt.registerLazySingleton<FirebaseMessagingService>(
          () {
            return FirebaseMessagingService();
          },
        );
      }
    } catch (e, stackTrace) {
      _firebaseAvailable = false;
    }
  }

  /// ✅ تهيئة سريعة ومحسّنة للبانرات
  Future<void> _initializeFirebaseServices() async {
    if (!_firebaseAvailable) {
      return;
    }
    
    try {
      final storage = getIt<StorageService>();
      final stopwatch = Stopwatch()..start();
      
      // ✅ 1. تهيئة Remote Config أولاً (الأهم!)
      if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
        try {
          final remoteConfig = getIt<FirebaseRemoteConfigService>();
          
          if (!remoteConfig.isInitialized) {
            await remoteConfig.initialize();
          }
          
          // ✅ 2. تهيئة Manager
          if (getIt.isRegistered<RemoteConfigManager>()) {
            final manager = getIt<RemoteConfigManager>();
            
            if (!manager.isInitialized) {
              await manager.initialize(
                remoteConfig: remoteConfig,
                storage: storage,
              );
            }
          }
          
          // ✅ 3. تهيئة Banner Manager (الأهم!)
          if (getIt.isRegistered<PromotionalBannerManager>()) {
            final bannerManager = getIt<PromotionalBannerManager>();
            
            if (!bannerManager.isInitialized) {
              await bannerManager.initialize(
                remoteConfig: remoteConfig,
                storage: storage,
              );
              
              stopwatch.stop();
              // طباعة حالة البانرات
              if (bannerManager.activeBannersCount > 0) {
                bannerManager.printStatus();
              } else {
              }
            }
          }
          
        } catch (e) {
        }
      }
      
      // 4. Firebase Messaging (اختياري)
      if (getIt.isRegistered<FirebaseMessagingService>()) {
        try {
          final messaging = getIt<FirebaseMessagingService>();
          
          if (!messaging.isInitialized) {
            await messaging.initialize(
              storage: storage,
              notificationService: getIt<NotificationService>(),
            );
          }
        } catch (e) {
        }
      }
    } catch (e) {
    }
  }

  // ==================== Advanced Firebase ====================

  static Future<void> initializeAdvancedFirebaseServices() async {
    await _instance._initializeAdvancedFirebase();
  }

  Future<void> _initializeAdvancedFirebase() async {
    if (!_firebaseAvailable) {
      return;
    }

    if (_advancedFirebaseInitialized) {
      return;
    }

    try {
      // Analytics Service
      if (!getIt.isRegistered<AnalyticsService>()) {
        getIt.registerSingleton<AnalyticsService>(AnalyticsService());
        final analytics = getIt<AnalyticsService>();
        await analytics.initialize();
      }
      
      // Performance Service
      if (!getIt.isRegistered<PerformanceService>()) {
        getIt.registerSingleton<PerformanceService>(PerformanceService());
        final performance = getIt<PerformanceService>();
        await performance.initialize();
      }
      
      // ✅ In-App Messaging Service - جديد!
      if (!getIt.isRegistered<InAppMessagingService>()) {
        getIt.registerSingleton<InAppMessagingService>(InAppMessagingService());
        final inAppMessaging = getIt<InAppMessagingService>();
        await inAppMessaging.initialize();
      }
      
      _advancedFirebaseInitialized = true;
    } catch (e) {
    }
  }

  // ==================== الخدمات المساعدة ====================

  static bool areEssentialServicesReady() {
    return _instance._isEssentialInitialized &&
           getIt.isRegistered<StorageService>() &&
           getIt.isRegistered<ThemeNotifier>() &&
           getIt.isRegistered<PermissionService>() &&
           getIt.isRegistered<UnifiedPermissionManager>() &&
           getIt.isRegistered<BatteryService>() &&
           getIt.isRegistered<ShareService>();
  }

  static bool isAppReadyToRun() {
    return areEssentialServicesReady() && areFeatureServicesRegistered;
  }

  static Future<void> reset({bool clearCache = false}) async {
    try {
      await _instance._cleanup();
      
      if (clearCache) {
        await _instance._resetSavedState();
      }
      
      await getIt.reset();
      _instance._isEssentialInitialized = false;
      
      if (clearCache) {
        _instance._isFeatureServicesRegistered = false;
        _instance._firebaseAvailable = false;
        _instance._advancedFirebaseInitialized = false;
      }
      
    } catch (e) {
    }
  }

  Future<void> _cleanup() async {
    try {
      if (getIt.isRegistered<SettingsServicesManager>()) {
        try {
          if (_isServiceActuallyInitialized<SettingsServicesManager>()) {
            getIt<SettingsServicesManager>().dispose();
          }
        } catch (e) {
        }
      }

      if (getIt.isRegistered<ThemeNotifier>()) {
        getIt<ThemeNotifier>().dispose();
      }

      if (getIt.isRegistered<PrayerTimesService>()) {
        try {
          if (_isServiceActuallyInitialized<PrayerTimesService>()) {
            getIt<PrayerTimesService>().dispose();
          }
        } catch (e) {
        }
      }
      
      if (getIt.isRegistered<AthkarService>()) {
        try {
          if (_isServiceActuallyInitialized<AthkarService>()) {
            getIt<AthkarService>().dispose();
          }
        } catch (e) {
        }
      }

      if (getIt.isRegistered<BatteryService>()) {
        await getIt<BatteryService>().dispose();
      }

      if (getIt.isRegistered<NotificationService>()) {
        await getIt<NotificationService>().dispose();
      }

      if (getIt.isRegistered<UnifiedPermissionManager>()) {
        getIt<UnifiedPermissionManager>().dispose();
      }

      if (getIt.isRegistered<PermissionService>()) {
        await getIt<PermissionService>().dispose();
      }

      _cleanupFirebaseServices();
      _cleanupAdvancedFirebaseServices();
    } catch (e) {
    }
  }

  bool _isServiceActuallyInitialized<T extends Object>() {
    try {
      return getIt.isRegistered<T>() && getIt.isReadySync<T>();
    } catch (e) {
      return false;
    }
  }

  void _cleanupFirebaseServices() {
    try {
      if (getIt.isRegistered<FirebaseMessagingService>()) {
        if (_isServiceActuallyInitialized<FirebaseMessagingService>()) {
          getIt<FirebaseMessagingService>().dispose();
        }
      }

      if (getIt.isRegistered<RemoteConfigManager>()) {
        if (_isServiceActuallyInitialized<RemoteConfigManager>()) {
          getIt<RemoteConfigManager>().dispose();
        }
      }
      
      if (getIt.isRegistered<PromotionalBannerManager>()) {
        if (_isServiceActuallyInitialized<PromotionalBannerManager>()) {
          getIt<PromotionalBannerManager>().dispose();
        }
      }

      if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
        if (_isServiceActuallyInitialized<FirebaseRemoteConfigService>()) {
          getIt<FirebaseRemoteConfigService>().dispose();
        }
      }
    } catch (e) {
    }
  }

  void _cleanupAdvancedFirebaseServices() {
    try {
      if (getIt.isRegistered<AnalyticsService>()) {
        if (_isServiceActuallyInitialized<AnalyticsService>()) {
          getIt<AnalyticsService>().dispose();
        }
      }
      
      if (getIt.isRegistered<PerformanceService>()) {
        if (_isServiceActuallyInitialized<PerformanceService>()) {
          getIt<PerformanceService>().dispose();
        }
      }
      
      // تنظيف In-App Messaging
      if (getIt.isRegistered<InAppMessagingService>()) {
        if (_isServiceActuallyInitialized<InAppMessagingService>()) {
          getIt<InAppMessagingService>().dispose();
        }
      }
    } catch (e) {
    }
  }

  static Future<void> dispose() async {
    await reset(clearCache: true);
  }
}

// ==================== Helper functions ====================

T getService<T extends Object>() {
  if (!getIt.isRegistered<T>()) {
    throw Exception('Service $T is not registered. Make sure to call ServiceLocator.initEssential() first.');
  }
  return getIt<T>();
}

T? getServiceSafe<T extends Object>() {
  try {
    return getIt.isRegistered<T>() ? getIt<T>() : null;
  } catch (e) {
    return null;
  }
}

// ==================== Extension methods ====================

extension ServiceLocatorExtensions on BuildContext {
  T getService<T extends Object>() => getIt<T>();
  bool hasService<T extends Object>() => getIt.isRegistered<T>();
  
  StorageService get storageService => getIt<StorageService>();
  NotificationService get notificationService => getIt<NotificationService>();
  PermissionService get permissionService => getIt<PermissionService>();
  UnifiedPermissionManager get permissionManager => getIt<UnifiedPermissionManager>();
  AppErrorHandler get errorHandler => getIt<AppErrorHandler>();
  BatteryService get batteryService => getIt<BatteryService>();
  ThemeNotifier get themeNotifier => getIt<ThemeNotifier>();
  ShareService get shareService => getIt<ShareService>();
  ReviewService get reviewService => getIt<ReviewService>();
  ReviewManager get reviewManager => getIt<ReviewManager>();
  
  PrayerTimesService get prayerTimesService => getIt<PrayerTimesService>();
  AthkarService get athkarService => getIt<AthkarService>();
  DuaService get duaService => getIt<DuaService>();
  TasbihService get tasbihService => getIt<TasbihService>();
  QiblaServiceV3 get qiblaService => getIt<QiblaServiceV3>();
  SettingsServicesManager get settingsManager => getIt<SettingsServicesManager>();
  
  FirebaseRemoteConfigService? get firebaseRemoteConfig {
    try {
      return ServiceLocator.isFirebaseAvailable && getIt.isRegistered<FirebaseRemoteConfigService>() 
          ? getIt<FirebaseRemoteConfigService>() 
          : null;
    } catch (e) {
      return null;
    }
  }
  
  RemoteConfigManager? get remoteConfigManager {
    try {
      return ServiceLocator.isFirebaseAvailable && getIt.isRegistered<RemoteConfigManager>() 
          ? getIt<RemoteConfigManager>() 
          : null;
    } catch (e) {
      return null;
    }
  }
  
  FirebaseMessagingService? get firebaseMessaging {
    try {
      return ServiceLocator.isFirebaseAvailable && getIt.isRegistered<FirebaseMessagingService>() 
          ? getIt<FirebaseMessagingService>() 
          : null;
    } catch (e) {
      return null;
    }
  }
  
  PromotionalBannerManager? get bannerManager {
    try {
      return ServiceLocator.isFirebaseAvailable && 
             getIt.isRegistered<PromotionalBannerManager>() 
          ? getIt<PromotionalBannerManager>() 
          : null;
    } catch (e) {
      return null;
    }
  }
  
  // ✅ إضافة In-App Messaging Service
  InAppMessagingService? get inAppMessaging {
    try {
      return ServiceLocator.isFirebaseAvailable && 
             getIt.isRegistered<InAppMessagingService>() 
          ? getIt<InAppMessagingService>() 
          : null;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> showBanners({required String screenName}) async {
    try {
      final manager = bannerManager;
      if (manager == null || !manager.isInitialized) {
        return;
      }
      
      await BannerHelpers.showBannersForScreen(
        context: this,
        screenName: screenName,
      );
    } catch (e) {
    }
  }
  
  Future<void> showSpecificBanner(String bannerId) async {
    try {
      await BannerHelpers.showBannerById(
        context: this,
        bannerId: bannerId,
      );
    } catch (e) {
    }
  }
  
  Future<void> refreshBanners() async {
    try {
      final manager = bannerManager;
      if (manager != null && manager.isInitialized) {
        await manager.refresh();
      }
    } catch (e) {
    }
  }
  
  int get activeBannersCount {
    final manager = bannerManager;
    return manager?.activeBannersCount ?? 0;
  }
  
  Map<String, dynamic>? getBannerStats(String bannerId) {
    final manager = bannerManager;
    if (manager == null || !manager.isInitialized) return null;
    return manager.getBannerStats(bannerId);
  }
  
  Future<void> clearAllBannerData() async {
    final manager = bannerManager;
    if (manager != null && manager.isInitialized) {
      await manager.clearAllBannerData();
    }
  }
  
  void printBannerStatus() {
    final manager = bannerManager;
    if (manager != null && manager.isInitialized) {
      manager.printStatus();
    } else {
    }
  }
  
  // ✅ وظائف In-App Messaging
  Future<void> triggerInAppMessage(String eventName) async {
    final service = inAppMessaging;
    if (service != null && service.isInitialized) {
      await service.triggerEvent(eventName);
    } else {
    }
  }
  
  void suppressInAppMessages(bool suppress) {
    final service = inAppMessaging;
    if (service != null && service.isInitialized) {
      service.suppressMessages(suppress);
    }
  }
  
  Map<String, dynamic>? getInAppMessagingStats() {
    final service = inAppMessaging;
    if (service != null && service.isInitialized) {
      return service.getStatistics();
    }
    return null;
  }
  
  AnalyticsService? get analyticsService {
    try {
      return getIt.isRegistered<AnalyticsService>() 
          ? getIt<AnalyticsService>() 
          : null;
    } catch (e) {
      return null;
    }
  }
  
  PerformanceService? get performanceService {
    try {
      return getIt.isRegistered<PerformanceService>() 
          ? getIt<PerformanceService>() 
          : null;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> logAnalyticsEvent(String name, [Map<String, dynamic>? params]) async {
    try {
      final service = analyticsService;
      if (service != null && service.isInitialized) {
        await service.logEvent(name, params);
      }
    } catch (e) {
    }
  }
  
  Future<void> logScreenView(String screenName, {Map<String, dynamic>? extras}) async {
    try {
      final service = analyticsService;
      if (service != null && service.isInitialized) {
        await service.logScreenView(screenName, extras: extras);
      }
    } catch (e) {
    }
  }
  
  Future<T> trackPerformance<T>(
    String traceName,
    Future<T> Function() operation, {
    Map<String, dynamic>? attributes,
  }) async {
    try {
      final service = performanceService;
      if (service != null && service.isInitialized) {
        return await service.trackPerformance(traceName, operation, attributes: attributes);
      }
    } catch (e) {
    }
    
    return await operation();
  }
  
  void startTrace(String traceName) {
    try {
      final service = performanceService;
      if (service != null && service.isInitialized) {
        service.startTrace(traceName);
      }
    } catch (e) {
    }
  }
  
  Future<void> stopTrace(String traceName, {Map<String, dynamic>? attributes}) async {
    try {
      final service = performanceService;
      if (service != null && service.isInitialized) {
        await service.stopTrace(traceName, attributes: attributes);
      }
    } catch (e) {
    }
  }
  
  bool get isMaintenanceModeActive {
    final manager = remoteConfigManager;
    return manager?.isMaintenanceModeActive ?? false;
  }
  
  bool get isForceUpdateRequired {
    final manager = remoteConfigManager;
    return manager?.isForceUpdateRequired ?? false;
  }
  
  String get requiredAppVersion {
    final manager = remoteConfigManager;
    return manager?.requiredAppVersion ?? '1.0.0';
  }
  
  String? get updateUrl {
    final manager = remoteConfigManager;
    return manager?.updateUrl;
  }
  
  Future<bool> refreshRemoteConfig() async {
    final manager = remoteConfigManager;
    if (manager == null || !manager.isInitialized) {
      return false;
    }
    
    return await manager.refreshConfig();
  }
  
  Map<String, dynamic>? get remoteConfigStatus {
    final manager = remoteConfigManager;
    return manager?.configStatus;
  }
  
  Future<bool> requestPermission(
    AppPermissionType permission, {
    String? customMessage,
    bool forceRequest = false,
  }) async {
    return await permissionManager.requestPermissionWithExplanation(
      this,
      permission,
      customMessage: customMessage,
      forceRequest: forceRequest,
    );
  }
  
  Future<bool> hasPermission(AppPermissionType permission) async {
    final status = await permissionService.checkPermissionStatus(permission);
    return status == AppPermissionStatus.granted;
  }
}