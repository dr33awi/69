//lib/core/infrastructure/services/text/screens/global_text_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import '../../../../../app/di/service_locator.dart';
import '../models/text_settings_models.dart';
import '../service/text_settings_service.dart';
import '../constants/text_settings_constants.dart';

/// شاشة إعدادات النصوص العامة والموحدة
class GlobalTextSettingsScreen extends StatefulWidget {
  final ContentType? initialContentType;
  
  const GlobalTextSettingsScreen({
    super.key,
    this.initialContentType,
  });

  @override
  State<GlobalTextSettingsScreen> createState() => _GlobalTextSettingsScreenState();
}

class _GlobalTextSettingsScreenState extends State<GlobalTextSettingsScreen> {
  late final TextSettingsService _textService;
  
  // الإعدادات الحالية لكل نوع محتوى
  final Map<ContentType, TextSettings> _currentSettings = {};
  final Map<ContentType, DisplaySettings> _currentDisplaySettings = {};
  
  // الإعدادات الأصلية لتتبع التغييرات
  final Map<ContentType, TextSettings> _originalSettings = {};
  final Map<ContentType, DisplaySettings> _originalDisplaySettings = {};
  
  // حالة التحميل والحفظ
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  
  // نوع المحتوى المختار حالياً
  ContentType _selectedContentType = ContentType.athkar;
  
  // معاينة النص
  final String _previewText = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ • الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';
  
  @override
  void initState() {
    super.initState();
    _textService = getIt<TextSettingsService>();
    _selectedContentType = widget.initialContentType ?? ContentType.athkar;
    _loadAllSettings();
  }

  /// تحميل جميع الإعدادات
  Future<void> _loadAllSettings() async {
    setState(() => _isLoading = true);
    
    try {
      for (final contentType in ContentType.values) {
        final textSettings = await _textService.getTextSettings(contentType);
        final displaySettings = await _textService.getDisplaySettings(contentType);
        
        _currentSettings[contentType] = textSettings;
        _currentDisplaySettings[contentType] = displaySettings;
        
        // حفظ نسخة أصلية
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

  /// التحقق من وجود تغييرات
  void _checkForChanges() {
    bool hasChanges = false;
    
    for (final contentType in ContentType.values) {
      final current = _currentSettings[contentType];
      final original = _originalSettings[contentType];
      
      if (current != original) {
        hasChanges = true;
        break;
      }
      
      final currentDisplay = _currentDisplaySettings[contentType];
      final originalDisplay = _originalDisplaySettings[contentType];
      
      if (currentDisplay != originalDisplay) {
        hasChanges = true;
        break;
      }
    }
    
    setState(() {
      _hasChanges = hasChanges;
    });
  }

  /// تحديث الإعدادات مع تتبع التغييرات
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

  /// حفظ جميع الإعدادات
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
      
      // تحديث الإعدادات الأصلية
      _originalSettings.clear();
      _originalDisplaySettings.clear();
      _originalSettings.addAll(_currentSettings);
      _originalDisplaySettings.addAll(_currentDisplaySettings);
      
      if (mounted) {
        HapticFeedback.mediumImpact();
        context.showSuccessSnackBar('تم حفظ الإعدادات بنجاح');
        
        setState(() {
          _hasChanges = false;
        });
      }
      
      setState(() => _isSaving = false);
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        context.showErrorSnackBar('حدث خطأ أثناء حفظ الإعدادات');
      }
    }
  }

  /// عرض dialog تأكيد الخروج مع تغييرات غير محفوظة
  Future<bool> _showUnsavedChangesDialog() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: ThemeConstants.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.warning_amber_rounded, color: ThemeConstants.warning, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'تغييرات غير محفوظة',
                style: TextStyle(fontSize: 16.sp, fontWeight: ThemeConstants.bold),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text('حفظ وخروج', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
    
    if (result == 'save') {
      // حفظ التغييرات
      await _saveAllSettings();
      return !_hasChanges;
    } else if (result == 'discard') {
      // تجاهل التغييرات - إرجاع الإعدادات للحالة الأصلية
      setState(() {
        _currentSettings.clear();
        _currentSettings.addAll(_originalSettings);
        _currentDisplaySettings.clear();
        _currentDisplaySettings.addAll(_originalDisplaySettings);
        _hasChanges = false;
      });
      return true; // السماح بالخروج
    }
    
    return false; // إلغاء (result == 'cancel' or null)
  }

