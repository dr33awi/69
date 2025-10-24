// lib/features/settings/services/settings_services_manager.dart

import 'package:flutter/material.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../app/themes/core/theme_notifier.dart';
import '../models/app_settings.dart';

/// مدير خدمات الإعدادات - مسؤول عن حفظ وتحميل الإعدادات والثيم
class SettingsServicesManager {
  final StorageService _storage;
  final ThemeNotifier _themeNotifier;

  // مفاتيح الإعدادات
  static const String _settingsKey = 'app_settings';

  // الإعدادات الحالية
  AppSettings _currentSettings = const AppSettings();

  SettingsServicesManager({
    required StorageService storage,
    required ThemeNotifier themeNotifier,
  }) : _storage = storage,
       _themeNotifier = themeNotifier {
    _loadSettings();
  }

  // ==================== تحميل وحفظ الإعدادات ====================
  
  Future<void> _loadSettings() async {
    try {
      final settingsJson = _storage.getMap(_settingsKey);
      if (settingsJson != null) {
        _currentSettings = AppSettings.fromJson(settingsJson);
        debugPrint('Settings loaded successfully');
      } else {
        debugPrint('No saved settings found, using defaults');
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final saved = await _storage.setMap(_settingsKey, _currentSettings.toJson());
      debugPrint('Settings saved: $saved');
    } catch (e) {
      debugPrint('Error saving settings: $e');
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

  // ==================== Theme Settings ====================
  
  Future<bool> changeTheme(ThemeMode mode) async {
    final saved = await _themeNotifier.setTheme(mode);
    
    if (saved) {
      debugPrint('Theme changed to: ${mode.name}');
    } else {
      debugPrint('Failed to change theme');
    }
    
    return saved;
  }
  
  Future<bool> toggleDarkMode() async {
    final newMode = _themeNotifier.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    return await changeTheme(newMode);
  }

  // ==================== إعدادات الإشعارات ====================
  
  Future<void> toggleVibration(bool enabled) async {
    _currentSettings = _currentSettings.copyWith(vibrationEnabled: enabled);
    await _saveSettings();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _currentSettings = _currentSettings.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> togglePrayerNotifications(bool enabled) async {
    _currentSettings = _currentSettings.copyWith(prayerNotificationsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> toggleAthkarNotifications(bool enabled) async {
    _currentSettings = _currentSettings.copyWith(athkarNotificationsEnabled: enabled);
    await _saveSettings();
  }

  // ==================== إعدادات إضافية ====================
  
  Future<void> toggleSound(bool enabled) async {
    _currentSettings = _currentSettings.copyWith(soundEnabled: enabled);
    await _saveSettings();
  }

  Future<void> changeFontSize(double size) async {
    _currentSettings = _currentSettings.copyWith(fontSize: size);
    await _saveSettings();
  }

  // ==================== إعادة تعيين الإعدادات ====================
  
  Future<void> resetSettings() async {
    try {
      _currentSettings = const AppSettings();
      await _storage.remove(_settingsKey);
      await _themeNotifier.setTheme(ThemeMode.system);
      debugPrint('Settings reset successfully');
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }
  }

  // ==================== Cleanup ====================
  
  void dispose() {
    debugPrint('SettingsServicesManager disposed');
  }
}