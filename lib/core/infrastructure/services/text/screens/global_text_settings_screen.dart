// lib/core/infrastructure/services/text/screens/global_text_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../../../../app/themes/app_theme.dart';
import '../../../../../app/di/service_locator.dart';
import '../models/text_settings_models.dart';
import '../service/text_settings_service.dart';
import '../constants/text_settings_constants.dart';

/// شاشة إعدادات النصوص بتصميم محسّن
class GlobalTextSettingsScreen extends StatefulWidget {
  final ContentType? initialContentType;
  
  const GlobalTextSettingsScreen({
    super.key,
    this.initialContentType,
  });

  @override
  State<GlobalTextSettingsScreen> createState() => _GlobalTextSettingsScreenState();
}

class _GlobalTextSettingsScreenState extends State<GlobalTextSettingsScreen> with TickerProviderStateMixin {
  late final TextSettingsService _textService;
  
  final Map<ContentType, TextSettings> _currentSettings = {};
  final Map<ContentType, DisplaySettings> _currentDisplaySettings = {};
  final Map<ContentType, TextSettings> _originalSettings = {};
  final Map<ContentType, DisplaySettings> _originalDisplaySettings = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  
  // حالة القوائم القابلة للتمدد
  bool _isPresetsExpanded = false;
  bool _isFontSettingsExpanded = false;
  bool _isDisplaySettingsExpanded = false;
  
  // تتبع القالب المختار لكل نوع محتوى
  final Map<ContentType, String?> _selectedPresets = {};
  
  ContentType _selectedContentType = ContentType.athkar;
  
  // نصوص المعاينة المختلفة لكل فئة
  final Map<ContentType, String> _previewTexts = {
    ContentType.athkar: '''سُبْحَانَ اللَّهِ وَبِحَمْدِهِ''',
    
    ContentType.dua: '''رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً
وَفِي الْآخِرَةِ حَسَنَةً
وَقِنَا عَذَابَ النَّارِ''',
    
    ContentType.asmaAllah: '''الرَّحْمَنُ • الرَّحِيمُ • الْمَلِكُ
الْمُهَيْمِنُ • الْعَزِيزُ • الْجَبَّارُ''',
  };

  @override
  void initState() {
    super.initState();
    _textService = getIt<TextSettingsService>();
    _selectedContentType = widget.initialContentType ?? ContentType.athkar;
    _loadAllSettings();
  }

