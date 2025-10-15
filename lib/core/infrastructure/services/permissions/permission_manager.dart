// lib/core/infrastructure/services/permissions/permission_manager.dart
// محدث: حل مشاكل التكرار والتضارب

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'permission_service.dart';
import 'permission_constants.dart';
import 'models/permission_state.dart';
import 'widgets/permission_dialogs.dart';
import '../storage/storage_service.dart';

/// مدير الأذونات الموحد المحسن - بدون تكرار
class UnifiedPermissionManager {
  final PermissionService _permissionService;
  
  // Singleton instance
  static UnifiedPermissionManager? _instance;
  
  // آخر نتيجة فحص
  PermissionCheckResult? _lastCheckResult;
  PermissionCheckResult? _lastEmittedResult; // لتتبع آخر نتيجة تم إرسالها
  
  // Streams للمراقبة
  final _stateController = StreamController<PermissionCheckResult>.broadcast();
  final _changeController = StreamController<PermissionChangeEvent>.broadcast();
  
  Stream<PermissionCheckResult> get stateStream => _stateController.stream;
  Stream<PermissionChangeEvent> get changeStream => _changeController.stream;
  
  // منع التكرار
  bool _hasCheckedThisSession = false;
  bool _isCheckInProgress = false; // لمنع الفحص المتزامن
  DateTime? _lastCheckTime;
  
  // استخدام الثوابت الموحدة من PermissionConstants
  static const Duration _minCheckInterval = Duration(seconds: 3); // موحد مع PermissionConstants
  
  // استخدام PermissionConstants بدلاً من التكرار
  List<AppPermissionType> get criticalPermissions => 
      PermissionConstants.criticalPermissions;
  
  // Constructor خاص للـ Singleton
  UnifiedPermissionManager._({
    required PermissionService permissionService,
    required StorageService storage,
  }) : _permissionService = permissionService {
    _initialize();
  }
  
  /// Factory method للحصول على instance واحد
  factory UnifiedPermissionManager.getInstance({
    required PermissionService permissionService,
    required StorageService storage,
  }) {
    _instance ??= UnifiedPermissionManager._(
      permissionService: permissionService,
      storage: storage,
    );
    return _instance!;
  }
  
  /// التهيئة
  void _initialize() {
    _setupPermissionChangeListener();
    _log('✅ Initialized (Without Onboarding)');
  }
  
  /// الاستماع لتغييرات الأذونات من PermissionService
  void _setupPermissionChangeListener() {
    _permissionService.permissionChanges.listen((change) {
      final event = PermissionChangeEvent(
        permission: change.permission,
        oldStatus: change.oldStatus,
        newStatus: change.newStatus,
      );
      
      _changeController.add(event);
      
      _log('🔄 Permission change detected', {
        'permission': change.permission.toString(),
        'oldStatus': change.oldStatus.toString(),
        'newStatus': change.newStatus.toString(),
      });
    });
  }
  
  // ==================== Getters ====================
  
  bool get hasCheckedThisSession => _hasCheckedThisSession;
  PermissionCheckResult? get lastCheckResult => _lastCheckResult;
  bool get isCheckInProgress => _isCheckInProgress;
  
  // ==================== الدوال الرئيسية ====================
  
  /// الفحص الأولي - يُستدعى مرة واحدة عند بدء التطبيق
  Future<PermissionCheckResult> performInitialCheck() async {
    // منع التكرار والفحص المتزامن
    if (_hasCheckedThisSession) {
      _log('⚠️ Already checked this session, returning cached result');
      return _lastCheckResult ?? PermissionCheckResult.success();
    }
    
    if (_isCheckInProgress) {
      _log('⏳ Check already in progress, waiting...');
      // انتظار انتهاء الفحص الحالي
      while (_isCheckInProgress) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _lastCheckResult ?? PermissionCheckResult.success();
    }
    
    _isCheckInProgress = true;
    _hasCheckedThisSession = true;
    _lastCheckTime = DateTime.now();
    
    _log('🔍 Performing initial check (ONCE per session)');
    
    try {
      // فحص الأذونات الحرجة فقط
      final result = await _checkCriticalPermissions();
      
      _lastCheckResult = result;
      _lastEmittedResult = result;
      _stateController.add(result);
      
      _logCheckResult(result);
      
      return result;
      
    } catch (e, s) {
      _logError('Initial check failed', e, s);
      
      final errorResult = PermissionCheckResult.error(e.toString());
      _lastCheckResult = errorResult;
      _stateController.add(errorResult);
      
      return errorResult;
    } finally {
      _isCheckInProgress = false;
    }
  }
  
  /// فحص سريع عند الحاجة (عند العودة من الخلفية أو الإعدادات)
  Future<PermissionCheckResult> performQuickCheck() async {
    // التحقق من الفترة الزمنية مع Throttling محسّن
    if (_lastCheckTime != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastCheckTime!);
      if (timeSinceLastCheck < _minCheckInterval) {
        _log('⏱️ Check throttled (${timeSinceLastCheck.inMilliseconds}ms < ${_minCheckInterval.inMilliseconds}ms)');
        return _lastCheckResult ?? PermissionCheckResult.success();
      }
    }
    
