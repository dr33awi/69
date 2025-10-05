// lib/core/infrastructure/firebase/special_event/services/event_data_service.dart


import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:athkar_app/core/infrastructure/firebase/remote_config_manager.dart';
import 'package:athkar_app/core/infrastructure/firebase/remote_config_service.dart';
/// خدمة جلب بيانات المناسبة من Firebase Remote Config
class EventDataService {
  final GetIt _getIt;
  
  EventDataService(this._getIt);
  
  /// جلب البيانات من المصادر المتاحة
  Future<Map<String, dynamic>?> fetchEventData() async {
    debugPrint('🎉 [EventDataService] Starting to fetch event data...');
    
    // محاولة من FirebaseRemoteConfigService
    final dataFromService = await _fetchFromRemoteConfigService();
    if (dataFromService != null) {
      debugPrint('✅ [EventDataService] Successfully fetched data from RemoteConfigService');
      return dataFromService;
    }
    
    // محاولة من RemoteConfigManager
    final dataFromManager = await _fetchFromRemoteConfigManager();
    if (dataFromManager != null) {
      debugPrint('✅ [EventDataService] Successfully fetched data from RemoteConfigManager');
      return dataFromManager;
    }
    
    debugPrint('ℹ️ [EventDataService] No event data found in any source');
    return null;
  }
  
  /// جلب من FirebaseRemoteConfigService مباشرة
  Future<Map<String, dynamic>?> _fetchFromRemoteConfigService() async {
    try {
      // التحقق من تسجيل الخدمة
      if (!_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        debugPrint('⚠️ [EventDataService] FirebaseRemoteConfigService not registered');
        return null;
      }
      
      final remoteConfig = _getIt<FirebaseRemoteConfigService>();
      
      // التحقق من تهيئة الخدمة
      if (!remoteConfig.isInitialized) {
        debugPrint('⚠️ [EventDataService] FirebaseRemoteConfigService not initialized');
        return null;
      }
      
      // جلب بيانات المناسبة
      final data = remoteConfig.specialEventData;
      
      // التحقق من وجود البيانات وصحتها
      if (data != null && data.isNotEmpty) {
        // التحقق من أن المناسبة نشطة
        final isActive = data['is_active'] ?? false;
        if (isActive == true) {
          debugPrint('📊 [EventDataService] Event data found: ${data['title']}');
          return data;
        } else {
          debugPrint('⚠️ [EventDataService] Event exists but is not active');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [EventDataService] Error fetching from RemoteConfigService: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    return null;
  }
  
  /// جلب من RemoteConfigManager
  Future<Map<String, dynamic>?> _fetchFromRemoteConfigManager() async {
    try {
      // التحقق من تسجيل المدير
      if (!_getIt.isRegistered<RemoteConfigManager>()) {
        debugPrint('⚠️ [EventDataService] RemoteConfigManager not registered');
        return null;
      }
      
      final manager = _getIt<RemoteConfigManager>();
      
      // التحقق من تهيئة المدير
      if (!manager.isInitialized) {
        debugPrint('⚠️ [EventDataService] RemoteConfigManager not initialized, skipping...');
        // لا نحاول التهيئة هنا لأنها تحتاج parameters
        return null;
      }
      
      // محاولة الحصول على الخدمة من خلال المدير
      if (_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final service = _getIt<FirebaseRemoteConfigService>();
        final data = service.specialEventData;
        
        if (data != null && data.isNotEmpty) {
          final isActive = data['is_active'] ?? false;
          if (isActive == true) {
            debugPrint('📊 [EventDataService] Event data found via Manager: ${data['title']}');
            return data;
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [EventDataService] Error fetching from RemoteConfigManager: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    return null;
  }
  
  /// تحديث البيانات من Firebase (للاستخدام اليدوي)
  Future<bool> refreshEventData() async {
    try {
      debugPrint('🔄 [EventDataService] Refreshing event data...');
      
      if (_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final remoteConfig = _getIt<FirebaseRemoteConfigService>();
        
        // محاولة جلب آخر التحديثات من Firebase
        // استخدم refresh() بدلاً من fetchAndActivate()
        await remoteConfig.refresh();
        
        debugPrint('✅ [EventDataService] Event data refreshed successfully');
        return true;
      }
    } catch (e) {
      debugPrint('❌ [EventDataService] Error refreshing event data: $e');
    }
    
    return false;
  }
  
  /// التحقق من توفر الخدمات
  bool get isServiceAvailable {
    final hasRemoteConfig = _getIt.isRegistered<FirebaseRemoteConfigService>();
    final hasManager = _getIt.isRegistered<RemoteConfigManager>();
    
    if (!hasRemoteConfig && !hasManager) {
      debugPrint('⚠️ [EventDataService] No Firebase services available');
      return false;
    }
    
    if (hasRemoteConfig) {
      final service = _getIt<FirebaseRemoteConfigService>();
      if (service.isInitialized) return true;
    }
    
    if (hasManager) {
      final manager = _getIt<RemoteConfigManager>();
      if (manager.isInitialized) return true;
    }
    
    return false;
  }
  
  /// الحصول على البيانات المخزنة محلياً (للاستخدام دون اتصال)
  Map<String, dynamic>? getCachedEventData() {
    try {
      if (_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final remoteConfig = _getIt<FirebaseRemoteConfigService>();
        final data = remoteConfig.specialEventData;
        
        if (data != null && data.isNotEmpty) {
          debugPrint('📦 [EventDataService] Using cached event data');
          return data;
        }
      }
    } catch (e) {
      debugPrint('❌ [EventDataService] Error getting cached data: $e');
    }
    
    return null;
  }
}