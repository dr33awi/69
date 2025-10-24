// lib/core/infrastructure/services/permissions/simple_permission_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_permission/smart_permission.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:app_settings/app_settings.dart';
import '../storage/storage_service.dart';
import '../../../../app/themes/theme_constants.dart';
import '../../../../app/themes/core/theme_extensions.dart';
import '../../../../app/themes/widgets/core/app_button.dart';


class SimplePermissionService {
  static final SimplePermissionService _instance = SimplePermissionService._internal();
  factory SimplePermissionService() => _instance;
  SimplePermissionService._internal();

  // ignore: unused_field
  StorageService? _storage; // محجوز للاستخدام المستقبلي لحفظ الحالات
  bool _isInitialized = false;

  // Stream controller للإشعار بالتغييرات
  final StreamController<PermissionChange> _changeController = 
      StreamController<PermissionChange>.broadcast();

  // Cache محسّن للحالات
  final Map<PermissionType, PermissionCacheEntry> _statusCache = {};
  static const Duration _cacheExpiration = Duration(hours: 1);
  
  // تتبع محاولات الطلب
  final Map<PermissionType, int> _requestAttempts = {};
  static const int _maxRetryAttempts = 20; // ✅ زيادة من 10 إلى 20 محاولات

  // ✅ قفل لمنع الطلبات المتزامنة (Mutex)
  final Map<PermissionType, Completer<bool>?> _activeRequests = {};

  /// الحصول على stream التغييرات
  Stream<PermissionChange> get permissionChanges => _changeController.stream;

  /// تهيئة الخدمة
  Future<void> initialize({StorageService? storage}) async {
    if (_isInitialized) return;
    
    _storage = storage;
    _configureSmartPermission();
    _isInitialized = true;
    debugPrint('🔐 SimplePermissionService initialized with smart_permission');
  }

  /// تكوين smart_permission بالألوان والنصوص العربية المحسّنة
  void _configureSmartPermission() {
    SmartPermission.config
      ..brightness = Brightness.light
      ..primaryColor = const Color(0xFF2E7D32)
      ..titleProvider = _getPermissionTitle
      ..descriptionProvider = _getPermissionDescription
      ..analytics = _PermissionAnalytics();
  }

  String? _getPermissionTitle(Permission permission) {
    if (permission == Permission.notification) return 'إذن الإشعارات مطلوب 🔔';
    if (permission == Permission.locationWhenInUse) return 'إذن الموقع مطلوب 📍';
    return null;
  }

  String? _getPermissionDescription(Permission permission) {
    if (permission == Permission.notification) {
      return '''نحتاج إذن الإشعارات لإرسال التنبيهات التالية:

- تنبيهات أوقات الصلاة والأذان 🕌
- تذكيرات الأذكار اليومية 📿
- تنبيهات الأحداث الإسلامية الخاصة 🌙

يمكنك التحكم الكامل بأنواع الإشعارات من الإعدادات.''';
    }
    if (permission == Permission.locationWhenInUse) {
      return '''نحتاج إذن الموقع لتوفير الخدمات التالية:

- تحديد اتجاه القبلة بدقة عالية 🧭
- حساب أوقات الصلاة لمدينتك 🕌
- عرض المساجد القريبة منك 📍

⚠️ لا نشارك موقعك مع أي جهة خارجية.
✅ نستخدم الموقع فقط عند الحاجة.''';
    }
    return null;
  }

  /// فحص الأذونات عند العودة للتطبيق
  Future<PermissionResults> checkPermissionsOnResume() async {
    debugPrint('🔄 Checking permissions on app resume');
    _clearExpiredCache();
    
    try {
      final notificationGranted = await checkNotificationPermission();
      final locationGranted = await checkLocationPermission();
      
      _notifyChange(PermissionType.notification, notificationGranted);
      _notifyChange(PermissionType.location, locationGranted);
      
      debugPrint('📱 Notification: $notificationGranted | 📍 Location: $locationGranted');
      
      return PermissionResults(
        notification: notificationGranted,
        location: locationGranted,
      );
    } catch (e) {
      debugPrint('❌ Error checking permissions on resume: $e');
      return const PermissionResults(notification: false, location: false);
    }
  }

  /// طلب إذن الإشعارات
  Future<bool> requestNotificationPermission(BuildContext context) async {
    return await _requestPermission(
      context,
      Permission.notification,
      PermissionType.notification,
    );
  }

