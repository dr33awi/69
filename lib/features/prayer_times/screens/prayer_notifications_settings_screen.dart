// lib/features/prayer_times/screens/prayer_notifications_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/themes/widgets/core/app_button.dart';
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
      if (!mounted) return;
      
      context.showSuccessSnackBar('تم حفظ إعدادات الإشعارات بنجاح');
      setState(() {
        _hasChanges = false;
      });
    } catch (e) {
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
            _buildCustomAppBar(context),
            
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
    const gradient = LinearGradient(
      colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return Container(
      padding: EdgeInsets.all(12.w),
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
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withOpacity(0.3),
                  blurRadius: 6.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_active,
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
                  'إعدادات إشعارات الصلوات',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 15.sp,
                  ),
                ),
                Text(
                  'تخصيص تنبيهات أوقات الصلاة',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 10.sp,
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
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: context.dividerColor.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3.r,
                          offset: Offset(0, 2.h),
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

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildMainSettingsSection(),
        ),
        
        SliverToBoxAdapter(
          child: _buildPrayerNotificationsSection(),
        ),
        
        SliverToBoxAdapter(
          child: _buildSaveButton(),
        ),
        
        SliverToBoxAdapter(
          child: SizedBox(height: 60.h),
        ),
      ],
    );
  }

  Widget _buildMainSettingsSection() {
    return Container(
      margin: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _primaryGreenColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: _primaryGreenColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات الإشعارات العامة',
                        style: TextStyle(
                          fontWeight: ThemeConstants.semiBold,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        'تفعيل أو تعطيل الإشعارات لجميع الصلوات',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: Text('تفعيل الإشعارات', style: TextStyle(fontSize: 13.sp)),
            subtitle: Text('تلقي تنبيهات أوقات الصلاة', style: TextStyle(fontSize: 10.sp)),
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
          
          SwitchListTile(
            title: Text('الاهتزاز', style: TextStyle(fontSize: 13.sp)),
            subtitle: Text('اهتزاز الجهاز عند التنبيه', style: TextStyle(fontSize: 10.sp)),
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
          
          SizedBox(height: 6.h),
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
      margin: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _primaryGreenColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.mosque,
                    color: _primaryGreenColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات إشعارات الصلوات',
                        style: TextStyle(
                          fontWeight: ThemeConstants.semiBold,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        'تخصيص الإشعارات لكل صلاة على حدة',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
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
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: _primaryGreenColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: _primaryGreenColor,
          size: 18.sp,
        ),
      ),
      title: Text(name, style: TextStyle(fontSize: 13.sp)),
      subtitle: Text(
        isEnabled && _notificationSettings.enabled
            ? 'تنبيه قبل $minutesBefore دقيقة'
            : 'التنبيه معطل',
        style: TextStyle(fontSize: 10.sp),
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
              horizontal: 12.w,
              vertical: 6.h,
            ),
            child: Row(
              children: [
                Text('التنبيه قبل', style: TextStyle(fontSize: 12.sp)),
                SizedBox(width: 10.w),
                SizedBox(
                  width: 70.w,
                  child: DropdownButtonFormField<int>(
                    value: minutesBefore,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                    ),
                    items: [0, 5, 10, 15, 20, 25, 30, 45, 60]
                        .map((minutes) => DropdownMenuItem(
                              value: minutes,
                              child: Text(
                                '$minutes',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 12.sp,
                                ),
                              ),
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
                SizedBox(width: 6.w),
                Text('دقيقة', style: TextStyle(fontSize: 12.sp)),
              ],
            ),
          ),
      ],
    );
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
      if (mounted) {
        Navigator.pop(context);
      }
    } else if (result == false) {
      Navigator.pop(context);
    }
  }
}