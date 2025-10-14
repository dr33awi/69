// lib/features/qibla/services/qibla_service.dart - نسخة محسّنة مع معايرة أفضل
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../models/qibla_model.dart';

/// خدمة القبلة مع معايرة محسّنة
class QiblaService extends ChangeNotifier {
  final StorageService _storage;
  final PermissionService _permissionService;

  // مفاتيح التخزين
  static const String _qiblaDataKey = 'qibla_data';
  static const String _calibrationDataKey = 'compass_calibration';

  // حالة الخدمة
  QiblaModel? _qiblaData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  // البوصلة
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _currentDirection = 0.0;
  double _smoothDirection = 0.0;
  bool _hasCompass = false;
  double _compassAccuracy = 0.0;

  // معايرة محسّنة
  bool _isCalibrated = false;
  bool _isCalibrating = false;
  final List<double> _calibrationReadings = [];
  int _calibrationProgress = 0; // 0-100
  String _calibrationMessage = '';
  Timer? _calibrationTimer;
  
  // تتبع الحركة للتحقق من شكل رقم 8
  final List<_DirectionSample> _directionSamples = [];
  bool _hasMovedEnough = false;
  Set<int> _coveredQuadrants = {}; // الأرباع المغطاة (0-3)

  // تصفية القراءات
  static const int _filterSize = 10;
  final List<double> _directionHistory = [];

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
  double get currentDirection => _smoothDirection;
  bool get hasCompass => _hasCompass;
  double get compassAccuracy => _compassAccuracy;
  bool get isCalibrated => _isCalibrated;
  bool get isCalibrating => _isCalibrating;
  bool get isDisposed => _disposed;
  int get calibrationProgress => _calibrationProgress;
  String get calibrationMessage => _calibrationMessage;

  double get accuracyPercentage => _hasCompass ? math.min(_compassAccuracy * 100, 100) : 0;
  bool get hasRecentData => _qiblaData != null && !_qiblaData!.isStale;
  bool get needsCalibration => _hasCompass && (!_isCalibrated || _compassAccuracy < 0.5);

  Map<String, dynamic> getDiagnostics() => {
    'hasCompass': _hasCompass,
    'isCalibrated': _isCalibrated,
    'compassAccuracy': _compassAccuracy,
    'currentDirection': _currentDirection,
    'smoothDirection': _smoothDirection,
    'calibrationProgress': _calibrationProgress,
    'coveredQuadrants': _coveredQuadrants.length,
  };

  // ==================== التهيئة ====================

  Future<void> _init() async {
    if (_disposed) return;

    try {
      debugPrint('[QiblaService] بدء تهيئة خدمة القبلة');
      
      await _loadCalibrationData();
      await _checkCompassAvailability();

      if (_hasCompass) {
        await _startCompassListener();
      }

      await _loadStoredQiblaData();
      
      debugPrint('[QiblaService] تمت التهيئة بنجاح');
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء التهيئة';
      debugPrint('[QiblaService] خطأ في التهيئة: $e');
    }
  }

  Future<void> _checkCompassAvailability() async {
    try {
      final compassEvents = await FlutterCompass.events
          ?.timeout(const Duration(seconds: 3))
          .take(3)
          .toList();

      if (compassEvents != null && compassEvents.isNotEmpty) {
        _hasCompass = compassEvents.any((event) => event.heading != null);
        if (_hasCompass && compassEvents.last.accuracy != null) {
          _compassAccuracy = _calculateAccuracy(compassEvents.last.accuracy!);
        }
      }
    } catch (e) {
      _hasCompass = false;
      debugPrint('[QiblaService] خطأ في التحقق من البوصلة');
    }
  }

