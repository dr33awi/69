// lib/features/settings/screens/main_settings_screen.dart

import 'package:athkar_app/core/infrastructure/services/share/share_extensions.dart';
import 'package:athkar_app/features/settings/widgets/dialogs/about_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../core/infrastructure/services/permissions/permission_manager.dart';
import '../../../core/infrastructure/services/permissions/permission_constants.dart';
import '../../../core/infrastructure/services/permissions/models/permission_state.dart';

import '../widgets/header/settings_header.dart';
import '../widgets/permissions/permission_status_card.dart';
import '../widgets/permissions/permission_bottom_sheet.dart';
import '../widgets/sections/notifications_section.dart';
import '../widgets/sections/appearance_section.dart';
import '../widgets/sections/support_section.dart';
import '../widgets/dialogs/reset_settings_dialog.dart';
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
  
  List<AppPermissionType> get _criticalPermissions => 
      PermissionConstants.criticalPermissions;

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
      await _refreshPermissionStatuses();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading settings data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _refreshPermissionStatuses() async {
    try {
      debugPrint('[Settings] Refreshing permission statuses...');
      
      _permissionService.clearPermissionCache();
      
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
            SettingsHeader(onReset: _handleResetSettings),
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

  Widget _buildSettingsList() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: context.primaryColor,
      backgroundColor: context.cardColor,
      displacement: 40.h,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20.h),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            
            // بطاقة حالة الأذونات
            PermissionStatusCard(
              result: _permissionResult,
              onTap: _showPermissionsBottomSheet,
            ),
            
            // قسم الإشعارات
            NotificationsSection(manager: _settingsManager),
            
            // قسم المظهر
            AppearanceSection(manager: _settingsManager),
            
            // قسم الدعم
            SupportSection(
              onShare: _shareApp,
              onRate: _rateApp,
              onContact: _contactUs,
              onAbout: _showAboutDialog,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Event Handlers ====================
  
  void _showPermissionsBottomSheet() {
    PermissionBottomSheet.show(
      context: context,
      permissionStatuses: _permissionStatuses,
      criticalPermissions: _criticalPermissions,
      onRequestPermission: _requestPermission,
      onOpenSystemSettings: _permissionService.openAppSettings,
    ).then((_) => _handleRefresh());
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
        final title = PermissionConstants.getName(permission);
        _showSuccessMessage('تم تفعيل إذن $title');
      }
    }
    
    await _refreshPermissionStatuses();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    
    try {
      debugPrint('[Settings] ========== Starting Refresh ==========');
      
      _permissionService.clearPermissionCache();
      debugPrint('[Settings] ✅ Cache cleared');
      
      await _refreshPermissionStatuses();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
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

  Future<void> _handleResetSettings() async {
    HapticFeedback.heavyImpact();
    
    final confirmed = await ResetSettingsDialog.show(context);
    
    if (confirmed) {
      await _settingsManager.resetSettings();
      await _permissionManager.reset();
      await _loadInitialData();
      _showSuccessMessage('تم إعادة تعيين الإعدادات بنجاح');
    }
  }

  void _shareApp() {
    context.shareApp();
  }

  /// تقييم التطبيق باستخدام النظام الجديد الذكي
  Future<void> _rateApp() async {
    HapticFeedback.lightImpact();
    
    try {
      final reviewManager = context.reviewManager;
      
      // طلب التقييم مباشرة (يتجاوز شروط العرض التلقائي)
      await reviewManager.requestReviewDirect(context);
      
      debugPrint('[Settings] Review requested from settings');
      
      // رسالة شكر بعد طلب التقييم
      _showSuccessMessage('شكراً لك! نقدر وقتك ورأيك 💚');
      
    } catch (e) {
      debugPrint('[Settings] Error requesting review: $e');
      _showErrorMessage('حدث خطأ أثناء فتح صفحة التقييم');
    }
  }

  Future<void> _contactUs() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'dhakaranifeedback@gmail.com',
      queryParameters: {
        'subject': 'استفسار من تطبيق ذكرني',
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
    AppAboutDialog.show(context);
  }

  // ==================== Helper Methods ====================
  
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
            Icon(icon, color: Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Expanded(child: Text(message, style: TextStyle(fontSize: 12.sp))),
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
  
  @override
  void dispose() {
    super.dispose();
  }
}