// lib/features/qibla/services/qibla_service_v3.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/simple_permission_service.dart';
import '../models/qibla_model.dart';

/// خدمة القبلة المحسّنة V3 مع نظام الأذونات الجديد
class QiblaServiceV3 extends ChangeNotifier {
  final StorageService _storage;
  final SimplePermissionService _permissionService;

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
  double _compassAccuracy = 0.9;

  DateTime? _lastNotifyTime;
  static const Duration _minNotifyInterval = Duration(milliseconds: 100);
  
  static const int _smoothingWindow = 5;
  final List<double> _directionHistory = [];

  QiblaServiceV3({
    required StorageService storage,
    required SimplePermissionService simplePermissionService,
  })  : _storage = storage,
        _permissionService = simplePermissionService {
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
      await _loadStoredData();
      await _checkCompassAvailability();

      if (_hasCompass) {
        await _startQiblahListener();
      }
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء التهيئة';
      debugPrint('Error initializing QiblaService: $e');
    }
  }

  Future<void> _loadStoredData() async {
    try {
      final qiblaJson = _storage.getMap(_qiblaDataKey);
      if (qiblaJson != null && qiblaJson.isNotEmpty) {
        _qiblaData = QiblaModel.fromJson(qiblaJson);
        debugPrint('Loaded stored Qibla data');
      }
    } catch (e) {
      debugPrint('Error loading stored Qibla data: $e');
    }
  }

  Future<void> _checkCompassAvailability() async {
    try {
      final deviceSupport = await FlutterQiblah.androidDeviceSensorSupport();
      _hasCompass = deviceSupport ?? true;
      
      if (_hasCompass) {
        _compassAccuracy = 0.9;
        debugPrint('Compass available with high accuracy');
      } else {
        debugPrint('Compass not available');
      }
    } catch (e) {
      _hasCompass = true;
      debugPrint('Error checking compass availability: $e');
    }
  }

  Future<void> _startQiblahListener() async {
    if (!_hasCompass || _disposed) return;

    try {
      _qiblahSubscription = FlutterQiblah.qiblahStream.listen(
        (QiblahDirection qiblahDirection) {
          if (!_disposed) {
            _processQiblahReading(qiblahDirection);
          }
        },
        onError: (error) {
          _errorMessage = 'خطأ في قراءة البوصلة';
          _throttledNotify();
          debugPrint('Qiblah stream error: $error');
        },
      );
      debugPrint('Started Qiblah listener');
    } catch (e) {
      debugPrint('Error starting Qiblah listener: $e');
    }
  }

  void _processQiblahReading(QiblahDirection qiblahDirection) {
    if (_disposed) return;

    _qiblaDirection = qiblahDirection.qiblah;
    _currentDirection = qiblahDirection.direction;
    _offset = qiblahDirection.offset;

    _directionHistory.add(_currentDirection);
    if (_directionHistory.length > _smoothingWindow) {
      _directionHistory.removeAt(0);
    }

    if (_directionHistory.isNotEmpty) {
      _currentDirection = _calculateCircularMean(_directionHistory);
    }

    _updateAccuracy();
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

    final variance = _calculateVariance(_directionHistory);
    
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
        debugPrint('Error getting placemark: $e');
      }

      _qiblaData = QiblaModel.fromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        cityName: cityName,
        countryName: countryName,
      );

      await _saveQiblaData(_qiblaData!);
      debugPrint('Qibla data updated successfully');
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('Error updating Qibla data: $e');
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
      return await _permissionService.checkLocationPermission();
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  // ==================== التخزين ====================

  Future<void> _saveQiblaData(QiblaModel data) async {
    try {
      await _storage.setMap(_qiblaDataKey, data.toJson());
      debugPrint('Qibla data saved');
    } catch (e) {
      debugPrint('Error saving Qibla data: $e');
    }
  }

  // ==================== رسائل الأخطاء ====================

  String _getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'انتهت مهلة الحصول على الموقع';
    } else if (error.toString().contains('LOCATION_SERVICE_DISABLED') ||
               error.toString().contains('SERVICE_DISABLED')) {
      return 'خدمة الموقع معطلة';
    } else if (error.toString().contains('PERMISSION_DENIED')) {
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
    debugPrint('QiblaServiceV3 disposed');
    super.dispose();
  }
}