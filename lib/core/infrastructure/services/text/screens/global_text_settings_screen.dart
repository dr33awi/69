// lib/core/infrastructure/services/text/screens/global_text_settings_screen.dart
import 'package:athkar_app/core/infrastructure/services/text/service/text_settings_constants.dart';
import 'package:athkar_app/core/infrastructure/services/text/widgets/content_type_selector.dart';
import 'package:athkar_app/core/infrastructure/services/text/widgets/font_selector_widget.dart';
import 'package:athkar_app/core/infrastructure/services/text/widgets/presets_section.dart';
import 'package:athkar_app/core/infrastructure/services/text/widgets/shared_widgets.dart';
import 'package:athkar_app/core/infrastructure/services/text/widgets/text_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../../../../app/themes/app_theme.dart';
import '../../../../../app/themes/widgets/layout/app_bar.dart' as app_bar;
import '../../../../../app/di/service_locator.dart';
import '../models/text_settings_models.dart';
import '../service/text_settings_service.dart';
import '../constants/text_settings_constants.dart';


/// شاشة إعدادات النصوص المحسّنة - بدون أنيميشن
class GlobalTextSettingsScreen extends StatefulWidget {
  final ContentType? initialContentType;
  
  const GlobalTextSettingsScreen({
    super.key,
    this.initialContentType,
  });

  @override
  State<GlobalTextSettingsScreen> createState() => 
      _GlobalTextSettingsScreenState();
}

class _GlobalTextSettingsScreenState extends State<GlobalTextSettingsScreen> {
  late final TextSettingsService _textService;
  
  final Map<ContentType, TextSettings> _currentSettings = {};
  final Map<ContentType, DisplaySettings> _currentDisplaySettings = {};
  final Map<ContentType, TextSettings> _originalSettings = {};
  final Map<ContentType, DisplaySettings> _originalDisplaySettings = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  
  final Map<ContentType, String?> _selectedPresets = {};
  ContentType _selectedContentType = ContentType.athkar;
  
  // نصوص المعاينة
  final Map<ContentType, String> _previewTexts = {
    ContentType.athkar: '''سُبْحَانَ اللَّهِ وَبِحَمْدِهِ''',
    ContentType.dua: '''رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً
وَفِي الْآخِرَةِ حَسَنَةً
وَقِنَا عَذَابَ النَّارِ''',
    ContentType.asmaAllah: '''الرَّحْمَنُ • الرَّحِيمُ • الْمَلِكُ
الْمُهَيْمِنُ • الْعَزِيزُ • الْجَبَّارُ''',
  };

  // خريطة الألوان
  final Map<ContentType, Color> _colorMap = {
    ContentType.athkar: ThemeConstants.primary,
    ContentType.dua: ThemeConstants.accent,
    ContentType.asmaAllah: ThemeConstants.tertiary,
  };

  // خريطة الأيقونات
  final Map<ContentType, IconData> _iconMap = {
    ContentType.athkar: Icons.article_rounded,
    ContentType.dua: Icons.volunteer_activism_rounded,
    ContentType.asmaAllah: Icons.star_rounded,
  };

