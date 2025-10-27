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
      
      Navigator.pop(context);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: context.cardColor,
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
                    blurRadius: 8.r,
                    offset: Offset(0, 3.h),
                  ),
                ],
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: Text('حفظ وخروج', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
    
    if (result == 'save') {
      // حفظ التغييرات
      await _saveSettings();
      return !_hasChanges;
    } else if (result == 'discard') {
      // تجاهل التغييرات - إرجاع الإعدادات للحالة الأصلية
      setState(() {
        _notificationSettings = _originalSettings;
        _hasChanges = false;
      });
      return true; // السماح بالخروج
    }
    
    return false; // إلغاء (result == 'cancel' or null)
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
      padding: EdgeInsets.symmetric(
        horizontal: ThemeConstants.space3,
        vertical: ThemeConstants.space3,
      ),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () async {
              final canPop = await _showUnsavedChangesDialog();
              if (canPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          
          SizedBox(width: ThemeConstants.space2),
          
          Container(
            padding: EdgeInsets.all(ThemeConstants.space2 - 2.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withValues(alpha: 0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: ThemeConstants.iconSm,
            ),
          ),
          
          SizedBox(width: ThemeConstants.space2),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إشعارات الصلوات',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 17.sp,
                  ),
                ),
                Text(
                  'تخصيص تنبيهات أوقات الصلاة',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          
          if (_hasChanges && !_isSaving && _hasNotificationPermission)
            Container(
              margin: EdgeInsets.only(left: ThemeConstants.space2 - 2.w),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _saveSettings();
                  },
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    padding: EdgeInsets.all(ThemeConstants.space2 - 2.w),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: context.dividerColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.06),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: context.isDarkMode ? 0.08 : 0.03),
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.save,
                      color: ThemeConstants.primary,
                      size: ThemeConstants.iconSm,
                    ),
                  ),
                ),
              ),
            ),
          
          if (_isSaving)
            Container(
              margin: EdgeInsets.only(left: ThemeConstants.space2 - 2.w),
              child: SizedBox(
                width: ThemeConstants.iconSm,
                height: ThemeConstants.iconSm,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: const AlwaysStoppedAnimation<Color>(ThemeConstants.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadSettings();
        await _checkNotificationPermission();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(ThemeConstants.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ عرض بطاقة التحذير إذا لم يكن هناك إذن
            if (!_hasNotificationPermission) ...[
              PermissionWarningCard.notification(
                onGrantPermission: _requestNotificationPermission,
                isCompact: false,
              ),
              SizedBox(height: ThemeConstants.space3),
            ],
            
            if (_hasNotificationPermission) ...[
              _buildQuickStats(),
              SizedBox(height: ThemeConstants.space3),
              
              Text(
                'إعدادات الصلوات (5)',
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  color: context.textPrimaryColor,
                  fontSize: ThemeConstants.textSizeMd,
                ),
              ),
              
              SizedBox(height: ThemeConstants.space2 - 2.h),
              
              Text(
                'فعّل التنبيهات وخصص أوقاتها',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: ThemeConstants.textSizeXs,
                ),
              ),
              
              SizedBox(height: ThemeConstants.space3),
              
              _buildPrayerNotificationsSection(),
            ],
          ],
        ),
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
    
    return Column(
      children: prayers
          .map((prayer) => _buildPrayerNotificationTile(
                prayer.$1,
                prayer.$2,
                prayer.$3,
              ))
          .toList(),
    );
  }

  Widget _buildQuickStats() {
    final enabledCount = _notificationSettings.enabledPrayers.values.where((e) => e).length;
    final disabledCount = 5 - enabledCount; // 5 صلوات
    
    return Container(
      padding: EdgeInsets.all(ThemeConstants.space3),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.06),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.08 : 0.03),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.notifications_active,
              count: enabledCount,
              label: 'مفعلة',
              color: ThemeConstants.success,
            ),
          ),
          
          Container(
            width: ThemeConstants.borderLight,
            height: 32.h,
            color: context.dividerColor,
          ),
          
          Expanded(
            child: _StatItem(
              icon: Icons.notifications_off,
              count: disabledCount,
              label: 'معطلة',
              color: context.textSecondaryColor,
            ),
          ),
          
          Container(
            width: ThemeConstants.borderLight,
            height: 32.h,
            color: context.dividerColor,
          ),
          
          Expanded(
            child: _StatItem(
              icon: Icons.mosque,
              count: 5,
              label: 'الكل',
              color: context.primaryColor,
            ),
          ),
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
    
    return Padding(
      padding: EdgeInsets.only(bottom: ThemeConstants.space2 + ThemeConstants.space1),
      child: Container(
        padding: EdgeInsets.all(ThemeConstants.space3),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: context.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.06),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.08 : 0.03),
              blurRadius: 6.r,
              offset: Offset(0, 2.h),
              spreadRadius: -1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: _primaryGreenColor.withOpacity(ThemeConstants.opacity10),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: _primaryGreenColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreenColor.withValues(alpha: 0.15),
                        blurRadius: 6.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: _primaryGreenColor,
                    size: ThemeConstants.iconSm,
                  ),
                ),
                
                SizedBox(width: ThemeConstants.space2 + ThemeConstants.space1),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: ThemeConstants.semiBold,
                          fontSize: ThemeConstants.textSizeSm,
                        ),
                      ),
                      Text(
                        isEnabled && _notificationSettings.enabled
                            ? 'تنبيه قبل $minutesBefore دقيقة'
                            : 'التنبيه معطل',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: ThemeConstants.textSizeXs,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: isEnabled,
                    onChanged: _notificationSettings.enabled && _hasNotificationPermission
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
                ),
              ],
            ),
            
            if (isEnabled && _notificationSettings.enabled) ...[
              SizedBox(height: ThemeConstants.space2 + ThemeConstants.space1),
              _buildTimeSelector(
                type: type,
                minutesBefore: minutesBefore,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required PrayerType type,
    required int minutesBefore,
  }) {
    return Container(
      padding: EdgeInsets.all(ThemeConstants.space2 + ThemeConstants.space1 + 2.w),
      decoration: BoxDecoration(
        color: _primaryGreenColor.withOpacity(ThemeConstants.opacity10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: _primaryGreenColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGreenColor.withValues(alpha: 0.12),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: ThemeConstants.iconSm,
            color: _primaryGreenColor,
          ),
          SizedBox(width: ThemeConstants.space2 - 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التنبيه قبل $minutesBefore دقيقة',
                  style: TextStyle(
                    color: _primaryGreenColor,
                    fontWeight: ThemeConstants.medium,
                    fontSize: ThemeConstants.textSizeSm,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ThemeConstants.space2,
              vertical: ThemeConstants.space1,
            ),
            decoration: BoxDecoration(
              color: _primaryGreenColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: DropdownButton<int>(
              value: minutesBefore,
              isDense: true,
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: ThemeConstants.textSizeXs,
                color: _primaryGreenColor,
                fontWeight: ThemeConstants.semiBold,
              ),
              dropdownColor: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              items: [0, 5, 10, 15, 20, 25, 30, 45, 60]
                  .map((minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text(
                          '$minutes دقيقة',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: ThemeConstants.textSizeXs,
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
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: ThemeConstants.iconSm,
        ),
        SizedBox(height: 3.h),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: ThemeConstants.bold,
            fontSize: ThemeConstants.textSizeMd,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}