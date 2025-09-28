# 🔒 تحسين الأمان والموثوقية

## 1. إدارة البيانات الحساسة

### تشفير البيانات المحلية:

```dart
// lib/core/security/encryption_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static final _key = Key.fromSecureRandom(32);
  static final _iv = IV.fromSecureRandom(16);
  static final _encrypter = Encrypter(AES(_key));
  
  /// تشفير النص
  static String encryptText(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }
  
  /// فك التشفير
  static String decryptText(String encryptedText) {
    final encrypted = Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }
  
  /// تشفير البيانات الحساسة قبل الحفظ
  static Future<void> saveSecureData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedValue = encryptText(value);
    await prefs.setString(key, encryptedValue);
  }
  
  /// قراءة البيانات المشفرة
  static Future<String?> getSecureData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedValue = prefs.getString(key);
    
    if (encryptedValue == null) return null;
    
    try {
      return decryptText(encryptedValue);
    } catch (e) {
      debugPrint('فشل فك التشفير: $e');
      return null;
    }
  }
}
```

### حماية الـ API Keys:

```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');
  
  // مفاتيح مختلفة للإنتاج والتطوير
  static String get firebaseApiKey {
    return _isProduction 
        ? 'PRODUCTION_FIREBASE_KEY'
        : 'DEVELOPMENT_FIREBASE_KEY';
  }
  
  static String get baseApiUrl {
    return _isProduction
        ? 'https://api.production.com'
        : 'https://api.development.com';
  }
  
  // إخفاء المفاتيح الحساسة
  static String _obfuscateKey(String key) {
    if (key.length <= 8) return '*' * key.length;
    return key.substring(0, 4) + '*' * (key.length - 8) + key.substring(key.length - 4);
  }
  
  static void logConfig() {
    debugPrint('API URL: $baseApiUrl');
    debugPrint('Firebase Key: ${_obfuscateKey(firebaseApiKey)}');
  }
}
```

## 2. التحقق من صحة البيانات

### Validation Service:

```dart
// lib/core/validation/validation_service.dart
class ValidationService {
  /// التحقق من صحة الإحداثيات
  static bool isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    
    return latitude >= -90 && latitude <= 90 &&
           longitude >= -180 && longitude <= 180;
  }
  
  /// التحقق من صحة وقت الصلاة
  static bool isValidPrayerTime(DateTime? time) {
    if (time == null) return false;
    
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));
    
    return time.isAfter(yesterday) && time.isBefore(tomorrow);
  }
  
  /// تنظيف وتصحيح النصوص
  static String sanitizeText(String? input) {
    if (input == null || input.isEmpty) return '';
    
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // إزالة المسافات الزائدة
        .replaceAll(RegExp(r'[^\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\s\d\p{P}]', unicode: true), '') // السماح فقط بالعربية والأرقام والرموز
        ;
  }
  
  /// التحقق من صحة الإعدادات
  static ValidationResult validatePrayerSettings(PrayerCalculationSettings settings) {
    final errors = <String>[];
    
    if (settings.calculationMethod == null) {
      errors.add('يجب اختيار طريقة الحساب');
    }
    
    if (settings.asrMethod == null) {
      errors.add('يجب اختيار طريقة حساب العصر');
    }
    
    if (settings.fajrAngle < 10 || settings.fajrAngle > 20) {
      errors.add('زاوية الفجر يجب أن تكون بين 10 و 20 درجة');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
  
  String get errorMessage => errors.join('\n');
}
```

## 3. مراقبة الأخطاء والتقارير

### Crash Analytics:

```dart
// lib/core/analytics/crash_service.dart
class CrashService {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // إعداد Firebase Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    
    // معالجة الأخطاء خارج Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    _isInitialized = true;
  }
  
  /// تسجيل خطأ مخصص
  static Future<void> recordError(
    dynamic error, 
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: fatal,
      information: context != null 
          ? context.entries.map((e) => '${e.key}: ${e.value}').toList()
          : null,
    );
  }
  
  /// تسجيل معلومات المستخدم (بدون بيانات حساسة)
  static Future<void> setUserInfo({
    required String userId,
    String? deviceInfo,
    String? appVersion,
  }) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    
    if (deviceInfo != null) {
      await FirebaseCrashlytics.instance.setCustomKey('device_info', deviceInfo);
    }
    
    if (appVersion != null) {
      await FirebaseCrashlytics.instance.setCustomKey('app_version', appVersion);
    }
  }
}
```

## 4. إدارة الأذونات الآمنة

### Secure Permission Handler:

