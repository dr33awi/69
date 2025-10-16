// lib/core/infrastructure/firebase/special_event/services/event_data_service.dart
// النسخة المُبسّطة - مصدر واحد فقط

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:athkar_app/core/infrastructure/firebase/remote_config_service.dart';

/// خدمة جلب بيانات المناسبة - مُبسّطة
class EventDataService {
  final GetIt _getIt;
  
  EventDataService(this._getIt);
  
  /// جلب البيانات من Remote Config مباشرة
  Future<Map<String, dynamic>?> fetchEventData() async {
    debugPrint('🎉 [EventDataService] Fetching event data...');
    
    try {
      // ✅ مصدر واحد فقط
      if (!_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        debugPrint('⚠️ FirebaseRemoteConfigService not registered');
        return null;
      }
      
      final remoteConfig = _getIt<FirebaseRemoteConfigService>();
      
      if (!remoteConfig.isInitialized) {
        debugPrint('⚠️ FirebaseRemoteConfigService not initialized');
        return null;
      }
      
      final data = remoteConfig.specialEventData;
      
      if (data != null && data.isNotEmpty) {
        final isActive = data['is_active'] ?? false;
        
        if (isActive == true) {
          debugPrint('✅ Event data found: ${data['title']}');
          return data;
        } else {
          debugPrint('ℹ️ Event exists but is not active');
        }
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching event data: $e');
      debugPrint('Stack: $stackTrace');
    }
    
    return null;
  }
  
  /// تحديث البيانات من Firebase
  Future<bool> refreshEventData() async {
    try {
      debugPrint('🔄 Refreshing event data...');
      
      if (_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final remoteConfig = _getIt<FirebaseRemoteConfigService>();
        await remoteConfig.refresh();
        
        debugPrint('✅ Event data refreshed');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Refresh error: $e');
    }
    
    return false;
  }
  
  /// التحقق من توفر الخدمة
  bool get isServiceAvailable {
    if (!_getIt.isRegistered<FirebaseRemoteConfigService>()) {
      return false;
    }
    
    final service = _getIt<FirebaseRemoteConfigService>();
    return service.isInitialized;
  }
  
  /// البيانات المخزنة محلياً
  Map<String, dynamic>? getCachedEventData() {
    try {
      if (_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final remoteConfig = _getIt<FirebaseRemoteConfigService>();
        return remoteConfig.specialEventData;
      }
    } catch (e) {
      debugPrint('❌ Error getting cached data: $e');
    }
    
    return null;
  }
}