  @override
  void initState() {
    super.initState();
    _textService = getIt<TextSettingsService>();
    _selectedContentType = widget.initialContentType ?? ContentType.athkar;
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    setState(() => _isLoading = true);
    
    try {
      for (final contentType in ContentType.values) {
        final textSettings = await _textService.getTextSettings(contentType);
        final displaySettings = await _textService.getDisplaySettings(contentType);
        
        _currentSettings[contentType] = textSettings;
        _currentDisplaySettings[contentType] = displaySettings;
        _originalSettings[contentType] = textSettings;
        _originalDisplaySettings[contentType] = displaySettings;
      }
      
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _checkForChanges() {
    bool hasChanges = false;
    
    for (final contentType in ContentType.values) {
      if (_currentSettings[contentType] != _originalSettings[contentType] ||
          _currentDisplaySettings[contentType] != 
              _originalDisplaySettings[contentType]) {
        hasChanges = true;
        break;
      }
    }
    
    setState(() => _hasChanges = hasChanges);
  }

  void _updateSettings(ContentType contentType, {
    TextSettings? textSettings,
    DisplaySettings? displaySettings,
  }) {
    setState(() {
      if (textSettings != null) {
        _currentSettings[contentType] = textSettings;
      }
      if (displaySettings != null) {
        _currentDisplaySettings[contentType] = displaySettings;
      }
    });
    _checkForChanges();
  }

  Future<void> _saveAllSettings() async {
    if (!_hasChanges) return;
    
    setState(() => _isSaving = true);
    
    try {
      for (final contentType in ContentType.values) {
        final textSettings = _currentSettings[contentType];
        final displaySettings = _currentDisplaySettings[contentType];
        
        if (textSettings != null) {
          await _textService.saveTextSettings(textSettings);
        }
        
        if (displaySettings != null) {
          await _textService.saveDisplaySettings(contentType, displaySettings);
        }
      }
      
      _originalSettings.clear();
      _originalDisplaySettings.clear();
      _originalSettings.addAll(_currentSettings);
      _originalDisplaySettings.addAll(_currentDisplaySettings);
      
      if (!mounted) return;
      
      context.showSuccessSnackBar('تم حفظ الإعدادات بنجاح');
      setState(() => _hasChanges = false);
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('فشل حفظ الإعدادات');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: ThemeConstants.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: ThemeConstants.warning,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'تغييرات غير محفوظة',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: ThemeConstants.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'لديك تغييرات لم يتم حفظها. هل تريد حفظ التغييرات قبل المغادرة؟',
          style: TextStyle(fontSize: 14.sp, height: 1.6),
        ),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text(
              'تجاهل التغييرات',
              style: TextStyle(fontSize: 14.sp, color: ThemeConstants.error),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text('حفظ وخروج', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
    
    if (result == 'save') {
      await _saveAllSettings();
      return !_hasChanges;
    } else if (result == 'discard') {
      setState(() {
        _currentSettings.clear();
        _currentSettings.addAll(_originalSettings);
        _currentDisplaySettings.clear();
        _currentDisplaySettings.addAll(_originalDisplaySettings);
        _hasChanges = false;
      });
      return true;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showUnsavedChangesDialog,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            ContentTypeSelector(
                              selectedContentType: _selectedContentType,
                              onChanged: (type) {
                                setState(() => _selectedContentType = type);
                              },
                              colorMap: _colorMap,
                              iconMap: _iconMap,
                            ),
                            _buildContentTypeSettings(_selectedContentType),
                            SizedBox(height: 60.h),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          app_bar.AppBackButton(
            onPressed: () async {
              final canPop = await _showUnsavedChangesDialog();
              if (canPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          
          SizedBox(width: 8.w),
          
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeConstants.info,
                  ThemeConstants.info.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.info.withOpacity(0.25),
                  blurRadius: 6.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Icon(
              Icons.text_fields_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          
          SizedBox(width: 8.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات النصوص',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 17.sp,
                  ),
                ),
                Text(
                  'تخصيص مظهر النصوص والخطوط',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          
          if (_hasChanges && !_isSaving)
            Container(
              margin: EdgeInsets.only(left: 6.w),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _saveAllSettings();
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: context.dividerColor.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 3.r,
                          offset: Offset(0, 1.5.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.save,
                      color: ThemeConstants.primary,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ),
          
          if (!_isLoading)
            Container(
              margin: EdgeInsets.only(left: 6.w),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                child: InkWell(
                  onTap: _showResetAllDialog,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: context.dividerColor.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 3.r,
                          offset: Offset(0, 1.5.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.restore_rounded,
                      color: ThemeConstants.error,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentTypeSettings(ContentType contentType) {
    final textSettings = _currentSettings[contentType];
    final displaySettings = _currentDisplaySettings[contentType];
    
    if (textSettings == null || displaySettings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final accentColor = _colorMap[contentType] ?? ThemeConstants.primary;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
      child: Column(
        children: [
          // معاينة النص المحسّنة
          TextPreviewWidget(
            contentType: contentType,
            textSettings: textSettings,
            displaySettings: displaySettings,
            accentColor: accentColor,
            previewTexts: _previewTexts,
          ),
          
          SizedBox(height: 20.h),
          
          // القوالب الجاهزة
          PresetsSection(
            contentType: contentType,
            currentPresetName: _getCurrentPresetName(contentType),
            onPresetSelected: (preset) => _applyPreset(contentType, preset),
            accentColor: ThemeConstants.accent,
          ),
          
          SizedBox(height: 20.h),
          
          // إعدادات الخط
          _buildFontSettingsSection(contentType, textSettings, accentColor),
          
          SizedBox(height: 20.h),
          
          // إعدادات العرض
          _buildDisplaySettingsSection(contentType, displaySettings, accentColor),
        ],
      ),
    );
  }

  Widget _buildFontSettingsSection(
    ContentType contentType,
    TextSettings textSettings,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: EdgeInsets.all(20.w),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.w),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ThemeConstants.info,
                      ThemeConstants.info.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.info.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.font_download_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تخصيص الخط',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'حجم الخط والتباعد والنوع',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ThemeConstants.info,
            size: 28.sp,
          ),
          children: [
            Column(
              children: [
                EnhancedSlider(
                  title: 'حجم الخط',
                  icon: Icons.format_size_rounded,
                  value: textSettings.fontSize,
                  min: TextSettingsConstants.minFontSize,
                  max: TextSettingsConstants.maxFontSize,
                  divisions: 12,
                  label: '${textSettings.fontSize.round()}',
                  color: ThemeConstants.primary,
                  onChanged: (value) {
                    _updateSettings(
                      contentType,
                      textSettings: textSettings.copyWith(fontSize: value),
                    );
                  },
                ),
                
                SizedBox(height: 24.h),
                
                FontSelectorWidget(
                  contentType: contentType,
                  currentFont: textSettings.fontFamily,
                  onChanged: (value) {
                    _updateSettings(
                      contentType,
                      textSettings: textSettings.copyWith(fontFamily: value!),
                    );
                  },
                  accentColor: accentColor,
                ),
                
                SizedBox(height: 24.h),
                
                EnhancedSlider(
                  title: 'تباعد الأسطر',
                  icon: Icons.format_line_spacing_rounded,
                  value: textSettings.lineHeight,
                  min: TextSettingsConstants.minLineHeight,
                  max: TextSettingsConstants.maxLineHeight,
                  divisions: 20,
                  label: textSettings.lineHeight.toStringAsFixed(1),
                  color: ThemeConstants.accent,
                  onChanged: (value) {
                    _updateSettings(
                      contentType,
                      textSettings: textSettings.copyWith(lineHeight: value),
                    );
                  },
                ),
                
                SizedBox(height: 24.h),
                
                EnhancedSlider(
                  title: 'تباعد الأحرف',
                  icon: Icons.space_bar_rounded,
                  value: textSettings.letterSpacing,
                  min: TextSettingsConstants.minLetterSpacing,
                  max: TextSettingsConstants.maxLetterSpacing,
                  divisions: 20,
                  label: textSettings.letterSpacing.toStringAsFixed(1),
                  color: ThemeConstants.tertiary,
                  onChanged: (value) {
                    _updateSettings(
                      contentType,
                      textSettings: textSettings.copyWith(letterSpacing: value),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySettingsSection(
    ContentType contentType,
    DisplaySettings displaySettings,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(20.w),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.w),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ThemeConstants.success,
                      ThemeConstants.success.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.success.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'خيارات العرض',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'التشكيل والعداد والمصدر',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ThemeConstants.success,
            size: 28.sp,
          ),
          children: [
            Column(
              children: [
                EnhancedSwitch(
                  title: 'إظهار التشكيل',
                  subtitle: 'عرض الحركات والتشكيل على النص',
                  icon: Icons.abc_rounded,
                  value: displaySettings.showTashkeel,
                  onChanged: (value) {
                    _updateSettings(
                      contentType,
                      displaySettings: 
                          displaySettings.copyWith(showTashkeel: value),
                    );
                  },
                  accentColor: accentColor,
                ),
                
                EnhancedSwitch(
                  title: 'إظهار الفضيلة',
                  subtitle: 'عرض فضل الذكر إن وجد',
                  icon: Icons.stars_rounded,
                  value: displaySettings.showFadl,
                  onChanged: (value) {
                    _updateSettings(
                      contentType,
                      displaySettings: displaySettings.copyWith(showFadl: value),
                    );
                  },
                  accentColor: accentColor,
                ),
                
                EnhancedSwitch(
                  title: 'إظهار المصدر',
                  subtitle: 'عرض مصدر النص',
                  icon: Icons.library_books_rounded,
                  value: displaySettings.showSource,
                  onChanged: (value) {
                    _updateSettings(
                      contentType,
                      displaySettings: 
                          displaySettings.copyWith(showSource: value),
                    );
                  },
                  accentColor: accentColor,
                ),
                
                if (contentType == ContentType.athkar)
                  EnhancedSwitch(
                    title: 'إظهار العداد',
                    subtitle: 'عرض عداد التكرار للأذكار',
                    icon: Icons.looks_one_rounded,
                    value: displaySettings.showCounter,
                    onChanged: (value) {
                      _updateSettings(
                        contentType,
                        displaySettings: 
                            displaySettings.copyWith(showCounter: value),
                      );
                    },
                    accentColor: accentColor,
                  ),
                
                EnhancedSwitch(
                  title: 'الاهتزاز',
                  subtitle: 'تفعيل الاهتزاز عند اللمس',
                  icon: Icons.vibration_rounded,
                  value: displaySettings.enableVibration,
                  onChanged: (value) {
                    _updateSettings(
                      contentType,
                      displaySettings: 
                          displaySettings.copyWith(enableVibration: value),
                    );
                  },
                  accentColor: accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(ThemeConstants.info),
            strokeWidth: 3.w,
          ),
          SizedBox(height: 24.h),
          Text(
            'جاري تحميل الإعدادات...',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: ThemeConstants.medium,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String? _getCurrentPresetName(ContentType contentType) {
    final currentSettings = _currentSettings[contentType];
    if (currentSettings == null) return null;
    
    for (final preset in TextStylePresets.all) {
      final presetSettings = preset.applyToSettings(currentSettings);
      
      if (currentSettings.fontSize == presetSettings.fontSize &&
          currentSettings.lineHeight == presetSettings.lineHeight &&
          currentSettings.letterSpacing == presetSettings.letterSpacing) {
        return preset.name;
      }
    }
    
    return _selectedPresets[contentType];
  }

  void _applyPreset(ContentType contentType, TextStylePreset preset) {
    final currentSettings = _currentSettings[contentType];
    if (currentSettings != null) {
      final updatedSettings = preset.applyToSettings(currentSettings);
      
      setState(() {
        _selectedPresets[contentType] = preset.name;
      });
      
      _updateSettings(contentType, textSettings: updatedSettings);
      HapticFeedback.mediumImpact();
    }
  }

  void _showResetAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          backgroundColor: context.cardColor,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: ThemeConstants.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.restore_rounded,
                  color: ThemeConstants.error,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Text(
                'إعادة تعيين الكل',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: ThemeConstants.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل تريد إعادة جميع الإعدادات إلى القيم الافتراضية؟\nسيتم فقدان جميع التخصيصات.',
            style: TextStyle(fontSize: 15.sp, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: TextStyle(fontSize: 14.sp)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              ),
              child: Text(
                'إعادة تعيين',
                style: TextStyle(fontSize: 14.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    
    if (confirmed == true) {
      for (final contentType in ContentType.values) {
        await _resetToDefault(contentType);
      }
      HapticFeedback.heavyImpact();
      _showSuccessMessage('تم إعادة التعيين بنجاح');
    }
  }

  Future<void> _resetToDefault(ContentType contentType) async {
    final defaultSettings = 
        TextSettingsConstants.getDefaultSettings(contentType);
    const defaultDisplaySettings = 
        TextSettingsConstants.defaultDisplaySettings;
    
    setState(() {
      _selectedPresets[contentType] = null;
    });
    
    _updateSettings(
      contentType,
      textSettings: defaultSettings,
      displaySettings: defaultDisplaySettings,
    );
  }

  void _showSuccessMessage([String message = 'تم حفظ الإعدادات بنجاح']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Text(message),
          ],
        ),
        backgroundColor: ThemeConstants.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }
}