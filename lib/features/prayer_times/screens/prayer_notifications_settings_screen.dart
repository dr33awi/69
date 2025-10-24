// lib/features/prayer_times/screens/prayer_notifications_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/permissions/simple_permission_extensions.dart';
import '../../../core/infrastructure/services/permissions/widgets/permission_warning_card.dart';
import '../services/prayer_times_service.dart';
import '../models/prayer_time_model.dart';

class PrayerNotificationsSettingsScreen extends StatefulWidget {
  const PrayerNotificationsSettingsScreen({super.key});

  @override
  State<PrayerNotificationsSettingsScreen> createState() => _PrayerNotificationsSettingsScreenState();
}

class _PrayerNotificationsSettingsScreenState extends State<PrayerNotificationsSettingsScreen> 
    with WidgetsBindingObserver {
  late final PrayerTimesService _prayerService;
  
  late PrayerNotificationSettings _notificationSettings;
  late PrayerNotificationSettings _originalSettings;
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _hasNotificationPermission = false;

  final Color _primaryGreenColor = ThemeConstants.success;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _checkNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionOnResume();
    }
  }

  Future<void> _checkPermissionOnResume() async {
    final hasPermission = await context.checkNotificationPermission();
    if (mounted && hasPermission != _hasNotificationPermission) {
      setState(() {
        _hasNotificationPermission = hasPermission;
      });
      
      if (hasPermission) {
        context.showPermissionGrantedMessage('الإشعارات');
      }
    }
  }

  void _initializeServices() {
    _prayerService = getIt<PrayerTimesService>();
  }

  void _loadSettings() {
    setState(() {
      _notificationSettings = _prayerService.notificationSettings;
      _originalSettings = _prayerService.notificationSettings;
      _isLoading = false;
      _hasChanges = false;
    });
  }

  Future<void> _checkNotificationPermission() async {
    final hasPermission = await context.checkNotificationPermission();
    if (mounted) {
      setState(() {
        _hasNotificationPermission = hasPermission;
      });
    }
  }

  // ✅ طلب إذن الإشعارات مع رسالة موحدة عند الرفض
  Future<bool> _requestNotificationPermission() async {
    final granted = await context.requestNotificationPermission();
    
    if (granted) {
      setState(() {
        _hasNotificationPermission = true;
      });
    } else {
      // ✅ عرض رسالة الرفض الموحدة
      if (mounted) {
        context.showPermissionDeniedMessage('الإشعارات');
      }
    }
    
    return granted;
  }

  void _checkForChanges() {
    setState(() {
      _hasChanges = _notificationSettings != _originalSettings;
    });
  }

  Future<void> _saveSettings() async {
    // ✅ التحقق من الإذن قبل الحفظ
    if (!_hasNotificationPermission) {
      final granted = await _requestNotificationPermission();
      if (!granted) {
        return;
      }
    }
    
    setState(() => _isSaving = true);
    
    try {
      await _prayerService.updateNotificationSettings(_notificationSettings);
      if (!mounted) return;
      
      context.showSuccessSnackBar('تم حفظ إعدادات الإشعارات بنجاح');
      setState(() {
        _originalSettings = _notificationSettings;
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

  Future<bool> _showUnsavedChangesDialog() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: context.cardColor,
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
          AppButton.text(
            text: 'تجاهل التغييرات',
            onPressed: () => Navigator.pop(context, 'discard'),
            size: ButtonSize.medium,
            color: ThemeConstants.error,
          ),
          SizedBox(width: ThemeConstants.space2),
          AppButton.primary(
            text: 'حفظ وخروج',
            onPressed: () => Navigator.pop(context, 'save'),
            size: ButtonSize.medium,
          ),
        ],
      ),
    );
    
    if (result == 'save') {
      await _saveSettings();
      return !_hasChanges;
    } else if (result == 'discard') {
      setState(() {
        _notificationSettings = _originalSettings;
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
              _buildCustomAppBar(context),
              
              Expanded(
                child: _isLoading
                    ? Center(child: AppLoading.circular())
                    : _buildContent(),
              ),
            ],
          ),
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
            onPressed: () async {
              final canPop = await _showUnsavedChangesDialog();
              if (canPop && mounted) {
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
        // ✅ عرض بطاقة التحذير إذا لم يكن هناك إذن
        if (!_hasNotificationPermission)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: PermissionWarningCard.notification(
                onGrantPermission: _requestNotificationPermission,
                isCompact: false,
              ),
            ),
          ),
        
        if (_hasNotificationPermission)
          SliverToBoxAdapter(
            child: _buildPrayerNotificationsSection(),
          ),
        
        SliverToBoxAdapter(
          child: SizedBox(height: 60.h),
        ),
      ],
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
                });
                _checkForChanges();
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
                        });
                        _checkForChanges();
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
}