  /// تطبيق قالب على نوع محتوى معين
  Future<void> _applyPreset(ContentType contentType, TextStylePreset preset) async {
    final currentSettings = _currentSettings[contentType];
    if (currentSettings != null) {
      final updatedSettings = preset.applyToSettings(currentSettings);
      _updateSettings(contentType, textSettings: updatedSettings);
      HapticFeedback.lightImpact();
    }
  }

  /// إعادة تعيين إعدادات نوع محتوى معين
  Future<void> _resetToDefault(ContentType contentType) async {
    final confirmed = await _showResetConfirmDialog(contentType);
    if (confirmed == true) {
      final defaultSettings = TextSettingsConstants.getDefaultSettings(contentType);
      const defaultDisplaySettings = TextSettingsConstants.defaultDisplaySettings;
      
      _updateSettings(
        contentType,
        textSettings: defaultSettings,
        displaySettings: defaultDisplaySettings,
      );
      
      HapticFeedback.mediumImpact();
    }
  }

  /// عرض dialog تأكيد إعادة التعيين
  Future<bool?> _showResetConfirmDialog(ContentType contentType) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: ThemeConstants.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.restore, color: ThemeConstants.warning, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'إعادة تعيين ${contentType.displayName}',
                style: TextStyle(fontSize: 16.sp, fontWeight: ThemeConstants.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'هل تريد إعادة جميع إعدادات ${contentType.displayName} إلى القيم الافتراضية؟',
          style: TextStyle(fontSize: 14.sp, height: 1.6),
        ),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text('إلغاء', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.warning,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text('إعادة تعيين', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showUnsavedChangesDialog,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: _buildAppBar(context),
        body: _isLoading
            ? _buildLoadingIndicator()
            : Column(
                children: [
                  _buildContentTypeSelector(),
                  Expanded(
                    child: _buildContentTypeSettings(_selectedContentType),
                  ),
                ],
              ),
      ),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.cardColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () async {
          final canPop = await _showUnsavedChangesDialog();
          if (canPop && mounted) {
            Navigator.pop(context);
          }
        },
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: context.textPrimaryColor,
          size: 20.sp,
        ),
      ),
      title: Text(
        'إعدادات النصوص',
        style: TextStyle(
          color: context.textPrimaryColor,
          fontWeight: ThemeConstants.bold,
          fontSize: 18.sp,
        ),
      ),
      actions: [
        if (_hasChanges && !_isSaving)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _saveAllSettings();
            },
            icon: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: ThemeConstants.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.save,
                color: ThemeConstants.primary,
                size: 20.sp,
              ),
            ),
            tooltip: 'حفظ التغييرات',
          ),
        IconButton(
          onPressed: () => _resetToDefault(_selectedContentType),
          icon: Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: ThemeConstants.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.restore_rounded,
              color: ThemeConstants.warning,
              size: 20.sp,
            ),
          ),
          tooltip: 'إعادة الإعدادات الافتراضية',
        ),
        SizedBox(width: 4.w),
      ],
    );
  }

  /// بناء محدد نوع المحتوى
  Widget _buildContentTypeSelector() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: ContentType.values.map((contentType) {
          final isSelected = _selectedContentType == contentType;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedContentType = contentType);
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? ThemeConstants.primary 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getContentTypeIcon(contentType),
                      size: 22.sp,
                      color: isSelected 
                          ? Colors.white 
                          : context.textSecondaryColor,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      contentType.displayName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected 
                            ? ThemeConstants.bold 
                            : ThemeConstants.medium,
                        color: isSelected 
                            ? Colors.white 
                            : context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// الحصول على أيقونة نوع المحتوى
  IconData _getContentTypeIcon(ContentType contentType) {
    switch (contentType) {
      case ContentType.athkar:
        return Icons.article_rounded;
      case ContentType.dua:
        return Icons.volunteer_activism_rounded;
      case ContentType.asmaAllah:
        return Icons.star_rounded;
    }
  }

  /// بناء إعدادات نوع محتوى معين
  Widget _buildContentTypeSettings(ContentType contentType) {
    final textSettings = _currentSettings[contentType];
    final displaySettings = _currentDisplaySettings[contentType];
    
    if (textSettings == null || displaySettings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        _buildPreviewSection(textSettings, displaySettings),
        SizedBox(height: 16.h),
        _buildPresetsSection(contentType, textSettings),
        SizedBox(height: 16.h),
        _buildFontSettingsSection(contentType, textSettings),
        SizedBox(height: 16.h),
        _buildDisplaySettingsSection(contentType, displaySettings),
        SizedBox(height: 20.h),
      ],
    );
  }

  /// بناء قسم المعاينة
  Widget _buildPreviewSection(TextSettings textSettings, DisplaySettings displaySettings) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.visibility_rounded,
            title: 'معاينة النص',
            color: ThemeConstants.primary,
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeConstants.primary.withOpacity(0.05),
                  ThemeConstants.primary.withOpacity(0.08),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: ThemeConstants.primary.withOpacity(0.15),
                width: 1.5.w,
              ),
            ),
            child: Text(
              displaySettings.showTashkeel ? _previewText : _removeTashkeel(_previewText),
              style: TextStyle(
                fontSize: textSettings.fontSize,
                fontFamily: textSettings.fontFamily,
                height: textSettings.lineHeight,
                letterSpacing: textSettings.letterSpacing,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء قسم القوالب الجاهزة
  Widget _buildPresetsSection(ContentType contentType, TextSettings textSettings) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.palette_rounded,
            title: 'القوالب الجاهزة',
            color: ThemeConstants.accent,
          ),
          SizedBox(height: 16.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 2.2,
            children: TextStylePresets.all.map((preset) {
              return _buildPresetCard(contentType, preset);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة قالب جاهز
  Widget _buildPresetCard(ContentType contentType, TextStylePreset preset) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _applyPreset(contentType, preset),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ThemeConstants.accent.withOpacity(0.08),
                ThemeConstants.accent.withOpacity(0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: ThemeConstants.accent.withOpacity(0.2),
              width: 1.w,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                preset.icon,
                size: 24.sp,
                color: ThemeConstants.accent,
              ),
              SizedBox(height: 6.h),
              Text(
                preset.name,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: ThemeConstants.bold,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء قسم إعدادات الخط
  Widget _buildFontSettingsSection(ContentType contentType, TextSettings textSettings) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.text_fields_rounded,
            title: 'إعدادات الخط',
            color: ThemeConstants.info,
          ),
          SizedBox(height: 20.h),
          
          _buildSliderSetting(
            title: 'حجم الخط',
            icon: Icons.format_size_rounded,
            value: textSettings.fontSize,
            min: TextSettingsConstants.minFontSize,
            max: TextSettingsConstants.maxFontSize,
            divisions: 12,
            label: '${textSettings.fontSize.round()}',
            onChanged: (value) {
              _updateSettings(
                contentType,
                textSettings: textSettings.copyWith(fontSize: value),
              );
            },
          ),
          
          SizedBox(height: 20.h),
          
          _buildDropdownSetting(
            title: 'نوع الخط',
            icon: Icons.font_download_rounded,
            value: textSettings.fontFamily,
            items: TextSettingsConstants.availableFonts,
            onChanged: (value) {
              _updateSettings(
                contentType,
                textSettings: textSettings.copyWith(fontFamily: value!),
              );
            },
          ),
          
          SizedBox(height: 20.h),
          
          _buildSliderSetting(
            title: 'تباعد الأسطر',
            icon: Icons.format_line_spacing_rounded,
            value: textSettings.lineHeight,
            min: TextSettingsConstants.minLineHeight,
            max: TextSettingsConstants.maxLineHeight,
            divisions: 20,
            label: textSettings.lineHeight.toStringAsFixed(1),
            onChanged: (value) {
              _updateSettings(
                contentType,
                textSettings: textSettings.copyWith(lineHeight: value),
              );
            },
          ),
          
          SizedBox(height: 20.h),
          
          _buildSliderSetting(
            title: 'تباعد الأحرف',
            icon: Icons.space_bar_rounded,
            value: textSettings.letterSpacing,
            min: TextSettingsConstants.minLetterSpacing,
            max: TextSettingsConstants.maxLetterSpacing,
            divisions: 20,
            label: textSettings.letterSpacing.toStringAsFixed(1),
            onChanged: (value) {
              _updateSettings(
                contentType,
                textSettings: textSettings.copyWith(letterSpacing: value),
              );
            },
          ),
        ],
      ),
    );
  }

  /// بناء قسم إعدادات العرض
  Widget _buildDisplaySettingsSection(ContentType contentType, DisplaySettings displaySettings) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.tune_rounded,
            title: 'إعدادات العرض',
            color: ThemeConstants.success,
          ),
          SizedBox(height: 12.h),
          
          _buildSwitchSetting(
            title: 'إظهار التشكيل',
            subtitle: 'عرض الحركات والتشكيل على النص',
            icon: Icons.abc_rounded,
            value: displaySettings.showTashkeel,
            onChanged: (value) {
              _updateSettings(
                contentType,
                displaySettings: displaySettings.copyWith(showTashkeel: value),
              );
            },
          ),
          
          _buildSwitchSetting(
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
          ),
          
          _buildSwitchSetting(
            title: 'إظهار المصدر',
            subtitle: 'عرض مصدر النص',
            icon: Icons.library_books_rounded,
            value: displaySettings.showSource,
            onChanged: (value) {
              _updateSettings(
                contentType,
                displaySettings: displaySettings.copyWith(showSource: value),
              );
            },
          ),
          
          if (contentType == ContentType.athkar)
            _buildSwitchSetting(
              title: 'إظهار العداد',
              subtitle: 'عرض عداد التكرار للأذكار',
              icon: Icons.looks_one_rounded,
              value: displaySettings.showCounter,
              onChanged: (value) {
                _updateSettings(
                  contentType,
                  displaySettings: displaySettings.copyWith(showCounter: value),
                );
              },
            ),
          
          _buildSwitchSetting(
            title: 'الاهتزاز',
            subtitle: 'تفعيل الاهتزاز عند اللمس',
            icon: Icons.vibration_rounded,
            value: displaySettings.enableVibration,
            onChanged: (value) {
              _updateSettings(
                contentType,
                displaySettings: displaySettings.copyWith(enableVibration: value),
              );
            },
          ),
        ],
      ),
    );
  }

  /// بناء عنوان القسم
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontWeight: ThemeConstants.bold,
            fontSize: 15.sp,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  /// بناء إعداد منزلق
  Widget _buildSliderSetting({
    required String title,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18.sp, color: ThemeConstants.primary),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: ThemeConstants.medium,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeConstants.primary.withOpacity(0.1),
                    ThemeConstants.primary.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: ThemeConstants.primary.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: ThemeConstants.bold,
                  color: ThemeConstants.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: ThemeConstants.primary,
            inactiveTrackColor: ThemeConstants.primary.withOpacity(0.2),
            thumbColor: ThemeConstants.primary,
            overlayColor: ThemeConstants.primary.withOpacity(0.15),
            trackHeight: 6.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// بناء إعداد قائمة منسدلة
  Widget _buildDropdownSetting({
    required String title,
    required IconData icon,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18.sp, color: ThemeConstants.primary),
            SizedBox(width: 10.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: ThemeConstants.medium,
                color: context.textPrimaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: context.dividerColor.withOpacity(0.3),
              width: 1.5.w,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            items: items.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: ThemeConstants.medium,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 24.sp),
            dropdownColor: context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ],
    );
  }

  /// بناء إعداد مفتاح
  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: value 
            ? ThemeConstants.primary.withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: value 
              ? ThemeConstants.primary.withOpacity(0.15)
              : context.dividerColor.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: value 
                  ? ThemeConstants.primary.withOpacity(0.1)
                  : context.dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: value 
                  ? ThemeConstants.primary
                  : context.textSecondaryColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: ThemeConstants.medium,
                    color: context.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ThemeConstants.primary,
            activeTrackColor: ThemeConstants.primary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  /// بناء مؤشر التحميل
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(ThemeConstants.primary),
            strokeWidth: 3.w,
          ),
          SizedBox(height: 24.h),
          Text(
            'جاري تحميل الإعدادات...',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: ThemeConstants.medium,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// إزالة التشكيل من النص
  String _removeTashkeel(String text) {
    final tashkeelRegex = RegExp(r'[\u0617-\u061A\u064B-\u0652]');
    return text.replaceAll(tashkeelRegex, '');
  }
}

/// بطاقة مخصصة للإعدادات
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(20.r),
      margin: margin,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: child,
    );
  }
}