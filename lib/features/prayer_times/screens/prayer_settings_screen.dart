// lib/features/prayer_times/screens/prayer_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/prayer_times_service.dart';
import '../models/prayer_time_model.dart';

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({super.key});

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> {
  late final PrayerTimesService _prayerService;
  
  late PrayerCalculationSettings _calculationSettings;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadSettings();
  }

  void _initializeServices() {
    _prayerService = getIt<PrayerTimesService>();
  }

  void _loadSettings() {
    setState(() {
      _calculationSettings = _prayerService.calculationSettings;
      _isLoading = false;
    });
  }

  void _markAsChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    try {
      await _prayerService.updateCalculationSettings(_calculationSettings);
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            
            Expanded(
              child: _isLoading
                  ? Center(child: AppLoading.circular())
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildCalculationSection(),
                        ),
                        
                        SliverToBoxAdapter(
                          child: _buildJuristicSection(),
                        ),
                        
                        SliverToBoxAdapter(
                          child: _buildManualAdjustmentsSection(),
                        ),
                        
                        SliverToBoxAdapter(
                          child: _buildSaveButton(),
                        ),
                        
                        SliverToBoxAdapter(
                          child: SizedBox(height: 20.h),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    const gradient = LinearGradient(
      colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () {
              if (_hasChanges) {
                _showUnsavedChangesDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          
          SizedBox(width: 8.w),
          
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              gradient: gradient,
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
              Icons.settings,
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
                  'إعدادات المواقيت',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  'طريقة حساب أوقات الصلاة',
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
                    _saveSettings();
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
        ],
      ),
    );
  }

  void _showUnsavedChangesDialog() async {
    final result = await AppInfoDialog.showConfirmation(
      context: context,
      title: 'تغييرات غير محفوظة',
      content: 'لديك تغييرات لم يتم حفظها. هل تريد حفظ التغييرات قبل المغادرة؟',
      confirmText: 'حفظ وخروج',
      cancelText: 'تجاهل التغييرات',
    );
    
    if (!mounted) return;
    
    if (result == true) {
      await _saveSettings();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildCalculationSection() {
    return SettingsSection(
      title: 'طريقة الحساب',
      icon: Icons.calculate,
      children: [
        _buildCalculationMethodTile(),
      ],
    );
  }

  Widget _buildCalculationMethodTile() {
    final methodNames = {
      CalculationMethod.muslimWorldLeague: 'رابطة العالم الإسلامي',
      CalculationMethod.egyptian: 'الهيئة المصرية',
      CalculationMethod.karachi: 'جامعة كراتشي',
      CalculationMethod.ummAlQura: 'أم القرى',
      CalculationMethod.dubai: 'دبي',
      CalculationMethod.qatar: 'قطر',
      CalculationMethod.kuwait: 'الكويت',
      CalculationMethod.singapore: 'سنغافورة',
      CalculationMethod.northAmerica: 'أمريكا الشمالية',
      CalculationMethod.other: 'أخرى',
    };
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      title: Text('طريقة الحساب', style: TextStyle(fontSize: 13.sp)),
      subtitle: Text(methodNames[_calculationSettings.method] ?? '', style: TextStyle(fontSize: 11.sp)),
      trailing: Icon(Icons.chevron_right, size: 20.sp),
      onTap: () {
        _showCalculationMethodDialog();
      },
    );
  }

  void _showCalculationMethodDialog() {
    showDialog(
      context: context,
      builder: (context) => CalculationMethodDialog(
        currentMethod: _calculationSettings.method,
        onMethodSelected: (method) {
          setState(() {
            _calculationSettings = _calculationSettings.copyWith(
              method: method,
            );
            _markAsChanged();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildJuristicSection() {
    return SettingsSection(
      title: 'المذهب الفقهي',
      icon: Icons.school,
      children: [
        RadioListTile<AsrJuristic>(
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          title: Text('الجمهور', style: TextStyle(fontSize: 13.sp)),
          subtitle: Text('الشافعي، المالكي، الحنبلي', style: TextStyle(fontSize: 11.sp)),
          value: AsrJuristic.standard,
          groupValue: _calculationSettings.asrJuristic,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _calculationSettings = _calculationSettings.copyWith(
                  asrJuristic: value,
                );
                _markAsChanged();
              });
            }
          },
          activeColor: ThemeConstants.success,
        ),
        RadioListTile<AsrJuristic>(
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          title: Text('الحنفي', style: TextStyle(fontSize: 13.sp)),
          subtitle: Text('المذهب الحنفي', style: TextStyle(fontSize: 11.sp)),
          value: AsrJuristic.hanafi,
          groupValue: _calculationSettings.asrJuristic,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _calculationSettings = _calculationSettings.copyWith(
                  asrJuristic: value,
                );
                _markAsChanged();
              });
            }
          },
          activeColor: ThemeConstants.success,
        ),
      ],
    );
  }

  Widget _buildManualAdjustmentsSection() {
    return SettingsSection(
      title: 'تعديلات يدوية',
      icon: Icons.tune,
      subtitle: 'تعديل أوقات الصلاة بالدقائق',
      children: [
        _buildAdjustmentTile('الفجر', 'fajr'),
        _buildAdjustmentTile('الشروق', 'sunrise'),
        _buildAdjustmentTile('الظهر', 'dhuhr'),
        _buildAdjustmentTile('العصر', 'asr'),
        _buildAdjustmentTile('المغرب', 'maghrib'),
        _buildAdjustmentTile('العشاء', 'isha'),
      ],
    );
  }

  Widget _buildAdjustmentTile(String name, String key) {
    final adjustment = _calculationSettings.manualAdjustments[key] ?? 0;
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      title: Text(name, style: TextStyle(fontSize: 13.sp)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove_circle_outline, size: 20.sp),
            color: ThemeConstants.success,
            padding: EdgeInsets.all(6.r),
            constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
            onPressed: () {
              _updateAdjustment(key, adjustment - 1);
            },
          ),
          SizedBox(
            width: 42.w,
            child: Text(
              adjustment > 0 ? '+$adjustment' : adjustment.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: ThemeConstants.semiBold,
                fontSize: 14.sp,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, size: 20.sp),
            color: ThemeConstants.success,
            padding: EdgeInsets.all(6.r),
            constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
            onPressed: () {
              _updateAdjustment(key, adjustment + 1);
            },
          ),
        ],
      ),
    );
  }

  void _updateAdjustment(String key, int value) {
    setState(() {
      final adjustments = Map<String, int>.from(
        _calculationSettings.manualAdjustments,
      );
      adjustments[key] = value.clamp(-30, 30);
      
      _calculationSettings = _calculationSettings.copyWith(
        manualAdjustments: adjustments,
      );
      _markAsChanged();
    });
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.all(12.r),
      child: AppButton.primary(
        text: 'حفظ الإعدادات',
        onPressed: _isSaving || !_hasChanges ? null : _saveSettings,
        isLoading: _isSaving,
        isFullWidth: true,
        icon: Icons.save,
        backgroundColor: ThemeConstants.success,
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: ThemeConstants.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: ThemeConstants.success,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: ThemeConstants.semiBold,
                        fontSize: 14.sp,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Card(
          margin: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 6.h,
          ),
          color: context.cardColor,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class CalculationMethodDialog extends StatelessWidget {
  final CalculationMethod currentMethod;
  final Function(CalculationMethod) onMethodSelected;

  const CalculationMethodDialog({
    super.key,
    required this.currentMethod,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [
      (CalculationMethod.muslimWorldLeague, 'رابطة العالم الإسلامي', 'الفجر 18°، العشاء 17°'),
      (CalculationMethod.egyptian, 'الهيئة المصرية', 'الفجر 19.5°، العشاء 17.5°'),
      (CalculationMethod.karachi, 'جامعة كراتشي', 'الفجر 18°، العشاء 18°'),
      (CalculationMethod.ummAlQura, 'أم القرى', 'الفجر 18.5°، العشاء 90 دقيقة'),
      (CalculationMethod.dubai, 'دبي', 'الفجر 18.2°، العشاء 18.2°'),
      (CalculationMethod.qatar, 'قطر', 'الفجر 18°، العشاء 90 دقيقة'),
      (CalculationMethod.kuwait, 'الكويت', 'الفجر 18°، العشاء 17.5°'),
      (CalculationMethod.singapore, 'سنغافورة', 'الفجر 20°، العشاء 18°'),
      (CalculationMethod.northAmerica, 'أمريكا الشمالية', 'الفجر 15°، العشاء 15°'),
    ];
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(14.r),
            child: Text(
              'اختر طريقة الحساب',
              style: TextStyle(
                fontWeight: ThemeConstants.semiBold,
                fontSize: 16.sp,
              ),
            ),
          ),
          
          Divider(height: 1.h),
          
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: methods.map((method) {
                  return RadioListTile<CalculationMethod>(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                    title: Text(method.$2, style: TextStyle(fontSize: 13.sp)),
                    subtitle: Text(
                      method.$3,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 11.sp,
                      ),
                    ),
                    value: method.$1,
                    groupValue: currentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        onMethodSelected(value);
                      }
                    },
                    activeColor: ThemeConstants.success,
                  );
                }).toList(),
              ),
            ),
          ),
          
          Divider(height: 1.h),
          
          Padding(
            padding: EdgeInsets.all(10.r),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: ThemeConstants.success,
              ),
              child: Text('إلغاء', style: TextStyle(fontSize: 13.sp)),
            ),
          ),
        ],
      ),
    );
  }
}