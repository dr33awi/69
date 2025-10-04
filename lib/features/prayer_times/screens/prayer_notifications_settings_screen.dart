// lib/features/prayer_times/screens/prayer_notifications_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/prayer_times_service.dart';
import '../models/prayer_time_model.dart';

class PrayerNotificationsSettingsScreen extends StatefulWidget {
  const PrayerNotificationsSettingsScreen({super.key});

  @override
  State<PrayerNotificationsSettingsScreen> createState() => _PrayerNotificationsSettingsScreenState();
}

class _PrayerNotificationsSettingsScreenState extends State<PrayerNotificationsSettingsScreen> {
  late final PrayerTimesService _prayerService;
  
  late PrayerNotificationSettings _notificationSettings;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  // استخدام اللون الأخضر الموحد
  final Color _primaryGreenColor = ThemeConstants.success;

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
      _notificationSettings = _prayerService.notificationSettings;
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
      await _prayerService.updateNotificationSettings(_notificationSettings);
      
      debugPrint('Prayer notification settings updated - '
          'enabled: ${_notificationSettings.enabled}, '
          'enabled_prayers_count: ${_notificationSettings.enabledPrayers.values.where((v) => v).length}');
      
      if (!mounted) return;
      
      context.showSuccessSnackBar('تم حفظ إعدادات الإشعارات بنجاح');
      setState(() {
        _hasChanges = false;
      });
    } catch (e) {
      debugPrint('خطأ في حفظ إعدادات الإشعارات: $e');
      
      if (!mounted) return;
      
      context.showErrorSnackBar('فشل حفظ إعدادات الإشعارات');
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
            // Custom AppBar محسن
            _buildCustomAppBar(context),
            
            // المحتوى
            Expanded(
              child: _isLoading
                  ? Center(child: AppLoading.circular())
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    // استخدام نفس التدرج المستخدم في CategoryGrid لفئة prayer_times
    const gradient = LinearGradient(
      colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // زر الرجوع
          AppBackButton(
            onPressed: () {
              if (_hasChanges) {
                _showUnsavedChangesDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          
          SizedBox(width: 12.w),
          
          // الأيقونة الجانبية مع نفس التدرج المستخدم في CategoryGrid
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withOpacity(0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // العنوان والوصف
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات إشعارات الصلوات',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  'تخصيص تنبيهات أوقات الصلاة',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          
          // زر الحفظ
          if (_hasChanges && !_isSaving)
            Container(
              margin: EdgeInsets.only(left: 8.w),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _saveSettings();
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.dividerColor.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.save,
                      color: ThemeConstants.primary,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // القسم الرئيسي للإعدادات
        SliverToBoxAdapter(
          child: _buildMainSettingsSection(),
        ),
        
        // قسم الإشعارات لكل صلاة
        SliverToBoxAdapter(
          child: _buildPrayerNotificationsSection(),
        ),
        
        // زر الحفظ
        SliverToBoxAdapter(
          child: _buildSaveButton(),
        ),
        
        // مساحة في الأسفل
        SliverToBoxAdapter(
          child: SizedBox(height: 80.h),
        ),
      ],
    );
  }

  Widget _buildMainSettingsSection() {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: _primaryGreenColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: _primaryGreenColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات الإشعارات العامة',
                        style: TextStyle(
                          fontWeight: ThemeConstants.semiBold,
                          fontSize: 16.sp,
                        ),
                      ),
                      Text(
                        'تفعيل أو تعطيل الإشعارات لجميع الصلوات',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // تفعيل/تعطيل الإشعارات
          SwitchListTile(
            title: const Text('تفعيل الإشعارات'),
            subtitle: const Text('تلقي تنبيهات أوقات الصلاة'),
            value: _notificationSettings.enabled,
            onChanged: (value) {
              setState(() {
                _notificationSettings = _notificationSettings.copyWith(
                  enabled: value,
                );
                _markAsChanged();
              });
            },
            activeColor: _primaryGreenColor,
          ),
          
          // الاهتزاز
          SwitchListTile(
            title: const Text('الاهتزاز'),
            subtitle: const Text('اهتزاز الجهاز عند التنبيه'),
            value: _notificationSettings.vibrate,
            onChanged: _notificationSettings.enabled
                ? (value) {
                    setState(() {
                      _notificationSettings = _notificationSettings.copyWith(
                        vibrate: value,
                      );
                      _markAsChanged();
                    });
                  }
                : null,
            activeColor: _primaryGreenColor,
          ),
          
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildPrayerNotificationsSection() {
    final prayers = [
      (PrayerType.fajr, 'الفجر', Icons.dark_mode),
      (PrayerType.dhuhr, 'الظهر', Icons.light_mode),
      (PrayerType.asr, 'العصر', Icons.wb_cloudy),
      (PrayerType.maghrib, 'المغرب', Icons.wb_twilight),
      (PrayerType.isha, 'العشاء', Icons.bedtime),
    ];
    
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: _primaryGreenColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.mosque,
                    color: _primaryGreenColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات إشعارات الصلوات',
                        style: TextStyle(
                          fontWeight: ThemeConstants.semiBold,
                          fontSize: 16.sp,
                        ),
                      ),
                      Text(
                        'تخصيص الإشعارات لكل صلاة على حدة',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // قائمة الصلوات
          ...prayers.map((prayer) => _buildPrayerNotificationTile(
            prayer.$1,
            prayer.$2,
            prayer.$3,
          )),
        ],
      ),
    );
  }

  Widget _buildPrayerNotificationTile(
    PrayerType type,
    String name,
    IconData icon,
  ) {
    final isEnabled = _notificationSettings.enabledPrayers[type] ?? false;
    final minutesBefore = _notificationSettings.minutesBefore[type] ?? 0;
    
    return ExpansionTile(
      leading: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: _primaryGreenColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          color: _primaryGreenColor,
          size: 20.sp,
        ),
      ),
      title: Text(name),
      subtitle: Text(
        isEnabled && _notificationSettings.enabled
            ? 'تنبيه قبل $minutesBefore دقيقة'
            : 'التنبيه معطل',
      ),
      trailing: Switch(
        value: isEnabled,
        onChanged: _notificationSettings.enabled
            ? (value) {
                setState(() {
                  final updatedPrayers = Map<PrayerType, bool>.from(
                    _notificationSettings.enabledPrayers,
                  );
                  updatedPrayers[type] = value;
                  
                  _notificationSettings = _notificationSettings.copyWith(
                    enabledPrayers: updatedPrayers,
                  );
                  _markAsChanged();
                });
              }
            : null,
        activeColor: _primaryGreenColor,
      ),
      children: [
        if (isEnabled && _notificationSettings.enabled)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            child: Row(
              children: [
                const Text('التنبيه قبل'),
                SizedBox(width: 12.w),
                SizedBox(
                  width: 80.w,
                  child: DropdownButtonFormField<int>(
                    value: minutesBefore,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                    ),
                    items: [0, 5, 10, 15, 20, 25, 30, 45, 60]
                        .map((minutes) => DropdownMenuItem(
                              value: minutes,
                              child: Text('$minutes'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          final updatedMinutes = Map<PrayerType, int>.from(
                            _notificationSettings.minutesBefore,
                          );
                          updatedMinutes[type] = value;
                          
                          _notificationSettings = _notificationSettings.copyWith(
                            minutesBefore: updatedMinutes,
                          );
                          _markAsChanged();
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 8.w),
                const Text('دقيقة'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: _isSaving || !_hasChanges ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreenColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 2,
          ),
          child: _isSaving
              ? SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'حفظ الإعدادات',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  void _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغييرات غير محفوظة'),
        content: const Text('لديك تغييرات لم يتم حفظها. هل تريد حفظ التغييرات قبل المغادرة؟'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('تجاهل التغييرات'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('حفظ وخروج'),
          ),
        ],
      ),
    );
    
    if (!mounted) return;
    
    if (result == true) {
      await _saveSettings();
      if (mounted) {
        Navigator.pop(context);
      }
    } else if (result == false) {
      Navigator.pop(context);
    }
  }
}