  Future<void> _startCompassListener() async {
    if (!_hasCompass || _disposed) return;

    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        if (!_disposed && event.heading != null) {
          _processCompassReading(event);
        }
      },
      onError: (error) {
        debugPrint('[QiblaService] خطأ في قراءة البوصلة');
      },
    );
  }

  void _processCompassReading(CompassEvent event) {
    if (_disposed) return;

    _currentDirection = event.heading!;
    
    if (event.accuracy != null) {
      _compassAccuracy = _calculateAccuracy(event.accuracy!);
    }

    _directionHistory.add(_currentDirection);
    if (_directionHistory.length > _filterSize) {
      _directionHistory.removeAt(0);
    }

    _smoothDirection = _applySmoothing(_directionHistory);

    if (_isCalibrating) {
      _processCalibrationReading(_currentDirection);
    }

    notifyListeners();
  }

  // ==================== المعايرة المحسّنة ====================

  Future<void> startCalibration() async {
    if (_disposed || !_hasCompass || _isCalibrating) return;

    _isCalibrating = true;
    _isCalibrated = false;
    _calibrationReadings.clear();
    _directionSamples.clear();
    _coveredQuadrants.clear();
    _calibrationProgress = 0;
    _hasMovedEnough = false;
    _calibrationMessage = 'ابدأ بتحريك الجهاز ببطء';
    
    debugPrint('[QiblaService] بدء عملية معايرة البوصلة المحسّنة');
    notifyListeners();

    // مؤقت أطول للمعايرة (30 ثانية)
    _calibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_disposed && _isCalibrating) {
        _updateCalibrationProgress(timer.tick);
        
        // إنهاء المعايرة بعد 30 ثانية أو عند الاكتمال
        if (timer.tick >= 30 || _calibrationProgress >= 100) {
          _completeCalibration();
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _processCalibrationReading(double direction) {
    if (!_isCalibrating) return;

    // إضافة القراءة
    _calibrationReadings.add(direction);
    
    // إضافة عينة الاتجاه مع وقتها
    _directionSamples.add(_DirectionSample(
      direction: direction,
      timestamp: DateTime.now(),
    ));

    // الاحتفاظ بآخر 100 عينة فقط
    if (_directionSamples.length > 100) {
      _directionSamples.removeAt(0);
    }

    // تحديث الأرباع المغطاة
    final quadrant = (direction ~/ 90) % 4;
    _coveredQuadrants.add(quadrant);

    // التحقق من الحركة الكافية
    _checkMovementQuality();
  }

  void _checkMovementQuality() {
    if (_directionSamples.length < 20) return;

    // حساب نطاق الحركة
    final directions = _directionSamples.map((s) => s.direction).toList();
    final minDir = directions.reduce(math.min);
    final maxDir = directions.reduce(math.max);
    final range = _calculateCircularRange(minDir, maxDir);

    // التحقق من تغطية كافية للاتجاهات
    _hasMovedEnough = range > 180 && _coveredQuadrants.length >= 3;

    // التحقق من وجود حركة دائرية (شكل 8)
    if (_directionSamples.length >= 40) {
      final hasCircularMotion = _detectCircularMotion();
      if (hasCircularMotion) {
        _hasMovedEnough = true;
      }
    }
  }

  bool _detectCircularMotion() {
    if (_directionSamples.length < 40) return false;

    // تحليل آخر 40 عينة
    final recentSamples = _directionSamples.sublist(_directionSamples.length - 40);
    
    // حساب التغييرات في الاتجاه
    int directionChanges = 0;
    double lastDirection = recentSamples.first.direction;
    
    for (var sample in recentSamples.skip(1)) {
      final diff = _calculateAngleDifference(lastDirection, sample.direction);
      if (diff.abs() > 5) { // تغيير ملحوظ في الاتجاه
        directionChanges++;
      }
      lastDirection = sample.direction;
    }

    // إذا كان هناك تغييرات كثيرة، فالمستخدم يحرك الجهاز بشكل دائري
    return directionChanges >= 20;
  }

  void _updateCalibrationProgress(int seconds) {
    // حساب التقدم بناءً على عدة عوامل
    int progress = 0;

    // 1. عامل الوقت (40%)
    progress += ((seconds / 30.0) * 40).toInt();

    // 2. عامل عدد القراءات (30%)
    final readingsProgress = math.min(_calibrationReadings.length / 100.0, 1.0);
    progress += (readingsProgress * 30).toInt();

    // 3. عامل تغطية الاتجاهات (20%)
    final coverageProgress = _coveredQuadrants.length / 4.0;
    progress += (coverageProgress * 20).toInt();

    // 4. عامل جودة الحركة (10%)
    if (_hasMovedEnough) {
      progress += 10;
    }

    _calibrationProgress = math.min(progress, 100);

    // تحديث الرسالة بناءً على التقدم
    if (_calibrationProgress < 25) {
      _calibrationMessage = 'ابدأ بتحريك الجهاز ببطء على شكل رقم 8';
    } else if (_calibrationProgress < 50) {
      _calibrationMessage = 'استمر... حرك الجهاز في جميع الاتجاهات';
    } else if (_calibrationProgress < 75) {
      _calibrationMessage = 'جيد! تأكد من تغطية جميع الاتجاهات';
    } else if (_calibrationProgress < 100) {
      _calibrationMessage = 'ممتاز! أكمل الحركة...';
    } else {
      _calibrationMessage = 'اكتملت المعايرة!';
    }

    // تحذيرات إذا لم يتحرك المستخدم
    if (seconds > 5 && !_hasMovedEnough) {
      _calibrationMessage = '⚠️ حرك الجهاز بشكل أكبر';
    }
    if (seconds > 10 && _coveredQuadrants.length < 2) {
      _calibrationMessage = '⚠️ غط جميع الاتجاهات (الشمال، الجنوب، الشرق، الغرب)';
    }

    notifyListeners();
  }

  void _completeCalibration() {
    if (_disposed) return;

    _isCalibrating = false;
    _calibrationTimer?.cancel();

    // معايير نجاح أكثر مرونة لتجنب الانتظار الطويل
    final hasEnoughReadings = _calibrationReadings.length >= 40; // تقليل من 60
    final hasCoveredEnoughQuadrants = _coveredQuadrants.length >= 2; // تقليل من 3
    final hasGoodMovement = _hasMovedEnough || _calibrationReadings.length >= 50;

    if (hasEnoughReadings && hasCoveredEnoughQuadrants && hasGoodMovement) {
      // حساب جودة المعايرة
      final stdDev = _calculateStandardDeviation(_calibrationReadings);
      final variance = _calculateCircularVariance(_calibrationReadings);
      
      // معايرة ناجحة بمعايير أكثر مرونة
      _isCalibrated = stdDev < 25 && variance > 0.2;
      
      if (_isCalibrated) {
        _compassAccuracy = math.max(_compassAccuracy, 0.85);
        _calibrationMessage = '✅ تمت المعايرة بنجاح!';
        debugPrint('[QiblaService] معايرة ناجحة - StdDev: $stdDev, Variance: $variance');
      } else {
        _calibrationMessage = '⚠️ المعايرة مقبولة';
        _isCalibrated = true; // قبول المعايرة حتى لو لم تكن مثالية
        _compassAccuracy = math.max(_compassAccuracy, 0.7);
        debugPrint('[QiblaService] معايرة مقبولة - StdDev: $stdDev, Variance: $variance');
      }
    } else {
      _calibrationMessage = '⚠️ معايرة جزئية - يمكنك المحاولة مرة أخرى';
      _isCalibrated = true; // قبول المعايرة الجزئية
      _compassAccuracy = math.max(_compassAccuracy, 0.6);
      debugPrint('[QiblaService] معايرة جزئية - القراءات: ${_calibrationReadings.length}, الأرباع: ${_coveredQuadrants.length}');
    }

    _calibrationProgress = 100;
    _saveCalibrationData();
    notifyListeners();
  }

  void resetCalibration() {
    if (_disposed) return;
    
    _isCalibrating = false;
    _isCalibrated = false;
    _calibrationReadings.clear();
    _directionSamples.clear();
    _coveredQuadrants.clear();
    _calibrationProgress = 0;
    _compassAccuracy = 0.0;
    _calibrationTimer?.cancel();
    
    _saveCalibrationData();
    notifyListeners();
  }

  // ==================== حسابات محسّنة ====================

  double _calculateCircularRange(double minDir, double maxDir) {
    // حساب النطاق مع مراعاة الدائرية
    double range = maxDir - minDir;
    if (range > 180) {
      range = 360 - range;
    }
    return range;
  }

  double _calculateCircularVariance(List<double> angles) {
    if (angles.isEmpty) return 0;
    
    // تحويل الزوايا إلى إحداثيات ديكارتية
    double sumX = 0, sumY = 0;
    for (var angle in angles) {
      final radians = angle * math.pi / 180;
      sumX += math.cos(radians);
      sumY += math.sin(radians);
    }
    
    final avgX = sumX / angles.length;
    final avgY = sumY / angles.length;
    
    // طول المتجه الناتج (مقياس التركيز)
    final r = math.sqrt(avgX * avgX + avgY * avgY);
    
    // التباين الدائري = 1 - r
    // قيم أعلى تعني توزيع أفضل للقراءات
    return 1 - r;
  }

  double _calculateAngleDifference(double from, double to) {
    double diff = to - from;
    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;
    return diff;
  }

  // ==================== باقي الكود كما هو ====================

  Future<void> updateQiblaData({bool forceUpdate = false}) async {
    if (_disposed || _isLoading) return;

    if (!forceUpdate && hasRecentData && _qiblaData!.hasHighAccuracy) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[QiblaService] بدء تحديث بيانات القبلة');

      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        throw Exception('لم يتم منح إذن الوصول إلى الموقع');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 25),
      );

      String? cityName;
      String? countryName;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        ).timeout(const Duration(seconds: 10));

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          cityName = placemark.locality ?? placemark.administrativeArea;
          countryName = placemark.country;
        }
      } catch (e) {
        debugPrint('[QiblaService] لم يتم الحصول على معلومات الموقع');
      }

      _qiblaData = QiblaModel.fromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        cityName: cityName,
        countryName: countryName,
      );

      await _saveQiblaData(_qiblaData!);
      
      debugPrint('[QiblaService] تم تحديث بيانات القبلة بنجاح');
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('[QiblaService] خطأ في تحديث البيانات: $e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> forceUpdate() => updateQiblaData(forceUpdate: true);

  // ==================== التخزين ====================

  Future<void> _loadStoredQiblaData() async {
    try {
      final qiblaJson = _storage.getMap(_qiblaDataKey);
      if (qiblaJson != null && qiblaJson.isNotEmpty) {
        _qiblaData = QiblaModel.fromJson(qiblaJson);
        debugPrint('[QiblaService] تم تحميل بيانات القبلة المخزنة');
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

  Future<void> _loadCalibrationData() async {
    try {
      final data = _storage.getMap(_calibrationDataKey);
      if (data != null) {
        _isCalibrated = data['isCalibrated'] as bool? ?? false;
        _compassAccuracy = (data['accuracy'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (e) {
      debugPrint('[QiblaService] خطأ في تحميل بيانات المعايرة');
    }
  }

  Future<void> _saveCalibrationData() async {
    try {
      await _storage.setMap(_calibrationDataKey, {
        'isCalibrated': _isCalibrated,
        'lastCalibration': DateTime.now().toIso8601String(),
        'accuracy': _compassAccuracy,
      });
    } catch (e) {
      debugPrint('[QiblaService] خطأ في حفظ بيانات المعايرة');
    }
  }

  // ==================== الوظائف المساعدة ====================

  double _applySmoothing(List<double> readings) {
    if (readings.isEmpty) return 0;

    final sines = readings.map((angle) => math.sin(angle * math.pi / 180)).toList();
    final cosines = readings.map((angle) => math.cos(angle * math.pi / 180)).toList();

    final avgSin = sines.reduce((a, b) => a + b) / readings.length;
    final avgCos = cosines.reduce((a, b) => a + b) / readings.length;

    double angle = math.atan2(avgSin, avgCos) * 180 / math.pi;
    return (angle + 360) % 360;
  }

  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => math.pow(v - mean, 2));
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;
    
    return math.sqrt(variance);
  }

  double _calculateAccuracy(double rawAccuracy) {
    if (rawAccuracy < 0) return 1.0;
    if (rawAccuracy > 180) return 0.0;
    return 1.0 - (rawAccuracy / 180.0);
  }

  Future<bool> _checkLocationPermission() async {
    try {
      final status = await _permissionService.checkPermissionStatus(
        AppPermissionType.location,
      );

      if (status != AppPermissionStatus.granted) {
        final result = await _permissionService.requestPermission(
          AppPermissionType.location,
        );
        return result == AppPermissionStatus.granted;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'انتهت مهلة الحصول على الموقع';
    } else if (error is LocationServiceDisabledException) {
      return 'خدمة الموقع معطلة';
    } else if (error is PermissionDeniedException) {
      return 'لم يتم منح إذن الوصول';
    }
    return 'حدث خطأ غير متوقع';
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    debugPrint('[QiblaService] بدء تنظيف موارد الخدمة');
    
    _compassSubscription?.cancel();
    _calibrationTimer?.cancel();
    _directionHistory.clear();
    _calibrationReadings.clear();
    _directionSamples.clear();
    _coveredQuadrants.clear();

    super.dispose();
  }
}

// ==================== نموذج عينة الاتجاه ====================

class _DirectionSample {
  final double direction;
  final DateTime timestamp;

  _DirectionSample({
    required this.direction,
    required this.timestamp,
  });
}