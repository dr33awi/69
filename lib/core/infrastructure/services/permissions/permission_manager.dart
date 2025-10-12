// lib/core/infrastructure/services/permissions/permission_manager.dart
// المدير الموحد للأذونات - نسخة محسّنة

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'permission_service.dart';
import 'permission_constants.dart';
import '../storage/storage_service.dart';

/// المدير الموحد لجميع عمليات الأذونات
/// 
/// يوفر:
/// - طلب الأذونات مع شرح
/// - معالجة الرفض الدائم
/// - حفظ حالة الأذونات
/// - فحص دوري
class UnifiedPermissionManager {
  final PermissionService _permissionService;
  final StorageService _storage;
  
  bool _hasCheckedThisSession = false;
  int? _androidVersion;
  
  UnifiedPermissionManager({
    required PermissionService permissionService,
    required StorageService storage,
  })  : _permissionService = permissionService,
        _storage = storage {
    _initAndroidVersion();
  }
  
  /// تهيئة إصدار Android
  Future<void> _initAndroidVersion() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        _androidVersion = androidInfo.version.sdkInt;
        debugPrint('[PermissionManager] Android version: $_androidVersion');
      } catch (e) {
        debugPrint('[PermissionManager] Error getting Android version: $e');
      }
    }
  }
  
  bool get hasCheckedThisSession => _hasCheckedThisSession;
  
  // ============== الفحص الأولي ==============
  
  /// الفحص الأولي للأذونات عند بدء التطبيق
  Future<void> performInitialCheck() async {
    if (_hasCheckedThisSession) {
      debugPrint('[PermissionManager] Already checked this session');
      return;
    }
    
    debugPrint('[PermissionManager] Performing initial permission check');
    _hasCheckedThisSession = true;
    
    try {
      final results = <AppPermissionType, AppPermissionStatus>{};
      
      // فحص جميع الأذونات الحرجة
      for (final permission in PermissionConstants.criticalPermissions) {
        final status = await _permissionService.checkPermissionStatus(permission);
        results[permission] = status;
        
        // حفظ الحالة
        await _savePermissionStatus(permission, status);
        
        // طباعة النتيجة
        _logPermissionStatus(permission, status);
      }
      
      // حفظ وقت آخر فحص
      await _storage.setString(
        'last_permission_check',
        DateTime.now().toIso8601String(),
      );
      
      debugPrint('[PermissionManager] Initial check completed: ${results.length} permissions checked');
      
    } catch (e, stackTrace) {
      debugPrint('[PermissionManager] Error in initial check: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  // ============== طلب الأذونات ==============
  
  /// طلب إذن واحد مع عرض شرح
  Future<bool> requestPermissionWithExplanation(
    BuildContext context,
    AppPermissionType type, {
    bool forceRequest = false,
    bool showExplanation = true,
  }) async {
    debugPrint('[PermissionManager] Requesting permission: ${type.name}');
    
    try {
      // 1. فحص الحالة الحالية
      final currentStatus = await _permissionService.checkPermissionStatus(type);
      
      // إذا كان مسموحاً بالفعل
      if (currentStatus == AppPermissionStatus.granted) {
        debugPrint('[PermissionManager] Permission already granted');
        return true;
      }
      
      // 2. معالجة الرفض الدائم
      if (currentStatus == AppPermissionStatus.permanentlyDenied) {
        debugPrint('[PermissionManager] Permission permanently denied');
        return await _handlePermanentlyDenied(context, type);
      }
      
      // 3. عرض الشرح (إذا لم يكن forceRequest)
      if (!forceRequest && showExplanation) {
        final shouldRequest = await _showPermissionExplanation(context, type);
        
        if (!shouldRequest) {
          debugPrint('[PermissionManager] User declined to grant permission');
          await _savePermissionDeclined(type);
          return false;
        }
      }
      
      // 4. طلب الإذن
      debugPrint('[PermissionManager] Requesting permission from system');
      final granted = await _permissionService.requestPermission(type);
      
      // 5. حفظ النتيجة
      await _savePermissionResult(type, granted);
      
      debugPrint('[PermissionManager] Permission request result: $granted');
      return granted;
      
    } catch (e, stackTrace) {
      debugPrint('[PermissionManager] Error requesting permission: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// طلب عدة أذونات بالتتابع
  Future<Map<AppPermissionType, bool>> requestMultiplePermissions(
    BuildContext context,
    List<AppPermissionType> permissions, {
    bool stopOnFirstDenial = false,
  }) async {
    debugPrint('[PermissionManager] Requesting ${permissions.length} permissions');
    
    final results = <AppPermissionType, bool>{};
    
    for (final permission in permissions) {
      final granted = await requestPermissionWithExplanation(context, permission);
      results[permission] = granted;
      
      if (stopOnFirstDenial && !granted) {
        debugPrint('[PermissionManager] Stopping due to denial');
        break;
      }
      
      // تأخير صغير بين الطلبات
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    return results;
  }
  
  // ============== فحص الأذونات ==============
  
  /// فحص حالة إذن واحد
  Future<AppPermissionStatus> checkPermissionStatus(
    AppPermissionType type,
  ) async {
    return await _permissionService.checkPermissionStatus(type);
  }
  
  /// فحص إذا كان الإذن ممنوحاً
  Future<bool> isPermissionGranted(AppPermissionType type) async {
    final status = await checkPermissionStatus(type);
    return status == AppPermissionStatus.granted;
  }
  
  /// فحص جميع الأذونات الحرجة
  Future<Map<AppPermissionType, AppPermissionStatus>> checkAllCriticalPermissions() async {
    final results = <AppPermissionType, AppPermissionStatus>{};
    
    for (final permission in PermissionConstants.criticalPermissions) {
      results[permission] = await checkPermissionStatus(permission);
    }
    
    return results;
  }
  
  /// فحص إذا كانت جميع الأذونات الحرجة ممنوحة
  Future<bool> areAllCriticalPermissionsGranted() async {
    for (final permission in PermissionConstants.criticalPermissions) {
      final granted = await isPermissionGranted(permission);
      if (!granted) return false;
    }
    return true;
  }
  
  // ============== معالجة الحالات الخاصة ==============
  
  /// معالجة الرفض الدائم
  Future<bool> _handlePermanentlyDenied(
    BuildContext context,
    AppPermissionType type,
  ) async {
    final info = _getPermissionInfo(type);
    
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('إذن مطلوب')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'يبدو أنك رفضت إذن "${info.title}" سابقاً.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(info.permanentlyDeniedMessage),
            const SizedBox(height: 12),
            const Text(
              'لتفعيل الإذن، يجب فتح إعدادات التطبيق يدوياً.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.settings, size: 20),
            label: const Text('فتح الإعدادات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    
    if (shouldOpenSettings == true) {
      return await _permissionService.openAppSettings();
    }
    
    return false;
  }
  
  /// عرض شرح الإذن قبل طلبه
  Future<bool> _showPermissionExplanation(
    BuildContext context,
    AppPermissionType type,
  ) async {
    final info = _getPermissionInfo(type);
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                info.icon,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(info.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.description,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.benefit,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              info.isCritical ? 'ليس الآن' : 'تخطي',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 20),
            label: const Text('السماح'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ) ?? false;
  }
  
  // ============== التخزين والسجلات ==============
  
  /// حفظ حالة الإذن
  Future<void> _savePermissionStatus(
    AppPermissionType type,
    AppPermissionStatus status,
  ) async {
    await _storage.setString(
      'permission_status_${type.name}',
      status.toString(),
    );
    await _storage.setString(
      'permission_status_time_${type.name}',
      DateTime.now().toIso8601String(),
    );
  }
  
  /// حفظ نتيجة طلب الإذن
  Future<void> _savePermissionResult(
    AppPermissionType type,
    bool granted,
  ) async {
    await _storage.setBool('permission_${type.name}_requested', true);
    await _storage.setBool('permission_${type.name}_granted', granted);
    await _storage.setString(
      'permission_${type.name}_request_time',
      DateTime.now().toIso8601String(),
    );
    
    final count = _storage.getInt('permission_${type.name}_request_count') ?? 0;
    await _storage.setInt('permission_${type.name}_request_count', count + 1);
  }
  
  /// حفظ رفض المستخدم
  Future<void> _savePermissionDeclined(AppPermissionType type) async {
    await _storage.setBool('permission_${type.name}_declined', true);
    await _storage.setString(
      'permission_${type.name}_decline_time',
      DateTime.now().toIso8601String(),
    );
  }
  
  /// طباعة حالة الإذن
  void _logPermissionStatus(AppPermissionType type, AppPermissionStatus status) {
    final emoji = status == AppPermissionStatus.granted ? '✅' : '❌';
    debugPrint('[PermissionManager] $emoji ${type.name}: $status');
  }
  
  // ============== معلومات الأذونات ==============
  
  /// الحصول على معلومات الإذن
  PermissionInfo _getPermissionInfo(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.location:
        return PermissionInfo(
          icon: Icons.location_on,
          title: 'إذن الموقع',
          description: 'نحتاج موقعك لتحديد أوقات الصلاة الدقيقة واتجاه القبلة بناءً على موقعك الحالي.',
          benefit: 'ستحصل على أوقات صلاة دقيقة واتجاه قبلة صحيح.',
          permanentlyDeniedMessage: 'إذن الموقع ضروري لعمل التطبيق بشكل صحيح. بدونه لن نتمكن من تحديد أوقات الصلاة واتجاه القبلة.',
          isCritical: true,
        );
        
      case AppPermissionType.backgroundLocation:
        return PermissionInfo(
          icon: Icons.my_location,
          title: 'الموقع في الخلفية',
          description: 'للحصول على تنبيهات ذكية بناءً على موقعك حتى عندما يكون التطبيق مغلقاً.',
          benefit: 'تنبيهات دقيقة حتى عند السفر أو تغيير الموقع.',
          permanentlyDeniedMessage: 'هذا الإذن اختياري لكنه يحسن دقة التنبيهات.',
          isCritical: false,
        );
        
      case AppPermissionType.notification:
        return PermissionInfo(
          icon: Icons.notifications_active,
          title: 'إذن الإشعارات',
          description: 'للتذكير بأذكار الصباح والمساء، وأوقات الصلاة، والأذكار المخصصة التي تضيفها.',
          benefit: 'لن تفوتك أي ذكر أو صلاة مع التنبيهات التلقائية.',
          permanentlyDeniedMessage: 'الإشعارات ضرورية لتذكيرك بالأذكار والصلوات. بدونها لن تتلقى أي تنبيهات.',
          isCritical: true,
        );
        
      case AppPermissionType.exactAlarm:
        return PermissionInfo(
          icon: Icons.alarm,
          title: 'التنبيهات الدقيقة',
          description: 'لضمان وصول التنبيهات في الوقت المحدد بالضبط، خاصة لأوقات الصلاة.',
          benefit: 'تنبيهات دقيقة 100% في الوقت المحدد بدون تأخير.',
          permanentlyDeniedMessage: 'هذا الإذن مهم لضمان دقة مواعيد الصلاة والأذكار.',
          isCritical: true,
        );
        
      case AppPermissionType.batteryOptimization:
        return PermissionInfo(
          icon: Icons.battery_charging_full,
          title: 'تحسين البطارية',
          description: 'لضمان عمل التطبيق في الخلفية وعدم إيقافه من قبل النظام.',
          benefit: 'التنبيهات ستعمل دائماً حتى مع وضع توفير الطاقة.',
          permanentlyDeniedMessage: 'بدون هذا الإذن، قد يوقف النظام التطبيق ولن تصلك التنبيهات.',
          isCritical: false,
        );
        
      case AppPermissionType.systemAlertWindow:
        return PermissionInfo(
          icon: Icons.picture_in_picture,
          title: 'النوافذ الطافية',
          description: 'لعرض تنبيهات سريعة فوق التطبيقات الأخرى عند وقت الأذكار.',
          benefit: 'تنبيهات فورية حتى أثناء استخدامك لتطبيقات أخرى.',
          permanentlyDeniedMessage: 'هذا الإذن اختياري لكنه يحسن تجربة التنبيهات.',
          isCritical: false,
        );
        
      default:
        return PermissionInfo(
          icon: Icons.security,
          title: 'إذن مطلوب',
          description: 'هذا الإذن مطلوب لعمل التطبيق بشكل صحيح.',
          benefit: 'سيعمل التطبيق بكامل ميزاته.',
          permanentlyDeniedMessage: 'يرجى السماح بهذا الإذن من الإعدادات.',
          isCritical: false,
        );
    }
  }
  
  // ============== الإحصائيات ==============
  
  /// الحصول على إحصائيات الأذونات
  Future<Map<String, dynamic>> getPermissionStatistics() async {
    final stats = <String, dynamic>{
      'checked_this_session': _hasCheckedThisSession,
      'android_version': _androidVersion,
      'last_check': _storage.getString('last_permission_check'),
      'permissions': <String, dynamic>{},
    };
    
    for (final permission in AppPermissionType.values) {
      stats['permissions'][permission.name] = {
        'requested': _storage.getBool('permission_${permission.name}_requested') ?? false,
        'granted': _storage.getBool('permission_${permission.name}_granted') ?? false,
        'declined': _storage.getBool('permission_${permission.name}_declined') ?? false,
        'request_count': _storage.getInt('permission_${permission.name}_request_count') ?? 0,
        'last_request_time': _storage.getString('permission_${permission.name}_request_time'),
        'status': _storage.getString('permission_status_${permission.name}'),
      };
    }
    
    return stats;
  }
  
  /// طباعة تقرير مفصل عن الأذونات
  Future<void> printPermissionReport() async {
    debugPrint('');
    debugPrint('========== Permission Report ==========');
    debugPrint('Session checked: $_hasCheckedThisSession');
    debugPrint('Android version: $_androidVersion');
    debugPrint('Last check: ${_storage.getString('last_permission_check')}');
    debugPrint('');
    
    for (final permission in PermissionConstants.criticalPermissions) {
      final status = await checkPermissionStatus(permission);
      final requested = _storage.getBool('permission_${permission.name}_requested') ?? false;
      final granted = _storage.getBool('permission_${permission.name}_granted') ?? false;
      final count = _storage.getInt('permission_${permission.name}_request_count') ?? 0;
      
      debugPrint('📋 ${permission.name}:');
      debugPrint('   Status: $status');
      debugPrint('   Requested: $requested');
      debugPrint('   Granted: $granted');
      debugPrint('   Request count: $count');
      debugPrint('');
    }
    
    debugPrint('======================================');
    debugPrint('');
  }
  
  // ============== إعادة تعيين ==============
  
  /// إعادة تعيين جميع بيانات الأذونات (للاختبار فقط)
  Future<void> resetAllPermissionData() async {
    debugPrint('[PermissionManager] Resetting all permission data');
    
    for (final permission in AppPermissionType.values) {
      await _storage.remove('permission_${permission.name}_requested');
      await _storage.remove('permission_${permission.name}_granted');
      await _storage.remove('permission_${permission.name}_declined');
      await _storage.remove('permission_${permission.name}_request_time');
      await _storage.remove('permission_${permission.name}_decline_time');
      await _storage.remove('permission_${permission.name}_request_count');
      await _storage.remove('permission_status_${permission.name}');
      await _storage.remove('permission_status_time_${permission.name}');
    }
    
    await _storage.remove('last_permission_check');
    _hasCheckedThisSession = false;
    
    debugPrint('[PermissionManager] Reset completed');
  }
  
  /// إعادة تعيين إذن واحد
  Future<void> resetPermission(AppPermissionType type) async {
    debugPrint('[PermissionManager] Resetting ${type.name}');
    
    await _storage.remove('permission_${type.name}_requested');
    await _storage.remove('permission_${type.name}_granted');
    await _storage.remove('permission_${type.name}_declined');
    await _storage.remove('permission_${type.name}_request_time');
    await _storage.remove('permission_${type.name}_decline_time');
    await _storage.remove('permission_${type.name}_request_count');
    await _storage.remove('permission_status_${type.name}');
    await _storage.remove('permission_status_time_${type.name}');
  }
  
  // ============== مساعدات ==============
  
  /// فحص إذا يجب إعادة طلب الإذن
  Future<bool> shouldRequestAgain(AppPermissionType type) async {
    // إذا كان ممنوحاً، لا داعي لإعادة الطلب
    if (await isPermissionGranted(type)) {
      return false;
    }
    
    // إذا كان مرفوضاً بشكل دائم، لا تطلب تلقائياً
    final status = await checkPermissionStatus(type);
    if (status == AppPermissionStatus.permanentlyDenied) {
      return false;
    }
    
    // فحص آخر مرة تم الطلب فيها
    final lastRequestTime = _storage.getString('permission_${type.name}_request_time');
    if (lastRequestTime == null) {
      return true; // لم يتم الطلب من قبل
    }
    
    final lastTime = DateTime.parse(lastRequestTime);
    final daysSince = DateTime.now().difference(lastTime).inDays;
    
    // إعادة الطلب بعد 7 أيام
    return daysSince >= 7;
  }
  
  /// الحصول على آخر وقت طلب
  DateTime? getLastRequestTime(AppPermissionType type) {
    final timeString = _storage.getString('permission_${type.name}_request_time');
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }
  
  /// الحصول على عدد مرات الطلب
  int getRequestCount(AppPermissionType type) {
    return _storage.getInt('permission_${type.name}_request_count') ?? 0;
  }
  
  /// فحص إذا كان الإذن مدعوماً في الجهاز الحالي
  bool isPermissionSupported(AppPermissionType type) {
    if (!Platform.isAndroid) return false;
    if (_androidVersion == null) return true; // افترض الدعم إذا لم نعرف الإصدار
    
    switch (type) {
      case AppPermissionType.notification:
        return _androidVersion! >= 33; // Android 13+
        
      case AppPermissionType.exactAlarm:
        return _androidVersion! >= 31; // Android 12+
        
      case AppPermissionType.backgroundLocation:
        return _androidVersion! >= 29; // Android 10+
        
      default:
        return true;
    }
  }
}

/// معلومات الإذن
class PermissionInfo {
  final IconData icon;
  final String title;
  final String description;
  final String benefit;
  final String permanentlyDeniedMessage;
  final bool isCritical;

  PermissionInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.benefit,
    required this.permanentlyDeniedMessage,
    required this.isCritical,
  });
}