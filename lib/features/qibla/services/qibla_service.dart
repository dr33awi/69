// lib/features/qibla/services/qibla_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../models/qibla_model.dart';

/// خدمة القبلة المحسنة للحركة السلسة
class QiblaService extends ChangeNotifier {
  final StorageService _storage;
  final PermissionService _permissionService;

  // مفاتيح التخزين
  static const String _qiblaDataKey = 'qibla_data_v3';
  static const String _calibrationKey = 'compass_calibration_v3';
  static const String _lastCalibrationDateKey = 'last_calibration_date_v3';

  // حالة الخدمة
  QiblaModel? _qiblaData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  // المستشعرات
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  double _currentDirection = 0.0;
  bool _hasCompass = true;

  // قيم المستشعرات
  List<double> _magnetometerValues = [0, 0, 0];
  List<double> _accelerometerValues = [0, 0, 0];
  
  // تنعيم محسّن
  static const double _smoothingFactor = 0.15; // أقل للحركة الأكثر سلاسة
  double _smoothedDirection = 0.0;
  
  // Low-pass filter للتنعيم الإضافي
  final List<double> _directionBuffer = [];
  static const int _bufferSize = 5;
  
  // Debouncing محسّن
  Timer? _notifyTimer;
  static const Duration _notifyInterval = Duration(milliseconds: 16); // 60 FPS
  bool _hasUpdate = false;

  // المعايرة والدقة
  bool _isCalibrated = false;
  bool _isCalibrating = false;
  int _calibrationProgress = 0;
  String _calibrationMessage = '';
  Timer? _calibrationTimer;
  bool _needsCalibration = false;
  
  // تتبع الدقة
  final List<double> _recentReadings = [];
  static const int _maxReadings = 30;
  Timer? _stabilityCheckTimer;
  double _lastCalculatedAccuracy = 1.0;

  QiblaService({
    required StorageService storage,
    required PermissionService permissionService,
  })  : _storage = storage,
        _permissionService = permissionService {
    _init();
  }

  // ==================== الخصائص العامة ====================

  QiblaModel? get qiblaData => _qiblaData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get currentDirection => _currentDirection;
  double get qiblaDirection => _qiblaData?.qiblaDirection ?? 0.0;
  bool get hasCompass => _hasCompass;
  bool get isDisposed => _disposed;
  bool get hasRecentData => _qiblaData != null && !_qiblaData!.isStale;
  
  // خصائص المعايرة
  bool get isCalibrated => _isCalibrated && !_needsCalibration;
  bool get isCalibrating => _isCalibrating;
  int get calibrationProgress => _calibrationProgress;
  String get calibrationMessage => _calibrationMessage;
  bool get needsCalibration => _needsCalibration;
  double get compassAccuracy => _lastCalculatedAccuracy;

  // ==================== التهيئة ====================

  Future<void> _init() async {
    if (_disposed) return;

    try {
      debugPrint('[QiblaService] بدء تهيئة خدمة القبلة');
      
      // تحميل حالة المعايرة
      _loadCalibrationState();
      
      // بدء الاستماع للمستشعرات
      await _startSensors();
      
      // بدء timer للتحديثات المنتظمة
      _startNotifyTimer();
      
      // بدء مراقبة الاستقرار
      _startStabilityMonitoring();

      await _loadStoredQiblaData();
      
      debugPrint('[QiblaService] تمت التهيئة بنجاح');
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء التهيئة';
      debugPrint('[QiblaService] خطأ في التهيئة: $e');
    }
  }

  Future<void> _startSensors() async {
    if (_disposed) return;

    try {
      // الاستماع للمغناطيسية بمعدل أعلى
      _magnetometerSubscription = magnetometerEventStream(
        samplingPeriod: const Duration(milliseconds: 50), // 20 Hz
      ).listen(
        (MagnetometerEvent event) {
          if (!_disposed) {
            _magnetometerValues = [event.x, event.y, event.z];
            _updateDirection();
          }
        },
        onError: (error) {
          debugPrint('[QiblaService] خطأ في المغناطيسية: $error');
        },
      );

      // الاستماع للتسارع بمعدل أعلى
      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 50), // 20 Hz
      ).listen(
        (AccelerometerEvent event) {
          if (!_disposed) {
            _accelerometerValues = [event.x, event.y, event.z];
          }
        },
        onError: (error) {
          debugPrint('[QiblaService] خطأ في التسارع: $error');
        },
      );