  /// طلب إذن الموقع
  Future<bool> requestLocationPermission(BuildContext context) async {
    return await _requestPermission(
      context,
      Permission.locationWhenInUse,
      PermissionType.location,
    );
  }

  /// طلب إذن عام (داخلي) باستخدام smart_permission مع retry logic محسّن
  Future<bool> _requestPermission(
    BuildContext context,
    Permission permission,
    PermissionType type,
  ) async {
    // ✅ فحص إذا كان هناك طلب نشط بالفعل
    if (_activeRequests[type] != null) {
      debugPrint('⏳ ${type.name} permission request already in progress, waiting...');
      return await _activeRequests[type]!.future;
    }

    // إنشاء Completer جديد للطلب الحالي
    final completer = Completer<bool>();
    _activeRequests[type] = completer;

    try {
      // التحقق من عدد المحاولات
      final attempts = _requestAttempts[type] ?? 0;
      if (attempts >= _maxRetryAttempts) {
        debugPrint('⚠️ Max retry attempts ($attempts) reached for ${type.name}');
        await _showMaxAttemptsDialog(context, type);
        completer.complete(false);
        return false;
      }

      // التحقق من الـ Cache
      final cached = _getCachedStatus(type);
      if (cached != null && cached) {
        debugPrint('✅ ${type.name} already granted (from cache)');
        completer.complete(true);
        return true;
      }

      debugPrint('📱 Requesting ${type.name} permission (attempt ${attempts + 1}/$_maxRetryAttempts)...');

      // ✅ طلب الإذن مباشرة بدون Dialog توضيحي
      // استخدام permission_handler مباشرة بدلاً من smart_permission
      late bool granted;
      if (permission == Permission.notification) {
        final status = await ph.Permission.notification.request();
        granted = status.isGranted;
      } else if (permission == Permission.locationWhenInUse) {
        final status = await ph.Permission.locationWhenInUse.request();
        granted = status.isGranted;
      } else {
        granted = false;
      }

      // تحديث عداد المحاولات والـ Cache
      if (granted) {
        _requestAttempts.remove(type); // إعادة تعيين العداد عند النجاح
        _updateCache(type, true);
        _notifyChange(type, true);
        debugPrint('✅ ${type.name} permission granted successfully');
        completer.complete(true);
        return true;
      }

      // زيادة عداد المحاولات
      _requestAttempts[type] = attempts + 1;
      _updateCache(type, false);
      _notifyChange(type, false);
      
      debugPrint('❌ ${type.name} permission denied (attempt ${attempts + 1}/$_maxRetryAttempts)');

      // ✅ تم إزالة Dialog التوضيحي - طلب مباشر فقط

      completer.complete(false);
      return false;
    } catch (e) {
      debugPrint('❌ Error requesting ${type.name} permission: $e');
      
      // في حالة الخطأ، نعيد المحاولة بعد تأخير قصير
      final currentAttempt = _requestAttempts[type] ?? 0;
      if (currentAttempt < _maxRetryAttempts - 1) {
        debugPrint('🔄 Retrying after error in ${Duration(seconds: currentAttempt + 1).inSeconds}s...');
        await Future.delayed(Duration(seconds: currentAttempt + 1));
        final result = await _requestPermission(context, permission, type);
        completer.complete(result);
        return result;
      }
      
      completer.complete(false);
      return false;
    } finally {
      // ✅ إزالة القفل بعد انتهاء الطلب
      _activeRequests.remove(type);
    }
  }

  /// فحص إذن الإشعارات
  Future<bool> checkNotificationPermission() async {
    return await _checkPermissionWithCache(
      Permission.notification,
      PermissionType.notification,
    );
  }

  /// فحص إذن الموقع
  Future<bool> checkLocationPermission() async {
    return await _checkPermissionWithCache(
      Permission.locationWhenInUse,
      PermissionType.location,
    );
  }

  /// فحص إذن مع استخدام الـ Cache
  Future<bool> _checkPermissionWithCache(
    Permission permission,
    PermissionType type,
  ) async {
    final cached = _getCachedStatus(type);
    if (cached != null) return cached;

    final granted = await _checkPermissionStatus(permission);
    _updateCache(type, granted);
    return granted;
  }

