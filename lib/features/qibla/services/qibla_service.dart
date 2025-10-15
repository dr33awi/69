// lib/features/qibla/services/qibla_service.dart - معايرة أسرع ومحسّنة
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../models/qibla_model.dart';

/// خدمة القبلة مع معايرة محسّنة وأسرع
class QiblaService extends ChangeNotifier {
  final StorageService _storage;
  final PermissionService _permissionService;

  static const String _qiblaDataKey = 'qibla_data';
  static const String _calibrationDataKey = 'compass_calibration';

  QiblaModel? _qiblaData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  StreamSubscription<CompassEvent>? _compassSubscription;
  double _currentDirection = 0.0;
  double _smoothDirection = 0.0;
  bool _hasCompass = false;
  double _compassAccuracy = 0.0;

  // معايرة محسّنة وأسرع
  bool _isCalibrated = false;
  bool _isCalibrating = false;
  final List<double> _calibrationReadings = [];
  int _calibrationProgress = 0;
  String _calibrationMessage = '';
  Timer? _calibrationTimer;
  
  // تتبع محسّن للحركة
  final List<_DirectionSample> _directionSamples = [];
  Set<int> _coveredQuadrants = {};
  double _totalRotation = 0.0;
  double _lastDirection = 0.0;
  int _significantMovements = 0;
  
  // معايير محسّنة للإنجاز السريع
  static const int _minReadings = 30; // كان 40
  static const int _minQuadrants = 2; // كان 2
  static const double _minRotation = 180.0; // الحد الأدنى للدوران الكلي
  static const int _minSignificantMovements = 8; // عدد الحركات المهمة
  static const Duration _maxCalibrationTime = Duration(seconds: 15); // كان 30

  static const int _filterSize = 10;
  final List<double> _directionHistory = [];

  QiblaService({
    required StorageService storage,
    required PermissionService permissionService,
  })  : _storage = storage,
        _permissionService = permissionService {
    _init();
  }

