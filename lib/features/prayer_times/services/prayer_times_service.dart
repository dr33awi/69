// lib/features/prayer_times/services/prayer_times_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:adhan/adhan.dart' as adhan;

import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/notifications/notification_manager.dart';
import '../../../core/infrastructure/services/permissions/simple_permission_service.dart';
import '../../../core/error/exceptions.dart';
import '../models/prayer_time_model.dart';
import '../utils/prayer_utils.dart';

/// خدمة مواقيت الصلاة المحدثة مع نظام موحد لتحديد الموقع
class PrayerTimesService {
  final StorageService _storage;
  final SimplePermissionService _permissionService;
  
  // مفاتيح التخزين
  static const String _locationKey = 'prayer_location';
  static const String _settingsKey = 'prayer_settings';
  static const String _notificationSettingsKey = 'prayer_notification_settings';
  static const String _cachedTimesKey = 'cached_prayer_times';
  static const String _lastLocationUpdateKey = 'last_location_update';
  static const String _lastDataUpdateKey = 'last_data_update';
  
  // متغيرات الحالة
  PrayerLocation? _currentLocation;
  PrayerCalculationSettings _settings = const PrayerCalculationSettings();
  PrayerNotificationSettings _notificationSettings = const PrayerNotificationSettings();
  
  // Stream Controllers
  StreamController<DailyPrayerTimes>? _prayerTimesController;
  StreamController<PrayerTime?>? _nextPrayerController;
  Timer? _updateTimer;
  Timer? _countdownTimer;
  Timer? _dataRefreshTimer;
  
  // Cache
  final Map<String, DailyPrayerTimes> _timesCache = {};
  DailyPrayerTimes? _currentTimes;
  
  // حالة الخدمة
  bool _isDisposed = false;
  bool _isUpdating = false;
  DateTime? _lastLocationUpdate;
  DateTime? _lastDataUpdate;

  PrayerTimesService({
    required StorageService storage,
    required SimplePermissionService simplePermissionService,
  }) : _storage = storage,
       _permissionService = simplePermissionService {
    _initializeControllers();
    _initialize();
  }

  /// تهيئة StreamControllers
  void _initializeControllers() {
    _prayerTimesController = StreamController<DailyPrayerTimes>.broadcast();
    _nextPrayerController = StreamController<PrayerTime?>.broadcast();
  }

  /// تهيئة الخدمة
  Future<void> _initialize() async {
    if (_isDisposed) return;
    try {
      await _loadSavedSettings();
      await _loadSavedLocation();
      await _loadLastUpdateTimes();
      _startTimers();
      
      if (_currentLocation != null) {
        await _checkAndUpdateData();
      }
    } catch (e) {
      debugPrint('Error initializing PrayerTimesService: $e');
    }
  }

  /// تحميل أوقات آخر التحديثات
  Future<void> _loadLastUpdateTimes() async {
    try {
      final lastLocationStr = _storage.getString(_lastLocationUpdateKey);
      if (lastLocationStr != null) {
        _lastLocationUpdate = DateTime.tryParse(lastLocationStr);
      }
      
      final lastDataStr = _storage.getString(_lastDataUpdateKey);
      if (lastDataStr != null) {
        _lastDataUpdate = DateTime.tryParse(lastDataStr);
      }
    } catch (e) {
      debugPrint('Error loading last update times: $e');
    }
  }