  /// فحص حالة الإذن مباشرة
  Future<bool> _checkPermissionStatus(Permission permission) async {
    try {
      // استخدام permission_handler مباشرة للفحص
      ph.PermissionStatus status;
      if (permission == Permission.notification) {
        status = await ph.Permission.notification.status;
      } else if (permission == Permission.locationWhenInUse) {
        status = await ph.Permission.locationWhenInUse.status;
      } else {
        return false;
      }
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking permission status: $e');
      return false;
    }
  }

  /// فحص جميع الأذونات
  Future<PermissionResults> checkAllPermissions() async {
    final notificationGranted = await checkNotificationPermission();
    final locationGranted = await checkLocationPermission();
    
    return PermissionResults(
      notification: notificationGranted,
      location: locationGranted,
    );
  }

  /// طلب جميع الأذونات دفعة واحدة
  Future<PermissionResults> requestAllPermissions(BuildContext context) async {
    debugPrint('🔐 Requesting all critical permissions...');
    
    // استخدام smart_permission لطلب متعدد
    final results = await SmartPermission.requestMultiple(
      context,
      permissions: [
        Permission.notification,
        Permission.locationWhenInUse,
      ],
    );
    
    final notificationGranted = results[Permission.notification] ?? false;
    final locationGranted = results[Permission.locationWhenInUse] ?? false;
    
    // تحديث الـ Cache
    _updateCache(PermissionType.notification, notificationGranted);
    _updateCache(PermissionType.location, locationGranted);
    
    // إرسال الإشعارات
    _notifyChange(PermissionType.notification, notificationGranted);
    _notifyChange(PermissionType.location, locationGranted);
    
    final permResults = PermissionResults(
      notification: notificationGranted,
      location: locationGranted,
    );
    
    debugPrint('🔐 All permissions result: ${permResults.allGranted}');
    return permResults;
  }

/// فتح إعدادات التطبيق
Future<bool> openAppSettings() async {
  try {
    await AppSettings.openAppSettings();
    return true; // نعتبر أن الفتح نجح إذا لم يحدث خطأ
  } catch (e) {
    debugPrint('❌ Error opening app settings: $e');
    return false;
  }
}

  /// إعادة تعيين محاولات الطلب
  void resetRequestAttempts(PermissionType type) {
    _requestAttempts.remove(type);
    debugPrint('🔄 Reset request attempts for ${type.name}');
  }

  /// مسح الـ Cache المنتهي
  void _clearExpiredCache() {
    final now = DateTime.now();
    _statusCache.removeWhere((key, entry) {
      final expired = now.difference(entry.timestamp) > _cacheExpiration;
      if (expired) debugPrint('🧹 Cleared expired cache for ${key.name}');
      return expired;
    });
  }

  /// تنظيف الـ Cache بالكامل
  void clearCache() {
    _statusCache.clear();
    debugPrint('🧹 Permission cache cleared completely');
  }

  /// تنظيف الموارد
  void dispose() {
    _changeController.close();
    clearCache();
    _requestAttempts.clear();
    _isInitialized = false;
  }

  // ==================== Private Helper Methods ====================

  bool? _getCachedStatus(PermissionType type) {
    final entry = _statusCache[type];
    if (entry == null) return null;
    
    final now = DateTime.now();
    if (now.difference(entry.timestamp) > _cacheExpiration) {
      _statusCache.remove(type);
      return null;
    }
    
    return entry.granted;
  }

  void _updateCache(PermissionType type, bool granted) {
    _statusCache[type] = PermissionCacheEntry(
      granted: granted,
      timestamp: DateTime.now(),
    );
  }

  void _notifyChange(PermissionType type, bool newStatus) {
    final change = PermissionChange(
      type: type,
      isGranted: newStatus,
      timestamp: DateTime.now(),
    );
    _changeController.add(change);
  }

