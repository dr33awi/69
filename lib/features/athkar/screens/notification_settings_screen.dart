// lib/features/athkar/screens/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
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
  late final PermissionService _permissionService;
  late final StorageService _storage;
  
  List<AthkarCategory>? _categories;
  final Map<String, bool> _enabled = {};
  final Map<String, TimeOfDay> _customTimes = {};
  final Map<String, TimeOfDay> _originalTimes = {};
  
  bool _saving = false;
  bool _hasPermission = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = getIt<AthkarService>();
    _permissionService = getIt<PermissionService>();
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
      _originalTimes.clear();
      
      final autoEnabledIds = <String>[];
      
      for (final category in allCategories) {
        bool shouldEnable = enabledIds.contains(category.id);
        
        if (isFirstLaunch && AthkarConstants.shouldAutoEnable(category.id)) {
          shouldEnable = true;
          autoEnabledIds.add(category.id);
        }
        
        _enabled[category.id] = shouldEnable;
        
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
      });
      
      if (isFirstLaunch && autoEnabledIds.isNotEmpty) {
        await _saveInitialSettings(autoEnabledIds);
      }
      
      if (_hasPermission) {
        await _validateScheduledNotifications();
      }
      
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات: $e');
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
    debugPrint('ترقية إعدادات الأذكار من الإصدار $fromVersion');
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
        debugPrint('إعادة جدولة الإشعارات المفقودة: $missingNotifications');
        await _service.scheduleCategoryReminders();
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من الإشعارات: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final granted = await _permissionService.requestNotificationPermission();
      setState(() => _hasPermission = granted);
      
      if (granted) {
        context.showSuccessSnackBar('تم منح إذن الإشعارات');
        
        final enabledIds = _enabled.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();
            
        if (enabledIds.isNotEmpty) {
          await _service.scheduleCategoryReminders();
        }
      } else {
        context.showErrorSnackBar('تم رفض إذن الإشعارات');
      }
    } catch (e) {
      context.showErrorSnackBar('حدث خطأ أثناء طلب الإذن');
    }
  }

  Future<void> _toggleCategory(String categoryId, bool value) async {
    final oldValue = _enabled[categoryId];
    
    setState(() {
      _enabled[categoryId] = value;
    });
    
    try {
      await _saveChanges();
    } catch (e) {
      setState(() {
        _enabled[categoryId] = oldValue ?? false;
      });
      rethrow;
    }
  }

  Future<void> _updateTime(String categoryId, TimeOfDay time) async {
    final oldTime = _customTimes[categoryId];
    
    setState(() {
      _customTimes[categoryId] = time;
    });
    
    try {
      await _service.saveCustomTimes(_customTimes);
      
      if (_enabled[categoryId] == true && _hasPermission) {
        final category = _categories!.firstWhere((c) => c.id == categoryId);
        
        await NotificationManager.instance.cancelAthkarReminder(categoryId);
        await NotificationManager.instance.scheduleAthkarReminder(
          categoryId: categoryId,
          categoryName: category.title,
          time: time,
        );
      }
      
      if (!(_enabled[categoryId] ?? false)) {
        await _toggleCategory(categoryId, true);
      }
      
      if (mounted) {
        context.showSuccessSnackBar('تم تحديث الوقت بنجاح');
      }
    } catch (e) {
      setState(() {
        _customTimes[categoryId] = oldTime ?? 
            AthkarConstants.getDefaultTimeForCategory(categoryId);
      });
      
      if (mounted) {
        context.showErrorSnackBar('حدث خطأ في تحديث الوقت');
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_saving) return;
    
    setState(() => _saving = true);
    
    try {
      if (!_hasPermission) {
        final enabledCount = _enabled.values.where((e) => e).length;
        if (enabledCount > 0) {
          if (mounted) {
            context.showWarningSnackBar('يجب تفعيل أذونات الإشعارات أولاً');
          }
          return;
        }
      }

      await _service.updateReminderSettings(
        enabledMap: _enabled,
        customTimes: _customTimes,
      );
      
      _originalTimes.clear();
      _originalTimes.addAll(_customTimes);
      
      if (mounted) {
        context.showSuccessSnackBar('تم حفظ الإعدادات بنجاح');
      }
    } catch (e) {
      debugPrint('خطأ في حفظ الإعدادات: $e');
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
                fontSize: 16.sp,
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
      await _saveChanges();
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
      await _saveChanges();
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
            Expanded(child: _buildBody()),
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
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 12.w),
          
          Container(
            padding: EdgeInsets.all(8.r),
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
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إشعارات الأذكار',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  'تخصيص تذكيرات الأذكار اليومية',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          
          if (_hasPermission && (_categories?.isNotEmpty ?? false))
            _buildActionsMenu(),
          
          if (_saving)
            Container(
              margin: EdgeInsets.only(left: 8.w),
              child: SizedBox(
                width: 24.w,
                height: 24.w,
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
      margin: EdgeInsets.only(left: 8.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: PopupMenuButton<String>(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.dividerColor.withOpacity(0.3),
                width: 1.w,
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
              Icons.more_vert,
              color: context.textPrimaryColor,
              size: 24.sp,
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
                  const Icon(Icons.notifications_active),
                  SizedBox(width: 8.w),
                  const Text('تفعيل الكل'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'disable_all',
              child: Row(
                children: [
                  const Icon(Icons.notifications_off),
                  SizedBox(width: 8.w),
                  const Text('إيقاف الكل'),
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
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionSection(),
            
            SizedBox(height: 24.h),
            
            if (_hasPermission) ...[
              if (categories.isEmpty)
                _buildNoCategoriesMessage()
              else ...[
                _buildQuickStats(categories),
                
                SizedBox(height: 16.h),
                
                Text(
                  'جميع فئات الأذكار (${categories.length})',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 16.sp,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                Text(
                  'يمكنك تفعيل التذكيرات لأي فئة وتخصيص أوقاتها',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                ...categories.map((category) => 
                  _buildCategoryTile(category)
                ),
              ],
            ] else
              _buildPermissionRequiredMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(List<AthkarCategory> categories) {
    final enabledCount = _enabled.values.where((e) => e).length;
    final disabledCount = categories.length - enabledCount;
    
    return AppCard(
      padding: EdgeInsets.all(16.r),
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
            height: 40.h,
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
            height: 40.h,
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

  Widget _buildPermissionSection() {
    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasPermission ? Icons.notifications_active : Icons.notifications_off,
                color: _hasPermission ? ThemeConstants.success : ThemeConstants.warning,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasPermission ? 'الإشعارات مفعلة' : 'الإشعارات معطلة',
                      style: TextStyle(
                        fontWeight: ThemeConstants.semiBold,
                        color: _hasPermission ? ThemeConstants.success : ThemeConstants.warning,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      _hasPermission 
                          ? 'يمكنك الآن تخصيص تذكيرات الأذكار'
                          : 'قم بتفعيل الإشعارات لتلقي التذكيرات',
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
          if (!_hasPermission) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                text: 'تفعيل الإشعارات',
                onPressed: _requestPermission,
                icon: Icons.notifications,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoCategoriesMessage() {
    return AppCard(
      padding: EdgeInsets.all(20.r),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48.sp,
            color: context.textSecondaryColor.withOpacity(0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            'لا توجد فئات أذكار',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'لم يتم العثور على أي فئات للأذكار',
            style: TextStyle(
              color: context.textSecondaryColor.withOpacity(0.7),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequiredMessage() {
    return AppCard(
      padding: EdgeInsets.all(20.r),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 48.sp,
            color: ThemeConstants.warning,
          ),
          SizedBox(height: 12.h),
          Text(
            'الإشعارات مطلوبة',
            style: TextStyle(
              color: ThemeConstants.warning,
              fontWeight: ThemeConstants.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'يجب تفعيل الإشعارات أولاً لتتمكن من إعداد تذكيرات الأذكار',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          AppButton.primary(
            text: 'تفعيل الإشعارات الآن',
            onPressed: _requestPermission,
            icon: Icons.notifications_active,
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
      padding: EdgeInsets.only(bottom: 12.h),
      child: AppCard(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 24.sp,
                  ),
                ),
                
                SizedBox(width: 12.w),
                
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
                                fontSize: 14.sp,
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
                            fontSize: 12.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      Text(
                        '${category.athkar.length} ذكر',
                        style: TextStyle(
                          color: context.textSecondaryColor.withOpacity(0.7),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Switch(
                  value: isEnabled,
                  onChanged: _hasPermission 
                      ? (value) => _toggleCategory(category.id, value)
                      : null,
                  activeColor: isEssential 
                      ? ThemeConstants.success 
                      : ThemeConstants.primary,
                ),
              ],
            ),
            
            if (isEnabled) ...[
              SizedBox(height: 12.h),
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
      margin: EdgeInsets.only(left: 8.w),
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
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
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: (isEssential ? ThemeConstants.success : ThemeConstants.primary)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
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
            size: 20.sp,
            color: isEssential ? ThemeConstants.success : ThemeConstants.primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وقت التذكير: ${currentTime.format(context)}',
                  style: TextStyle(
                    color: isEssential ? ThemeConstants.success : ThemeConstants.primary,
                    fontWeight: ThemeConstants.medium,
                    fontSize: 14.sp,
                  ),
                ),
                if (category.notifyTime == null)
                  Text(
                    'وقت افتراضي - يمكنك تغييره',
                    style: TextStyle(
                      color: (isEssential ? ThemeConstants.success : ThemeConstants.primary)
                          .withOpacity(0.7),
                      fontSize: 11.sp,
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
                horizontal: 12.w,
              ),
            ),
            child: const Text('تغيير'),
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
          size: 20.sp,
        ),
        SizedBox(height: 4.h),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: ThemeConstants.bold,
            fontSize: 16.sp,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}