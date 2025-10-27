// lib/core/infrastructure/services/text/screens/global_text_settings_screen.dart
import 'package:athkar_app/core/infrastructure/services/text_settings/constants/text_settings_constants.dart'; // ✅ المسار الصحيح
import 'package:athkar_app/core/infrastructure/services/text_settings/widgets/shared_widgets.dart';
import 'package:athkar_app/core/infrastructure/services/text_settings/widgets/text_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
import '../../../../../app/themes/app_theme.dart';
import '../../../../../app/themes/widgets/layout/app_bar.dart' as app_bar;
import '../../../../../app/di/service_locator.dart';
import '../models/text_settings_models.dart';
import '../service/text_settings_service.dart';


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

class _GlobalTextSettingsScreenState extends State<GlobalTextSettingsScreen> 
    with SingleTickerProviderStateMixin {
  late final TextSettingsService _textService;
  late TabController _tabController;
  
  final Map<ContentType, TextSettings> _currentSettings = {};
  final Map<ContentType, DisplaySettings> _currentDisplaySettings = {};
  final Map<ContentType, TextSettings> _originalSettings = {};
  final Map<ContentType, DisplaySettings> _originalDisplaySettings = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  
  final Map<ContentType, String?> _selectedPresets = {};
  
  // نصوص المعاينة
  final Map<ContentType, String> _previewTexts = {
    ContentType.athkar: '''سُبْحَانَ اللَّهِ وَبِحَمْدِهِ''',
    ContentType.dua: '''رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً
وَفِي الْآخِرَةِ حَسَنَةً
وَقِنَا عَذَابَ النَّارِ''',
    ContentType.asmaAllah: '''الرَّحْمَنُ • الرَّحِيمُ • الْمَلِكُ''',

  };
  
  // بيانات المعاينة الإضافية (الفضيلة والمصدر والعداد)
  final Map<ContentType, Map<String, dynamic>> _previewMetadata = {
    ContentType.athkar: {
      'fadl': 'من قالها مائة مرة في يوم حُطَّت خطاياه وإن كانت مثل زبد البحر',
      'source': 'متفق عليه',
      'count': 100,
      'currentCount': 45,
    },
    ContentType.dua: {
      'fadl': 'من الأدعية الجامعة التي كان النبي ﷺ يكثر منها',
      'source': 'البقرة: 201',
    },
    ContentType.asmaAllah: {
      // أسماء الله لا تحتاج لفضيلة أو مصدر في المعاينة
    },
  };

  // خريطة الألوان
  final Map<ContentType, Color> _colorMap = {
    ContentType.athkar: ThemeConstants.primary,
    ContentType.dua: ThemeConstants.accent,
    ContentType.asmaAllah: ThemeConstants.tertiary,
  };

  @override
  void initState() {
    super.initState();
    _textService = getIt<TextSettingsService>();
    
    // تهيئة TabController
    _tabController = TabController(
      length: ContentType.values.length,
      vsync: this,
    );
    
    // تعيين التاب الافتراضي
    if (widget.initialContentType != null) {
      final index = ContentType.values.indexOf(widget.initialContentType!);
      _tabController.index = index;
    }
    
    _tabController.addListener(_onTabChanged);
    
    _loadAllSettings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
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
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: ThemeConstants.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: ThemeConstants.warning.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeConstants.warning.withValues(alpha: 0.15),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
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
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
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
              _buildTabBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : TabBarView(
                        controller: _tabController,
                        children: ContentType.values.map((contentType) {
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildContentTypeSettings(contentType),
                                SizedBox(height: 60.h),
                              ],
                            ),
                          );
                        }).toList(),
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
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeConstants.info,
                  ThemeConstants.info.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.15 : 0.06,
                  ),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.08 : 0.03,
                  ),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                  spreadRadius: -1,
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
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _saveAllSettings();
                  },
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: context.dividerColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDarkMode ? 0.15 : 0.06,
                          ),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDarkMode ? 0.08 : 0.03,
                          ),
                          blurRadius: 6.r,
                          offset: Offset(0, 2.h),
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.save,
                      color: ThemeConstants.success,
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
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  onTap: _showResetDialog,
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: context.dividerColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDarkMode ? 0.15 : 0.06,
                          ),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDarkMode ? 0.08 : 0.03,
                          ),
                          blurRadius: 6.r,
                          offset: Offset(0, 2.h),
                          spreadRadius: -1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.restore_rounded,
                      color: ThemeConstants.warning,
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

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: ThemeConstants.accent,
        unselectedLabelColor: context.textSecondaryColor,
        indicatorColor: ThemeConstants.accent,
        indicatorWeight: 3.h,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: ThemeConstants.semiBold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: ThemeConstants.regular,
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        tabs: ContentType.values.map((type) {
          final icon = type == ContentType.athkar 
              ? Icons.menu_book_rounded 
              : type == ContentType.dua 
                  ? FlutterIslamicIcons.solidPrayer 
                  : FlutterIslamicIcons.solidAllah;
          
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18.sp),
                SizedBox(width: 4.w),
                Text(type.displayName),
              ],
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

    final accentColor = _colorMap[contentType] ?? ThemeConstants.primary;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
      child: Column(
        children: [
          // معاينة النص المحسّنة مع جميع التحكمات
          TextPreviewWidget(
            contentType: contentType,
            textSettings: textSettings,
            displaySettings: displaySettings,
            accentColor: accentColor,
            previewTexts: _previewTexts,
            previewMetadata: _previewMetadata,
            currentPresetName: _getCurrentPresetName(contentType),
            onPresetSelected: (preset) => _applyPreset(contentType, preset),
            onFontChanged: (newFont) {
              _updateSettings(
                contentType,
                textSettings: textSettings.copyWith(fontFamily: newFont),
              );
            },
            onFontSizeChanged: (newSize) {
              _updateSettings(
                contentType,
                textSettings: textSettings.copyWith(fontSize: newSize),
              );
            },
            onLineHeightChanged: (newHeight) {
              _updateSettings(
                contentType,
                textSettings: textSettings.copyWith(lineHeight: newHeight),
              );
            },
            onLetterSpacingChanged: (newSpacing) {
              _updateSettings(
                contentType,
                textSettings: textSettings.copyWith(letterSpacing: newSpacing),
              );
            },
          ),
          
          SizedBox(height: 20.h),
          
          // إعدادات العرض فقط (تم نقل إعدادات الخط والقوالب إلى كارد المعاينة)
          _buildDisplaySettingsSection(contentType, displaySettings, accentColor),
        ],
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

  void _showResetDialog() async {
    _showResetAllDialog();
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