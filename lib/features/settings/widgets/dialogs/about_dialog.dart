// lib/features/settings/widgets/dialogs/app_about_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../app/themes/app_theme.dart';

/// حوار معلومات عن التطبيق المحسّن
class AppAboutDialog extends StatefulWidget {
  const AppAboutDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => const AppAboutDialog(),
    );
  }

  @override
  State<AppAboutDialog> createState() => _AppAboutDialogState();
}

class _AppAboutDialogState extends State<AppAboutDialog> {
  String _version = '1.0.0';
  String _buildNumber = '1';
  
  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }
  
  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(
            color: context.primaryColor.withOpacitySafe(0.08),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? context.primaryColor.withOpacitySafe(0.2) : context.primaryColor.withOpacitySafe(0.1),
              blurRadius: 24.r,
              offset: Offset(0, 12.h),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : context.primaryColor.withOpacitySafe(0.05),
              blurRadius: 40.r,
              offset: Offset(0, 16.h),
              spreadRadius: -4.r,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildContent(context),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Header Section ====================
  Widget _buildHeader(BuildContext context) {
    final isDark = context.isDarkMode;
    
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withOpacitySafe(0.08),
            context.primaryColor.withOpacitySafe(0.03),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? context.primaryColor.withOpacitySafe(0.15) : context.primaryColor.withOpacitySafe(0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: -2.r,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ذكرني',
                  style: context.headlineMedium?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: context.primaryColor,
                    fontSize: 26.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'رفيقك اليومي للأذكار والأدعية',
                  style: context.bodyMedium?.copyWith(
                    color: context.textSecondaryColor.withOpacitySafe(0.8),
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: context.textSecondaryColor.withOpacitySafe(0.08),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: context.textSecondaryColor.withOpacitySafe(0.12),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.2) : context.textSecondaryColor.withOpacitySafe(0.08),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 20.sp,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Content Section ====================
  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          _buildInfoCard(
            context,
            icon: Icons.task_alt_rounded,
            iconColor: AppColors.accent,
            title: 'رسالة التطبيق',
            description: 'تطبيق ذكرني صُمم لمساعدة المسلمين على المحافظة على أذكارهم اليومية بسهولة ويسر، مع توفير تجربة استخدام سلسة وموثوقة تجمع بين التقنيات الحديثة وروح الإيمان.',
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withOpacitySafe(0.1),
                AppColors.accent.withOpacitySafe(0.05),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          _buildInfoCard(
            context,
            icon: Icons.visibility_rounded,
            iconColor: AppColors.accent,
            title: 'رؤية التطبيق',
            description: 'أن نصبح التطبيق الإسلامي الأول والأكثر ثقة وتميّزًا في تقديم الأذكار والأدعية للمستخدمين في العالمين العربي والإسلامي.',
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withOpacitySafe(0.1),
                AppColors.accent.withOpacitySafe(0.05),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          _buildFeaturesCard(context),
        ],
      ),
    );
  }

  // ==================== Info Card Widget ====================
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required Gradient gradient,
  }) {
    final isDark = context.isDarkMode;
    
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: iconColor.withOpacitySafe(0.2),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? iconColor.withOpacitySafe(0.15) : iconColor.withOpacitySafe(0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: -2.r,
          ),
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : iconColor.withOpacitySafe(0.04),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
            spreadRadius: -4.r,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacitySafe(0.15),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: iconColor.withOpacitySafe(0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacitySafe(0.2),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Icon(icon, size: 22.sp, color: iconColor),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.titleMedium?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: context.primaryColor,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  description,
                  style: context.bodySmall?.copyWith(
                    height: 1.6,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Features Card Widget ====================
  Widget _buildFeaturesCard(BuildContext context) {
    final isDark = context.isDarkMode;
    final features = [
      {'icon': Icons.menu_book_rounded, 'text': 'الأذكار اليومية الشاملة'},
      {'icon': FlutterIslamicIcons.solidPrayer, 'text': 'الأدعية الإسلامية الموثقة'},
      {'icon': FlutterIslamicIcons.solidTasbihHand, 'text': 'التسبيح الرقمي الذكي'},
      {'icon': FlutterIslamicIcons.solidMosque, 'text': 'أوقات الصلاة الدقيقة'},
      {'icon': FlutterIslamicIcons.solidQibla, 'text': 'اتجاه القبلة بدقة'},
      {'icon': FlutterIslamicIcons.solidAllah, 'text': 'أسماء الله الحسنى'},
      {'icon': Icons.notifications_active_rounded, 'text': 'نظام إشعارات ذكي'},
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacitySafe(0.05),
            AppColors.primary.withOpacitySafe(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: context.primaryColor.withOpacitySafe(0.2),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.accent.withOpacitySafe(0.15) : context.primaryColor.withOpacitySafe(0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: -2.r,
          ),
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : context.primaryColor.withOpacitySafe(0.04),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
            spreadRadius: -4.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.accent.withOpacitySafe(0.3),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacitySafe(0.3),
                      blurRadius: 10.r,
                      offset: Offset(0, 3.h),
                    ),
                    BoxShadow(
                      color: AppColors.accent.withOpacitySafe(0.2),
                      blurRadius: 16.r,
                      offset: Offset(0, 6.h),
                      spreadRadius: -2.r,
                    ),
                  ],
                ),
                child: Icon(Icons.star_rounded, size: 22.sp, color: Colors.white),
              ),
              SizedBox(width: 10.w),
              Text(
                'الميزات الرئيسية',
                style: context.titleMedium?.copyWith(
                  fontWeight: ThemeConstants.bold,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            final color = AppColors.getAsmaAllahColorByIndex(index);
            
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: color.withOpacitySafe(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: color.withOpacitySafe(0.25),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacitySafe(0.1),
                          blurRadius: 6.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      size: 18.sp,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      feature['text'] as String,
                      style: context.bodyMedium?.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: ThemeConstants.medium,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==================== Footer Section ====================
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: Column(
        children: [
          Divider(height: 1.h, color: context.dividerColor),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'صُنع بـ',
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor.withOpacitySafe(0.8),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.favorite,
                size: 13.sp,
                color: AppColors.error.withOpacitySafe(0.8),
              ),
              SizedBox(width: 4.w),
              Text(
                'لوجه الله تعالى',
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor.withOpacitySafe(0.8),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacitySafe(0.06),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'v$_version',
              style: context.labelSmall?.copyWith(
                color: context.textSecondaryColor.withOpacitySafe(0.7),
                fontSize: 10.sp,
                fontWeight: ThemeConstants.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}