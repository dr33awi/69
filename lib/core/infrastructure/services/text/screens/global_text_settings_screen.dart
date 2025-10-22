// lib/core/infrastructure/services/text/screens/global_text_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import '../../../../../app/di/service_locator.dart';
import '../models/text_settings_models.dart';
import '../text_settings_service.dart';
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

class _GlobalTextSettingsScreenState extends State<GlobalTextSettingsScreen>
    with TickerProviderStateMixin {
  late final TextSettingsService _textService;
  late TabController _tabController;
  
  // الإعدادات الحالية لكل نوع محتوى
  final Map<ContentType, TextSettings> _currentSettings = {};
  final Map<ContentType, DisplaySettings> _currentDisplaySettings = {};
  
  // حالة التحميل والحفظ
  bool _isLoading = true;
  bool _isSaving = false;
  
  // معاينة النص
  final String _previewText = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ • الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';
  
  @override
  void initState() {
    super.initState();
    _textService = getIt<TextSettingsService>();
    _tabController = TabController(
      length: ContentType.values.length,
      vsync: this,
      initialIndex: widget.initialContentType?.index ?? 0,
    );
    _loadAllSettings();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحميل جميع الإعدادات
  Future<void> _loadAllSettings() async {
    setState(() => _isLoading = true);
    
    try {
      for (final contentType in ContentType.values) {
        _currentSettings[contentType] = await _textService.getTextSettings(contentType);
        _currentDisplaySettings[contentType] = await _textService.getDisplaySettings(contentType);
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// حفظ جميع الإعدادات
  Future<void> _saveAllSettings() async {
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: ThemeConstants.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      setState(() => _isSaving = false);
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء حفظ الإعدادات'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    }
  }

  /// تطبيق قالب على نوع محتوى معين
  Future<void> _applyPreset(ContentType contentType, TextStylePreset preset) async {
    final currentSettings = _currentSettings[contentType];
    if (currentSettings != null) {
      final updatedSettings = preset.applyToSettings(currentSettings);
      setState(() {
        _currentSettings[contentType] = updatedSettings;
      });
      
      HapticFeedback.lightImpact();
    }
  }

  /// إعادة تعيين إعدادات نوع محتوى معين
  Future<void> _resetToDefault(ContentType contentType) async {
    final confirmed = await _showResetConfirmDialog(contentType);
    if (confirmed == true) {
      final defaultSettings = TextSettingsConstants.getDefaultSettings(contentType);
      const defaultDisplaySettings = TextSettingsConstants.defaultDisplaySettings;
      
      setState(() {
        _currentSettings[contentType] = defaultSettings;
        _currentDisplaySettings[contentType] = defaultDisplaySettings;
      });
      
      HapticFeedback.lightImpact();
    }
  }

  /// عرض dialog تأكيد إعادة التعيين
  Future<bool?> _showResetConfirmDialog(ContentType contentType) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.restore, color: ThemeConstants.warning, size: 20.sp),
            SizedBox(width: 8.w),
            Text('إعادة تعيين ${contentType.displayName}', style: TextStyle(fontSize: 16.sp)),
          ],
        ),
        content: Text(
          'هل تريد إعادة جميع إعدادات ${contentType.displayName} إلى القيم الافتراضية؟',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: _buildAppBar(context),
      body: _isLoading
          ? _buildLoadingIndicator()
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: ContentType.values.map((contentType) {
                      return _buildContentTypeSettings(contentType);
                    }).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildSaveButton(),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.backgroundColor,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
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
        IconButton(
          onPressed: _showGlobalActions,
          icon: Icon(
            Icons.more_vert,
            color: context.textPrimaryColor,
            size: 20.sp,
          ),
        ),
      ],
    );
  }

  /// بناء شريط التبويبات
  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: ThemeConstants.primary,
        unselectedLabelColor: context.textSecondaryColor,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: ThemeConstants.medium),
        unselectedLabelStyle: TextStyle(fontSize: 11.sp),
        indicator: BoxDecoration(
          color: ThemeConstants.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: ContentType.values.map((contentType) {
          return Tab(
            text: contentType.displayName,
            icon: Icon(_getContentTypeIcon(contentType), size: 16.sp),
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
      case ContentType.quran:
        return Icons.auto_stories_rounded;
      case ContentType.hadith:
        return Icons.format_quote_rounded;
    }
  }

  /// بناء إعدادات نوع محتوى معين
  Widget _buildContentTypeSettings(ContentType contentType) {
    final textSettings = _currentSettings[contentType];
    final displaySettings = _currentDisplaySettings[contentType];
    
    if (textSettings == null || displaySettings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewSection(textSettings, displaySettings),
          SizedBox(height: 16.h),
          _buildPresetsSection(contentType, textSettings),
          SizedBox(height: 16.h),
          _buildFontSettingsSection(contentType, textSettings),
          SizedBox(height: 16.h),
          _buildDisplaySettingsSection(contentType, displaySettings),
          SizedBox(height: 16.h),
          _buildActionsSection(contentType),
          SizedBox(height: 100.h), // مساحة للـ FAB
        ],
      ),
    );
  }

  /// بناء قسم المعاينة
  Widget _buildPreviewSection(TextSettings textSettings, DisplaySettings displaySettings) {
    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                color: ThemeConstants.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'معاينة النص',
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? ThemeConstants.primary.withOpacity(0.08)
                  : ThemeConstants.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: ThemeConstants.primary.withOpacity(0.2),
                width: 1.w,
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
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_fix_high_rounded,
                color: ThemeConstants.accent,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'القوالب الجاهزة',
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: TextStylePresets.all.map((preset) {
              return _buildPresetButton(contentType, preset);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// بناء زر قالب جاهز
  Widget _buildPresetButton(ContentType contentType, TextStylePreset preset) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: () => _applyPreset(contentType, preset),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: ThemeConstants.tertiary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: ThemeConstants.tertiary.withOpacity(0.3),
              width: 1.w,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                preset.icon,
                size: 16.sp,
                color: ThemeConstants.tertiary,
              ),
              SizedBox(width: 4.w),
              Text(
                preset.name,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: ThemeConstants.medium,
                  color: ThemeConstants.tertiary,
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
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.font_download_rounded,
                color: ThemeConstants.info,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'إعدادات الخط',
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          _buildSliderSetting(
            title: 'حجم الخط',
            value: textSettings.fontSize,
            min: TextSettingsConstants.minFontSize,
            max: TextSettingsConstants.maxFontSize,
            divisions: 12,
            label: '${textSettings.fontSize.round()}',
            onChanged: (value) {
              setState(() {
                _currentSettings[contentType] = textSettings.copyWith(fontSize: value);
              });
            },
          ),
          
          SizedBox(height: 16.h),
          
          _buildDropdownSetting(
            title: 'نوع الخط',
            value: textSettings.fontFamily,
            items: TextSettingsConstants.availableFonts,
            onChanged: (value) {
              setState(() {
                _currentSettings[contentType] = textSettings.copyWith(fontFamily: value!);
              });
            },
          ),
          
          SizedBox(height: 16.h),
          
          _buildSliderSetting(
            title: 'تباعد الأسطر',
            value: textSettings.lineHeight,
            min: TextSettingsConstants.minLineHeight,
            max: TextSettingsConstants.maxLineHeight,
            divisions: 20,
            label: textSettings.lineHeight.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _currentSettings[contentType] = textSettings.copyWith(lineHeight: value);
              });
            },
          ),
          
          SizedBox(height: 16.h),
          
          _buildSliderSetting(
            title: 'تباعد الأحرف',
            value: textSettings.letterSpacing,
            min: TextSettingsConstants.minLetterSpacing,
            max: TextSettingsConstants.maxLetterSpacing,
            divisions: 20,
            label: textSettings.letterSpacing.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _currentSettings[contentType] = textSettings.copyWith(letterSpacing: value);
              });
            },
          ),
        ],
      ),
    );
  }

  /// بناء قسم إعدادات العرض
  Widget _buildDisplaySettingsSection(ContentType contentType, DisplaySettings displaySettings) {
    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                color: ThemeConstants.success,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'إعدادات العرض',
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          _buildSwitchSetting(
            title: 'إظهار التشكيل',
            subtitle: 'عرض الحركات والتشكيل على النص',
            value: displaySettings.showTashkeel,
            onChanged: (value) {
              setState(() {
                _currentDisplaySettings[contentType] = displaySettings.copyWith(showTashkeel: value);
              });
            },
          ),
          
          _buildSwitchSetting(
            title: 'إظهار الفضيلة',
            subtitle: 'عرض فضل الذكر إن وجد',
            value: displaySettings.showFadl,
            onChanged: (value) {
              setState(() {
                _currentDisplaySettings[contentType] = displaySettings.copyWith(showFadl: value);
              });
            },
          ),
          
          _buildSwitchSetting(
            title: 'إظهار المصدر',
            subtitle: 'عرض مصدر النص',
            value: displaySettings.showSource,
            onChanged: (value) {
              setState(() {
                _currentDisplaySettings[contentType] = displaySettings.copyWith(showSource: value);
              });
            },
          ),
          
          if (contentType == ContentType.athkar)
            _buildSwitchSetting(
              title: 'إظهار العداد',
              subtitle: 'عرض عداد التكرار للأذكار',
              value: displaySettings.showCounter,
              onChanged: (value) {
                setState(() {
                  _currentDisplaySettings[contentType] = displaySettings.copyWith(showCounter: value);
                });
              },
            ),
          
          _buildSwitchSetting(
            title: 'الاهتزاز',
            subtitle: 'تفعيل الاهتزاز عند اللمس',
            value: displaySettings.enableVibration,
            onChanged: (value) {
              setState(() {
                _currentDisplaySettings[contentType] = displaySettings.copyWith(enableVibration: value);
              });
            },
          ),
        ],
      ),
    );
  }

  /// بناء قسم الإجراءات
  Widget _buildActionsSection(ContentType contentType) {
    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_rounded,
                color: ThemeConstants.warning,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'إجراءات',
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _resetToDefault(contentType),
              icon: Icon(Icons.restore, size: 18.sp),
              label: Text('إعادة للافتراضي'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeConstants.warning,
                side: BorderSide(color: ThemeConstants.warning),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء إعداد منزلق
  Widget _buildSliderSetting({
    required String title,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: ThemeConstants.medium,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ThemeConstants.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: ThemeConstants.medium,
                  color: ThemeConstants.primary,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: ThemeConstants.primary,
            inactiveTrackColor: ThemeConstants.primary.withOpacity(0.3),
            thumbColor: ThemeConstants.primary,
            overlayColor: ThemeConstants.primary.withOpacity(0.2),
            trackHeight: 4.h,
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
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: ThemeConstants.medium,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: context.dividerColor.withOpacity(0.5),
              width: 1.w,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            items: items.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: TextStyle(fontSize: 14.sp),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: Icon(Icons.arrow_drop_down, size: 20.sp),
          ),
        ),
      ],
    );
  }

  /// بناء إعداد مفتاح
  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: ThemeConstants.medium,
                  ),
                ),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ThemeConstants.primary,
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
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل الإعدادات...',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء زر الحفظ
  Widget _buildSaveButton() {
    return FloatingActionButton.extended(
      onPressed: _isSaving ? null : _saveAllSettings,
      backgroundColor: ThemeConstants.primary,
      foregroundColor: Colors.white,
      icon: _isSaving
          ? SizedBox(
              width: 16.w,
              height: 16.h,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
                strokeWidth: 2,
              ),
            )
          : Icon(Icons.save_rounded, size: 20.sp),
      label: Text(
        _isSaving ? 'جاري الحفظ...' : 'حفظ الإعدادات',
        style: TextStyle(fontSize: 14.sp, fontWeight: ThemeConstants.medium),
      ),
    );
  }

  /// عرض الإجراءات العامة
  void _showGlobalActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.font_download_rounded, color: ThemeConstants.primary),
              title: const Text('تعيين خط عام'),
              subtitle: const Text('تطبيق خط واحد على جميع الأنواع'),
              onTap: () {
                Navigator.pop(context);
                _showGlobalFontDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.auto_fix_high_rounded, color: ThemeConstants.accent),
              title: const Text('تطبيق قالب على الكل'),
              subtitle: const Text('تطبيق قالب جاهز على جميع الأنواع'),
              onTap: () {
                Navigator.pop(context);
                _showGlobalPresetDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.restore_rounded, color: ThemeConstants.warning),
              title: const Text('إعادة تعيين الكل'),
              subtitle: const Text('إعادة جميع الإعدادات للافتراضي'),
              onTap: () {
                Navigator.pop(context);
                _showGlobalResetDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// عرض dialog اختيار خط عام
  void _showGlobalFontDialog() {
    // TODO: تنفيذ لاحقاً
  }

  /// عرض dialog اختيار قالب عام
  void _showGlobalPresetDialog() {
    // TODO: تنفيذ لاحقاً
  }

  /// عرض dialog إعادة تعيين عام
  void _showGlobalResetDialog() {
    // TODO: تنفيذ لاحقاً
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
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: child,
    );
  }
}