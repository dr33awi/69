// lib/core/infrastructure/firebase/promotional_banners/widgets/promotional_banner_dialog.dart
// ✅ محسّن مع blur + background_image + إخفاء ذكي

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/promotional_banner_model.dart';
import '../../../../app/themes/app_theme.dart';
import '../../../../app/themes/widgets/core/app_button.dart';

/// Dialog لعرض البانر الترويجي مع تأثير Blur محسّن
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
    return Stack(
      children: [
        // ✅ Blur للخلفية - مطابق تماماً لـ PermissionMonitor
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            onDismiss?.call();
          },
          child: Container(
            color: Colors.black.withOpacity(0.6),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        
        // ✅ الـ Dialog نفسه
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _BannerCard(
            banner: banner,
            onDismiss: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            onActionPressed: () {
              _handleAction(context);
            },
          ),
        ),
      ],
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
      } catch (e) {
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
      } else {
      }
    } catch (e) {
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
      barrierColor: Colors.transparent, // ✅ شفاف لأننا نستخدم Stack مع blur
      builder: (context) => PromotionalBannerDialog(
        banner: banner,
        onDismiss: onDismiss,
        onActionPressed: onActionPressed,
      ),
    );
  }
}

/// بطاقة البانر - منفصلة للوضوح
class _BannerCard extends StatelessWidget {
  final PromotionalBanner banner;
  final VoidCallback onDismiss;
  final VoidCallback onActionPressed;

  const _BannerCard({
    required this.banner,
    required this.onDismiss,
    required this.onActionPressed,
  });

  /// ✅ التحقق من وجود أيقونة (ليس null ولا فارغ)
  bool _hasIcon() {
    return (banner.emoji != null && banner.emoji!.trim().isNotEmpty) ||
           (banner.imageUrl != null && banner.imageUrl!.trim().isNotEmpty);
  }

  /// ✅ التحقق من وجود action (ليس null ولا فارغ)
  bool _hasAction() {
    final hasActionText = banner.actionText != null && 
                          banner.actionText!.trim().isNotEmpty;
    final hasRoute = banner.actionRoute != null && 
                     banner.actionRoute!.trim().isNotEmpty;
    final hasUrl = banner.actionUrl != null && 
                   banner.actionUrl!.trim().isNotEmpty;
    
    return hasActionText && (hasRoute || hasUrl);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 0.85.sw,
      constraints: BoxConstraints(
        maxWidth: 380.w,
        minHeight: 280.h,
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Stack(
          children: [
            // ✅ صورة الخلفية (إن وجدت)
            if (banner.backgroundImage != null && 
                banner.backgroundImage!.trim().isNotEmpty) ...[
              _buildBackgroundImage(),
            ],
            
            // Container الأساسي
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                // ✅ تحكم بالشفافية هنا - قلل الرقم لتخفيف الشفافية
                color: banner.backgroundImage != null && 
                       banner.backgroundImage!.trim().isNotEmpty
                    ? (isDark ? Colors.black : Colors.white).withOpacity(0.7) // ✅ كان 0.85
                    : (isDark ? Colors.grey[900] : Colors.white),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Stack(
                children: [
                  // المحتوى الرئيسي
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر الإغلاق
                      Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onDismiss();
                            },
                            borderRadius: BorderRadius.circular(20.r),
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 20.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 8.h),
                      
                      // ✅ مساحة ثابتة للأيقونة (سواء موجودة أو لا)
                      SizedBox(
                        height: 72.h,
                        child: _hasIcon() ? _buildIcon(isDark) : const SizedBox(),
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // عنوان
                      Text(
                        banner.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                          letterSpacing: 0.2,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      // وصف
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          banner.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.5,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // ✅ مساحة ثابتة للزر (سواء موجود أو لا)
                      SizedBox(
                        height: 50.h,
                        child: _hasAction() ? _buildButtons(context) : const SizedBox(),
                      ),
                    ],
                  ),

                  // شارة الأولوية
                  if (banner.priority == BannerPriority.urgent)
                    _buildUrgentBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ بناء صورة الخلفية
  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Image.network(
          banner.backgroundImage!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          isAntiAlias: true,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: SizedBox(
                  width: 30.w,
                  height: 30.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5.w,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox();
          },
        ),
      ),
    );
  }

  /// بناء الأيقونة مع gradient من AppColors + دعم GIF
  Widget _buildIcon(bool isDark) {
    final mainColor = banner.gradientColors.isNotEmpty 
        ? banner.gradientColors.first 
        : ThemeConstants.primary;

    // التحقق من وجود emoji وأنه ليس فارغاً
    if (banner.emoji != null && banner.emoji!.trim().isNotEmpty) {
      return Container(
        width: 72.w,
        height: 72.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              mainColor.withOpacity(0.2),
              mainColor.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: mainColor.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            banner.emoji!,
            style: TextStyle(fontSize: 36.sp),
          ),
        ),
      );
    } 
    
    // التحقق من وجود imageUrl وأنه ليس فارغاً
    if (banner.imageUrl != null && banner.imageUrl!.trim().isNotEmpty) {
      final isGif = banner.imageUrl!.toLowerCase().endsWith('.gif');
      
      return Container(
        width: 72.w,
        height: 72.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              mainColor.withOpacity(0.2),
              mainColor.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: mainColor.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36.r),
          child: Image.network(
            banner.imageUrl!,
            width: 72.w,
            height: 72.w,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            isAntiAlias: true,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              
              return Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                isGif ? Icons.gif_box_outlined : Icons.image_outlined,
                size: 36.sp,
                color: mainColor,
              );
            },
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// بناء الأزرار
  Widget _buildButtons(BuildContext context) {
    final mainColor = banner.gradientColors.isNotEmpty 
        ? banner.gradientColors.first 
        : ThemeConstants.primary;

    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: _buildButton(
        context: context,
        text: banner.actionText!,
        onPressed: () {
          HapticFeedback.mediumImpact();
          onActionPressed();
        },
        isPrimary: true,
        mainColor: mainColor,
      ),
    );
  }

  /// بناء زر واحد
  Widget _buildButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
    required Color mainColor,
  }) {
    return isPrimary 
        ? AppButton.custom(
            text: text,
            onPressed: onPressed,
            isFullWidth: true,
            size: ButtonSize.small,
            backgroundColor: mainColor,
            textColor: Colors.white,
          )
        : AppButton.outline(
            text: text,
            onPressed: onPressed,
            isFullWidth: true,
            size: ButtonSize.small,
            color: Colors.grey[600],
          );
  }

  /// شارة عاجل
  Widget _buildUrgentBadge() {
    return Positioned(
      top: 6.h,
      right: 6.w,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 5.h,
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 6.r,
              offset: Offset(0, 1.5.h),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.priority_high_rounded,
              color: Colors.white,
              size: 14.sp,
            ),
            SizedBox(width: 3.w),
            Text(
              'عاجل',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: ThemeConstants.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}