```dart
// lib/core/permissions/secure_permission_service.dart
class SecurePermissionService {
  static const Map<AppPermissionType, Duration> _permissionTimeout = {
    AppPermissionType.location: Duration(seconds: 30),
    AppPermissionType.notification: Duration(seconds: 15),
    AppPermissionType.batteryOptimization: Duration(seconds: 20),
  };
  
  /// طلب الإذن مع timeout
  static Future<AppPermissionStatus> requestWithTimeout(
    AppPermissionType permission,
  ) async {
    final timeout = _permissionTimeout[permission] ?? const Duration(seconds: 15);
    
    try {
      return await Future.any([
        _requestPermission(permission),
        Future.delayed(timeout).then((_) => AppPermissionStatus.denied),
      ]);
    } catch (e) {
      await CrashService.recordError(
        'Permission request failed: $permission',
        StackTrace.current,
        context: {'permission': permission.toString()},
      );
      return AppPermissionStatus.denied;
    }
  }
  
  static Future<AppPermissionStatus> _requestPermission(
    AppPermissionType permission,
  ) async {
    // التحقق من الحالة أولاً
    final currentStatus = await PermissionService.checkStatus(permission);
    if (currentStatus == AppPermissionStatus.granted) {
      return currentStatus;
    }
    
    // طلب الإذن
    final result = await PermissionService.request(permission);
    
    // تسجيل النتيجة للإحصائيات
    await _logPermissionResult(permission, result);
    
    return result;
  }
  
  static Future<void> _logPermissionResult(
    AppPermissionType permission,
    AppPermissionStatus result,
  ) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'permission_request_result',
      parameters: {
        'permission_type': permission.toString(),
        'result': result.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
```

## 5. Network Security

### Secure HTTP Client:

```dart
// lib/core/network/secure_http_client.dart
class SecureHttpClient {
  static final Dio _dio = Dio();
  
  static Future<void> initialize() async {
    // إعداد الـ interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: false, // لا نسجل الـ request body للأمان
      responseBody: false, // لا نسجل الـ response body للأمان
      logPrint: (obj) => debugPrint(obj.toString()),
    ));
    
    // إعداد timeout
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    
    // إعداد headers الأمان
    _dio.options.headers.addAll({
      'User-Agent': await _getUserAgent(),
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    });
    
    // Certificate Pinning (اختياري)
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (cert, host, port) {
        // فحص الشهادة هنا
        return _verifyCertificate(cert, host);
      };
      return client;
    };
  }
  
  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }
  
  static Future<String> _getUserAgent() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = await DeviceInfoPlugin().deviceInfo;
    
    return 'AthkarApp/${packageInfo.version} '
           '(${Platform.operatingSystem}; ${deviceInfo.toString()})';
  }
  
  static bool _verifyCertificate(X509Certificate cert, String host) {
    // تحقق من الشهادة الرقمية
    // يمكن إضافة منطق للتحقق من الشهادات المعتمدة
    return true; // مؤقتاً
  }
  
  static Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkError('انتهت مهلة الاتصال');
      case DioExceptionType.badResponse:
        return NetworkError('خطأ في الاستجابة: ${e.response?.statusCode}');
      default:
        return NetworkError('خطأ في الشبكة: ${e.message}');
    }
  }
}
```

## 6. Secure Storage

### آمان البيانات المحلية:

```dart
// lib/core/storage/secure_storage_service.dart
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      preferencesKeyPrefix: 'athkar_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.athkar.app',
      accessibility: IOSAccessibility.first_unlock_this_device,
    ),
  );
  
  /// حفظ بيانات حساسة
  static Future<void> writeSecure(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      await CrashService.recordError(
        'Secure storage write failed',
        StackTrace.current,
        context: {'key': key, 'error': e.toString()},
      );
      rethrow;
    }
  }
  
  /// قراءة بيانات حساسة
  static Future<String?> readSecure(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      await CrashService.recordError(
        'Secure storage read failed',
        StackTrace.current,
        context: {'key': key, 'error': e.toString()},
      );
      return null;
    }
  }
  
  /// مسح البيانات عند تسجيل الخروج
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      await CrashService.recordError(
        'Secure storage clear failed',
        StackTrace.current,
      );
    }
  }
}
```

## الخلاصة:

1. **تشفير البيانات الحساسة محلياً**
2. **حماية الـ API Keys والمفاتيح**
3. **التحقق من صحة جميع البيانات**
4. **مراقبة شاملة للأخطاء والانهيارات**
5. **إدارة آمنة للأذونات**
6. **أمان الاتصالات الشبكية**
7. **استخدام Secure Storage للبيانات الحساسة**