  // ==================== الخصائص ====================

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
    'totalRotation': _totalRotation,
    'significantMovements': _significantMovements,
  };

  // ==================== التهيئة ====================

  Future<void> _init() async {
    if (_disposed) return;

    try {
      debugPrint('[QiblaService] بدء التهيئة');
      
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

  // ==================== المعايرة المحسّنة والأسرع ====================

  Future<void> startCalibration() async {
    if (_disposed || !_hasCompass || _isCalibrating) return;

    _isCalibrating = true;
    _isCalibrated = false;
    _calibrationReadings.clear();
    _directionSamples.clear();
    _coveredQuadrants.clear();
    _calibrationProgress = 0;
    _totalRotation = 0.0;
    _lastDirection = _currentDirection;
    _significantMovements = 0;
    _calibrationMessage = 'حرك الجهاز في شكل ∞ (رقم 8)';
    
    debugPrint('[QiblaService] بدء المعايرة السريعة');
    notifyListeners();

    int elapsedSeconds = 0;
    _calibrationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_disposed && _isCalibrating) {
        elapsedSeconds++;
        _updateCalibrationProgress(elapsedSeconds);
        
        // التحقق من اكتمال المعايرة مبكراً
        if (_checkEarlyCompletion() || elapsedSeconds >= 30) { // 15 ثانية
          debugPrint('[QiblaService] اكتملت المعايرة مبكراً');
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
    
    // حساب الدوران الكلي
    double diff = _calculateAngleDifference(_lastDirection, direction);
    if (diff.abs() > 2.0) { // حركة ملحوظة
      _totalRotation += diff.abs();
      
      // عد الحركات المهمة
      if (diff.abs() > 10.0) {
        _significantMovements++;
      }
    }
    _lastDirection = direction;

    // إضافة عينة
    _directionSamples.add(_DirectionSample(
      direction: direction,
      timestamp: DateTime.now(),
    ));

    // الاحتفاظ بآخر 60 عينة
    if (_directionSamples.length > 60) {
      _directionSamples.removeAt(0);
    }

    // تحديث الأرباع
    final quadrant = (direction ~/ 90) % 4;
    _coveredQuadrants.add(quadrant);
  }

  bool _checkEarlyCompletion() {
    // معايير الإنجاز المبكر (أكثر مرونة)
    final hasEnoughReadings = _calibrationReadings.length >= _minReadings;
    final hasEnoughQuadrants = _coveredQuadrants.length >= _minQuadrants;
    final hasEnoughRotation = _totalRotation >= _minRotation;
    final hasEnoughMovements = _significantMovements >= _minSignificantMovements;
    
    // يكفي تحقيق 3 من 4 معايير
    int metCriteria = 0;
    if (hasEnoughReadings) metCriteria++;
    if (hasEnoughQuadrants) metCriteria++;
    if (hasEnoughRotation) metCriteria++;
    if (hasEnoughMovements) metCriteria++;
    
    return metCriteria >= 3 && _calibrationProgress >= 60;
  }

  void _updateCalibrationProgress(int halfSeconds) {
    int progress = 0;

    // 1. عامل الوقت (25%)
    final timeProgress = math.min(halfSeconds / 30.0, 1.0); // 15 ثانية
    progress += (timeProgress * 25).toInt();

    // 2. عامل القراءات (20%)
    final readingsProgress = math.min(_calibrationReadings.length / 50.0, 1.0);
    progress += (readingsProgress * 20).toInt();

    // 3. عامل الأرباع (20%)
    final quadrantsProgress = _coveredQuadrants.length / 4.0;
    progress += (quadrantsProgress * 20).toInt();

    // 4. عامل الدوران الكلي (20%)
    final rotationProgress = math.min(_totalRotation / 360.0, 1.0);
    progress += (rotationProgress * 20).toInt();

    // 5. عامل الحركات المهمة (15%)
    final movementsProgress = math.min(_significantMovements / _minSignificantMovements, 1.0);
    progress += (movementsProgress * 15).toInt();

    _calibrationProgress = math.min(progress, 100);

    // رسائل محسّنة
    if (_calibrationProgress < 20) {
      _calibrationMessage = '🔄 ابدأ بتحريك الجهاز في شكل ∞';
    } else if (_calibrationProgress < 40) {
      _calibrationMessage = '↗️ استمر... حرك في جميع الاتجاهات';
    } else if (_calibrationProgress < 60) {
      _calibrationMessage = '✨ جيد! غط الاتجاهات المتبقية';
    } else if (_calibrationProgress < 80) {
      _calibrationMessage = '🎯 ممتاز! أكمل الحركة...';
    } else {
      _calibrationMessage = '✅ شارفت على الانتهاء!';
    }

    // تحذيرات ذكية
    if (halfSeconds > 10) { // بعد 5 ثوان
      if (_totalRotation < 90) {
        _calibrationMessage = '⚠️ حرك الجهاز أكثر وبشكل أوسع';
      } else if (_coveredQuadrants.length < 2) {
        _calibrationMessage = '⚠️ غط جميع الاتجاهات (شمال، جنوب، شرق، غرب)';
      }
    }

    notifyListeners();
  }

  void _completeCalibration() {
    if (_disposed) return;

    _isCalibrating = false;
    _calibrationTimer?.cancel();

    final hasEnoughReadings = _calibrationReadings.length >= _minReadings;
    final hasEnoughQuadrants = _coveredQuadrants.length >= _minQuadrants;
    final hasEnoughRotation = _totalRotation >= _minRotation;

    debugPrint('[QiblaService] إحصائيات المعايرة:');
    debugPrint('  - القراءات: ${_calibrationReadings.length}');
    debugPrint('  - الأرباع: ${_coveredQuadrants.length}/4');
    debugPrint('  - الدوران الكلي: ${_totalRotation.toStringAsFixed(1)}°');
    debugPrint('  - الحركات المهمة: $_significantMovements');

    if (hasEnoughReadings && hasEnoughQuadrants && hasEnoughRotation) {
      // حساب جودة المعايرة
      final variance = _calculateCircularVariance(_calibrationReadings);
      final coverage = _coveredQuadrants.length / 4.0;
      final quality = (variance * 0.6) + (coverage * 0.4);
      
      _isCalibrated = true;
      _compassAccuracy = math.min(0.6 + (quality * 0.4), 1.0);
      _calibrationMessage = '✅ تمت المعايرة بنجاح!';
      
      debugPrint('[QiblaService] معايرة ناجحة - الجودة: ${(quality * 100).toStringAsFixed(1)}%');
    } else {
      // قبول المعايرة الجزئية
      _isCalibrated = true;
      _compassAccuracy = math.max(_compassAccuracy, 0.65);
      _calibrationMessage = '✓ معايرة مقبولة';
      
      debugPrint('[QiblaService] معايرة جزئية مقبولة');
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
    _totalRotation = 0.0;
    _significantMovements = 0;
    _calibrationTimer?.cancel();
    
    _saveCalibrationData();
    notifyListeners();
  }

  // ==================== حسابات محسّنة ====================

  double _calculateCircularVariance(List<double> angles) {
    if (angles.isEmpty) return 0;
    
    double sumX = 0, sumY = 0;
    for (var angle in angles) {
      final radians = angle * math.pi / 180;
      sumX += math.cos(radians);
      sumY += math.sin(radians);
    }
    
    final avgX = sumX / angles.length;
    final avgY = sumY / angles.length;
    final r = math.sqrt(avgX * avgX + avgY * avgY);
    
    return 1 - r;
  }

  double _calculateAngleDifference(double from, double to) {
    double diff = to - from;
    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;
    return diff;
  }

  // ==================== باقي الكود ====================

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

  double _applySmoothing(List<double> readings) {
    if (readings.isEmpty) return 0;

    final sines = readings.map((angle) => math.sin(angle * math.pi / 180)).toList();
    final cosines = readings.map((angle) => math.cos(angle * math.pi / 180)).toList();

    final avgSin = sines.reduce((a, b) => a + b) / readings.length;
    final avgCos = cosines.reduce((a, b) => a + b) / readings.length;

    double angle = math.atan2(avgSin, avgCos) * 180 / math.pi;
    return (angle + 360) % 360;
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

    debugPrint('[QiblaService] تنظيف الموارد');
    
    _compassSubscription?.cancel();
    _calibrationTimer?.cancel();
    _directionHistory.clear();
    _calibrationReadings.clear();
    _directionSamples.clear();
    _coveredQuadrants.clear();

    super.dispose();
  }
}

class _DirectionSample {
  final double direction;
  final DateTime timestamp;

  _DirectionSample({
    required this.direction,
    required this.timestamp,
  });
}