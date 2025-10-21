// lib/features/athkar/screens/text_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../services/athkar_service.dart';
import '../constants/athkar_constants.dart';

class AthkarTextSettingsScreen extends StatefulWidget {
  const AthkarTextSettingsScreen({super.key});

  @override
  State<AthkarTextSettingsScreen> createState() => _AthkarTextSettingsScreenState();
}

class _AthkarTextSettingsScreenState extends State<AthkarTextSettingsScreen> {
  late final AthkarService _service;
  late final StorageService _storage;
  
  // إعدادات حجم الخط
  double _fontSize = AthkarConstants.defaultFontSize;
  
  // إعدادات نوع الخط
  String _fontFamily = ThemeConstants.fontFamilyArabic;
  
  // إعدادات التباعد
  double _lineHeight = 1.8;
  double _letterSpacing = 0.3;
  
  // إعدادات العرض
  bool _showTashkeel = true;
  bool _showFadl = true;
  bool _showSource = true;
  bool _showCounter = true;
  bool _enableVibration = true;
  
  // نص تجريبي للمعاينة
  final String _previewText = 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ';
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _service = getIt<AthkarService>();
    _storage = getIt<StorageService>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // تحميل حجم الخط
      _fontSize = await _service.getSavedFontSize();
      
      // تحميل إعدادات أخرى من التخزين
      _fontFamily = _storage.getString('athkar_font_family') ?? ThemeConstants.fontFamilyArabic;
      _lineHeight = _storage.getDouble('athkar_line_height') ?? 1.8;
      _letterSpacing = _storage.getDouble('athkar_letter_spacing') ?? 0.3;
      
