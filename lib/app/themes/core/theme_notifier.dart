// lib/app/themes/core/theme_notifier.dart

import 'package:flutter/material.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';

/// Theme Notifier لإدارة حالة الثيم
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  final StorageService _storage;
  static const String _themeKey = 'app_theme_mode';
  
  ThemeNotifier(this._storage) : super(ThemeMode.system) {
    _loadTheme();
  }
  
  /// تحميل الثيم المحفوظ
  Future<void> _loadTheme() async {
    try {
      debugPrint('[ThemeNotifier] Loading saved theme...');
      final savedTheme = _storage.getString(_themeKey);
      
      if (savedTheme != null) {
        // تحويل النص المحفوظ إلى ThemeMode
        switch (savedTheme) {
          case 'light':
            value = ThemeMode.light;
            debugPrint('[ThemeNotifier] Loaded theme: Light');
            break;
          case 'dark':
            value = ThemeMode.dark;
            debugPrint('[ThemeNotifier] Loaded theme: Dark');
            break;
          case 'system':
            value = ThemeMode.system;
            debugPrint('[ThemeNotifier] Loaded theme: System');
            break;
          default:
            // في حالة قيمة غير معروفة، استخدم النظام
            value = ThemeMode.system;
            debugPrint('[ThemeNotifier] Unknown theme value, using system');
        }
      } else {
        debugPrint('[ThemeNotifier] No saved theme found, using system default');
      }
    } catch (e) {
      debugPrint('[ThemeNotifier] Error loading theme: $e');
      value = ThemeMode.system;
    }
  }
  
  /// حفظ الثيم
  Future<bool> _saveTheme() async {
    try {
      // تحويل ThemeMode إلى نص للحفظ
      String themeString;
      switch (value) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      
      final saved = await _storage.setString(_themeKey, themeString);
      debugPrint('[ThemeNotifier] Theme saved: $themeString - Success: $saved');
      return saved;
    } catch (e) {
      debugPrint('[ThemeNotifier] Error saving theme: $e');
      return false;
    }
  }
  
  /// تغيير الثيم مع الحفظ
  Future<bool> setTheme(ThemeMode mode) async {
    debugPrint('[ThemeNotifier] Changing theme to: $mode');
    
    // تحديث القيمة
    value = mode;
    
    // حفظ الثيم
    final saved = await _saveTheme();
    
    // إشعار المستمعين بالتغيير
    notifyListeners();
    
    return saved;
  }
  
  /// تبديل بين الوضع الليلي والنهاري
  Future<bool> toggleTheme() async {
    final newMode = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    return await setTheme(newMode);
  }
  
  /// الحصول على اسم الثيم الحالي
  String get currentThemeName {
    switch (value) {
      case ThemeMode.light:
        return 'الوضع النهاري';
      case ThemeMode.dark:
        return 'الوضع الليلي';
      case ThemeMode.system:
        return 'حسب النظام';
    }
  }
  
  /// فحص إذا كان الوضع الليلي مفعل
  bool get isDarkMode {
    return value == ThemeMode.dark;
  }
  
  /// فحص إذا كان الوضع النهاري مفعل
  bool get isLightMode {
    return value == ThemeMode.light;
  }
  
  /// فحص إذا كان يتبع النظام
  bool get isSystemMode {
    return value == ThemeMode.system;
  }
  
  @override
  void dispose() {
    debugPrint('[ThemeNotifier] Disposing theme notifier');
    super.dispose();
  }
}