  /// عرض dialog عند الوصول لأقصى عدد من المحاولات (20 محاولات)
  Future<void> _showMaxAttemptsDialog(BuildContext context, PermissionType type) async {
    final isNotification = type == PermissionType.notification;
    final typeName = isNotification ? 'الإشعارات' : 'الموقع';
    final icon = isNotification ? Icons.notifications_off : Icons.location_off;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radius2xl),
        ),
        backgroundColor: context.cardColor,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ThemeConstants.space2),
              decoration: BoxDecoration(
                color: ThemeConstants.warning.withOpacity(ThemeConstants.opacity10),
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                boxShadow: ThemeConstants.shadowSm,
              ),
              child: Icon(
                icon,
                color: ThemeConstants.warning,
                size: ThemeConstants.iconLg,
              ),
            ),
            SizedBox(width: ThemeConstants.space3),
            Expanded(
              child: Text(
                'تم رفض إذن $typeName',
                style: TextStyle(
                  fontSize: ThemeConstants.textSizeLg,
                  fontWeight: ThemeConstants.bold,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لقد تم رفض إذن $typeName عدة مرات متتالية.',
              style: TextStyle(
                fontSize: ThemeConstants.textSizeMd,
                height: 1.6,
                color: context.textPrimaryColor,
              ),
            ),
            
            SizedBox(height: ThemeConstants.space4),
            
            // بطاقة الخطوات
            Container(
              padding: EdgeInsets.all(ThemeConstants.space3),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(ThemeConstants.opacity05),
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                border: Border.all(
                  color: context.primaryColor.withOpacity(ThemeConstants.opacity20),
                  width: ThemeConstants.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'يمكنك منح الإذن في أي وقت من خلال:',
                    style: TextStyle(
                      fontSize: ThemeConstants.textSizeSm,
                      fontWeight: ThemeConstants.semiBold,
                      color: context.primaryColor,
                    ),
                  ),
                  
                  SizedBox(height: ThemeConstants.space2),
                  
                  _buildStep(context, '١. فتح إعدادات التطبيق'),
                  _buildStep(context, '٢. الانتقال إلى "الأذونات"'),
                  _buildStep(context, '٣. تفعيل إذن $typeName'),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          ThemeConstants.space4,
          0,
          ThemeConstants.space4,
          ThemeConstants.space4,
        ),
        actions: [
          // زر فتح الإعدادات - استخدام AppButton
          AppButton.custom(
            text: 'فتح الإعدادات الآن',
            onPressed: () async {
              Navigator.pop(dialogContext);
              await AppSettings.openAppSettings();
            },
            icon: Icons.settings,
            size: ButtonSize.medium,
            isFullWidth: false,
            backgroundColor: ThemeConstants.warning,
            textColor: Colors.white,
          ),
          
          SizedBox(width: ThemeConstants.space2),
          
          // زر الإغلاق - استخدام AppButton
          AppButton.text(
            text: 'إغلاق',
            onPressed: () => Navigator.pop(dialogContext),
            size: ButtonSize.medium,
            color: context.textSecondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(top: ThemeConstants.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: ThemeConstants.iconSm,
            color: ThemeConstants.success,
          ),
          SizedBox(width: ThemeConstants.space2),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: ThemeConstants.textSizeSm,
                height: 1.5,
                color: context.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Analytics Tracker ====================

class _PermissionAnalytics implements PermissionAnalyticsTracker {
  @override
  void onDenied(Permission permission) {
    debugPrint('📊 Analytics: Permission denied - ${permission.toString()}');
  }

  @override
  void onPermanentlyDenied(Permission permission) {
    debugPrint('📊 Analytics: Permission permanently denied - ${permission.toString()}');
  }
}

// ==================== Models ====================

/// أنواع الأذونات
enum PermissionType {
  notification,
  location,
}

/// إدخال الـ Cache
class PermissionCacheEntry {
  final bool granted;
  final DateTime timestamp;

  PermissionCacheEntry({
    required this.granted,
    required this.timestamp,
  });
}

/// نتائج الأذونات
class PermissionResults {
  final bool notification;
  final bool location;

  const PermissionResults({
    required this.notification,
    required this.location,
  });

  bool get allGranted => notification && location;
  bool get anyGranted => notification || location;
  
  int get grantedCount {
    int count = 0;
    if (notification) count++;
    if (location) count++;
    return count;
  }

  List<PermissionType> get deniedPermissions {
    final denied = <PermissionType>[];
    if (!notification) denied.add(PermissionType.notification);
    if (!location) denied.add(PermissionType.location);
    return denied;
  }

  @override
  String toString() {
    return 'PermissionResults(notification: $notification, location: $location)';
  }
}

/// تغيير حالة الإذن
class PermissionChange {
  final PermissionType type;
  final bool isGranted;
  final DateTime timestamp;

  const PermissionChange({
    required this.type,
    required this.isGranted,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PermissionChange(${type.name}: $isGranted at $timestamp)';
  }
}