      _showTashkeel = _storage.getBool('athkar_show_tashkeel') ?? true;
      _showFadl = _storage.getBool('athkar_show_fadl') ?? true;
      _showSource = _storage.getBool('athkar_show_source') ?? true;
      _showCounter = _storage.getBool('athkar_show_counter') ?? true;
      _enableVibration = _storage.getBool('athkar_enable_vibration') ?? true;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    try {
      // حفظ حجم الخط
      await _service.saveFontSize(_fontSize);
      
      // حفظ الإعدادات الأخرى
      await _storage.setString('athkar_font_family', _fontFamily);
      await _storage.setDouble('athkar_line_height', _lineHeight);
      await _storage.setDouble('athkar_letter_spacing', _letterSpacing);
      
      await _storage.setBool('athkar_show_tashkeel', _showTashkeel);
      await _storage.setBool('athkar_show_fadl', _showFadl);
      await _storage.setBool('athkar_show_source', _showSource);
      await _storage.setBool('athkar_show_counter', _showCounter);
      await _storage.setBool('athkar_enable_vibration', _enableVibration);
      
      if (_enableVibration) {
        HapticFeedback.mediumImpact();
      }
      
      if (mounted) {
        context.showSuccessSnackBar('تم حفظ الإعدادات بنجاح');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('فشل حفظ الإعدادات');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefaults() async {
    final shouldReset = await AppInfoDialog.showConfirmation(
      context: context,
      title: 'إعادة تعيين الإعدادات',
      content: 'هل تريد إعادة جميع الإعدادات إلى القيم الافتراضية؟',
      confirmText: 'إعادة تعيين',
      cancelText: 'إلغاء',
      icon: Icons.restore,
      destructive: true,
    );
    
    if (shouldReset == true) {
      setState(() {
        _fontSize = AthkarConstants.defaultFontSize;
        _fontFamily = ThemeConstants.fontFamilyArabic;
        _lineHeight = 1.8;
        _letterSpacing = 0.3;
        _showTashkeel = true;
        _showFadl = true;
        _showSource = true;
        _showCounter = true;
        _enableVibration = true;
      });
      
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: AppLoading.page(
                    message: 'جاري تحميل الإعدادات...',
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreviewSection(),
                      SizedBox(height: 20.h),
                      _buildFontSettingsSection(),
                      SizedBox(height: 20.h),
                      _buildDisplaySettingsSection(),
                      SizedBox(height: 20.h),
                      _buildAdvancedSettingsSection(),
                      SizedBox(height: 80.h), // للزر العائم
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 8.w),
          
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withOpacity(0.25),
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
                  'إعدادات النص',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 17.sp,
                  ),
                ),
                Text(
                  'تخصيص عرض الأذكار',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: _resetToDefaults,
            icon: Icon(
              Icons.restore,
              color: context.textSecondaryColor,
              size: 22.sp,
            ),
            tooltip: 'إعادة تعيين',
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
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
              _showTashkeel ? _previewText : _removeTashkeel(_previewText),
              style: TextStyle(
                fontSize: _fontSize.sp,
                height: _lineHeight,
                letterSpacing: _letterSpacing,
                fontFamily: _fontFamily,
                fontWeight: ThemeConstants.regular,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSettingsSection() {
    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.font_download_rounded,
                color: ThemeConstants.accent,
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
          
          // حجم الخط
          _buildSliderSetting(
            title: 'حجم الخط',
            value: _fontSize,
            min: AthkarConstants.minFontSize,
            max: AthkarConstants.maxFontSize,
            divisions: 8,
            label: '${_fontSize.round()}',
            onChanged: (value) {
              setState(() => _fontSize = value);
            },
          ),
          
          SizedBox(height: 16.h),
          
          // نوع الخط
          _buildDropdownSetting(
            title: 'نوع الخط',
            value: _fontFamily,
            items: const {
              'Cairo': 'القاهرة',
              'Amiri': 'أميري',
              'AmiriQuran': 'أميري قرآن',
            },
            onChanged: (value) {
              setState(() => _fontFamily = value!);
            },
          ),
          
          SizedBox(height: 16.h),
          
          // تباعد الأسطر
          _buildSliderSetting(
            title: 'تباعد الأسطر',
            value: _lineHeight,
            min: 1.2,
            max: 2.5,
            divisions: 13,
            label: _lineHeight.toStringAsFixed(1),
            onChanged: (value) {
              setState(() => _lineHeight = value);
            },
          ),
          
          SizedBox(height: 16.h),
          
          // تباعد الأحرف
          _buildSliderSetting(
            title: 'تباعد الأحرف',
            value: _letterSpacing,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: _letterSpacing.toStringAsFixed(1),
            onChanged: (value) {
              setState(() => _letterSpacing = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySettingsSection() {
    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                color: ThemeConstants.info,
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
            value: _showTashkeel,
            onChanged: (value) {
              setState(() => _showTashkeel = value);
            },
          ),
          
          _buildSwitchSetting(
            title: 'إظهار الفضيلة',
            subtitle: 'عرض فضل الذكر إن وجد',
            value: _showFadl,
            onChanged: (value) {
              setState(() => _showFadl = value);
            },
          ),
          
          _buildSwitchSetting(
            title: 'إظهار المصدر',
            subtitle: 'عرض مصدر الحديث أو الذكر',
            value: _showSource,
            onChanged: (value) {
              setState(() => _showSource = value);
            },
          ),
          
          _buildSwitchSetting(
            title: 'إظهار العداد',
            subtitle: 'عرض عداد التكرار للأذكار',
            value: _showCounter,
            onChanged: (value) {
              setState(() => _showCounter = value);
            },
          ),
          
          _buildSwitchSetting(
            title: 'الاهتزاز عند اللمس',
            subtitle: 'تفعيل الاهتزاز عند التفاعل',
            value: _enableVibration,
            onChanged: (value) {
              setState(() => _enableVibration = value);
              if (value) {
                HapticFeedback.lightImpact();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_applications_rounded,
                color: ThemeConstants.error,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'إعدادات متقدمة',
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          Text(
            'قوالب جاهزة',
            style: TextStyle(
              fontWeight: ThemeConstants.semiBold,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _PresetButton(
                title: 'قراءة مريحة',
                onTap: () {
                  setState(() {
                    _fontSize = 20.0;
                    _lineHeight = 2.0;
                    _letterSpacing = 0.5;
                  });
                },
              ),
              _PresetButton(
                title: 'مضغوط',
                onTap: () {
                  setState(() {
                    _fontSize = 16.0;
                    _lineHeight = 1.5;
                    _letterSpacing = 0.1;
                  });
                },
              ),
              _PresetButton(
                title: 'كبار السن',
                onTap: () {
                  setState(() {
                    _fontSize = 24.0;
                    _lineHeight = 2.2;
                    _letterSpacing = 0.7;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                fontSize: 12.sp,
                fontWeight: ThemeConstants.medium,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: ThemeConstants.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: ThemeConstants.primary,
                  fontWeight: ThemeConstants.bold,
                  fontSize: 11.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            activeColor: ThemeConstants.primary,
            inactiveColor: ThemeConstants.primary.withOpacity(0.2),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

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
            fontSize: 12.sp,
            fontWeight: ThemeConstants.medium,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: context.dividerColor.withOpacity(0.3),
              width: 1.w,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontFamily: entry.key,
                      fontSize: 14.sp,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: ThemeConstants.medium,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: ThemeConstants.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_hasChanges())
          FloatingActionButton.small(
            onPressed: _loadSettings,
            backgroundColor: context.surfaceColor,
            elevation: 4,
            tooltip: 'تراجع',
            child: Icon(
              Icons.undo_rounded,
              color: context.textSecondaryColor,
            ),
          ),
        SizedBox(height: 8.h),
        FloatingActionButton.extended(
          onPressed: _isSaving ? null : _saveSettings,
          backgroundColor: ThemeConstants.primary,
          elevation: 8,
          label: Row(
            children: [
              if (_isSaving)
                SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  Icons.save_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              SizedBox(width: 8.w),
              Text(
                _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: ThemeConstants.semiBold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasChanges() {
    // التحقق من وجود تغييرات غير محفوظة
    // يمكنك تحسين هذه الدالة للمقارنة مع القيم الأصلية
    return true;
  }

  String _removeTashkeel(String text) {
    // إزالة التشكيل من النص
    final tashkeelRegex = RegExp(r'[\u0617-\u061A\u064B-\u0652]');
    return text.replaceAll(tashkeelRegex, '');
  }
}

// ويدجت زر القالب الجاهز
class _PresetButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  
  const _PresetButton({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 8.h,
          ),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: context.dividerColor.withOpacity(0.3),
              width: 1.w,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: ThemeConstants.medium,
            ),
          ),
        ),
      ),
    );
  }
}