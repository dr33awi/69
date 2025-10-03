// lib/app/di/service_locator.dart - محسن نهائياً مع Lazy Loading حقيقي
import 'package:athkar_app/app/themes/core/theme_notifier.dart';
import 'package:athkar_app/core/error/error_handler.dart';
import 'package:athkar_app/core/infrastructure/firebase/firebase_messaging_service.dart';
import 'package:athkar_app/core/infrastructure/firebase/remote_config_manager.dart';
import 'package:athkar_app/core/infrastructure/firebase/remote_config_service.dart';
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
import 'package:athkar_app/features/athkar/services/athkar_service.dart';
import 'package:athkar_app/features/dua/services/dua_service.dart';
import 'package:athkar_app/features/prayer_times/services/prayer_times_service.dart';
import 'package:athkar_app/features/qibla/services/qibla_service.dart';
import 'package:athkar_app/features/settings/services/settings_services_manager.dart';
import 'package:athkar_app/features/tasbih/services/tasbih_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

final getIt = GetIt.instance;

/// Service Locator محسن مع Lazy Loading حقيقي
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // حالة التهيئة
  bool _isEssentialInitialized = false;
  bool _isFeatureServicesRegistered = false;
  bool _firebaseAvailable = false;
  
  // مفاتيح التخزين للـ Cache
  static const String _keyLastInitTime = 'last_init_time';
  static const String _keyFeatureServicesRegistered = 'feature_services_registered';
  static const String _keyFirebaseAvailable = 'firebase_available';

  /// تهيئة سريعة - خدمات أساسية فقط
  static Future<void> initEssential() async {
    await _instance._initializeEssentialOnly();
  }

  /// تسجيل خدمات الميزات (بدون تهيئة)
  static Future<void> registerFeatureServices() async {
    await _instance._registerFeatureServicesIfNeeded();
  }

  /// فحص إذا كانت الخدمات الأساسية جاهزة
  static bool get isEssentialReady => _instance._isEssentialInitialized;

  /// فحص إذا كانت خدمات الميزات مسجلة (بدون تهيئة فعلية)
  static bool get areFeatureServicesRegistered => _instance._isFeatureServicesRegistered;

  /// فحص توفر Firebase
  static bool get isFirebaseAvailable => _instance._firebaseAvailable;

  /// تهيئة الخدمات الأساسية فقط (سريعة جداً)
  Future<void> _initializeEssentialOnly() async {
    if (_isEssentialInitialized) {
      debugPrint('ServiceLocator: Essential services already ready ⚡');
      return;
    }

    try {
      debugPrint('ServiceLocator: Fast initialization starting...');
      final stopwatch = Stopwatch()..start();

      // 1. الخدمات الأساسية المطلوبة فوراً
      await _registerCoreServices();
      await _registerStorageServices();
      
      // 2. تحميل الحالة المحفوظة
      await _loadSavedState();
      
      // 3. خدمات التطوير والمراقبة
      _registerDevelopmentServices();
      
      // 4. باقي الخدمات الأساسية
      _registerThemeServices();
      _registerPermissionServices();
      await _registerNotificationServices();
      _registerDeviceServices();
      _registerErrorHandler();

      _isEssentialInitialized = true;
      stopwatch.stop();
      
      debugPrint('ServiceLocator: Essential init completed in ${stopwatch.elapsedMilliseconds}ms ⚡');
      
    } catch (e, stackTrace) {
      debugPrint('ServiceLocator: Essential init failed: $e');
      debugPrint('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// تسجيل خدمات الميزات (بدون تهيئة فعلية)
  Future<void> _registerFeatureServicesIfNeeded() async {
    if (_isFeatureServicesRegistered) {
      debugPrint('ServiceLocator: Feature services already registered');
      return;
    }

    try {
      debugPrint('ServiceLocator: Registering feature services lazily...');
      
      _registerFeatureServicesLazy();
      _isFeatureServicesRegistered = true;
      
      // حفظ الحالة
      await _saveRegistrationState();
      
      debugPrint('ServiceLocator: Feature services registered successfully ✅');
      
    } catch (e) {
      debugPrint('ServiceLocator: Feature services registration failed: $e');
    }
  }

  /// تحميل الحالة المحفوظة
  Future<void> _loadSavedState() async {
    try {
      final prefs = getIt<SharedPreferences>();
      
      // فحص آخر وقت تهيئة (إعادة تعيين بعد يوم)
      final lastInitTime = prefs.getInt(_keyLastInitTime) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final dayInMillis = 24 * 60 * 60 * 1000;
      
      if (now - lastInitTime > dayInMillis) {
        await _resetSavedState();
        return;
      }

      // تحميل الحالة
      _isFeatureServicesRegistered = prefs.getBool(_keyFeatureServicesRegistered) ?? false;
      _firebaseAvailable = prefs.getBool(_keyFirebaseAvailable) ?? false;
      
      debugPrint('ServiceLocator: Loaded cached state:');
      debugPrint('  - Feature Services Registered: $_isFeatureServicesRegistered');
      debugPrint('  - Firebase Available: $_firebaseAvailable');
      
      // إعادة تسجيل خدمات الميزات إذا كانت مسجلة من قبل
      if (_isFeatureServicesRegistered) {
        _registerFeatureServicesLazy();
        debugPrint('ServiceLocator: Feature services re-registered from cache');
      }

    } catch (e) {
      debugPrint('ServiceLocator: Error loading saved state: $e');
      await _resetSavedState();
    }
  }

  /// حفظ حالة التسجيل
  Future<void> _saveRegistrationState() async {
    try {
      final prefs = getIt<SharedPreferences>();
      
      await prefs.setInt(_keyLastInitTime, DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool(_keyFeatureServicesRegistered, _isFeatureServicesRegistered);
      await prefs.setBool(_keyFirebaseAvailable, _firebaseAvailable);
      
      debugPrint('ServiceLocator: Registration state saved');
      
    } catch (e) {
      debugPrint('ServiceLocator: Error saving registration state: $e');
    }
  }

  /// إعادة تعيين الحالة المحفوظة
  Future<void> _resetSavedState() async {
    try {
      final prefs = getIt<SharedPreferences>();
      
      await prefs.remove(_keyLastInitTime);
      await prefs.remove(_keyFeatureServicesRegistered);
      await prefs.remove(_keyFirebaseAvailable);
      
      _isFeatureServicesRegistered = false;
      _firebaseAvailable = false;
      
      debugPrint('ServiceLocator: Saved state reset');
      
    } catch (e) {
      debugPrint('ServiceLocator: Error resetting saved state: $e');
    }
  }

  // ==================== تسجيل الخدمات الأساسية ====================

  Future<void> _registerCoreServices() async {
    debugPrint('ServiceLocator: Registering core services...');

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
    debugPrint('ServiceLocator: Registering storage services...');

    if (!getIt.isRegistered<StorageService>()) {
      getIt.registerLazySingleton<StorageService>(
        () => StorageServiceImpl(getIt<SharedPreferences>()),
      );
    }
  }

  void _registerThemeServices() {
    debugPrint('ServiceLocator: Registering theme services...');
    
    if (!getIt.isRegistered<ThemeNotifier>()) {
      getIt.registerLazySingleton<ThemeNotifier>(
        () => ThemeNotifier(getIt<StorageService>()),
      );
    }
  }

  void _registerPermissionServices() {
    debugPrint('ServiceLocator: Registering permission services...');

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
    debugPrint('ServiceLocator: Registering notification services...');

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
      debugPrint('ServiceLocator: Notification manager init error: $e');
    }
  }

  void _registerDeviceServices() {
    debugPrint('ServiceLocator: Registering device services...');

    if (!getIt.isRegistered<BatteryService>()) {
      getIt.registerLazySingleton<BatteryService>(
        () => BatteryServiceImpl(battery: getIt<Battery>()),
      );
    }
  }

  void _registerErrorHandler() {
    debugPrint('ServiceLocator: Registering error handler...');

    if (!getIt.isRegistered<AppErrorHandler>()) {
      getIt.registerLazySingleton<AppErrorHandler>(() => AppErrorHandler());
    }
  }

  /// تسجيل خدمات التطوير والمراقبة
  void _registerDevelopmentServices() {
    debugPrint('ServiceLocator: Registering development services...');
    
    try {
      // Logger - Singleton
      if (!getIt.isRegistered<AppLogger>()) {
        getIt.registerSingleton<AppLogger>(AppLogger.instance);
        AppLogger.info('AppLogger service registered');
      }

      // Performance Monitor - Singleton
      if (!getIt.isRegistered<PerformanceMonitor>()) {
        getIt.registerSingleton<PerformanceMonitor>(PerformanceMonitor.instance);
        AppLogger.info('PerformanceMonitor service registered');
      }

      // Leak Tracker Service - Singleton
      if (!getIt.isRegistered<LeakTrackerService>()) {
        getIt.registerSingleton<LeakTrackerService>(LeakTrackerService.instance);
        LeakTrackerService.instance.initialize();
        AppLogger.info('LeakTrackerService initialized and registered');
      }

      debugPrint('✅ Development services registered successfully');
    } catch (e) {
      debugPrint('❌ Error registering development services: $e');
    }
  }

  /// تسجيل خدمات الميزات كـ Lazy (لن تُهيئ حتى الاستخدام الفعلي)
  void _registerFeatureServicesLazy() {
    debugPrint('ServiceLocator: Registering feature services as TRUE LAZY...');
    
    // خدمة مواقيت الصلاة - Lazy Singleton
    if (!getIt.isRegistered<PrayerTimesService>()) {
      getIt.registerLazySingleton<PrayerTimesService>(
        () {
          debugPrint('🔄 ACTUAL LAZY LOADING: PrayerTimesService initialized NOW');
          return PrayerTimesService(
            storage: getIt<StorageService>(),
            permissionService: getIt<PermissionService>(),
          );
        },
      );
    }

    // خدمة الأذكار - Lazy Singleton
    if (!getIt.isRegistered<AthkarService>()) {
      getIt.registerLazySingleton<AthkarService>(
        () {
          debugPrint('🔄 ACTUAL LAZY LOADING: AthkarService initialized NOW');
          return AthkarService(storage: getIt<StorageService>());
        },
      );
    }

    // خدمة الأدعية - Lazy Singleton
    if (!getIt.isRegistered<DuaService>()) {
      getIt.registerLazySingleton<DuaService>(
        () {
          debugPrint('🔄 ACTUAL LAZY LOADING: DuaService initialized NOW');
          return DuaService(storage: getIt<StorageService>());
        },
      );
    }
    
    // خدمة التسبيح - Factory
    if (!getIt.isRegistered<TasbihService>()) {
      getIt.registerFactory<TasbihService>(
        () {
          debugPrint('🔄 FACTORY: New TasbihService instance created');
          return TasbihService(storage: getIt<StorageService>());
        },
      );
    }
    
    // خدمة القبلة - Factory
    if (!getIt.isRegistered<QiblaService>()) {
      getIt.registerFactory<QiblaService>(
        () {
          debugPrint('🔄 FACTORY: New QiblaService instance created');
          return QiblaService(
            storage: getIt<StorageService>(),
            permissionService: getIt<PermissionService>(),
          );
        },
      );
    }

    // خدمات الإعدادات - Lazy Singleton
    if (!getIt.isRegistered<SettingsServicesManager>()) {
      getIt.registerLazySingleton<SettingsServicesManager>(
        () {
          debugPrint('🔄 ACTUAL LAZY LOADING: SettingsServicesManager initialized NOW');
          return SettingsServicesManager(
            storage: getIt<StorageService>(),
            permissionService: getIt<PermissionService>(),
            themeNotifier: getIt<ThemeNotifier>(),
          );
        },
      );
    }
    
    debugPrint('ServiceLocator: TRUE LAZY feature services registered ✅');
  }

  // ==================== Firebase Services ====================

  /// تهيئة Firebase في الخلفية (اختياري)
  static Future<void> initializeFirebaseInBackground() async {
    await _instance._safeInitializeFirebase();
  }

  Future<void> _safeInitializeFirebase() async {
    if (_firebaseAvailable) {
      debugPrint('ServiceLocator: Firebase already available from cache');
      return;
    }

    try {
      debugPrint('ServiceLocator: Initializing Firebase in background...');
      
      // فحص إذا كان Firebase مُهيأ فعلياً
      await _checkFirebaseAvailability();
      
      if (_firebaseAvailable) {
        _registerFirebaseServices();
        await _initializeFirebaseServices();
        await _saveRegistrationState();
        debugPrint('ServiceLocator: Firebase initialized in background ✅');
      }
      
    } catch (e) {
      debugPrint('ServiceLocator: Firebase background init failed: $e');
      _firebaseAvailable = false;
    }
  }

  Future<void> _checkFirebaseAvailability() async {
    try {
      // فحص حقيقي لـ Firebase
      final List<FirebaseApp> apps = Firebase.apps;
      if (apps.isNotEmpty) {
        // Firebase مُهيأ
        _firebaseAvailable = true;
        debugPrint('ServiceLocator: Firebase apps found: ${apps.length}');
        
        // فحص خدمات محددة
        try {
          final token = await FirebaseMessaging.instance.getToken();
          debugPrint('ServiceLocator: Firebase Messaging available ✅ (Token: ${token != null})');
        } catch (e) {
          debugPrint('ServiceLocator: Firebase Messaging error: $e');
        }
        
        try {
          await FirebaseRemoteConfig.instance.fetchAndActivate();
          debugPrint('ServiceLocator: Firebase Remote Config available ✅');
        } catch (e) {
          debugPrint('ServiceLocator: Firebase Remote Config error: $e');
        }
        
      } else {
        _firebaseAvailable = false;
        debugPrint('ServiceLocator: No Firebase apps found');
      }
    } catch (e) {
      _firebaseAvailable = false;
      debugPrint('ServiceLocator: Firebase check failed: $e');
    }
  }

  void _registerFirebaseServices() {
    if (!_firebaseAvailable) return;
    
    try {
      if (!getIt.isRegistered<FirebaseRemoteConfigService>()) {
        getIt.registerLazySingleton<FirebaseRemoteConfigService>(
          () => FirebaseRemoteConfigService(),
        );
      }
      
      if (!getIt.isRegistered<RemoteConfigManager>()) {
        getIt.registerLazySingleton<RemoteConfigManager>(
          () => RemoteConfigManager(),
        );
      }
      
      if (!getIt.isRegistered<FirebaseMessagingService>()) {
        getIt.registerLazySingleton<FirebaseMessagingService>(
          () => FirebaseMessagingService(),
        );
      }
      
      debugPrint('ServiceLocator: Firebase services registered ✅');
      
    } catch (e) {
      debugPrint('ServiceLocator: Firebase services registration error: $e');
      _firebaseAvailable = false;
    }
  }

  Future<void> _initializeFirebaseServices() async {
    if (!_firebaseAvailable) return;
    
    try {
      final storage = getIt<StorageService>();
      
      // تهيئة Remote Config
      if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
        try {
          final remoteConfig = getIt<FirebaseRemoteConfigService>();
          await remoteConfig.initialize();
          debugPrint('ServiceLocator: Remote Config initialized ✅');
          
          if (getIt.isRegistered<RemoteConfigManager>()) {
            final configManager = getIt<RemoteConfigManager>();
            await configManager.initialize(
              remoteConfig: remoteConfig,
              storage: storage,
            );
            debugPrint('ServiceLocator: Remote Config Manager initialized ✅');
          }
        } catch (e) {
          debugPrint('ServiceLocator: Remote Config init failed: $e');
        }
      }
      
      // تهيئة Firebase Messaging
      if (getIt.isRegistered<FirebaseMessagingService>()) {
        try {
          final messaging = getIt<FirebaseMessagingService>();
          await messaging.initialize(
            storage: storage,
            notificationService: getIt<NotificationService>(),
          );
          debugPrint('ServiceLocator: Firebase Messaging initialized ✅');
        } catch (e) {
          debugPrint('ServiceLocator: Firebase Messaging init failed: $e');
        }
      }
      
    } catch (e) {
      debugPrint('ServiceLocator: Firebase services init failed: $e');
    }
  }

  // ==================== الخدمات المساعدة ====================

  /// فحص جاهزية الخدمات الأساسية فقط
  static bool areEssentialServicesReady() {
    return _instance._isEssentialInitialized &&
           getIt.isRegistered<StorageService>() &&
           getIt.isRegistered<ThemeNotifier>() &&
           getIt.isRegistered<PermissionService>() &&
           getIt.isRegistered<UnifiedPermissionManager>() &&
           getIt.isRegistered<BatteryService>();
  }

  /// فحص أن التطبيق جاهز للعمل (بدون إجبار تهيئة الخدمات)
  static bool isAppReadyToRun() {
    return areEssentialServicesReady() && areFeatureServicesRegistered;
  }

  /// إعادة تعيين
  static Future<void> reset({bool clearCache = false}) async {
    debugPrint('ServiceLocator: Resetting (clearCache: $clearCache)...');
    
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
      }
      
    } catch (e) {
      debugPrint('ServiceLocator: Reset error: $e');
    }
  }

  Future<void> _cleanup() async {
    debugPrint('ServiceLocator: Cleaning up resources...');

    try {
      // تنظيف الخدمات المُهيئة فقط (بدون إجبار التهيئة)
      
      if (getIt.isRegistered<SettingsServicesManager>()) {
        try {
          // فحص إذا كانت مُهيئة فعلياً
          if (_isServiceActuallyInitialized<SettingsServicesManager>()) {
            getIt<SettingsServicesManager>().dispose();
          }
        } catch (e) {
          debugPrint('ServiceLocator: SettingsServicesManager cleanup error: $e');
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
          debugPrint('ServiceLocator: PrayerTimesService cleanup error: $e');
        }
      }
      
      if (getIt.isRegistered<AthkarService>()) {
        try {
          if (_isServiceActuallyInitialized<AthkarService>()) {
            getIt<AthkarService>().dispose();
          }
        } catch (e) {
          debugPrint('ServiceLocator: AthkarService cleanup error: $e');
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

      debugPrint('ServiceLocator: Resources cleaned up');
    } catch (e) {
      debugPrint('ServiceLocator: Error cleaning up resources: $e');
    }
  }

  /// فحص إذا كانت الخدمة مُهيئة فعلياً (وليس مجرد مسجلة)
  bool _isServiceActuallyInitialized<T extends Object>() {
    try {
      // محاولة الوصول للخدمة بدون إجبار التهيئة
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

      if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
        if (_isServiceActuallyInitialized<FirebaseRemoteConfigService>()) {
          getIt<FirebaseRemoteConfigService>().dispose();
        }
      }
      
      debugPrint('ServiceLocator: Firebase services cleaned up');
    } catch (e) {
      debugPrint('ServiceLocator: Error cleaning Firebase services: $e');
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
    debugPrint('Error getting service $T: $e');
    return null;
  }
}

// ==================== Extension methods للوصول السريع للخدمات ====================

extension ServiceLocatorExtensions on BuildContext {
  T getService<T extends Object>() => getIt<T>();
  bool hasService<T extends Object>() => getIt.isRegistered<T>();
  
  // الخدمات الأساسية (آمنة دائماً)
  StorageService get storageService => getIt<StorageService>();
  NotificationService get notificationService => getIt<NotificationService>();
  PermissionService get permissionService => getIt<PermissionService>();
  UnifiedPermissionManager get permissionManager => getIt<UnifiedPermissionManager>();
  AppErrorHandler get errorHandler => getIt<AppErrorHandler>();
  BatteryService get batteryService => getIt<BatteryService>();
  ThemeNotifier get themeNotifier => getIt<ThemeNotifier>();
  
  // خدمات الميزات (ستُهيئ عند أول استخدام)
  PrayerTimesService get prayerTimesService {
    debugPrint('🔄 Accessing PrayerTimesService - will initialize if not already done');
    return getIt<PrayerTimesService>();
  }
  
  AthkarService get athkarService {
    debugPrint('🔄 Accessing AthkarService - will initialize if not already done');
    return getIt<AthkarService>();
  }
  
  DuaService get duaService {
    debugPrint('🔄 Accessing DuaService - will initialize if not already done');
    return getIt<DuaService>();
  }
  
  TasbihService get tasbihService => getIt<TasbihService>();
  QiblaService get qiblaService => getIt<QiblaService>();
  
  SettingsServicesManager get settingsManager {
    debugPrint('🔄 Accessing SettingsServicesManager - will initialize if not already done');
    return getIt<SettingsServicesManager>();
  }
  
  // Firebase Services (Safe Access)
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
  
  bool isFeatureEnabled(String featureName) {
    final manager = remoteConfigManager;
    if (manager == null) return true;
    
    try {
      switch (featureName.toLowerCase()) {
        case 'prayer_times':
          return manager.isPrayerTimesFeatureEnabled;
        case 'qibla':
          return manager.isQiblaFeatureEnabled;
        case 'athkar':
          return manager.isAthkarFeatureEnabled;
        case 'notifications':
          return manager.isNotificationsFeatureEnabled;
        default:
          return true;
      }
    } catch (e) {
      debugPrint('Error checking feature enabled: $e');
      return true;
    }
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