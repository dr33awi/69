// lib/features/settings/screens/main_settings_screen.dart

import 'package:athkar_app/core/infrastructure/services/share/share_extensions.dart';
import 'package:athkar_app/features/settings/widgets/dialogs/about_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../widgets/header/settings_header.dart';
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

  @override
  void initState() {
    super.initState();
    _settingsManager = getIt<SettingsServicesManager>();
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
              child: _buildSettingsList(),
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
            
            // Footer Section
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }

  // ==================== Footer Section ====================
  Widget _buildFooterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        children: [
          // Divider
          Container(
            height: 1.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.dividerColor.withOpacitySafe(0),
                  context.dividerColor,
                  context.dividerColor.withOpacitySafe(0),
                ],
              ),
            ),
          ),
          
          // Made with Love
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'صُنع بـ',
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor.withOpacitySafe(0.7),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.favorite,
                size: 14.sp,
                color: AppColors.error.withOpacitySafe(0.8),
              ),
              SizedBox(width: 4.w),
              Text(
                'لوجه الله تعالى',
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor.withOpacitySafe(0.7),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Version
          FutureBuilder<String>(
            future: _getAppVersion(),
            builder: (context, snapshot) {
              final version = snapshot.data ?? '1.0.0';
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacitySafe(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'الإصدار $version',
                  style: context.labelSmall?.copyWith(
                    color: context.textSecondaryColor.withOpacitySafe(0.7),
                    fontSize: 11.sp,
                    fontWeight: ThemeConstants.medium,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '1.0.0';
    }
  }

  // ==================== Event Handlers ====================

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        _showSuccessMessage('تم تحديث الإعدادات بنجاح');
      }
    } catch (e) {
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
      // رسالة شكر بعد طلب التقييم
      _showSuccessMessage('شكراً لك! نقدر وقتك ورأيك 💚');
      
    } catch (e) {
      _showErrorMessage('حدث خطأ أثناء فتح صفحة التقييم');
    }
  }

  Future<void> _contactUs() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'dhakarani.app@gmail.com',
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