  @override
  void dispose() {
    super.dispose();
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
          _currentDisplaySettings[contentType] != _originalDisplaySettings[contentType]) {
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
      
      // تحديث الإعدادات الأصلية
      _originalSettings.clear();
      _originalDisplaySettings.clear();
      _originalSettings.addAll(_currentSettings);
      _originalDisplaySettings.addAll(_currentDisplaySettings);
      
      if (!mounted) return;
      
      context.showSuccessSnackBar('تم حفظ الإعدادات بنجاح');
      setState(() {
        _hasChanges = false;
      });
      
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
                            _buildContentTypeSelector(),
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
          AppBackButton(
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
                colors: [ThemeConstants.info, ThemeConstants.info.withOpacity(0.8)],
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

  Widget _buildContentTypeSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getContentTypeColor(contentType),
                            _getContentTypeColor(contentType).withOpacity(0.85),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(13.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _getContentTypeColor(contentType).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: EdgeInsets.all(isSelected ? 9.r : 7.r),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : _getContentTypeColor(contentType).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getContentTypeIcon(contentType),
                        size: isSelected ? 22.sp : 18.sp,
                        color: isSelected
                            ? Colors.white
                            : _getContentTypeColor(contentType),
                      ),
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

  Widget _buildContentTypeSettings(ContentType contentType) {
    final textSettings = _currentSettings[contentType];
    final displaySettings = _currentDisplaySettings[contentType];
    
    if (textSettings == null || displaySettings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
      child: Column(
        children: [
          _buildEnhancedPreviewSection(textSettings, displaySettings),
          SizedBox(height: 20.h),
          _buildExpandablePresetsSection(contentType),
          SizedBox(height: 20.h),
          _buildExpandableFontSettingsSection(contentType, textSettings),
          SizedBox(height: 20.h),
          _buildExpandableDisplaySettingsSection(contentType, displaySettings),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildEnhancedPreviewSection(TextSettings textSettings, DisplaySettings displaySettings) {
    final previewText = _previewTexts[_selectedContentType] ?? _previewTexts[ContentType.athkar]!;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getContentTypeColor(_selectedContentType).withOpacity(0.08),
            _getContentTypeColor(_selectedContentType).withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: _getContentTypeColor(_selectedContentType).withOpacity(0.2),
          width: 1.5.w,
        ),
      ),
      child: Column(
        children: [
          // هيدر مضغوط
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
            child: Row(
              children: [
                Icon(
                  Icons.preview_rounded,
                  color: _getContentTypeColor(_selectedContentType),
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'معاينة',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: ThemeConstants.bold,
                    color: _getContentTypeColor(_selectedContentType),
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _getContentTypeColor(_selectedContentType).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${textSettings.fontSize.round()}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: ThemeConstants.bold,
                      color: _getContentTypeColor(_selectedContentType),
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  _getPreviewSubtitle(_selectedContentType),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // خط فاصل رفيع
          Container(
            height: 1.h,
            margin: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _getContentTypeColor(_selectedContentType).withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // النص - مضغوط
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Text(
              displaySettings.showTashkeel ? previewText : _removeTashkeel(previewText),
              style: TextStyle(
                fontSize: textSettings.fontSize,
                fontFamily: textSettings.fontFamily,
                height: textSettings.lineHeight,
                letterSpacing: textSettings.letterSpacing,
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandablePresetsSection(ContentType contentType) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isPresetsExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isPresetsExpanded = expanded);
            HapticFeedback.selectionClick();
          },
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
                      ThemeConstants.accent,
                      ThemeConstants.accent.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.accent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.dashboard_customize_rounded,
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
                      'قوالب جاهزة',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      _getCurrentPresetName(contentType) != null
                          ? 'القالب الحالي: ${_getCurrentPresetName(contentType)}'
                          : 'اختر قالباً وطبقه بضغطة واحدة',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _getCurrentPresetName(contentType) != null
                            ? ThemeConstants.accent
                            : context.textSecondaryColor,
                        fontWeight: _getCurrentPresetName(contentType) != null
                            ? ThemeConstants.semiBold
                            : ThemeConstants.regular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: AnimatedRotation(
            turns: _isPresetsExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: ThemeConstants.accent,
              size: 28.sp,
            ),
          ),
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 1.1,
              children: TextStylePresets.all.map((preset) {
                return _buildEnhancedPresetCard(contentType, preset);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFontSettingsSection(ContentType contentType, TextSettings textSettings) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isFontSettingsExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isFontSettingsExpanded = expanded);
            HapticFeedback.selectionClick();
          },
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
          trailing: AnimatedRotation(
            turns: _isFontSettingsExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: ThemeConstants.info,
              size: 28.sp,
            ),
          ),
          children: [
            Column(
              children: [
                _buildEnhancedSlider(
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
                
                _buildExpandableFontSelector(
                  contentType: contentType,
                  currentFont: textSettings.fontFamily,
                  onChanged: (value) {
                    _updateSettings(
                      contentType,
                      textSettings: textSettings.copyWith(fontFamily: value!),
                    );
                  },
                ),
                
                SizedBox(height: 24.h),
                
                _buildEnhancedSlider(
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
                
                _buildEnhancedSlider(
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

  Widget _buildExpandableDisplaySettingsSection(ContentType contentType, DisplaySettings displaySettings) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isDisplaySettingsExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isDisplaySettingsExpanded = expanded);
            HapticFeedback.selectionClick();
          },
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
          trailing: AnimatedRotation(
            turns: _isDisplaySettingsExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: ThemeConstants.success,
              size: 28.sp,
            ),
          ),
          children: [
            Column(
              children: [
                _buildEnhancedSwitch(
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
                
                _buildEnhancedSwitch(
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
                
                _buildEnhancedSwitch(
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
                  _buildEnhancedSwitch(
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
                
                _buildEnhancedSwitch(
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
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedPresetCard(ContentType contentType, TextStylePreset preset) {
    final currentPreset = _getCurrentPresetName(contentType);
    final isSelected = currentPreset == preset.name;
    final presetColor = _getPresetColor(preset.name);
    final presetIcon = _getPresetIconData(preset.name);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          _applyPreset(contentType, preset);
        },
        borderRadius: BorderRadius.circular(18.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      presetColor,
                      presetColor.withOpacity(0.8),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      presetColor.withOpacity(0.08),
                      presetColor.withOpacity(0.12),
                    ],
                  ),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isSelected 
                  ? presetColor
                  : presetColor.withOpacity(0.25),
              width: isSelected ? 2.5.w : 1.5.w,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: presetColor.withOpacity(0.4),
                      blurRadius: 16.r,
                      offset: Offset(0, 6.h),
                    ),
                    BoxShadow(
                      color: presetColor.withOpacity(0.2),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الأيقونة
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isSelected ? 12.r : 10.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : presetColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 8.r,
                            spreadRadius: 2.r,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  presetIcon,
                  size: isSelected ? 26.sp : 22.sp,
                  color: isSelected ? Colors.white : presetColor,
                ),
              ),
              
              SizedBox(height: 10.h),
              
              // النص
              Text(
                preset.name,
                style: TextStyle(
                  fontSize: isSelected ? 14.sp : 13.sp,
                  fontWeight: isSelected ? ThemeConstants.bold : ThemeConstants.semiBold,
                  color: isSelected ? Colors.white : presetColor,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // علامة التحديد
              if (isSelected) ...[
                SizedBox(height: 8.h),
                AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8.r,
                          spreadRadius: 1.r,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: presetColor,
                      size: 16.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // دالة للتحقق من القالب المطبق حالياً
  String? _getCurrentPresetName(ContentType contentType) {
    final currentSettings = _currentSettings[contentType];
    if (currentSettings == null) return null;
    
    // التحقق من مطابقة الإعدادات الحالية مع أي قالب
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

  // دالة لتحديد لون كل قالب
  Color _getPresetColor(String presetName) {
    switch (presetName) {
      case 'قراءة مريحة':
        return const Color(0xFF10B981); // أخضر زمردي
      case 'واضح':
        return const Color(0xFF3B82F6); // أزرق سماوي
      case 'مضغوط':
        return const Color(0xFFF59E0B); // برتقالي ذهبي
      case 'موسع':
        return const Color(0xFF8B5CF6); // بنفسجي
      default:
        return ThemeConstants.primary;
    }
  }

  // دالة لتحديد أيقونة كل قالب
  IconData _getPresetIconData(String presetName) {
    switch (presetName) {
      case 'قراءة مريحة':
        return Icons.menu_book_rounded;
      case 'واضح':
        return Icons.wb_sunny_rounded;
      case 'مضغوط':
        return Icons.view_compact_rounded;
      case 'موسع':
        return Icons.open_in_full_rounded;
      default:
        return Icons.palette_rounded;
    }
  }

  // Widget جديد لقائمة الخطوط القابلة للتمدد
  Widget _buildExpandableFontSelector({
    required ContentType contentType,
    required String currentFont,
    required ValueChanged<String?> onChanged,
  }) {
    final recommendedFonts = TextSettingsConstants.getRecommendedFontsForContentType(contentType);
    bool isExpanded = false;
    
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          decoration: BoxDecoration(
            color: context.backgroundColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: context.dividerColor.withOpacity(0.2),
              width: 1.w,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              childrenPadding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
              onExpansionChanged: (expanded) {
                setLocalState(() => isExpanded = expanded);
                HapticFeedback.selectionClick();
              },
              title: Row(
                children: [
                  Icon(Icons.font_download_rounded, size: 20.sp, color: ThemeConstants.primary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نوع الخط',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: ThemeConstants.medium,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          TextSettingsConstants.availableFonts[currentFont] ?? currentFont,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontFamily: currentFont,
                            color: _getContentTypeColor(contentType),
                            fontWeight: ThemeConstants.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              trailing: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ThemeConstants.primary,
                  size: 28.sp,
                ),
              ),
              children: [
                Container(
                  constraints: BoxConstraints(maxHeight: 280.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(8.w),
                    itemCount: TextSettingsConstants.availableFonts.length,
                    separatorBuilder: (context, index) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final fontEntry = TextSettingsConstants.availableFonts.entries.elementAt(index);
                      final fontFamily = fontEntry.key;
                      final fontName = fontEntry.value;
                      final isSelected = currentFont == fontFamily;
                      final isRecommended = recommendedFonts.contains(fontFamily);
                      
                      return Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          onTap: () {
                            onChanged(fontFamily);
                            HapticFeedback.selectionClick();
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getContentTypeColor(contentType).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isSelected
                                    ? _getContentTypeColor(contentType).withOpacity(0.3)
                                    : context.dividerColor.withOpacity(0.2),
                                width: isSelected ? 2.w : 1.5.w,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              fontName,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: isSelected
                                                    ? ThemeConstants.bold
                                                    : ThemeConstants.medium,
                                                color: isSelected
                                                    ? _getContentTypeColor(contentType)
                                                    : context.textPrimaryColor,
                                                fontFamily: fontFamily,
                                              ),
                                            ),
                                          ),
                                          if (isRecommended) ...[
                                            SizedBox(width: 8.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8.w,
                                                vertical: 3.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: ThemeConstants.success.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6.r),
                                                border: Border.all(
                                                  color: ThemeConstants.success.withOpacity(0.3),
                                                  width: 1.w,
                                                ),
                                              ),
                                              child: Text(
                                                'موصى به',
                                                style: TextStyle(
                                                  fontSize: 10.sp,
                                                  fontWeight: ThemeConstants.bold,
                                                  color: ThemeConstants.success,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      SizedBox(height: 6.h),
                                      Text(
                                        'أ ب ت ث ج ح خ • ١ ٢ ٣ ٤',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontFamily: fontFamily,
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                AnimatedScale(
                                  scale: isSelected ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: BoxDecoration(
                                      color: _getContentTypeColor(contentType),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getContentTypeColor(contentType).withOpacity(0.4),
                                          blurRadius: 8.r,
                                          offset: Offset(0, 2.h),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSlider({
    required String title,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20.sp, color: color),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: ThemeConstants.medium,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5.w,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: ThemeConstants.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.15),
            trackHeight: 8.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 24.r),
            trackShape: RoundedRectSliderTrackShape(),
            tickMarkShape: RoundSliderTickMarkShape(tickMarkRadius: 0),
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

  Widget _buildEnhancedSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              gradient: value
                  ? LinearGradient(
                      colors: [
                        _getContentTypeColor(_selectedContentType).withOpacity(0.05),
                        _getContentTypeColor(_selectedContentType).withOpacity(0.08),
                      ],
                    )
                  : null,
              color: value ? null : context.backgroundColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: value
                    ? _getContentTypeColor(_selectedContentType).withOpacity(0.2)
                    : context.dividerColor.withOpacity(0.2),
                width: 1.5.w,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: value
                        ? _getContentTypeColor(_selectedContentType).withOpacity(0.1)
                        : context.dividerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    icon,
                    size: 22.sp,
                    color: value
                        ? _getContentTypeColor(_selectedContentType)
                        : context.textSecondaryColor,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: ThemeConstants.medium,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: _getContentTypeColor(_selectedContentType),
                    activeTrackColor: _getContentTypeColor(_selectedContentType).withOpacity(0.3),
                    inactiveThumbColor: context.textSecondaryColor,
                    inactiveTrackColor: context.dividerColor.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
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

  Color _getContentTypeColor(ContentType type) {
    switch (type) {
      case ContentType.athkar:
        return ThemeConstants.primary;
      case ContentType.dua:
        return ThemeConstants.accent;
      case ContentType.asmaAllah:
        return ThemeConstants.tertiary;
    }
  }

  IconData _getContentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.athkar:
        return Icons.article_rounded;
      case ContentType.dua:
        return Icons.volunteer_activism_rounded;
      case ContentType.asmaAllah:
        return Icons.star_rounded;
    }
  }

  String _getPreviewSubtitle(ContentType type) {
    switch (type) {
      case ContentType.athkar:
        return 'من أذكار الصباح';
      case ContentType.dua:
        return 'من الأدعية المأثورة';
      case ContentType.asmaAllah:
        return 'من أسماء الله الحسنى';
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
              child: Text(
                'إلغاء',
                style: TextStyle(fontSize: 14.sp),
              ),
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
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                ),
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
    final defaultSettings = TextSettingsConstants.getDefaultSettings(contentType);
    const defaultDisplaySettings = TextSettingsConstants.defaultDisplaySettings;
    
    setState(() {
      _selectedPresets[contentType] = null; // إعادة تعيين القالب
    });
    
    _updateSettings(
      contentType,
      textSettings: defaultSettings,
      displaySettings: defaultDisplaySettings,
    );
  }

  void _applyPreset(ContentType contentType, TextStylePreset preset) {
    final currentSettings = _currentSettings[contentType];
    if (currentSettings != null) {
      final updatedSettings = preset.applyToSettings(currentSettings);
      
      setState(() {
        _selectedPresets[contentType] = preset.name; // حفظ القالب المختار
      });
      
      _updateSettings(contentType, textSettings: updatedSettings);
      HapticFeedback.mediumImpact();
    }
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

  String _removeTashkeel(String text) {
    final tashkeelRegex = RegExp(r'[\u0617-\u061A\u064B-\u0652]');
    return text.replaceAll(tashkeelRegex, '');
  }
}

// Widget للزر الرجوع
class AppBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  
  const AppBackButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: context.cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_rounded,
          color: context.textPrimaryColor,
          size: 18.sp,
        ),
      ),
    );
  }
}