// lib/core/infrastructure/services/text/service/text_settings_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../storage/storage_service.dart';
import '../models/text_settings_models.dart';
import '../constants/text_settings_constants.dart'; // ✅ المسار الصحيح

/// خدمة موحدة لإدارة إعدادات النصوص في التطبيق
class TextSettingsService extends ChangeNotifier {
  final StorageService _storage;
  
  // Cache للإعدادات
  final Map<ContentType, TextSettings> _settingsCache = {};
  final Map<ContentType, DisplaySettings> _displaySettingsCache = {};
  
  // إعدادات عامة
  String? _globalFontFamily;
  String? _lastUsedPreset;
  
  // حالة التحميل
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  TextSettingsService({required StorageService storage}) : _storage = storage {
    _initialize();
  }
  
  /// تهيئة الخدمة
  Future<void> _initialize() async {
    _setLoading(true);
    try {
      await _loadGlobalSettings();
      await _migrateOldSettings();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }
  
  /// تحميل الإعدادات العامة
  Future<void> _loadGlobalSettings() async {
    try {
      _globalFontFamily = _storage.getString(TextSettingsConstants.globalFontFamilyKey);
      _lastUsedPreset = _storage.getString(TextSettingsConstants.lastUsedPresetKey);
    } catch (e) {
      // تجاهل الأخطاء واستخدام القيم الافتراضية
    }
  }
  
  // ==================== إدارة الإعدادات ====================
  
  /// الحصول على إعدادات نص لنوع محتوى معين
  Future<TextSettings> getTextSettings(ContentType contentType) async {
    try {
      if (_settingsCache.containsKey(contentType)) {
        return _settingsCache[contentType]!;
      }
      
      final key = TextSettingsConstants.getSettingsKey(contentType);
      final jsonData = _storage.getMap(key);
      
      TextSettings settings;
      if (jsonData != null) {
        settings = TextSettings.fromJson(jsonData, contentType);
        
        if (_globalFontFamily != null) {
          settings = settings.copyWith(fontFamily: _globalFontFamily);
        }
      } else {
        settings = TextSettingsConstants.getDefaultSettings(contentType);
        
        if (_globalFontFamily != null) {
          settings = settings.copyWith(fontFamily: _globalFontFamily);
        }
        
        await saveTextSettings(settings);
      }
      
      _settingsCache[contentType] = settings;
      
      return settings;
    } catch (e) {
      final defaultSettings = TextSettingsConstants.getDefaultSettings(contentType);
      _settingsCache[contentType] = defaultSettings;
      return defaultSettings;
    }
  }
  
  /// حفظ إعدادات النص
  Future<void> saveTextSettings(TextSettings settings) async {
    try {
      final key = TextSettingsConstants.getSettingsKey(settings.contentType);
      await _storage.setMap(key, settings.toJson());
      
      _settingsCache[settings.contentType] = settings;
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  /// الحصول على إعدادات العرض
  Future<DisplaySettings> getDisplaySettings(ContentType contentType) async {
    try {
      if (_displaySettingsCache.containsKey(contentType)) {
        return _displaySettingsCache[contentType]!;
      }
      
      final key = TextSettingsConstants.getDisplaySettingsKey(contentType);
      final jsonData = _storage.getMap(key);
      
      DisplaySettings settings;
      if (jsonData != null) {
        settings = DisplaySettings.fromJson(jsonData);
      } else {
        settings = TextSettingsConstants.defaultDisplaySettings;
        await saveDisplaySettings(contentType, settings);
      }
      
      _displaySettingsCache[contentType] = settings;
      
      return settings;
    } catch (e) {
      const defaultSettings = TextSettingsConstants.defaultDisplaySettings;
      _displaySettingsCache[contentType] = defaultSettings;
      return defaultSettings;
    }
  }
  
  /// حفظ إعدادات العرض
  Future<void> saveDisplaySettings(ContentType contentType, DisplaySettings settings) async {
    try {
      final key = TextSettingsConstants.getDisplaySettingsKey(contentType);
      await _storage.setMap(key, settings.toJson());
      
      _displaySettingsCache[contentType] = settings;
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  // ==================== إدارة الخط العام ====================
  
  /// تعيين خط عام لجميع أنواع المحتوى
  Future<void> setGlobalFontFamily(String? fontFamily) async {
    try {
      _globalFontFamily = fontFamily;
      
      if (fontFamily != null) {
        final validatedFont = TextSettingsConstants.validateFontFamily(fontFamily);
        await _storage.setString(TextSettingsConstants.globalFontFamilyKey, validatedFont);
        
        for (final contentType in _settingsCache.keys) {
          final currentSettings = _settingsCache[contentType]!;
          final updatedSettings = currentSettings.copyWith(fontFamily: validatedFont);
          await saveTextSettings(updatedSettings);
        }
      } else {
        await _storage.remove(TextSettingsConstants.globalFontFamilyKey);
        
        for (final contentType in ContentType.values) {
          final defaultSettings = TextSettingsConstants.getDefaultSettings(contentType);
          await saveTextSettings(defaultSettings);
        }
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  /// الحصول على الخط العام
  String? getGlobalFontFamily() => _globalFontFamily;
  
  // ==================== إدارة القوالب الجاهزة ====================
  
  /// تطبيق قالب جاهز على نوع محتوى معين
  Future<void> applyPreset(ContentType contentType, TextStylePreset preset) async {
    try {
      final currentSettings = await getTextSettings(contentType);
      final updatedSettings = preset.applyToSettings(currentSettings);
      
      await saveTextSettings(updatedSettings);
      
      _lastUsedPreset = preset.name;
      await _storage.setString(TextSettingsConstants.lastUsedPresetKey, preset.name);
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  /// تطبيق قالب على جميع أنواع المحتوى
  Future<void> applyPresetToAll(TextStylePreset preset) async {
    try {
      for (final contentType in ContentType.values) {
        await applyPreset(contentType, preset);
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  /// الحصول على آخر قالب مستخدم
  String? getLastUsedPreset() => _lastUsedPreset;
  
  // ==================== إعدادات محددة ====================
  
  /// تحديث حجم الخط فقط
  Future<void> updateFontSize(ContentType contentType, double fontSize) async {
    try {
      final clampedSize = TextSettingsConstants.clampFontSize(fontSize);
      final currentSettings = await getTextSettings(contentType);
      final updatedSettings = currentSettings.copyWith(fontSize: clampedSize);
      
      await saveTextSettings(updatedSettings);
    } catch (e) {
      rethrow;
    }
  }
  
  /// تحديث نوع الخط فقط
  Future<void> updateFontFamily(ContentType contentType, String fontFamily) async {
    try {
      final validatedFont = TextSettingsConstants.validateFontFamily(fontFamily);
      final currentSettings = await getTextSettings(contentType);
      final updatedSettings = currentSettings.copyWith(fontFamily: validatedFont);
      
      await saveTextSettings(updatedSettings);
    } catch (e) {
      rethrow;
    }
  }
  
  /// تحديث تباعد الأسطر فقط
  Future<void> updateLineHeight(ContentType contentType, double lineHeight) async {
    try {
      final clampedHeight = TextSettingsConstants.clampLineHeight(lineHeight);
      final currentSettings = await getTextSettings(contentType);
      final updatedSettings = currentSettings.copyWith(lineHeight: clampedHeight);
      
      await saveTextSettings(updatedSettings);
    } catch (e) {
      rethrow;
    }
  }
  
  /// تحديث تباعد الأحرف فقط
  Future<void> updateLetterSpacing(ContentType contentType, double letterSpacing) async {
    try {
      final clampedSpacing = TextSettingsConstants.clampLetterSpacing(letterSpacing);
      final currentSettings = await getTextSettings(contentType);
      final updatedSettings = currentSettings.copyWith(letterSpacing: clampedSpacing);
      
      await saveTextSettings(updatedSettings);
    } catch (e) {
      rethrow;
    }
  }
  
  // ==================== إعادة التعيين ====================
  
  /// إعادة تعيين إعدادات نوع محتوى معين للافتراضية
  Future<void> resetToDefault(ContentType contentType) async {
    try {
      final defaultSettings = TextSettingsConstants.getDefaultSettings(contentType);
      
      final finalSettings = _globalFontFamily != null
          ? defaultSettings.copyWith(fontFamily: _globalFontFamily)
          : defaultSettings;
      
      await saveTextSettings(finalSettings);
      
      const defaultDisplaySettings = TextSettingsConstants.defaultDisplaySettings;
      await saveDisplaySettings(contentType, defaultDisplaySettings);
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  /// إعادة تعيين جميع الإعدادات للافتراضية
  Future<void> resetAllToDefault() async {
    try {
      for (final contentType in ContentType.values) {
        await resetToDefault(contentType);
      }
      
      await setGlobalFontFamily(null);
      
      await _storage.remove(TextSettingsConstants.lastUsedPresetKey);
      _lastUsedPreset = null;
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  // ==================== ترحيل الإعدادات القديمة ====================
  
  /// ترحيل الإعدادات من الخدمات القديمة إلى النظام الجديد
  Future<void> _migrateOldSettings() async {
    try {
      await _migrateAthkarSettings();
      await _migrateDuaSettings();
      
      await _storage.setInt(TextSettingsConstants.settingsVersionKey, TextSettingsConstants.currentVersion);
      
    } catch (e) {
      // في حالة فشل الترحيل، تجاهل واستخدم الإعدادات الافتراضية
    }
  }
  
  /// ترحيل إعدادات الأذكار القديمة
  Future<void> _migrateAthkarSettings() async {
    try {
      final oldFontSize = _storage.getDouble('athkar_font_size');
      final oldFontFamily = _storage.getString('athkar_font_family');
      final oldLineHeight = _storage.getDouble('athkar_line_height');
      final oldLetterSpacing = _storage.getDouble('athkar_letter_spacing');
      
      if (oldFontSize != null || oldFontFamily != null) {
        final settings = TextSettings(
          fontSize: oldFontSize ?? TextSettingsConstants.defaultAthkarSettings.fontSize,
          fontFamily: oldFontFamily ?? TextSettingsConstants.defaultAthkarSettings.fontFamily,
          lineHeight: oldLineHeight ?? TextSettingsConstants.defaultAthkarSettings.lineHeight,
          letterSpacing: oldLetterSpacing ?? TextSettingsConstants.defaultAthkarSettings.letterSpacing,
          showTashkeel: _storage.getBool('athkar_show_tashkeel') ?? true,
          showFadl: _storage.getBool('athkar_show_fadl') ?? true,
          showSource: _storage.getBool('athkar_show_source') ?? true,
          showCounter: _storage.getBool('athkar_show_counter') ?? true,
          enableVibration: _storage.getBool('athkar_enable_vibration') ?? true,
          contentType: ContentType.athkar,
        );
        
        await saveTextSettings(settings);
      }
    } catch (e) {
      // تجاهل أخطاء الترحيل
    }
  }
  
  /// ترحيل إعدادات الدعاء القديمة
  Future<void> _migrateDuaSettings() async {
    try {
      final oldFontSize = _storage.getDouble('dua_font_size');
      
      if (oldFontSize != null) {
        final settings = TextSettings(
          fontSize: oldFontSize,
          fontFamily: TextSettingsConstants.defaultDuaSettings.fontFamily,
          lineHeight: TextSettingsConstants.defaultDuaSettings.lineHeight,
          letterSpacing: TextSettingsConstants.defaultDuaSettings.letterSpacing,
          showTashkeel: true,
          showFadl: true,
          showSource: true,
          showCounter: false,
          enableVibration: true,
          contentType: ContentType.dua,
        );
        
        await saveTextSettings(settings);
      }
    } catch (e) {
      // تجاهل أخطاء الترحيل
    }
  }
  
  // ==================== المساعدات ====================
  
  /// تعيين حالة التحميل
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  /// مسح جميع البيانات المحفوظة
  Future<void> clearAllData() async {
    try {
      for (final contentType in ContentType.values) {
        final settingsKey = TextSettingsConstants.getSettingsKey(contentType);
        final displayKey = TextSettingsConstants.getDisplaySettingsKey(contentType);
        
        await _storage.remove(settingsKey);
        await _storage.remove(displayKey);
      }
      
      await _storage.remove(TextSettingsConstants.globalFontFamilyKey);
      await _storage.remove(TextSettingsConstants.lastUsedPresetKey);
      await _storage.remove(TextSettingsConstants.settingsVersionKey);
      
      _settingsCache.clear();
      _displaySettingsCache.clear();
      _globalFontFamily = null;
      _lastUsedPreset = null;
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  /// الحصول على معلومات الإعدادات
  Map<String, dynamic> getSettingsInfo() {
    return {
      'cached_settings': _settingsCache.length,
      'cached_display_settings': _displaySettingsCache.length,
      'global_font': _globalFontFamily,
      'last_preset': _lastUsedPreset,
      'is_loading': _isLoading,
    };
  }
  
  /// تنظيف الموارد
  @override
  void dispose() {
    _settingsCache.clear();
    _displaySettingsCache.clear();
    super.dispose();
  }
}