    // منع الفحص المتزامن
    if (_isCheckInProgress) {
      _log('⏳ Check already in progress, returning last result');
      return _lastCheckResult ?? PermissionCheckResult.success();
    }
    
    _isCheckInProgress = true;
    _lastCheckTime = DateTime.now();
    _log('🔍 Performing quick check');
    
    try {
      final result = await _checkCriticalPermissions();
      
      // تحديث وإرسال النتيجة فقط إذا تغيرت بشكل فعلي
      if (_hasResultChangedSignificantly(result)) {
        _lastCheckResult = result;
        _lastEmittedResult = result;
        _stateController.add(result);
        _logCheckResult(result);
      } else {
        _log('ℹ️ No significant change in permissions status');
      }
      
      return result;
    } catch (e) {
      _logError('Quick check failed', e);
      return _lastCheckResult ?? PermissionCheckResult.error(e.toString());
    } finally {
      _isCheckInProgress = false;
    }
  }
  
  /// فحص الأذونات الحرجة فقط
  Future<PermissionCheckResult> _checkCriticalPermissions() async {
    final granted = <AppPermissionType>[];
    final missing = <AppPermissionType>[];
    final statuses = <AppPermissionType, AppPermissionStatus>{};
    
    // فحص الأذونات الحرجة بشكل متوازي
    final futures = <Future<void>>[];
    
    for (final permission in criticalPermissions) {
      futures.add(
        _checkSinglePermission(permission).then((status) {
          statuses[permission] = status;
          if (status == AppPermissionStatus.granted) {
            granted.add(permission);
            debugPrint('  ✅ $permission: GRANTED');
          } else {
            missing.add(permission);
            debugPrint('  ❌ $permission: ${status.toString().split('.').last}');
          }
        }).catchError((error) {
          debugPrint('  ⚠️ Error checking $permission: $error');
          missing.add(permission);
          statuses[permission] = AppPermissionStatus.unknown;
        }),
      );
    }
    
    // انتظار جميع الفحوصات
    await Future.wait(futures, eagerError: false);
    
    if (missing.isEmpty) {
      return PermissionCheckResult.success(
        granted: granted,
        statuses: statuses,
      );
    } else {
      return PermissionCheckResult.partial(
        granted: granted,
        missing: missing,
        statuses: statuses,
      );
    }
  }
  
  /// فحص إذن واحد
  Future<AppPermissionStatus> _checkSinglePermission(AppPermissionType permission) async {
    try {
      return await _permissionService.checkPermissionStatus(permission);
    } catch (e) {
      _logWarning('Failed to check permission', {
        'permission': permission.toString(), 
        'error': e.toString()
      });
      return AppPermissionStatus.unknown;
    }
  }
  
  /// طلب إذن محدد مع عرض الشرح
  Future<bool> requestPermissionWithExplanation(
    BuildContext context,
    AppPermissionType permission, {
    String? customMessage,
    bool forceRequest = false,
  }) async {
    _log('📱 Requesting permission', {
      'permission': permission.toString(),
      'forceRequest': forceRequest,
    });
    
    // فحص الحالة الحالية
    final currentStatus = await _permissionService.checkPermissionStatus(permission);
    
    if (currentStatus == AppPermissionStatus.granted) {
      _log('✅ Permission already granted');
      return true;
    }
    
    // إذا كان مرفوض نهائياً، فتح الإعدادات
    if (currentStatus == AppPermissionStatus.permanentlyDenied) {
      if (context.mounted) {
        await PermissionDialogs.showSettingsDialog(
          context: context,
          permissions: [permission],
          onOpenSettings: () => _permissionService.openAppSettings(),
        );
      }
      return false;
    }
    
    // عرض شرح الإذن
    if (context.mounted && !forceRequest) {
      final shouldRequest = await PermissionDialogs.showSinglePermission(
        context: context,
        permission: permission,
        customMessage: customMessage,
      );
      
      if (!shouldRequest) {
        _log('❌ User cancelled permission request');
        return false;
      }
    }
    
    // طلب الإذن
    HapticFeedback.lightImpact();
    final newStatus = await _permissionService.requestPermission(permission);
    
    final granted = newStatus == AppPermissionStatus.granted;
    
    _log('📊 Permission request result', {
      'permission': permission.toString(),
      'granted': granted,
      'status': newStatus.toString(),
    });
    
    // إرسال حدث التغيير
    _changeController.add(PermissionChangeEvent(
      permission: permission,
      oldStatus: currentStatus,
      newStatus: newStatus,
      wasUserInitiated: true,
    ));
    
    // فحص سريع بعد الطلب
    if (granted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        performQuickCheck();
      });
    }
    
    return granted;
  }
  
  /// طلب أذونات متعددة
  Future<PermissionCheckResult> requestMultiplePermissions(
    BuildContext context,
    List<AppPermissionType> permissions, {
    bool showExplanation = true,
  }) async {
    _log('📱 Requesting multiple permissions', {
      'count': permissions.length,
    });
    
    // عرض شرح الأذونات
    if (showExplanation && context.mounted) {
      final shouldContinue = await PermissionDialogs.showExplanation(
        context: context,
        permissions: permissions,
      );
      
      if (!shouldContinue) {
        _log('❌ User cancelled batch request');
        return PermissionCheckResult.error('User cancelled');
      }
    }
    
    // طلب الأذونات
    final granted = <AppPermissionType>[];
    final missing = <AppPermissionType>[];
    final statuses = <AppPermissionType, AppPermissionStatus>{};
    
    for (final permission in permissions) {
      try {
        final status = await _permissionService.requestPermission(permission);
        statuses[permission] = status;
        
        if (status == AppPermissionStatus.granted) {
          granted.add(permission);
        } else {
          missing.add(permission);
        }
        
        // تأخير بسيط بين الطلبات
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        _logError('Failed to request permission', e);
        missing.add(permission);
      }
    }
    
    final result = missing.isEmpty
        ? PermissionCheckResult.success(granted: granted, statuses: statuses)
        : PermissionCheckResult.partial(
            granted: granted,
            missing: missing,
            statuses: statuses,
          );
    
    // عرض النتيجة
    if (context.mounted) {
      await PermissionDialogs.showResultDialog(
        context: context,
        granted: granted,
        denied: missing,
      );
    }
    
    // تحديث الحالة
    _lastCheckResult = result;
    _lastEmittedResult = result;
    _stateController.add(result);
    
    return result;
  }
  
  /// فتح إعدادات التطبيق
  Future<bool> openAppSettings() async {
    _log('⚙️ Opening app settings');
    return await _permissionService.openAppSettings();
  }
  
  /// إعادة تعيين (للتطوير والاختبار)
  Future<void> reset() async {
    _logWarning('🔄 Resetting all data');
    
    _hasCheckedThisSession = false;
    _isCheckInProgress = false;
    _lastCheckTime = null;
    _lastCheckResult = null;
    _lastEmittedResult = null;
    
    _log('✅ Reset completed');
  }
  
  /// التنظيف
  void dispose() {
    _log('🛑 Disposing');
    _stateController.close();
    _changeController.close();
    _instance = null;
  }
  
  // ==================== دوال مساعدة ====================
  
  /// التحقق من تغيير النتيجة بشكل جوهري
  bool _hasResultChangedSignificantly(PermissionCheckResult newResult) {
    if (_lastEmittedResult == null) return true;
    
    // التحقق من تغيير في عدد الأذونات
    if (_lastEmittedResult!.missingCount != newResult.missingCount ||
        _lastEmittedResult!.grantedCount != newResult.grantedCount) {
      return true;
    }
    
    // التحقق من تغيير في الحالات
    for (final entry in newResult.statuses.entries) {
      final oldStatus = _lastEmittedResult!.statuses[entry.key];
      if (oldStatus != entry.value) {
        // تغيير حقيقي في حالة الإذن
        if (_isSignificantStatusChange(oldStatus, entry.value)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// التحقق من أن التغيير في الحالة مهم
  bool _isSignificantStatusChange(
    AppPermissionStatus? oldStatus, 
    AppPermissionStatus newStatus
  ) {
    // التغييرات المهمة فقط
    if (oldStatus == AppPermissionStatus.granted && newStatus != AppPermissionStatus.granted) {
      return true; // فقدان الإذن
    }
    if (oldStatus != AppPermissionStatus.granted && newStatus == AppPermissionStatus.granted) {
      return true; // الحصول على الإذن
    }
    if (oldStatus != AppPermissionStatus.permanentlyDenied && 
        newStatus == AppPermissionStatus.permanentlyDenied) {
      return true; // أصبح مرفوض نهائياً
    }
    
    return false;
  }
  
  /// تسجيل نتيجة الفحص
  void _logCheckResult(PermissionCheckResult result) {
    _log('📊 Check result', {
      'allGranted': result.allGranted,
      'grantedCount': result.grantedCount,
      'missingCount': result.missingCount,
      'hasCriticalMissing': result.hasCriticalMissing,
    });
    
    if (result.missingPermissions.isNotEmpty) {
      _logWarning('⚠️ Missing permissions', {
        'missing': result.missingPermissions.map((p) => p.toString().split('.').last).toList(),
      });
    }
  }

  // ==================== Simple Logging Methods ====================

  void _log(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      debugPrint('🔐 [$timestamp] [PermissionManager] $message${data != null ? " - $data" : ""}');
    }
  }

  void _logWarning(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      debugPrint('⚠️ [$timestamp] [PermissionManager] WARNING: $message${data != null ? " - $data" : ""}');
    }
  }

  void _logError(String message, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      debugPrint('🔴 [$timestamp] [PermissionManager] ERROR: $message - $error');
      if (stackTrace != null && kDebugMode) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}