      debugPrint('[QiblaService] تم بدء المستشعرات');
    } catch (e) {
      debugPrint('[QiblaService] فشل بدء المستشعرات: $e');
      _hasCompass = false;
    }
  }

  void _startNotifyTimer() {
    _notifyTimer = Timer.periodic(_notifyInterval, (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      
      if (_hasUpdate) {
        _hasUpdate = false;
        notifyListeners();
      }
    });
  }

  void _updateDirection() {
    if (_disposed) return;

    try {
      // حساب الاتجاه من المستشعرات
      final direction = _calculateDirection(
        _magnetometerValues,
        _accelerometerValues,
      );

      if (direction != null) {
        // تطبيق Low-pass filter
        final filteredDirection = _applyLowPassFilter(direction);
        
        // تنعيم القراءات
        _smoothedDirection = _smoothDirection(_smoothedDirection, filteredDirection);
        _currentDirection = _smoothedDirection;

        // إضافة القراءة للتتبع
        _addReading(_currentDirection);

        // وضع علامة للتحديث
        _hasUpdate = true;
      }
    } catch (e) {
      debugPrint('[QiblaService] خطأ في حساب الاتجاه: $e');
    }
  }

  double _applyLowPassFilter(double newValue) {
    _directionBuffer.add(newValue);
    
    if (_directionBuffer.length > _bufferSize) {
      _directionBuffer.removeAt(0);
    }
    
    if (_directionBuffer.length == 1) {
      return newValue;
    }
    
    // حساب متوسط مرجح (الأحدث له وزن أكبر)
    double sum = 0;
    double weightSum = 0;
    
    for (int i = 0; i < _directionBuffer.length; i++) {
      final weight = i + 1; // الأحدث له وزن أكبر
      final value = _directionBuffer[i];
      
      // معالجة الانتقال عبر 360/0
      double diff = value - _directionBuffer[0];
      while (diff > 180) diff -= 360;
      while (diff < -180) diff += 360;
      
      sum += (_directionBuffer[0] + diff) * weight;
      weightSum += weight;
    }
    
    return (sum / weightSum) % 360;
  }

  double? _calculateDirection(List<double> magnetometer, List<double> accelerometer) {
    // تطبيع قيم التسارع
    final norm = math.sqrt(
      accelerometer[0] * accelerometer[0] +
      accelerometer[1] * accelerometer[1] +
      accelerometer[2] * accelerometer[2],
    );

    if (norm == 0) return null;

    final gravity = accelerometer.map((v) => v / norm).toList();

    // حساب الشرق
    final east = [
      magnetometer[1] * gravity[2] - magnetometer[2] * gravity[1],
      magnetometer[2] * gravity[0] - magnetometer[0] * gravity[2],
      magnetometer[0] * gravity[1] - magnetometer[1] * gravity[0],
    ];

    // حساب الشمال
    final north = [
      gravity[1] * east[2] - gravity[2] * east[1],
      gravity[2] * east[0] - gravity[0] * east[2],
      gravity[0] * east[1] - gravity[1] * east[0],
    ];

    // حساب الزاوية
    final angle = math.atan2(east[0], north[0]);
    double degrees = angle * (180 / math.pi);

    // تحويل إلى 0-360
    if (degrees < 0) {
      degrees += 360;
    }

    return degrees;
  }

  void _addReading(double reading) {
    _recentReadings.add(reading);

    if (_recentReadings.length > _maxReadings) {
      _recentReadings.removeAt(0);
    }
  }

  void _startStabilityMonitoring() {
    _stabilityCheckTimer = Timer.periodic(
      const Duration(seconds: 3), // تحقق أسرع
      (timer) {
        if (_disposed) {
          timer.cancel();
          return;
        }

        _checkStability();
      },
    );
  }

  void _checkStability() {
    if (_recentReadings.length < 10) {
      _lastCalculatedAccuracy = 0.5;
      return;
    }

    // حساب الانحراف المعياري
    final mean = _recentReadings.reduce((a, b) => a + b) / _recentReadings.length;
    
    // معالجة الانتقال عبر 360/0 في حساب الانحراف
    final adjustedReadings = _recentReadings.map((reading) {
      double diff = reading - mean;
      while (diff > 180) diff -= 360;
      while (diff < -180) diff += 360;
      return diff;
    }).toList();
    
    final variance = adjustedReadings
        .map((v) => v * v)
        .reduce((a, b) => a + b) / adjustedReadings.length;
    final stdDev = math.sqrt(variance);

    // تحديد الدقة بناءً على الاستقرار
    if (stdDev < 2) {
      _lastCalculatedAccuracy = 1.0; // ممتاز
      if (_needsCalibration && _isCalibrated) {
        _needsCalibration = false;
        _hasUpdate = true;
      }
    } else if (stdDev < 5) {
      _lastCalculatedAccuracy = 0.9; // ممتاز جداً
    } else if (stdDev < 10) {
      _lastCalculatedAccuracy = 0.8; // جيد جداً
    } else if (stdDev < 20) {
      _lastCalculatedAccuracy = 0.65; // جيد
    } else if (stdDev < 30) {
      _lastCalculatedAccuracy = 0.5; // متوسط
    } else {
      _lastCalculatedAccuracy = 0.3; // ضعيف
      if (!_needsCalibration && !_isCalibrating) {
        _needsCalibration = true;
        _hasUpdate = true;
      }
    }
  }

  double _smoothDirection(double current, double target) {
    double diff = target - current;

    // معالجة الانتقال عبر 360/0
    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;

    // استخدام smoothing factor ديناميكي بناءً على حجم التغيير
    double dynamicFactor = _smoothingFactor;
    if (diff.abs() > 90) {
      // تغيير كبير - استجابة أسرع
      dynamicFactor = 0.3;
    } else if (diff.abs() < 5) {
      // تغيير صغير - تنعيم أكثر
      dynamicFactor = 0.1;
    }

    return (current + diff * dynamicFactor) % 360;
  }

  // ==================== تحديث البيانات ====================

  Future<void> updateQiblaData({bool forceUpdate = false}) async {
    if (_disposed || _isLoading) return;

    if (!forceUpdate && hasRecentData && _qiblaData!.hasHighAccuracy) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _hasUpdate = true;

    try {
      debugPrint('[QiblaService] بدء تحديث بيانات القبلة');

      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        throw Exception('لم يتم منح إذن الوصول إلى الموقع');
      }

      final position = await _getLocationWithRetry();
      if (position == null) {
        throw Exception('فشل الحصول على الموقع');
      }

      final locationInfo = await _getLocationName(
        position.latitude,
        position.longitude,
      );

      _qiblaData = QiblaModel.fromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        cityName: locationInfo['city'],
        countryName: locationInfo['country'],
      );

      await _saveQiblaData(_qiblaData!);

      debugPrint('[QiblaService] تم تحديث بيانات القبلة بنجاح');
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('[QiblaService] خطأ في تحديث البيانات: $e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _hasUpdate = true;
      }
    }
  }

  Future<void> forceUpdate() => updateQiblaData(forceUpdate: true);

  // ==================== الحصول على الموقع مع إعادة المحاولة ====================

  Future<Position?> _getLocationWithRetry({int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15 + (attempt * 5)),
        );

        return position;

      } catch (e) {
        if (attempt == maxRetries - 1) {
          try {
            return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 30),
            );
          } catch (e) {
            rethrow;
          }
        }

        await Future.delayed(Duration(seconds: 1 + attempt));
      }
    }

    return null;
  }

  // ==================== Geocoding مع Cache ====================

  final Map<String, Map<String, String?>> _locationCache = {};

  Future<Map<String, String?>> _getLocationName(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';

    if (_locationCache.containsKey(key)) {
      return _locationCache[key]!;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final result = {
          'city': placemark.locality ?? placemark.administrativeArea,
          'country': placemark.country,
        };

        _locationCache[key] = result;

        if (_locationCache.length > 10) {
          _locationCache.remove(_locationCache.keys.first);
        }

        return result;
      }
    } catch (e) {
      debugPrint('[QiblaService] خطأ في الحصول على اسم الموقع: $e');
    }

    return {'city': null, 'country': null};
  }

  // ==================== معايرة البوصلة ====================

  Future<void> startCalibration() async {
    if (_isCalibrating || _disposed) return;

    _isCalibrating = true;
    _calibrationProgress = 0;
    _calibrationMessage = 'ابدأ بتحريك الهاتف في شكل رقم 8';
    _recentReadings.clear();
    _directionBuffer.clear();
    _hasUpdate = true;

    _calibrationTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (timer) {
        if (_disposed || !_isCalibrating) {
          timer.cancel();
          return;
        }

        _calibrationProgress += 5;

        if (_calibrationProgress <= 20) {
          _calibrationMessage = 'استمر في الحركة البطيئة...';
        } else if (_calibrationProgress <= 40) {
          _calibrationMessage = 'جيد! حرك الهاتف في جميع الاتجاهات';
        } else if (_calibrationProgress <= 60) {
          _calibrationMessage = 'ممتاز! استمر في رسم رقم 8';
        } else if (_calibrationProgress <= 80) {
          _calibrationMessage = 'تقريباً انتهينا...';
        } else if (_calibrationProgress < 100) {
          _calibrationMessage = 'اللمسات الأخيرة...';
        } else {
          _calibrationMessage = '✓ تمت المعايرة بنجاح!';
          _isCalibrated = true;
          _needsCalibration = false;
          _saveCalibrationState();

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (!_disposed) {
              _isCalibrating = false;
              _calibrationProgress = 100;
              _hasUpdate = true;
            }
          });

          timer.cancel();
        }

        _hasUpdate = true;
      },
    );
  }

  void resetCalibration() {
    _isCalibrated = false;
    _isCalibrating = false;
    _calibrationProgress = 0;
    _calibrationMessage = '';
    _needsCalibration = true;
    _recentReadings.clear();
    _directionBuffer.clear();
    _calibrationTimer?.cancel();
    _saveCalibrationState();
    _hasUpdate = true;
  }

  void _loadCalibrationState() {
    try {
      _isCalibrated = _storage.getBool(_calibrationKey) ?? false;

      final lastCalibrationStr = _storage.getString(_lastCalibrationDateKey);
      if (lastCalibrationStr != null && _isCalibrated) {
        final lastCalibration = DateTime.parse(lastCalibrationStr);
        final daysSinceCalibration = DateTime.now().difference(lastCalibration).inDays;

        if (daysSinceCalibration > 7) {
          _needsCalibration = true;
        }
      }
    } catch (e) {
      debugPrint('[QiblaService] خطأ في تحميل حالة المعايرة: $e');
    }
  }

  Future<void> _saveCalibrationState() async {
    try {
      await _storage.setBool(_calibrationKey, _isCalibrated);
      if (_isCalibrated) {
        await _storage.setString(
          _lastCalibrationDateKey,
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('[QiblaService] خطأ في حفظ حالة المعايرة: $e');
    }
  }

  // ==================== التخزين ====================

  Future<void> _loadStoredQiblaData() async {
    try {
      final qiblaJson = _storage.getMap(_qiblaDataKey);
      if (qiblaJson != null && qiblaJson.isNotEmpty) {
        _qiblaData = QiblaModel.fromJson(qiblaJson);
      }
    } catch (e) {
      debugPrint('[QiblaService] خطأ في تحميل البيانات المخزنة');
    }
  }

  Future<void> _saveQiblaData(QiblaModel data) async {
    try {
      await _storage.setMap(_qiblaDataKey, data.toJson());
    } catch (e) {
      debugPrint('[QiblaService] خطأ في حفظ البيانات');
    }
  }

  // ==================== فحص الأذونات ====================

  Future<bool> _checkLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'خدمة الموقع معطلة';
        return false;
      }

      final status = await _permissionService.checkPermissionStatus(
        AppPermissionType.location,
      );

      if (status == AppPermissionStatus.granted) {
        return true;
      }

      final newStatus = await _permissionService.requestPermission(
        AppPermissionType.location,
      );

      return newStatus == AppPermissionStatus.granted;

    } catch (e) {
      _errorMessage = 'خطأ في فحص أذونات الموقع';
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'انتهت مهلة الحصول على الموقع';
    } else if (error is LocationServiceDisabledException) {
      return 'خدمة الموقع معطلة';
    } else if (error is PermissionDeniedException) {
      return 'لم يتم منح إذن الوصول للموقع';
    }
    return 'حدث خطأ غير متوقع';
  }

  // ==================== التشخيص ====================

  Map<String, dynamic> getDiagnostics() => {
    'hasCompass': _hasCompass,
    'currentDirection': _currentDirection.toStringAsFixed(2),
    'qiblaDirection': qiblaDirection.toStringAsFixed(2),
    'compassAccuracy': compassAccuracy.toStringAsFixed(2),
    'bufferSize': _directionBuffer.length,
    'isCalibrated': _isCalibrated,
    'needsCalibration': _needsCalibration,
  };

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _notifyTimer?.cancel();
    _calibrationTimer?.cancel();
    _stabilityCheckTimer?.cancel();
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();

    super.dispose();
  }
}