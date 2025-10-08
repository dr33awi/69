// lib/features/settings/services/settings_services_manager.dart
// محدث: حذف reloadSettings غير المستخدمة

import 'package:flutter/material.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../app/themes/core/theme_notifier.dart';
import '../models/app_settings.dart';

/// مدير خدمات الإعدادات المبسط
/// يدير فقط الإعدادات التي لا تتعلق بالأذونات
class SettingsServicesManager {
  final StorageService _storage;
  final PermissionService _permissionService;
  final ThemeNotifier _themeNotifier;

  // مفاتيح الإعدادات
  static const String _settingsKey = 'app_settings';

  // الإعدادات الحالية
  AppSettings _currentSettings = const AppSettings();

  SettingsServicesManager({
    required StorageService storage,
    required PermissionService permissionService,
    required ThemeNotifier themeNotifier,
  }) : _storage = storage,
       _permissionService = permissionService,
       _themeNotifier = themeNotifier {
    _loadSettings();
  }

  // ==================== تحميل وحفظ الإعدادات ====================
  
  Future<void> _loadSettings() async {
    try {
      debugPrint('[SettingsManager] Loading settings...');
      
      // تحميل الإعدادات العامة من التخزين
      final settingsJson = _storage.getMap(_settingsKey);
      if (settingsJson != null) {
        _currentSettings = AppSettings.fromJson(settingsJson);
        debugPrint('[SettingsManager] Settings loaded from storage');
      } else {
        debugPrint('[SettingsManager] No saved settings found, using defaults');
      }
      
      // ThemeNotifier يحمل الثيم الخاص به بشكل منفصل
      debugPrint('[SettingsManager] Current theme: ${_themeNotifier.currentThemeName}');
      
    } catch (e) {
      debugPrint('[SettingsManager] Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final saved = await _storage.setMap(_settingsKey, _currentSettings.toJson());
      debugPrint('[SettingsManager] Settings saved: $saved');
    } catch (e) {
      debugPrint('[SettingsManager] Error saving settings: $e');
    }
  }

  // ==================== Getters ====================
  
  AppSettings get settings => _currentSettings;
  ThemeMode get currentTheme => _themeNotifier.value;
  String get currentThemeName => _themeNotifier.currentThemeName;
  bool get isDarkMode => _themeNotifier.isDarkMode;
  bool get vibrationEnabled => _currentSettings.vibrationEnabled;
  bool get notificationsEnabled => _currentSettings.notificationsEnabled;
  bool get prayerNotificationsEnabled => _currentSettings.prayerNotificationsEnabled;
  bool get athkarNotificationsEnabled => _currentSettings.athkarNotificationsEnabled;
  bool get soundEnabled => _currentSettings.soundEnabled;
  double get fontSize => _currentSettings.fontSize;
  
  // Getter للوصول المباشر لخدمة الأذونات
  PermissionService get permissionService => _permissionService;

  // ==================== Theme Settings ====================
  
  /// تغيير الثيم مع الحفظ التلقائي
  Future<bool> changeTheme(ThemeMode mode) async {
    debugPrint('[SettingsManager] Changing theme to: $mode');
    
    // استخدام ThemeNotifier's setTheme method الذي يحفظ تلقائياً
    final saved = await _themeNotifier.setTheme(mode);
    
    if (saved) {
      debugPrint('[SettingsManager] Theme changed successfully');
    } else {
      debugPrint('[SettingsManager] Failed to save theme');
    }
    
    return saved;
  }
  
  /// تبديل بين الوضع الليلي والنهاري
  Future<bool> toggleDarkMode() async {
    final newMode = _themeNotifier.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    return await changeTheme(newMode);
  }

  // ==================== إعدادات الإشعارات ====================
  
  Future<void> toggleVibration(bool enabled) async {
    _currentSettings = _currentSettings.copyWith(vibrationEnabled: enabled);
    await _saveSettings();
    debugPrint('[SettingsManager] Vibration toggled - enabled: $enabled');
  }

  Future<void> toggleNotifications(bool enabled) async {
    _currentSettings = _currentSettings.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
    
    if (enabled) {
      // طلب إذن الإشعارات إذا لزم الأمر
      final status = await _permissionService.checkPermissionStatus(AppPermissionType.notification);
      if (status != AppPermissionStatus.granted) {
        await _permissionService.requestPermission(AppPermissionType.notification);
      }
    }
    
    debugPrint('[SettingsManager] Notifications toggled - enabled: $enabled');
  }

  Future<void> togglePrayerNotifications(bool enabled) async {
    _currentSettings = _currentSettings.copyWith(prayerNotificationsEnabled: enabled);
    await _saveSettings();
    debugPrint('[SettingsManager] Prayer notifications toggled - enabled: $enabled');
  }

  Future<void> toggleAthkarNotifications(bool enabled) async {
    _currentSettings = _currentSettings.copyWith(athkarNotificationsEnabled: enabled);
    await _saveSettings();
    debugPrint('[SettingsManager] Athkar notifications toggled - enabled: $enabled');
  }

  // ==================== إعدادات إضافية ====================
  
  Future<void> toggleSound(bool enabled) async {
    _currentSettings = _currentSettings.copyWith(soundEnabled: enabled);
    await _saveSettings();
    debugPrint('[SettingsManager] Sound toggled - enabled: $enabled');
  }

  Future<void> changeFontSize(double size) async {
    _currentSettings = _currentSettings.copyWith(fontSize: size);
    await _saveSettings();
    debugPrint('[SettingsManager] Font size changed - size: $size');
  }

  // ==================== إعادة تعيين الإعدادات ====================
  
  Future<void> resetSettings() async {
    debugPrint('[SettingsManager] Resetting all settings...');
    
    try {
      // إعادة تعيين الإعدادات العامة
      _currentSettings = const AppSettings();
      await _storage.remove(_settingsKey);
      
      // إعادة تعيين الثيم إلى النظام
      await _themeNotifier.setTheme(ThemeMode.system);
      
      debugPrint('[SettingsManager] Settings reset completed successfully');
    } catch (e) {
      debugPrint('[SettingsManager] Error resetting settings: $e');
    }
  }

  // ==================== Cleanup ====================
  
  void dispose() {
    debugPrint('[SettingsManager] Disposing settings manager');
    // لا نحتاج dispose للـ ThemeNotifier هنا لأنه مسجل منفصل في ServiceLocator
  }
}