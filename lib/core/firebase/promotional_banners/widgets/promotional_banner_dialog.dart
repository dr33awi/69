// lib/core/infrastructure/firebase/promotional_banners/widgets/promotional_banner_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/promotional_banner_model.dart';
import '../../../../app/themes/app_theme.dart';

/// Dialog لعرض البانر الترويجي
class PromotionalBannerDialog extends StatelessWidget {
  final PromotionalBanner banner;
  final VoidCallback? onDismiss;
  final VoidCallback? onActionPressed;

  const PromotionalBannerDialog({
    super.key,
    required this.banner,
    this.onDismiss,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: banner.gradientColors.length >= 2
                ? banner.gradientColors
                : [
                    banner.gradientColors.first,
                    banner.gradientColors.first.withValues(alpha: 0.7),
                  ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: banner.gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 20.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            // محتوى البانر
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أيقونة/إيموجي
                  if (banner.emoji != null) ...[
                    Text(
                      banner.emoji!,
                      style: TextStyle(fontSize: 56.sp),
                    ),
                    SizedBox(height: 16.h),
                  ] else if (banner.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Image.network(
                        banner.imageUrl!,
                        height: 120.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              size: 48.sp,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // عنوان
                  Text(
                    banner.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: ThemeConstants.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // وصف
                  Text(
                    banner.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // أزرار
                  Row(
                    children: [
                      // زر الإغلاق
                      Expanded(
                        child: _buildButton(
                          context: context,
                          text: 'إغلاق',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            onDismiss?.call();
                          },
                          isPrimary: false,
                        ),
                      ),

                      // زر العمل (إذا كان موجوداً)
                      if (banner.actionText != null) ...[
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: banner.actionRoute != null || banner.actionUrl != null ? 2 : 1,
                          child: _buildButton(
                            context: context,
                            text: banner.actionText!,
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              _handleAction(context);
                            },
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // زر الإغلاق في الأعلى
            Positioned(
              top: 8.h,
              left: 8.w,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    onDismiss?.call();
                  },
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ),

            // شارة الأولوية (للبانرات العاجلة)
            if (banner.priority == BannerPriority.urgent)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.priority_high_rounded,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'عاجل',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: ThemeConstants.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// بناء زر
  Widget _buildButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary
          ? Colors.white
          : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: !isPrimary
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.w,
                  )
                : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: ThemeConstants.bold,
              color: isPrimary
                  ? banner.gradientColors.first
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// معالجة الإجراء
  void _handleAction(BuildContext context) {
    Navigator.pop(context);
    onActionPressed?.call();

    // التنقل إلى route
    if (banner.actionRoute != null && banner.actionRoute!.isNotEmpty) {
      try {
        Navigator.pushNamed(context, banner.actionRoute!);
        debugPrint('📍 Navigating to: ${banner.actionRoute}');
      } catch (e) {
        debugPrint('❌ Navigation error: $e');
      }
    }

    // فتح URL
    if (banner.actionUrl != null && banner.actionUrl!.isNotEmpty) {
      _launchUrl(banner.actionUrl!);
    }
  }

  /// فتح رابط خارجي
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('🌐 Opened URL: $url');
      } else {
        debugPrint('❌ Cannot launch URL: $url');
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
    }
  }

  /// عرض البانر
  static Future<void> show({
    required BuildContext context,
    required PromotionalBanner banner,
    VoidCallback? onDismiss,
    VoidCallback? onActionPressed,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => PromotionalBannerDialog(
        banner: banner,
        onDismiss: onDismiss,
        onActionPressed: onActionPressed,
      ),
    );
  }
}