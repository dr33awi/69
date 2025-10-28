// lib/features/athkar/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/infrastructure/services/permissions/simple_permission_extensions.dart';
import '../../../core/infrastructure/services/permissions/widgets/permission_warning_card.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../services/athkar_service.dart';
import '../models/athkar_model.dart';
import '../constants/athkar_constants.dart';
import '../utils/category_utils.dart';
import '../../../core/infrastructure/services/notifications/notification_manager.dart';
import '../../../core/infrastructure/services/notifications/models/notification_models.dart';

class AthkarNotificationSettingsScreen extends StatefulWidget {
  const AthkarNotificationSettingsScreen({super.key});

  @override
  State<AthkarNotificationSettingsScreen> createState() => 
      _AthkarNotificationSettingsScreenState();
}

class _AthkarNotificationSettingsScreenState 
    extends State<AthkarNotificationSettingsScreen> with WidgetsBindingObserver {
  late final AthkarService _service;
  late final StorageService _storage;
  
  List<AthkarCategory>? _categories;
  final Map<String, bool> _enabled = {};
  final Map<String, TimeOfDay> _customTimes = {};
  
  // الإعدادات الأصلية لتتبع التغييرات
  final Map<String, bool> _originalEnabled = {};
  final Map<String, TimeOfDay> _originalTimes = {};
  
  bool _saving = false;
  bool _hasPermission = false;
  bool _isLoading = true;
  bool _hasChanges = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = getIt<AthkarService>();
    _storage = getIt<StorageService>();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
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
    if (mounted && hasPermission != _hasPermission) {
      setState(() {
        _hasPermission = hasPermission;
      });
      
      if (hasPermission) {
        context.showPermissionGrantedMessage('الإشعارات');
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      await _checkSettingsVersion();
      _hasPermission = await context.checkNotificationPermission();
      
      final allCategories = await _service.loadCategories();
      final enabledIds = _service.getEnabledReminderCategories();
      final savedCustomTimes = _service.getCustomTimes();
      
      final isFirstLaunch = enabledIds.isEmpty && savedCustomTimes.isEmpty;
      
      _enabled.clear();
      _customTimes.clear();
      _originalEnabled.clear();
      _originalTimes.clear();
      
      final autoEnabledIds = <String>[];
      
      for (final category in allCategories) {
        bool shouldEnable = enabledIds.contains(category.id);
        
        if (isFirstLaunch && AthkarConstants.shouldAutoEnable(category.id)) {
          shouldEnable = true;
          autoEnabledIds.add(category.id);
        }
        
        _enabled[category.id] = shouldEnable;
        _originalEnabled[category.id] = shouldEnable;
        
        final customTime = savedCustomTimes[category.id];
        final time = customTime ?? 
                    category.notifyTime ?? 
                    AthkarConstants.getDefaultTimeForCategory(category.id);
        
        _customTimes[category.id] = time;
        _originalTimes[category.id] = time;
      }
      
      setState(() {
        _categories = allCategories;
        _isLoading = false;
        _hasChanges = false;
      });
      
      if (isFirstLaunch && autoEnabledIds.isNotEmpty) {
        await _saveInitialSettings(autoEnabledIds);
      }
      
      if (_hasPermission) {
        await _validateScheduledNotifications();
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل في تحميل البيانات. يرجى المحاولة مرة أخرى.';
      });
    }
  }

  Future<void> _checkSettingsVersion() async {
    final currentVersion = _storage.getInt(AthkarConstants.settingsVersionKey) ?? 1;
    
    if (currentVersion < AthkarConstants.currentSettingsVersion) {
      await _migrateSettings(currentVersion);
      await _storage.setInt(
        AthkarConstants.settingsVersionKey,
        AthkarConstants.currentSettingsVersion,
      );
    }
  }

  Future<void> _migrateSettings(int fromVersion) async {
    // Migration logic if needed
  }

  Future<void> _saveInitialSettings(List<String> autoEnabledIds) async {
    await _service.setEnabledReminderCategories(autoEnabledIds);
    await _service.saveCustomTimes(_customTimes);
    
    if (_hasPermission) {
      await _service.scheduleCategoryReminders();
    }
    
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.showSuccessSnackBar(
            'تم تفعيل الأذكار الأساسية تلقائياً (${autoEnabledIds.length} فئات)'
          );
        }
      });
    }
  }

  Future<void> _validateScheduledNotifications() async {
    try {
      final enabledIds = _service.getEnabledReminderCategories();
      final scheduledNotifications = await NotificationManager.instance
          .getScheduledNotifications();
      
      final scheduledAthkarIds = scheduledNotifications
          .where((n) => n.category == NotificationCategory.athkar)
          .map((n) => n.payload?['categoryId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();
      
      final enabledSet = enabledIds.toSet();
      final missingNotifications = enabledSet.difference(scheduledAthkarIds);
      
      if (missingNotifications.isNotEmpty) {
        await _service.scheduleCategoryReminders();
      }
    } catch (e) {
      debugPrint('Error validating notifications: $e');
    }
  }

  void _checkForChanges() {
    bool hasChanges = false;
    
    for (final entry in _enabled.entries) {
      if (entry.value != (_originalEnabled[entry.key] ?? false)) {
        hasChanges = true;
        break;
      }
    }
    
    if (!hasChanges) {
      for (final entry in _customTimes.entries) {
        final originalTime = _originalTimes[entry.key];
        if (originalTime == null || 
            entry.value.hour != originalTime.hour || 
            entry.value.minute != originalTime.minute) {
          hasChanges = true;
          break;
        }
      }
    }
    
    setState(() {
      _hasChanges = hasChanges;
    });
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
    await _saveChanges();
    return !_hasChanges;
  } else if (result == 'discard') {
    setState(() {
      _enabled.clear();
      _enabled.addAll(_originalEnabled);
      _customTimes.clear();
      _customTimes.addAll(_originalTimes);
      _hasChanges = false;
    });
    return true;
  }
  
  return false;
}

  Future<void> _toggleCategory(String categoryId, bool value) async {
    // ✅ إذا كان المستخدم يريد تفعيل التذكير وليس لديه إذن
    if (value && !_hasPermission) {
      final granted = await _requestNotificationPermission();
      if (!granted) {
        return; // لا تفعل التذكير إذا رفض الإذن
      }
    }
    
    setState(() {
      _enabled[categoryId] = value;
    });
    _checkForChanges();
  }

  // ✅ دالة موحدة لطلب إذن الإشعارات مع رسالة عند الرفض
  Future<bool> _requestNotificationPermission() async {
    final granted = await context.requestNotificationPermission();
    
    if (granted) {
      setState(() {
        _hasPermission = true;
      });
    } else {
      // ✅ عرض رسالة الرفض الموحدة
      if (mounted) {
        context.showPermissionDeniedMessage('الإشعارات');
      }
    }
    
    return granted;
  }

  Future<void> _updateTime(String categoryId, TimeOfDay time) async {
    setState(() {
      _customTimes[categoryId] = time;
    });
    _checkForChanges();
    
    if (!(_enabled[categoryId] ?? false)) {
      setState(() {
        _enabled[categoryId] = true;
      });
      _checkForChanges();
    }
  }

Future<void> _saveChanges() async {
  if (_saving || !_hasChanges) return;
  
  setState(() => _saving = true);
  
  try {
    if (!_hasPermission) {
      final enabledCount = _enabled.values.where((e) => e).length;
      if (enabledCount > 0) {
        if (mounted) {
          context.showPermissionDeniedMessage('الإشعارات');
        }
        setState(() => _saving = false);
        return;
      }
    }

    await _service.updateReminderSettings(
      enabledMap: _enabled,
      customTimes: _customTimes,
    );
    
    _originalEnabled.clear();
    _originalTimes.clear();
    _originalEnabled.addAll(_enabled);
    _originalTimes.addAll(_customTimes);
    
    if (!mounted) return;
    
    context.showSuccessSnackBar('تم حفظ الإعدادات بنجاح');
    setState(() {
      _hasChanges = false;
    });
    
    // ✅ إضافة هذا السطر للخروج بعد الحفظ
    Navigator.pop(context);
    
  } catch (e) {
    if (!mounted) return;
    
    context.showErrorSnackBar('حدث خطأ في حفظ الإعدادات');
  } finally {
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}

  Future<void> _selectTime(String categoryId, TimeOfDay currentTime) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      helpText: 'اختر وقت التذكير',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                textStyle: WidgetStateProperty.all(
                  TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: context.surfaceColor,
              hourMinuteTextColor: context.textPrimaryColor,
              dialHandColor: ThemeConstants.primary,
              dialBackgroundColor: context.cardColor,
              helpTextStyle: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              cancelButtonStyle: ButtonStyle(
                textStyle: WidgetStateProperty.all(
                  TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                foregroundColor: WidgetStateProperty.all(context.textPrimaryColor),
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                ),
              ),
              confirmButtonStyle: ButtonStyle(
                textStyle: WidgetStateProperty.all(
                  TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                foregroundColor: WidgetStateProperty.all(ThemeConstants.primary),
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                ),
              ),
              dayPeriodTextStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
              hourMinuteTextStyle: TextStyle(
                fontSize: 48.sp,
                fontWeight: FontWeight.bold,
              ),
              dayPeriodTextColor: context.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      await _updateTime(categoryId, selectedTime);
    }
  }

  Future<void> _enableAllReminders() async {
    HapticFeedback.mediumImpact();
    
    // ✅ التحقق من الإذن قبل تفعيل الكل
    if (!_hasPermission) {
      final granted = await _requestNotificationPermission();
      if (!granted) {
        return;
      }
    }
    
    final shouldEnable = await AppInfoDialog.showConfirmation(
      context: context,
      title: 'تفعيل جميع التذكيرات',
      content: 'هل تريد تفعيل تذكيرات جميع فئات الأذكار؟',
      confirmText: 'تفعيل الكل',
      cancelText: 'إلغاء',
      icon: Icons.notifications_active,
    );
    
    if (shouldEnable == true) {
      setState(() {
        for (final category in _categories ?? <AthkarCategory>[]) {
          _enabled[category.id] = true;
        }
      });
      _checkForChanges();
    }
  }

  Future<void> _disableAllReminders() async {
    HapticFeedback.mediumImpact();
    
    final shouldDisable = await AppInfoDialog.showConfirmation(
      context: context,
      title: 'إيقاف جميع التذكيرات',
      content: 'هل تريد إيقاف جميع تذكيرات الأذكار؟',
      confirmText: 'إيقاف الكل',
      cancelText: 'إلغاء',
      icon: Icons.notifications_off,
      destructive: true,
    );
    
    if (shouldDisable == true) {
      setState(() {
        for (final category in _categories ?? <AthkarCategory>[]) {
          _enabled[category.id] = false;
        }
      });
      _checkForChanges();
    }
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
              Expanded(child: _buildBody()),
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
                  'إشعارات الأذكار',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 17.sp,
                  ),
                ),
                Text(
                  'تخصيص التذكيرات اليومية',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          
          if (_hasChanges && !_saving && _hasPermission)
            Container(
              margin: EdgeInsets.only(left: ThemeConstants.space2 - 2.w),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _saveChanges();
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
          
          if (_hasPermission && (_categories?.isNotEmpty ?? false))
            _buildActionsMenu(),
          
          if (_saving)
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

  Widget _buildActionsMenu() {
    return Container(
      margin: EdgeInsets.only(left: ThemeConstants.space2 - 2.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: PopupMenuButton<String>(
          icon: Container(
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
              Icons.more_vert,
              color: context.textPrimaryColor,
              size: ThemeConstants.iconSm,
            ),
          ),
          onSelected: (value) {
            switch (value) {
              case 'enable_all':
                _enableAllReminders();
                break;
              case 'disable_all':
                _disableAllReminders();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'enable_all',
              child: Row(
                children: [
                  Icon(Icons.notifications_active, size: ThemeConstants.iconSm),
                  SizedBox(width: ThemeConstants.space2),
                  Text(
                    'تفعيل الكل',
                    style: TextStyle(fontSize: ThemeConstants.textSizeSm),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'disable_all',
              child: Row(
                children: [
                  Icon(Icons.notifications_off, size: ThemeConstants.iconSm),
                  SizedBox(width: ThemeConstants.space2),
                  Text(
                    'إيقاف الكل',
                    style: TextStyle(fontSize: ThemeConstants.textSizeSm),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: AppLoading.page(
          message: 'جاري تحميل الإعدادات...',
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: AppEmptyState.error(
          message: _errorMessage!,
          onRetry: _loadData,
        ),
      );
    }

    final categories = _categories ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(ThemeConstants.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ عرض بطاقة التحذير إذا لم يكن هناك إذن
            if (!_hasPermission) ...[
              PermissionWarningCard.notification(
                onGrantPermission: _requestNotificationPermission,
                isCompact: false,
              ),
              SizedBox(height: ThemeConstants.space3),
            ],
            
            if (_hasPermission) ...[
              if (categories.isEmpty)
                _buildNoCategoriesMessage()
              else ...[
                _buildQuickStats(categories),
                
                SizedBox(height: ThemeConstants.space3),
                
                Text(
                  'جميع فئات الأذكار (${categories.length})',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: ThemeConstants.textSizeMd,
                  ),
                ),
                
                SizedBox(height: ThemeConstants.space2 - 2.h),
                
                Text(
                  'فعّل التذكيرات وخصص أوقاتها',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: ThemeConstants.textSizeXs,
                  ),
                ),
                
                SizedBox(height: ThemeConstants.space3),
                
                ...categories.map((category) => 
                  _buildCategoryTile(category)
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ... باقي الـ widgets (نفس الكود السابق)
  
  Widget _buildQuickStats(List<AthkarCategory> categories) {
    final enabledCount = _enabled.values.where((e) => e).length;
    final disabledCount = categories.length - enabledCount;
    
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
              icon: Icons.format_list_numbered,
              count: categories.length,
              label: 'الكل',
              color: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCategoriesMessage() {
    return Container(
      padding: EdgeInsets.all(ThemeConstants.space4),
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
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: ThemeConstants.icon2xl,
            color: context.textSecondaryColor.withOpacity(ThemeConstants.opacity50),
          ),
          SizedBox(height: ThemeConstants.space2 + ThemeConstants.space1),
          Text(
            'لا توجد فئات أذكار',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: ThemeConstants.textSizeMd,
            ),
          ),
          SizedBox(height: ThemeConstants.space2 - 2.h),
          Text(
            'لم يتم العثور على أي فئات',
            style: TextStyle(
              color: context.textSecondaryColor.withOpacity(0.7),
              fontSize: ThemeConstants.textSizeSm,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(AthkarCategory category) {
    final isEnabled = _enabled[category.id] ?? false;
    final currentTime = _customTimes[category.id] ?? 
        AthkarConstants.getDefaultTimeForCategory(category.id);
    final isAutoEnabled = AthkarConstants.shouldAutoEnable(category.id);
    final isEssential = AthkarConstants.isEssentialCategory(category.id);
    
    final categoryColor = CategoryUtils.getCategoryThemeColor(category.id);
    final categoryIcon = CategoryUtils.getCategoryIcon(category.id);

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
                    color: categoryColor.withOpacity(ThemeConstants.opacity10),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.15),
                        blurRadius: 6.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: ThemeConstants.iconSm,
                  ),
                ),
                
                SizedBox(width: ThemeConstants.space2 + ThemeConstants.space1),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.title,
                              style: TextStyle(
                                fontWeight: ThemeConstants.semiBold,
                                fontSize: ThemeConstants.textSizeSm,
                              ),
                            ),
                          ),
                          if (isEssential)
                            _buildBadge(
                              'أساسي',
                              ThemeConstants.success,
                            ),
                          if (isAutoEnabled && !isEssential)
                            _buildBadge(
                              'مفضل',
                              ThemeConstants.info,
                            ),
                        ],
                      ),
                      if (category.description?.isNotEmpty == true)
                        Text(
                          category.description!,
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: ThemeConstants.textSizeXs,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      Text(
                        '${category.athkar.length} ذكر',
                        style: TextStyle(
                          color: context.textSecondaryColor.withOpacity(0.7),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: isEnabled,
                    onChanged: _hasPermission 
                        ? (value) => _toggleCategory(category.id, value)
                        : null,
                    activeColor: isEssential 
                        ? ThemeConstants.success 
                        : ThemeConstants.primary,
                  ),
                ),
              ],
            ),
            
            if (isEnabled) ...[
              SizedBox(height: ThemeConstants.space2 + ThemeConstants.space1),
              _buildTimeSelector(
                category: category,
                currentTime: currentTime,
                isEssential: isEssential,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: EdgeInsets.only(left: ThemeConstants.space2 - 2.w),
      padding: EdgeInsets.symmetric(
        horizontal: ThemeConstants.space2,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(ThemeConstants.opacity10),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.sp,
          fontWeight: ThemeConstants.bold,
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required AthkarCategory category,
    required TimeOfDay currentTime,
    required bool isEssential,
  }) {
    return Container(
      padding: EdgeInsets.all(ThemeConstants.space2 + ThemeConstants.space1 + 2.w),
      decoration: BoxDecoration(
        color: (isEssential ? ThemeConstants.success : ThemeConstants.primary)
            .withOpacity(ThemeConstants.opacity10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: (isEssential ? ThemeConstants.success : ThemeConstants.primary)
              .withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isEssential ? ThemeConstants.success : ThemeConstants.primary)
                .withValues(alpha: 0.12),
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
            color: isEssential ? ThemeConstants.success : ThemeConstants.primary,
          ),
          SizedBox(width: ThemeConstants.space2 - 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وقت التذكير: ${currentTime.format(context)}',
                  style: TextStyle(
                    color: isEssential ? ThemeConstants.success : ThemeConstants.primary,
                    fontWeight: ThemeConstants.medium,
                    fontSize: ThemeConstants.textSizeSm,
                  ),
                ),
                if (category.notifyTime == null)
                  Text(
                    'وقت افتراضي',
                    style: TextStyle(
                      color: (isEssential ? ThemeConstants.success : ThemeConstants.primary)
                          .withOpacity(0.7),
                      fontSize: 10.sp,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _selectTime(category.id, currentTime),
            style: TextButton.styleFrom(
              minimumSize: Size(0, 32.h),
              padding: EdgeInsets.symmetric(
                horizontal: ThemeConstants.space3,
                vertical: ThemeConstants.space2 - 2.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              backgroundColor: (isEssential ? ThemeConstants.success : ThemeConstants.primary)
                  .withOpacity(0.15),
            ),
            child: Text('تغيير', style: TextStyle(fontSize: ThemeConstants.textSizeXs)),
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