  /// بدء المؤقتات
  void _startTimers() {
    if (_isDisposed) return;
    
    _stopTimers();
    
    // مؤقت تحديث حالات الصلوات كل دقيقة
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_isDisposed) {
        _updatePrayerStates();
      }
    });
    
    // مؤقت العد التنازلي كل 30 ثانية
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isDisposed && _currentTimes != null && _nextPrayerController != null) {
        _nextPrayerController!.add(_currentTimes!.nextPrayer);
      }
    });
    
    // مؤقت تحديث البيانات كل ساعة
    _dataRefreshTimer = Timer.periodic(const Duration(hours: 1), (_) {
      if (!_isDisposed) {
        _checkAndUpdateData();
      }
    });
  }

  /// فحص وتحديث البيانات عند الحاجة
  Future<void> _checkAndUpdateData() async {
    if (_isUpdating || _isDisposed) return;
    
    final now = DateTime.now();
    bool needsUpdate = false;
    
    // تحقق من الحاجة لتحديث البيانات
    if (_lastDataUpdate == null || 
        now.difference(_lastDataUpdate!).inHours >= 6) {
      needsUpdate = true;
    }
    
    // تحقق من تغيير اليوم
    if (_currentTimes != null && 
        !PrayerUtils.isSameDay(_currentTimes!.date, now)) {
      needsUpdate = true;
    }
    
    // تحقق من انتهاء جميع الصلوات لليوم
    if (_currentTimes != null && 
        _currentTimes!.prayers.every((p) => p.isPassed)) {
      needsUpdate = true;
    }
    
    if (needsUpdate) {
      await updatePrayerTimes();
    }
  }

  /// الحصول على الموقع الحالي - محدث ليماثل نظام القبلة
  Future<PrayerLocation> getCurrentLocation({bool forceUpdate = false}) async {
    if (_isDisposed) {
      throw StateError('Service is disposed');
    }
    
    // تحقق من الحاجة لتحديث الموقع
    if (!forceUpdate && _currentLocation != null && _lastLocationUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastLocationUpdate!);
      if (timeSinceUpdate.inHours < 12) {
        return _currentLocation!;
      }
    }

    // التحقق من الأذونات
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      throw LocationException('لم يتم منح إذن الوصول إلى الموقع', code: 'PERMISSION_DENIED');
    }
    
    try {
      // التحقق من تفعيل خدمة الموقع
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('خدمة الموقع معطلة', code: 'SERVICE_DISABLED');
      }
      
      // الحصول على الموقع بنفس طريقة القبلة
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ).catchError((e) async {
        // محاولة بدقة متوسطة إذا فشلت الدقة العالية
        debugPrint('High accuracy failed, trying medium: $e');
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      }).catchError((e) async {
        // محاولة أخيرة بدقة منخفضة
        debugPrint('Medium accuracy failed, trying low: $e');
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 8),
        );
      });
      
      // تحسينات دقة الموقع
      if (_currentLocation != null) {
        final distance = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          position.latitude,
          position.longitude,
        );
        
        // إذا كان التغيير صغيراً والدقة مقبولة، نحتفظ بالموقع السابق
        if (distance < 5000 && position.accuracy > 100) {
          debugPrint('Location change is minimal, keeping previous location');
          await _saveLocationUpdateTime();
          return _currentLocation!;
        }
      }
      
      // الحصول على معلومات المنطقة الزمنية والمدينة
      String? cityName;
      String? countryName;
      
      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 8));
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          cityName = placemark.locality ?? 
                    placemark.administrativeArea ?? 
                    placemark.subAdministrativeArea ?? 
                    placemark.subLocality;
          countryName = placemark.country;
        }
      } catch (e) {
        debugPrint('Error getting placemark: $e');
        cityName = 'موقع مخصص';
        countryName = 'الإحداثيات: ${position.latitude.toStringAsFixed(4)}°, ${position.longitude.toStringAsFixed(4)}°';
      }
      
      final timezone = await _getTimezone(position.latitude, position.longitude);
      
      final location = PrayerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: cityName ?? 'غير محدد',
        countryName: countryName ?? 'غير محدد',
        timezone: timezone,
        altitude: position.altitude,
        accuracy: position.accuracy,
      );
      
      // حفظ الموقع
      _currentLocation = location;
      await _saveLocation(location);
      await _saveLocationUpdateTime();
      
      debugPrint('Location updated successfully: ${location.displayName}');
      return location;
      
    } on TimeoutException {
      if (_currentLocation != null) {
        debugPrint('Location timeout, using cached location');
        return _currentLocation!;
      }
      throw LocationException('انتهت مهلة الحصول على الموقع', code: 'TIMEOUT');
      
    } on LocationServiceDisabledException {
      throw LocationException('خدمة الموقع معطلة في الجهاز', code: 'SERVICE_DISABLED');
      
    } on PermissionDeniedException {
      throw LocationException('لا توجد صلاحية للوصول للموقع', code: 'PERMISSION_DENIED');
      
    } catch (e) {
      if (_currentLocation != null) {
        debugPrint('Error getting location, using cached: $e');
        return _currentLocation!;
      }
      
      throw LocationException(
        _getLocationErrorMessage(e),
        code: 'LOCATION_ERROR',
      );
    }
  }

  /// الحصول على رسالة خطأ الموقع
  String _getLocationErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('timeout')) {
      return 'انتهت مهلة الحصول على الموقع';
    } else if (errorStr.contains('service') && errorStr.contains('disabled')) {
      return 'خدمة الموقع معطلة';
    } else if (errorStr.contains('permission') && errorStr.contains('denied')) {
      return 'لم يتم منح إذن الوصول إلى الموقع';
    } else if (errorStr.contains('network')) {
      return 'تحقق من اتصالك بالإنترنت';
    }
    
    return 'حدث خطأ في تحديد الموقع';
  }

  /// حفظ وقت تحديث الموقع
  Future<void> _saveLocationUpdateTime() async {
    try {
      _lastLocationUpdate = DateTime.now();
      await _storage.setString(
        _lastLocationUpdateKey,
        _lastLocationUpdate!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error saving location update time: $e');
    }
  }

  /// تحديث مواقيت الصلاة
  Future<DailyPrayerTimes> updatePrayerTimes({DateTime? date}) async {
    if (_isDisposed) {
      throw StateError('Service is disposed');
    }
    
    if (_isUpdating) {
      while (_isUpdating && !_isDisposed) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_currentTimes != null) {
        return _currentTimes!;
      }
    }
    
    _isUpdating = true;
    
    try {
      final targetDate = date ?? DateTime.now();
      final dateKey = targetDate.toIso8601String().split('T')[0];
      
      if (_currentLocation == null) {
        throw DataNotFoundException('لم يتم تحديد الموقع');
      }

      // تحقق من وجود المواقيت في الذاكرة المؤقتة
      if (_timesCache.containsKey(dateKey)) {
        final cachedTimes = _timesCache[dateKey]!.updatePrayerStates();
        _currentTimes = cachedTimes;
        
        if (_prayerTimesController != null && !_prayerTimesController!.isClosed) {
          _prayerTimesController!.add(cachedTimes);
        }
        if (_nextPrayerController != null && !_nextPrayerController!.isClosed) {
          _nextPrayerController!.add(cachedTimes.nextPrayer);
        }
        
        return cachedTimes;
      }
      
      // حساب المواقيت باستخدام مكتبة adhan
      final prayers = _calculatePrayerTimes(targetDate, _currentLocation!);
      
      // إنشاء نموذج المواقيت اليومية
      final dailyTimes = DailyPrayerTimes(
        date: targetDate,
        prayers: prayers,
        location: _currentLocation!,
        settings: _settings,
      ).updatePrayerStates();
      
      _currentTimes = dailyTimes;
      
      // حفظ في الكاش
      await _cachePrayerTimes(dailyTimes);
      
      // حفظ في الذاكرة المؤقتة
      _timesCache[dateKey] = dailyTimes;
      
      // تنظيف الكاش القديم
      _cleanOldCache();
      
      // حفظ وقت التحديث
      await _saveDataUpdateTime();
      
      // إرسال إلى Stream
      if (_prayerTimesController != null && !_prayerTimesController!.isClosed) {
        _prayerTimesController!.add(dailyTimes);
      }
      if (_nextPrayerController != null && !_nextPrayerController!.isClosed) {
        _nextPrayerController!.add(dailyTimes.nextPrayer);
      }
      
      // جدولة التنبيهات
      await _scheduleNotifications(dailyTimes);
      
      debugPrint('Prayer times updated successfully');
      return dailyTimes;
      
    } catch (e) {
      debugPrint('Error updating prayer times: $e');
      rethrow;
    } finally {
      _isUpdating = false;
    }
  }

  /// حفظ وقت تحديث البيانات
  Future<void> _saveDataUpdateTime() async {
    try {
      _lastDataUpdate = DateTime.now();
      await _storage.setString(
        _lastDataUpdateKey,
        _lastDataUpdate!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error saving data update time: $e');
    }
  }

  /// تحديث حالات الصلوات
  void _updatePrayerStates() {
    if (_isDisposed || _currentTimes == null) return;
    
    try {
      final updated = _currentTimes!.updatePrayerStates();
      
      bool hasChanges = false;
      
      if (_currentTimes!.nextPrayer?.id != updated.nextPrayer?.id) {
        hasChanges = true;
      }
      
      for (int i = 0; i < _currentTimes!.prayers.length; i++) {
        if (_currentTimes!.prayers[i].isPassed != updated.prayers[i].isPassed ||
            _currentTimes!.prayers[i].isNext != updated.prayers[i].isNext) {
          hasChanges = true;
          break;
        }
      }
      
      if (hasChanges) {
        _currentTimes = updated;
        
        if (_prayerTimesController != null && !_prayerTimesController!.isClosed) {
          _prayerTimesController!.add(updated);
        }
        if (_nextPrayerController != null && !_nextPrayerController!.isClosed) {
          _nextPrayerController!.add(updated.nextPrayer);
        }
      }
    } catch (e) {
      debugPrint('Error updating prayer states: $e');
    }
  }

  /// إيقاف المؤقتات
  void _stopTimers() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _dataRefreshTimer?.cancel();
    _dataRefreshTimer = null;
  }

  // تحميل الإعدادات المحفوظة
  Future<void> _loadSavedSettings() async {
    try {
      final settingsJson = _storage.getMap(_settingsKey);
      if (settingsJson != null) {
        _settings = PrayerCalculationSettings.fromJson(settingsJson);
      }
      
      final notifJson = _storage.getMap(_notificationSettingsKey);
      if (notifJson != null) {
        _notificationSettings = PrayerNotificationSettings.fromJson(notifJson);
      }
    } catch (e) {
      _settings = const PrayerCalculationSettings();
      _notificationSettings = const PrayerNotificationSettings();
    }
  }

  /// تحميل الموقع المحفوظ
  Future<void> _loadSavedLocation() async {
    try {
      final locationJson = _storage.getMap(_locationKey);
      if (locationJson != null && locationJson.isNotEmpty) {
        _currentLocation = PrayerLocation.fromJson(locationJson);
      }
    } catch (e) {
      _currentLocation = null;
      try {
        await _storage.remove(_locationKey);
      } catch (cleanupError) {
        // تجاهل أخطاء التنظيف
      }
    }
  }

  /// حفظ بيانات الموقع
  Future<void> _saveLocation(PrayerLocation location) async {
    try {
      await _storage.setMap(_locationKey, location.toJson());
    } catch (e) {
      debugPrint('Error saving location: $e');
    }
  }

  /// التحقق من صلاحية الموقع
  Future<bool> _checkLocationPermission() async {
    try {
      return await _permissionService.checkLocationPermission();
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  // الحصول على المنطقة الزمنية
  Future<String> _getTimezone(double latitude, double longitude) async {
    try {
      // تحديد المنطقة الزمنية بناءً على خطوط الطول
      if (longitude >= 20 && longitude <= 60) {
        return 'Asia/Riyadh';
      } else if (longitude >= 60 && longitude <= 90) {
        return 'Asia/Kolkata';
      } else if (longitude >= 90 && longitude <= 140) {
        return 'Asia/Shanghai';
      } else if (longitude >= 140 || longitude <= -100) {
        return 'Pacific/Honolulu';
      } else if (longitude >= -100 && longitude <= -30) {
        return 'America/New_York';
      } else {
        return 'Europe/London';
      }
    } catch (e) {
      return 'UTC';
    }
  }

  // حساب مواقيت الصلاة
  List<PrayerTime> _calculatePrayerTimes(DateTime date, PrayerLocation location) {
    try {
      final coordinates = adhan.Coordinates(location.latitude, location.longitude);
      final params = _getCalculationParameters();
      final components = adhan.DateComponents.from(date);
      final prayerTimes = adhan.PrayerTimes(coordinates, components, params);
      final adjustments = _settings.manualAdjustments;
      
      return [
        PrayerTime(
          id: 'fajr',
          nameAr: 'الفجر',
          nameEn: 'Fajr',
          time: _applyAdjustment(prayerTimes.fajr, adjustments['fajr'] ?? 0),
          type: PrayerType.fajr,
        ),
        PrayerTime(
          id: 'sunrise',
          nameAr: 'الشروق',
          nameEn: 'Sunrise',
          time: _applyAdjustment(prayerTimes.sunrise, adjustments['sunrise'] ?? 0),
          type: PrayerType.sunrise,
        ),
        PrayerTime(
          id: 'dhuhr',
          nameAr: 'الظهر',
          nameEn: 'Dhuhr',
          time: _applyAdjustment(prayerTimes.dhuhr, adjustments['dhuhr'] ?? 0),
          type: PrayerType.dhuhr,
        ),
        PrayerTime(
          id: 'asr',
          nameAr: 'العصر',
          nameEn: 'Asr',
          time: _applyAdjustment(prayerTimes.asr, adjustments['asr'] ?? 0),
          type: PrayerType.asr,
        ),
        PrayerTime(
          id: 'maghrib',
          nameAr: 'المغرب',
          nameEn: 'Maghrib',
          time: _applyAdjustment(prayerTimes.maghrib, adjustments['maghrib'] ?? 0),
          type: PrayerType.maghrib,
        ),
        PrayerTime(
          id: 'isha',
          nameAr: 'العشاء',
          nameEn: 'Isha',
          time: _applyAdjustment(prayerTimes.isha, adjustments['isha'] ?? 0),
          type: PrayerType.isha,
        ),
      ];
    } catch (e) {
      debugPrint('Error calculating prayer times: $e');
      rethrow;
    }
  }

  // تطبيق تعديل الوقت
  DateTime _applyAdjustment(DateTime time, int minutes) {
    return time.add(Duration(minutes: minutes));
  }

  // الحصول على معاملات الحساب
  adhan.CalculationParameters _getCalculationParameters() {
    adhan.CalculationParameters params;
    
    switch (_settings.method) {
      case CalculationMethod.muslimWorldLeague:
        params = adhan.CalculationMethod.muslim_world_league.getParameters();
        break;
      case CalculationMethod.egyptian:
        params = adhan.CalculationMethod.egyptian.getParameters();
        break;
      case CalculationMethod.karachi:
        params = adhan.CalculationMethod.karachi.getParameters();
        break;
      case CalculationMethod.ummAlQura:
        params = adhan.CalculationMethod.umm_al_qura.getParameters();
        break;
      case CalculationMethod.dubai:
        params = adhan.CalculationMethod.dubai.getParameters();
        break;
      case CalculationMethod.qatar:
        params = adhan.CalculationMethod.qatar.getParameters();
        break;
      case CalculationMethod.kuwait:
        params = adhan.CalculationMethod.kuwait.getParameters();
        break;
      case CalculationMethod.singapore:
        params = adhan.CalculationMethod.singapore.getParameters();
        break;
      case CalculationMethod.northAmerica:
        params = adhan.CalculationMethod.north_america.getParameters();
        break;
      default:
        params = adhan.CalculationMethod.other.getParameters();
        params.fajrAngle = _settings.fajrAngle.toDouble();
        params.ishaAngle = _settings.ishaAngle.toDouble();
    }
    
    params.madhab = _settings.asrJuristic == AsrJuristic.hanafi
        ? adhan.Madhab.hanafi
        : adhan.Madhab.shafi;
    
    return params;
  }

  // حفظ المواقيت في الكاش
  Future<void> _cachePrayerTimes(DailyPrayerTimes times) async {
    try {
      final key = '${_cachedTimesKey}_${times.date.toIso8601String().split('T')[0]}';
      await _storage.setMap(key, times.toJson());
    } catch (e) {
      debugPrint('Error caching prayer times: $e');
    }
  }

  // تنظيف الكاش القديم
  void _cleanOldCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final key in _timesCache.keys) {
      try {
        final cacheDate = DateTime.parse('${key}T00:00:00');
        if (now.difference(cacheDate).inDays > 7) {
          keysToRemove.add(key);
        }
      } catch (e) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _timesCache.remove(key);
    }
  }

  // جدولة التنبيهات
  Future<void> _scheduleNotifications(DailyPrayerTimes times) async {
    if (!_notificationSettings.enabled) return;
    
    try {
      await NotificationManager.instance.cancelAllPrayerNotifications();
      
      for (final prayer in times.prayers) {
        if (prayer.type == PrayerType.sunrise) continue;
        if (_notificationSettings.enabledPrayers[prayer.type] != true) continue;
        if (prayer.isPassed) continue;
        
        final minutesBefore = _notificationSettings.minutesBefore[prayer.type] ?? 0;
        if (minutesBefore > 0) {
          await NotificationManager.instance.schedulePrayerNotification(
            prayerName: prayer.id,
            arabicName: prayer.nameAr,
            time: prayer.time,
            minutesBefore: minutesBefore,
          );
        }
        
        await NotificationManager.instance.schedulePrayerNotification(
          prayerName: prayer.id,
          arabicName: prayer.nameAr,
          time: prayer.time,
          minutesBefore: 0,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }

  /// API Methods
  
  Future<DailyPrayerTimes?> getCachedPrayerTimes(DateTime date) async {
    final key = '${_cachedTimesKey}_${date.toIso8601String().split('T')[0]}';
    final json = _storage.getMap(key);
    
    if (json != null) {
      try {
        return DailyPrayerTimes.fromJson(json);
      } catch (e) {
        debugPrint('Error loading cached prayer times: $e');
      }
    }
    return null;
  }

  Future<void> updateCalculationSettings(PrayerCalculationSettings settings) async {
    if (_isDisposed) return;
    
    try {
      _settings = settings;
      await _storage.setMap(_settingsKey, settings.toJson());
      _timesCache.clear();
      
      if (_currentLocation != null) {
        await updatePrayerTimes();
      }
    } catch (e) {
      debugPrint('Error updating calculation settings: $e');
    }
  }

  Future<void> updateNotificationSettings(PrayerNotificationSettings settings) async {
    if (_isDisposed) return;
    
    try {
      _notificationSettings = settings;
      await _storage.setMap(_notificationSettingsKey, settings.toJson());
      
      if (_currentTimes != null) {
        await _scheduleNotifications(_currentTimes!);
      }
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
    }
  }

  Future<void> setCustomLocation(PrayerLocation location) async {
    if (_isDisposed) return;
    
    try {
      _currentLocation = location;
      await _saveLocation(location);
      await _saveLocationUpdateTime();
      _timesCache.clear();
      await updatePrayerTimes();
    } catch (e) {
      debugPrint('Error setting custom location: $e');
    }
  }

  // Getters
  Stream<DailyPrayerTimes> get prayerTimesStream => 
      _prayerTimesController?.stream ?? const Stream.empty();
  
  Stream<PrayerTime?> get nextPrayerStream => 
      _nextPrayerController?.stream ?? const Stream.empty();
  
  PrayerLocation? get currentLocation => _currentLocation;
  PrayerCalculationSettings get calculationSettings => _settings;
  PrayerNotificationSettings get notificationSettings => _notificationSettings;
  
  /// تنظيف الموارد
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _stopTimers();
    
    await _prayerTimesController?.close();
    _prayerTimesController = null;
    
    await _nextPrayerController?.close();
    _nextPrayerController = null;
    
    _timesCache.clear();
    _currentTimes = null;
  }
}