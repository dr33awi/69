// lib/features/qibla/services/qibla_service_v2.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../models/qibla_model.dart';

/// خدمة القبلة المحسّنة - معايرة تلقائية وأداء محسّن
class QiblaServiceV2 extends ChangeNotifier {
  final StorageService _storage;
  final PermissionService _permissionService;

  static const String _qiblaDataKey = 'qibla_data_v2';

  QiblaModel? _qiblaData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  StreamSubscription<CompassEvent>? _compassSubscription;
  double _currentDirection = 0.0;
  double _smoothDirection = 0.0;
  bool _hasCompass = false;
  double _compassAccuracy = 0.8; // دقة افتراضية جيدة

  // معايرة تلقائية في الخلفية (بدون تدخل المستخدم)
  bool _isAutoCalibrating = false;
  final List<double> _calibrationSamples = [];

  // تحسين الأداء - تقليل التحديثات
  Timer? _updateThrottleTimer;
  DateTime? _lastNotifyTime;
  static const Duration _minNotifyInterval = Duration(milliseconds: 100); // 10 مرات/ثانية

  // تصفية وتنعيم القراءات
  static const int _filterSize = 8;
  final List<double> _directionHistory = [];

  QiblaServiceV2({
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
  bool get isDisposed => _disposed;

  double get accuracyPercentage => _hasCompass ? math.min(_compassAccuracy * 100, 100) : 0;
  bool get hasRecentData => _qiblaData != null && !_qiblaData!.isStale;

  String get locationInfo => _qiblaData?.cityName ?? 'غير محدد';

  // ==================== التهيئة ====================

  Future<void> _init() async {
    if (_disposed) return;

    try {
      debugPrint('[QiblaV2] بدء التهيئة المحسّنة');
      
      // تحميل البيانات المحفوظة
      await _loadStoredData();
      
      // فحص البوصلة
      await _checkCompassAvailability();

      // بدء الاستماع للبوصلة
      if (_hasCompass) {
        await _startCompassListener();
        _startAutoCalibration(); // معايرة تلقائية في الخلفية
      }
      
      debugPrint('[QiblaV2] تمت التهيئة بنجاح');
      debugPrint('  - البوصلة متوفرة: $_hasCompass');
      
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء التهيئة';
      debugPrint('[QiblaV2] خطأ في التهيئة: $e');
    }
  }

  Future<void> _loadStoredData() async {
    try {
      // تحميل بيانات القبلة
      final qiblaJson = _storage.getMap(_qiblaDataKey);
      if (qiblaJson != null && qiblaJson.isNotEmpty) {
        _qiblaData = QiblaModel.fromJson(qiblaJson);
      }

      debugPrint('[QiblaV2] تم تحميل البيانات المخزنة');
    } catch (e) {
      debugPrint('[QiblaV2] خطأ في تحميل البيانات: $e');
    }
  }

  Future<void> _checkCompassAvailability() async {
    try {
      final compassEvents = await FlutterCompass.events
          ?.timeout(const Duration(seconds: 2))
          .take(2)
          .toList();

      _hasCompass = compassEvents != null && 
                    compassEvents.isNotEmpty &&
                    compassEvents.any((e) => e.heading != null);
      
      if (_hasCompass) {
        _compassAccuracy = 0.75; // دقة افتراضية جيدة
      }
    } catch (e) {
      _hasCompass = false;
      debugPrint('[QiblaV2] البوصلة غير متوفرة');
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
        debugPrint('[QiblaV2] خطأ في قراءة البوصلة');
      },
    );
  }

  void _processCompassReading(CompassEvent event) {
    if (_disposed) return;

    _currentDirection = event.heading!;
    
    // تحديث دقة البوصلة
    if (event.accuracy != null) {
      _compassAccuracy = _calculateAccuracy(event.accuracy!);
    }

    // إضافة القراءة للسجل
    _directionHistory.add(_currentDirection);
    if (_directionHistory.length > _filterSize) {
      _directionHistory.removeAt(0);
    }

    // تطبيق التنعيم
    _smoothDirection = _applySmoothing(_directionHistory);

    // معايرة تلقائية
    if (_isAutoCalibrating) {
      _processAutoCalibration(_currentDirection);
    }

    // تحديث بتردد محدود (10 مرات/ثانية فقط)
    _throttledNotify();
  }

  // ==================== معايرة تلقائية (بدون تدخل المستخدم) ====================

  void _startAutoCalibration() {
    if (!_hasCompass) return;

    _isAutoCalibrating = true;
    _calibrationSamples.clear();

    debugPrint('[QiblaV2] بدء المعايرة التلقائية في الخلفية');

    // التوقف التلقائي بعد 30 ثانية
    Timer(const Duration(seconds: 30), () {
      if (_isAutoCalibrating) {
        _completeAutoCalibration();
      }
    });
  }

  void _processAutoCalibration(double direction) {
    if (!_isAutoCalibrating) return;

    _calibrationSamples.add(direction);

    // عند جمع 50 عينة، قم بالمعايرة
    if (_calibrationSamples.length >= 50) {
      _completeAutoCalibration();
    }
  }

  void _completeAutoCalibration() {
    if (!_isAutoCalibrating) return;

    _isAutoCalibrating = false;

    if (_calibrationSamples.length >= 20) {
      // حساب جودة المعايرة
      final variance = _calculateCircularVariance(_calibrationSamples);
      _compassAccuracy = math.max(0.7, math.min(1.0, 1.0 - variance));

      debugPrint('[QiblaV2] اكتملت المعايرة التلقائية');
      debugPrint('  - عدد العينات: ${_calibrationSamples.length}');
      debugPrint('  - الدقة: ${(_compassAccuracy * 100).toStringAsFixed(1)}%');
    }

    _calibrationSamples.clear();
  }

  // ==================== تحديث بيانات القبلة ====================

  Future<void> updateQiblaData({bool forceUpdate = false}) async {
    if (_disposed || _isLoading) return;

    if (!forceUpdate && hasRecentData) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notifyListenersNow();

    try {
      debugPrint('[QiblaV2] بدء تحديث بيانات القبلة');

      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        throw Exception('لم يتم منح إذن الوصول إلى الموقع');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      String? cityName;
      String? countryName;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 8));

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          cityName = placemark.locality ?? placemark.administrativeArea;
          countryName = placemark.country;
        }
      } catch (e) {
        debugPrint('[QiblaV2] لم يتم الحصول على معلومات الموقع');
      }

      _qiblaData = QiblaModel.fromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        cityName: cityName,
        countryName: countryName,
      );

      await _saveQiblaData(_qiblaData!);
      
      debugPrint('[QiblaV2] تم تحديث بيانات القبلة بنجاح');
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('[QiblaV2] خطأ في تحديث البيانات: $e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _notifyListenersNow();
      }
    }
  }

  // ==================== تحسينات الأداء ====================

  void _throttledNotify() {
    // تقليل التحديثات إلى 10 مرات في الثانية فقط
    final now = DateTime.now();
    if (_lastNotifyTime == null ||
        now.difference(_lastNotifyTime!) >= _minNotifyInterval) {
      _lastNotifyTime = now;
      notifyListeners();
    }
  }

  void _notifyListenersNow() {
    _lastNotifyTime = DateTime.now();
    notifyListeners();
  }

  // ==================== حسابات مساعدة ====================

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
    if (rawAccuracy > 180) return 0.3;
    return math.max(0.3, 1.0 - (rawAccuracy / 180.0));
  }

  double _calculateCircularVariance(List<double> angles) {
    if (angles.isEmpty) return 1.0;

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

  // ==================== الصلاحيات ====================

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

  // ==================== التخزين ====================

  Future<void> _saveQiblaData(QiblaModel data) async {
    try {
      await _storage.setMap(_qiblaDataKey, data.toJson());
    } catch (e) {
      debugPrint('[QiblaV2] خطأ في حفظ البيانات');
    }
  }

  // ==================== رسائل الأخطاء ====================

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'انتهت مهلة الحصول على الموقع';
    } else if (error is LocationServiceDisabledException) {
      return 'خدمة الموقع معطلة';
    } else if (error is PermissionDeniedException) {
      return 'لم يتم منح إذن الوصول إلى الموقع';
    }
    return 'حدث خطأ غير متوقع';
  }

  // ==================== التنظيف ====================

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    debugPrint('[QiblaV2] تنظيف الموارد');

    _compassSubscription?.cancel();
    _updateThrottleTimer?.cancel();
    _directionHistory.clear();
    _calibrationSamples.clear();

    super.dispose();
  }
}
