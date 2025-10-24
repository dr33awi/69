// lib/features/athkar/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/infrastructure/services/permissions/simple_permission_service.dart';
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
    extends State<AthkarNotificationSettingsScreen> {
  late final AthkarService _service;
  late final SimplePermissionService _permissionService;
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
    _permissionService = getIt<SimplePermissionService>();
    _storage = getIt<StorageService>();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      await _checkSettingsVersion();
      _hasPermission = await _permissionService.checkNotificationPermission();
      
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
    setState(() {
      _enabled[categoryId] = value;
    });
    _checkForChanges();
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
            context.showWarningSnackBar('يجب تفعيل أذونات الإشعارات أولاً');
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
      
      if (mounted) {
        context.showSuccessSnackBar('تم حفظ الإعدادات بنجاح');
        setState(() {
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('حدث خطأ في حفظ الإعدادات');
      }
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
            timePickerTheme: TimePickerThemeData(
              backgroundColor: context.surfaceColor,
              hourMinuteTextColor: context.textPrimaryColor,
              dialHandColor: ThemeConstants.primary,
              dialBackgroundColor: context.cardColor,
              helpTextStyle: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 14.sp,
              ),
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
              margin: EdgeInsets.only(left: 6.w),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _saveChanges();
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: context.dividerColor.withOpacity(0.3),
                        width: 1.w,
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
          
          if (_hasPermission && (_categories?.isNotEmpty ?? false))
            _buildActionsMenu(),
          
          if (_saving)
            Container(
              margin: EdgeInsets.only(left: 6.w),
              child: SizedBox(
                width: 20.w,
                height: 20.w,
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
      margin: EdgeInsets.only(left: 6.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: PopupMenuButton<String>(
          icon: Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: context.dividerColor.withOpacity(0.3),
                width: 1.w,
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
              Icons.more_vert,
              color: context.textPrimaryColor,
              size: 20.sp,
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
                  Icon(Icons.notifications_active, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text('تفعيل الكل', style: TextStyle(fontSize: 13.sp)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'disable_all',
              child: Row(
                children: [
                  Icon(Icons.notifications_off, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text('إيقاف الكل', style: TextStyle(fontSize: 13.sp)),
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
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة تحذير الإذن
            if (!_hasPermission)
              _buildPermissionWarningCard(),
            
            if (!_hasPermission)
              SizedBox(height: 16.h),
            
            if (_hasPermission) ...[
              if (categories.isEmpty)
                _buildNoCategoriesMessage()
              else ...[
                _buildQuickStats(categories),
                
                SizedBox(height: 12.h),
                
                Text(
                  'جميع فئات الأذكار (${categories.length})',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 14.sp,
                  ),
                ),
                
                SizedBox(height: 6.h),
                
                Text(
                  'فعّل التذكيرات وخصص أوقاتها',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
                
                SizedBox(height: 12.h),
                
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

  Widget _buildQuickStats(List<AthkarCategory> categories) {
    final enabledCount = _enabled.values.where((e) => e).length;
    final disabledCount = categories.length - enabledCount;
    
    return AppCard(
      padding: EdgeInsets.all(12.r),
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
            width: 1.w,
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
            width: 1.w,
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

  Widget _buildPermissionWarningCard() {
    return const SizedBox.shrink();
  }

  Widget _buildNoCategoriesMessage() {
    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 40.sp,
            color: context.textSecondaryColor.withOpacity(0.5),
          ),
          SizedBox(height: 10.h),
          Text(
            'لا توجد فئات أذكار',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'لم يتم العثور على أي فئات',
            style: TextStyle(
              color: context.textSecondaryColor.withOpacity(0.7),
              fontSize: 12.sp,
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
      padding: EdgeInsets.only(bottom: 10.h),
      child: AppCard(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 18.sp,
                  ),
                ),
                
                SizedBox(width: 10.w),
                
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
                                fontSize: 13.sp,
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
                            fontSize: 11.sp,
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
              SizedBox(height: 10.h),
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
      margin: EdgeInsets.only(left: 6.w),
      padding: EdgeInsets.symmetric(
        horizontal: 6.w,
        vertical: 3.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
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
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: (isEssential ? ThemeConstants.success : ThemeConstants.primary)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: (isEssential ? ThemeConstants.success : ThemeConstants.primary)
              .withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16.sp,
            color: isEssential ? ThemeConstants.success : ThemeConstants.primary,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وقت التذكير: ${currentTime.format(context)}',
                  style: TextStyle(
                    color: isEssential ? ThemeConstants.success : ThemeConstants.primary,
                    fontWeight: ThemeConstants.medium,
                    fontSize: 12.sp,
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
              minimumSize: Size(0, 28.h),
              padding: EdgeInsets.symmetric(
                horizontal: 10.w,
              ),
            ),
            child: Text('تغيير', style: TextStyle(fontSize: 11.sp)),
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
          size: 16.sp,
        ),
        SizedBox(height: 3.h),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: ThemeConstants.bold,
            fontSize: 14.sp,
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