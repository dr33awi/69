// lib/features/settings/screens/main_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../core/infrastructure/services/permissions/permission_manager.dart';
import '../../../core/infrastructure/services/permissions/models/permission_state.dart';

import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../services/settings_services_manager.dart';

class MainSettingsScreen extends StatefulWidget {
  const MainSettingsScreen({super.key});

  @override
  State<MainSettingsScreen> createState() => _MainSettingsScreenState();
}

class _MainSettingsScreenState extends State<MainSettingsScreen> {
  late final SettingsServicesManager _settingsManager;
  late final PermissionService _permissionService;
  late final UnifiedPermissionManager _permissionManager;

  // حالة الأذونات
  Map<AppPermissionType, AppPermissionStatus> _permissionStatuses = {};
  PermissionCheckResult? _permissionResult;
  bool _isLoading = false;

  // للتحكم في المراجعة داخل التطبيق
  final InAppReview _inAppReview = InAppReview.instance;
  
  // قائمة الأذونات الأساسية فقط
  final List<AppPermissionType> _criticalPermissions = [
    AppPermissionType.notification,
    AppPermissionType.location,
    AppPermissionType.batteryOptimization,
  ];

  @override
  void initState() {
    super.initState();
    _settingsManager = getIt<SettingsServicesManager>();
    _permissionService = getIt<PermissionService>();
    _permissionManager = getIt<UnifiedPermissionManager>();
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // تحميل حالة الأذونات بشكل جديد (فحص حقيقي وليس من الكاش)
      await _refreshPermissionStatuses();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading settings data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadPermissionStatuses() async {
    try {
      final statuses = await _permissionService.checkAllPermissions();
      if (mounted) {
        setState(() {
          _permissionStatuses = statuses;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('حدث خطأ في تحميل حالة الأذونات');
      }
    }
  }
  
  Future<void> _refreshPermissionStatuses() async {
    try {
      debugPrint('[Settings] Refreshing permission statuses...');
      
      // مسح الكاش أولاً لضمان فحص جديد
      _permissionService.clearPermissionCache();
      
      // فحص جديد لكل الأذونات
      final statuses = <AppPermissionType, AppPermissionStatus>{};
      
      for (final permission in _criticalPermissions) {
        final status = await _permissionService.checkPermissionStatus(permission);
        statuses[permission] = status;
        debugPrint('[Settings] $permission: $status');
      }
      
      if (mounted) {
        setState(() {
          _permissionStatuses = statuses;
        });
      }
      
      // تحديث نتيجة الفحص الكامل
      _permissionResult = await _permissionManager.performQuickCheck();
      
      debugPrint('[Settings] Permission refresh completed');
      debugPrint('[Settings] Granted: ${_permissionResult?.grantedCount ?? 0}');
      debugPrint('[Settings] Missing: ${_permissionResult?.missingCount ?? 0}');
      
    } catch (e) {
      debugPrint('[Settings] Error refreshing permissions: $e');
      if (mounted) {
        _showErrorMessage('حدث خطأ في تحديث حالة الأذونات');
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
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSettingsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.1),
            width: 1.w,
          ),
        ),
      ),
      child: Row(
        children: [
          // زر الرجوع
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 12.w),
          
          // الأيقونة
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.settings,
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
                  'الإعدادات',
                  style: context.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: context.headlineSmall?.fontSize?.sp,
                  ),
                ),
                Text(
                  'تخصيص تجربتك مع التطبيق',
                  style: context.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: context.bodySmall?.fontSize?.sp,
                  ),
                ),
              ],
            ),
          ),
          
          // زر إعادة تعيين الإعدادات
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _resetSettings(),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ThemeConstants.error.withValues(alpha: 0.3),
                    width: 1.5.w,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: ThemeConstants.error,
                      size: 20.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'إعادة تعيين',
                      style: TextStyle(
                        color: ThemeConstants.error,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    // الحصول على الإعدادات الحالية من المدير
    final settings = _settingsManager.settings;
    
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: context.primaryColor,
      backgroundColor: context.cardColor,
      displacement: 40.h,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 32.h),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            
            // ==================== 1. بطاقة حالة الأذونات في الأعلى ====================
            _buildPermissionStatusCard(),
            
            // ==================== 2. قسم الإشعارات ====================
            SettingsSection(
              title: 'الإشعارات',
              subtitle: 'إدارة التنبيهات والتذكيرات',
              icon: Icons.notifications_active,
              children: [
                SettingsTile(
                  icon: Icons.access_time,
                  title: 'إشعارات الصلاة',
                  subtitle: 'تنبيهات أوقات الصلاة والأذان',
                  onTap: () => Navigator.pushNamed(context, AppRouter.prayerNotificationsSettings),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                ),
                SettingsTile(
                  icon: Icons.menu_book,
                  title: 'إشعارات الأذكار',
                  subtitle: 'تذكيرات الأذكار اليومية',
                  onTap: () => Navigator.pushNamed(context, AppRouter.athkarNotificationsSettings),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                ),
                SettingsTile(
                  icon: Icons.vibration,
                  title: 'الاهتزاز',
                  subtitle: 'اهتزاز عند وصول الإشعارات',
                  trailing: SettingsSwitch(
                    value: settings.vibrationEnabled,
                    onChanged: (value) async {
                      await _settingsManager.toggleVibration(value);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            
            // ==================== 3. قسم المظهر والعرض ====================
            SettingsSection(
              title: 'المظهر والعرض',
              subtitle: 'تخصيص شكل التطبيق',
              icon: Icons.palette,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          _settingsManager.currentTheme == ThemeMode.dark 
                              ? Icons.dark_mode 
                              : Icons.light_mode,
                          color: context.primaryColor,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'وضع العرض',
                              style: context.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: context.titleMedium?.fontSize?.sp,
                              ),
                            ),
                            Text(
                              _settingsManager.currentTheme == ThemeMode.dark
                                  ? 'الوضع الليلي مفعل'
                                  : 'الوضع النهاري مفعل',
                              style: context.bodySmall?.copyWith(
                                color: context.textSecondaryColor,
                                fontSize: context.bodySmall?.fontSize?.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _settingsManager.currentTheme == ThemeMode.dark,
                        onChanged: (value) {
                          _settingsManager.changeTheme(
                            value ? ThemeMode.dark : ThemeMode.light
                          );
                          setState(() {});
                        },
                        activeColor: context.primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // ==================== 4. قسم الدعم والمعلومات ====================
            SettingsSection(
              title: 'الدعم والمعلومات',
              subtitle: 'معلومات التطبيق والدعم',
              icon: Icons.info_outline,
              children: [
                SettingsTile(
                  icon: Icons.share_outlined,
                  title: 'مشاركة التطبيق',
                  subtitle: 'شارك التطبيق مع الأصدقاء والعائلة',
                  onTap: () => _shareApp(),
                ),
                SettingsTile(
                  icon: Icons.star_outline,
                  title: 'تقييم التطبيق',
                  subtitle: 'قيم التطبيق على المتجر وادعمنا',
                  onTap: () => _rateApp(),
                ),
                SettingsTile(
                  icon: Icons.headset_mic_outlined,
                  title: 'تواصل معنا',
                  subtitle: 'أرسل استفساراتك ومقترحاتك',
                  onTap: () => _contactUs(),
                ),
                SettingsTile(
                  icon: Icons.info_outline,
                  title: 'عن التطبيق',
                  subtitle: 'معلومات الإصدار والمطور',
                  onTap: () => _showAboutDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== بطاقة حالة الأذونات ====================
  Widget _buildPermissionStatusCard() {
    if (_permissionResult == null) {
      return const SizedBox();
    }
    
    final granted = _permissionResult!.grantedCount;
    final denied = _permissionResult!.missingCount;
    final total = granted + denied;
    final percentage = total > 0 ? granted / total : 0.0;
    
    return GestureDetector(
      onTap: () => _showPermissionsBottomSheet(),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 8.h,
        ),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStatusColor(percentage),
              _getStatusColor(percentage).withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor(percentage).withValues(alpha: 0.3),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // الأيقونة
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                // المعلومات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالة الأذونات',
                        style: context.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: context.titleMedium?.fontSize?.sp,
                        ),
                      ),
                      Text(
                        '$granted من $total أذونات مفعلة',
                        style: context.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: context.bodySmall?.fontSize?.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // أيقونة السهم
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ],
            ),
            
            // إحصائيات سريعة
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('مفعلة', granted, Colors.white),
                Container(
                  width: 1.w,
                  height: 30.h,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildQuickStat('معطلة', denied, Colors.white.withValues(alpha: 0.9)),
                Container(
                  width: 1.w,
                  height: 30.h,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildQuickStat('الكل', total, Colors.white),
              ],
            ),
            
            // نص توضيحي
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'اضغط لإدارة الأذونات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // ==================== نافذة الأذونات المنبثقة ====================
  void _showPermissionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            children: [
              // مقبض السحب
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              
              // العنوان
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Theme.of(context).primaryColor,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إدارة الأذونات',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'تحكم في أذونات التطبيق',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      iconSize: 24.sp,
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1.h),
              
              // قائمة الأذونات
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16.w),
                  children: [
                    // عرض الأذونات
                    ..._criticalPermissions
                        .where((p) => _permissionStatuses.containsKey(p))
                        .map((permission) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildPermissionCard(permission),
                        )),
                    
                    SizedBox(height: 20.h),
                    
                    // زر إعدادات النظام
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                          width: 1.w,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16.r),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _permissionService.openAppSettings();
                          },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Row(
                              children: [
                                Container(
                                  width: 44.w,
                                  height: 44.h,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.phonelink_setup,
                                    color: Theme.of(context).primaryColor,
                                    size: 22.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'إعدادات النظام',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'فتح إعدادات التطبيق في النظام',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_new,
                                  size: 18.sp,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // تحديث البيانات عند إغلاق النافذة (بعد العودة من الإعدادات مثلاً)
      _handleRefresh();
    });
  }
  
  // ==================== بطاقة إذن ====================
  Widget _buildPermissionCard(AppPermissionType permission) {
    final status = _permissionStatuses[permission] ?? AppPermissionStatus.unknown;
    final isGranted = status == AppPermissionStatus.granted;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isGranted 
              ? ThemeConstants.success.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // أيقونة الإذن
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: isGranted
                        ? ThemeConstants.success.withValues(alpha: 0.1)
                        : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    _getPermissionIcon(permission),
                    color: isGranted
                        ? ThemeConstants.success
                        : Theme.of(context).primaryColor,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                
                // معلومات الإذن
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPermissionTitle(permission),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _getPermissionDescription(permission),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // حالة الإذن
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? ThemeConstants.success.withValues(alpha: 0.1)
                        : ThemeConstants.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGranted ? Icons.check_circle : Icons.warning,
                        size: 14.sp,
                        color: isGranted
                            ? ThemeConstants.success
                            : ThemeConstants.warning,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isGranted ? 'مفعل' : 'معطل',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: isGranted
                              ? ThemeConstants.success
                              : ThemeConstants.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // زر التفعيل إذا كان الإذن معطل
            if (!isGranted) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _requestPermission(permission);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'تفعيل الإذن',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // دوال مساعدة للحصول على معلومات الأذونات
  IconData _getPermissionIcon(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.notification:
        return Icons.notifications;
      case AppPermissionType.location:
        return Icons.location_on;
      case AppPermissionType.batteryOptimization:
        return Icons.battery_charging_full;
    }
  }
  
  String _getPermissionTitle(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.notification:
        return 'الإشعارات';
      case AppPermissionType.location:
        return 'الموقع';
      case AppPermissionType.batteryOptimization:
        return 'تحسين البطارية';
    }
  }
  
  String _getPermissionDescription(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.notification:
        return 'لإرسال تنبيهات الصلاة والأذكار';
      case AppPermissionType.location:
        return 'لحساب أوقات الصلاة حسب موقعك';
      case AppPermissionType.batteryOptimization:
        return 'لضمان عمل الإشعارات في الخلفية';
    }
  }
  
  Future<void> _requestPermission(AppPermissionType permission) async {
    HapticFeedback.lightImpact();
    
    final status = await _permissionService.checkPermissionStatus(permission);
    
    if (status == AppPermissionStatus.permanentlyDenied) {
      await _permissionService.openAppSettings();
    } else {
      final granted = await _permissionManager.requestPermissionWithExplanation(
        context,
        permission,
      );
      
      if (granted) {
        _showSuccessMessage('تم تفعيل إذن ${_getPermissionTitle(permission)}');
      }
    }
    
    // تحديث مباشر بعد تغيير الإذن
    await _refreshPermissionStatuses();
  }

  // ==================== معالج Pull to Refresh ====================
  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    
    try {
      debugPrint('[Settings] ========== Starting Refresh ==========');
      
      // 1. مسح الكاش أولاً
      _permissionService.clearPermissionCache();
      debugPrint('[Settings] ✅ Cache cleared');
      
      // 2. فحص جديد ومباشر لكل الأذونات
      await _refreshPermissionStatuses();
      
      // 3. تأخير بسيط لتحسين تجربة المستخدم
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 4. عرض رسالة نجاح
      if (mounted) {
        _showSuccessMessage('تم تحديث حالة الأذونات بنجاح');
      }
      
      debugPrint('[Settings] ========== Refresh Completed ==========');
      
    } catch (e) {
      debugPrint('[Settings] ❌ Refresh error: $e');
      if (mounted) {
        _showErrorMessage('حدث خطأ أثناء التحديث');
      }
    }
  }

  // ==================== الدوال المساعدة ====================
  
  Future<void> _resetSettings() async {
    HapticFeedback.heavyImpact();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: ThemeConstants.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.warning,
                color: ThemeConstants.error,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'إعادة تعيين الإعدادات',
              style: TextStyle(fontSize: 18.sp),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من إعادة جميع الإعدادات إلى الوضع الافتراضي؟\n\nسيتم مسح جميع التخصيصات والإعدادات المحفوظة.',
          style: TextStyle(height: 1.5, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text('إعادة تعيين', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      await _settingsManager.resetSettings();
      await _permissionManager.reset();
      await _loadInitialData();
      _showSuccessMessage('تم إعادة تعيين الإعدادات بنجاح');
    }
  }

  void _shareApp() {
    Share.share(
      'جرب تطبيق حصن المسلم - تطبيق شامل للأذكار والأدعية\n'
      'حمل التطبيق الآن من:\n'
      'https://play.google.com/store/apps/details?id=com.yourapp.athkar',
      subject: 'تطبيق حصن المسلم',
    );
  }

  Future<void> _rateApp() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    } else {
      final url = Uri.parse('https://play.google.com/store/apps/details?id=com.yourapp.athkar');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _contactUs() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@yourapp.com',
      queryParameters: {
        'subject': 'استفسار من تطبيق حصن المسلم',
        'body': 'اكتب رسالتك هنا...',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorMessage('لا يمكن فتح تطبيق البريد الإلكتروني');
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeConstants.primary.withValues(alpha: 0.1),
                    ThemeConstants.primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mosque,
                size: 60.sp,
                color: ThemeConstants.primary,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'حصن المسلم',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ThemeConstants.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'الإصدار 1.0.0',
                style: TextStyle(
                  color: ThemeConstants.primary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'تطبيق شامل للأذكار والأدعية\nيساعدك على المحافظة على أذكارك اليومية',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5, fontSize: 14.sp),
            ),
            SizedBox(height: 20.h),
            Divider(height: 1.h),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.code, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  'تطوير وتصميم',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'فريق التطوير',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  // ==================== رسائل التنبيه ====================
  
  void _showSuccessMessage(String message) {
    _showSnackBar(message, ThemeConstants.success, Icons.check_circle);
  }

  void _showErrorMessage(String message) {
    _showSnackBar(message, ThemeConstants.error, Icons.error);
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(child: Text(message, style: TextStyle(fontSize: 14.sp))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 1.0) return ThemeConstants.success;
    if (percentage >= 0.5) return ThemeConstants.warning;
    return ThemeConstants.error;
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}