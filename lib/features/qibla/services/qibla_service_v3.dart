// lib/features/qibla/services/qibla_service_v3.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../models/qibla_model.dart';

/// خدمة القبلة المحسّنة V3 - باستخدام flutter_qiblah للدقة القصوى
class QiblaServiceV3 extends ChangeNotifier {
  final StorageService _storage;
  final PermissionService _permissionService;

  static const String _qiblaDataKey = 'qibla_data_v3';

  QiblaModel? _qiblaData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  StreamSubscription<QiblahDirection>? _qiblahSubscription;
  double _currentDirection = 0.0;
  double _qiblaDirection = 0.0;
  double _offset = 0.0;
  bool _hasCompass = false;
  double _compassAccuracy = 0.9; // flutter_qiblah توفر دقة عالية افتراضياً

  // تحسين الأداء - تقليل التحديثات
  DateTime? _lastNotifyTime;
  static const Duration _minNotifyInterval = Duration(milliseconds: 100);
  
  // تنعيم إضافي للقراءات
  static const int _smoothingWindow = 5;
  final List<double> _directionHistory = [];

  QiblaServiceV3({
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
  double get currentDirection => _currentDirection;
  double get qiblaDirection => _qiblaDirection;
  double get offset => _offset;
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
      // تحميل البيانات المحفوظة
      await _loadStoredData();
      
      // فحص توفر البوصلة (خاص بـ Android)
      await _checkCompassAvailability();

      // بدء الاستماع لاتجاه القبلة
      if (_hasCompass) {
        await _startQiblahListener();
      }
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء التهيئة';
    }
  }

  Future<void> _loadStoredData() async {
    try {
      final qiblaJson = _storage.getMap(_qiblaDataKey);
      if (qiblaJson != null && qiblaJson.isNotEmpty) {
        _qiblaData = QiblaModel.fromJson(qiblaJson);
      }
    } catch (e) {
    }
  }

  Future<void> _checkCompassAvailability() async {
    try {
      // فحص توفر سنسور البوصلة
      final deviceSupport = await FlutterQiblah.androidDeviceSensorSupport();
      _hasCompass = deviceSupport ?? true; // iOS دائماً true
      
      if (_hasCompass) {
        _compassAccuracy = 0.9; // دقة عالية مع flutter_qiblah
      } else {
      }
    } catch (e) {
      _hasCompass = true; // افتراض التوفر في حالة الخطأ
    }
  }

  Future<void> _startQiblahListener() async {
    if (!_hasCompass || _disposed) return;

    try {
      // الاستماع لـ stream اتجاه القبلة من flutter_qiblah
      _qiblahSubscription = FlutterQiblah.qiblahStream.listen(
        (QiblahDirection qiblahDirection) {
          if (!_disposed) {
            _processQiblahReading(qiblahDirection);
          }
        },
        onError: (error) {
          _errorMessage = 'خطأ في قراءة البوصلة';
          _throttledNotify();
        },
      );
    } catch (e) {
    }
  }

  void _processQiblahReading(QiblahDirection qiblahDirection) {
    if (_disposed) return;

    // قراءة القيم من flutter_qiblah
    // البنية الصحيحة: qiblah (اتجاه القبلة) و direction (اتجاه الجهاز)
    _qiblaDirection = qiblahDirection.qiblah;
    _currentDirection = qiblahDirection.direction;
    _offset = qiblahDirection.offset;

    // تطبيق تنعيم إضافي على الاتجاه الحالي
    _directionHistory.add(_currentDirection);
    if (_directionHistory.length > _smoothingWindow) {
      _directionHistory.removeAt(0);
    }

    // حساب المتوسط المُنعّم
    if (_directionHistory.isNotEmpty) {
      _currentDirection = _calculateCircularMean(_directionHistory);
    }

    // تحديث الدقة بناءً على استقرار القراءات
    _updateAccuracy();

    // إشعار المستمعين بتردد محدود
    _throttledNotify();
  }

  // ==================== حساب المتوسط الدائري ====================

  double _calculateCircularMean(List<double> angles) {
    if (angles.isEmpty) return 0;
    
    double sinSum = 0;
    double cosSum = 0;
    
    for (var angle in angles) {
      final radians = angle * math.pi / 180;
      sinSum += math.sin(radians);
      cosSum += math.cos(radians);
    }
    
    final avgSin = sinSum / angles.length;
    final avgCos = cosSum / angles.length;
    
    double result = math.atan2(avgSin, avgCos) * 180 / math.pi;
    return (result + 360) % 360;
  }

  // ==================== تحديث الدقة ====================

  void _updateAccuracy() {
    if (_directionHistory.length < 3) {
      _compassAccuracy = 0.7;
      return;
    }

    // حساب التباين في القراءات
    final variance = _calculateVariance(_directionHistory);
    
    // دقة عالية عند تباين منخفض
    if (variance < 2.0) {
      _compassAccuracy = 0.95;
    } else if (variance < 5.0) {
      _compassAccuracy = 0.85;
    } else if (variance < 10.0) {
      _compassAccuracy = 0.75;
    } else {
      _compassAccuracy = 0.65;
    }
  }

  double _calculateVariance(List<double> angles) {
    if (angles.length < 2) return 0;

    final mean = _calculateCircularMean(angles);
    double sumSquaredDiff = 0;

    for (var angle in angles) {
      double diff = angle - mean;
      // تطبيع الفرق
      while (diff > 180) diff -= 360;
      while (diff < -180) diff += 360;
      sumSquaredDiff += diff * diff;
    }

    return math.sqrt(sumSquaredDiff / angles.length);
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
      }

      _qiblaData = QiblaModel.fromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        cityName: cityName,
        countryName: countryName,
      );

      await _saveQiblaData(_qiblaData!);
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _notifyListenersNow();
      }
    }
  }

  // ==================== تحسينات الأداء ====================

  void _throttledNotify() {
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
    _qiblahSubscription?.cancel();
    _directionHistory.clear();

    super.dispose();
  }
}
