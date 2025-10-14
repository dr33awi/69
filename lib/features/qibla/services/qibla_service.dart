// lib/features/qibla/services/qibla_service_v2.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../models/qibla_model.dart';

/// خدمة القبلة باستخدام flutter_qiblah
class QiblaService extends ChangeNotifier {
  final StorageService _storage;
  final PermissionService _permissionService;

  // مفاتيح التخزين
  static const String _qiblaDataKey = 'qibla_data_v2';

  // حالة الخدمة
  QiblaModel? _qiblaData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  // البوصلة من flutter_qiblah
  StreamSubscription<QiblahDirection>? _qiblahSubscription;
  double _currentDirection = 0.0;
  double _qiblaDirection = 0.0;
  bool _hasCompass = false;

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
  double get qiblaDirection => _qiblaDirection;
  bool get hasCompass => _hasCompass;
  bool get isDisposed => _disposed;
  bool get hasRecentData => _qiblaData != null && !_qiblaData!.isStale;

  // للتوافق مع الكود القديم
  double get compassAccuracy => 1.0;
  bool get isCalibrated => true;
  bool get isCalibrating => false;
  int get calibrationProgress => 100;
  String get calibrationMessage => '';

  // ==================== التهيئة ====================

  Future<void> _init() async {
    if (_disposed) return;

    try {
      debugPrint('[QiblaServiceV2] بدء تهيئة خدمة القبلة');
      
      // التحقق من دعم البوصلة
      _hasCompass = await FlutterQiblah.androidDeviceSensorSupport() ?? false;
      
      if (_hasCompass) {
        await _startQiblahListener();
      }

      await _loadStoredQiblaData();
      
      debugPrint('[QiblaServiceV2] تمت التهيئة بنجاح');
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء التهيئة';
      debugPrint('[QiblaServiceV2] خطأ في التهيئة: $e');
    }
  }

  Future<void> _startQiblahListener() async {
    if (!_hasCompass || _disposed) return;

    try {
      _qiblahSubscription = FlutterQiblah.qiblahStream.listen(
        (QiblahDirection direction) {
          if (!_disposed) {
            _currentDirection = direction.direction;
            _qiblaDirection = direction.qiblah;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('[QiblaServiceV2] خطأ في قراءة البوصلة: $error');
          _errorMessage = 'خطأ في قراءة البوصلة';
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[QiblaServiceV2] فشل بدء الاستماع للبوصلة: $e');
    }
  }

  // ==================== تحديث البيانات ====================

  Future<void> updateQiblaData({bool forceUpdate = false}) async {
    if (_disposed || _isLoading) return;

    if (!forceUpdate && hasRecentData && _qiblaData!.hasHighAccuracy) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[QiblaServiceV2] بدء تحديث بيانات القبلة');

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
        debugPrint('[QiblaServiceV2] لم يتم الحصول على معلومات الموقع');
      }

      _qiblaData = QiblaModel.fromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        cityName: cityName,
        countryName: countryName,
      );

      await _saveQiblaData(_qiblaData!);
      
      // إعادة بدء الاستماع للبوصلة بعد الحصول على الموقع
      if (_hasCompass && _qiblahSubscription == null) {
        await _startQiblahListener();
      }
      
      debugPrint('[QiblaServiceV2] تم تحديث بيانات القبلة بنجاح');
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      debugPrint('[QiblaServiceV2] خطأ في تحديث البيانات: $e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> forceUpdate() => updateQiblaData(forceUpdate: true);

  // ==================== وظائف المعايرة (للتوافق فقط) ====================

  Future<void> startCalibration() async {
    // flutter_qiblah لا تحتاج معايرة يدوية
    // يمكنك عرض رسالة أو حوار توضيحي
    debugPrint('[QiblaServiceV2] المعايرة غير مطلوبة مع flutter_qiblah');
  }

  void resetCalibration() {
    // لا حاجة لإعادة تعيين المعايرة
  }

  // ==================== التخزين ====================

  Future<void> _loadStoredQiblaData() async {
    try {
      final qiblaJson = _storage.getMap(_qiblaDataKey);
      if (qiblaJson != null && qiblaJson.isNotEmpty) {
        _qiblaData = QiblaModel.fromJson(qiblaJson);
        debugPrint('[QiblaServiceV2] تم تحميل بيانات القبلة المخزنة');
      }
    } catch (e) {
      debugPrint('[QiblaServiceV2] خطأ في تحميل البيانات المخزنة');
    }
  }

  Future<void> _saveQiblaData(QiblaModel data) async {
    try {
      await _storage.setMap(_qiblaDataKey, data.toJson());
    } catch (e) {
      debugPrint('[QiblaServiceV2] خطأ في حفظ البيانات');
    }
  }

  // ==================== الوظائف المساعدة ====================

  Future<bool> _checkLocationPermission() async {
    try {
      // فحص الحالة الحالية
      final status = await _permissionService.checkPermissionStatus(
        AppPermissionType.location,
      );

      if (status == AppPermissionStatus.granted) {
        return true;
      }

      // طلب الإذن من خلال النظام الموحد
      final newStatus = await _permissionService.requestPermission(
        AppPermissionType.location,
      );
      
      return newStatus == AppPermissionStatus.granted;
      
    } catch (e) {
      debugPrint('[QiblaServiceV2] خطأ في فحص أذونات الموقع: $e');
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

  Map<String, dynamic> getDiagnostics() => {
    'hasCompass': _hasCompass,
    'currentDirection': _currentDirection,
    'qiblaDirection': _qiblaDirection,
    'hasQiblaData': _qiblaData != null,
  };

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    debugPrint('[QiblaServiceV2] بدء تنظيف موارد الخدمة');
    
    _qiblahSubscription?.cancel();

    super.dispose();
  }
}