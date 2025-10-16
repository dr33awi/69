// lib/core/infrastructure/firebase/promotional_banners/widgets/banner_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import '../models/promotional_banner_model.dart';
import '../services/banner_service.dart';
import '../services/banner_analytics_service.dart';
import '../../special_event/modals/special_event_model.dart';
import '../../special_event/services/event_navigation_handler.dart';

/// Dialog للبانرات العاجلة
class BannerDialog extends StatefulWidget {
  final PromotionalBanner banner;
  final String screenName;
  
  const BannerDialog({
    super.key,
    required this.banner,
    required this.screenName,
  });

  /// عرض الـ Dialog
  static Future<void> show({
    required BuildContext context,
    required PromotionalBanner banner,
    required String screenName,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => BannerDialog(
        banner: banner,
        screenName: screenName,
      ),
    );
  }

  @override
  State<BannerDialog> createState() => _BannerDialogState();
}

class _BannerDialogState extends State<BannerDialog>
    with SingleTickerProviderStateMixin {
  final _bannerService = BannerService();
  final _analytics = BannerAnalyticsService();
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
    _recordImpression();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _recordImpression() async {
    await _bannerService.recordBannerDisplay(widget.banner.id);
    await _analytics.trackBannerImpression(widget.banner, widget.screenName);
  }

  void _handleAction() {
    HapticFeedback.lightImpact();
    _bannerService.recordBannerClick(widget.banner.id);
    _analytics.trackBannerClick(widget.banner, widget.screenName);
    
    Navigator.pop(context);
    
    EventNavigationHandler.handle(
      context: context,
      url: widget.banner.actionUrl,
      event: _convertToEventModel(),
    );
  }

  void _handleDismiss() {
    HapticFeedback.mediumImpact();
    _bannerService.recordBannerDismiss(widget.banner.id);
    _analytics.trackBannerDismiss(widget.banner, widget.screenName);
    
    Navigator.pop(context);
  }

  /// ✅ تحويل البانر لموديل المناسبة (للتوافق مع EventNavigationHandler)
  SpecialEventModel _convertToEventModel() {
    return SpecialEventModel(
      isActive: true,
      title: widget.banner.title,
      description: widget.banner.description,
      icon: widget.banner.icon,
      backgroundImage: widget.banner.imageUrl,
      gradientColors: widget.banner.gradientColors,
      actionText: widget.banner.actionText,
      actionUrl: widget.banner.actionUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400.w,
              maxHeight: 500.h,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: LinearGradient(
                colors: widget.banner.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.banner.gradientColors.first.withOpacity(0.4),
                  blurRadius: 30.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Stack(
                children: [
                  // صورة الخلفية
                  if (widget.banner.imageUrl.isNotEmpty)
                    _buildBackgroundImage(),
                  
                  // المحتوى
                  SingleChildScrollView(
                    padding: EdgeInsets.all(24.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الأيقونة
                        if (widget.banner.icon.isNotEmpty) ...[
                          _buildIcon(),
                          SizedBox(height: 16.h),
                        ],
                        
                        // العنوان
                        _buildTitle(),
                        
                        SizedBox(height: 12.h),
                        
                        // الوصف
                        _buildDescription(),
                        
                        SizedBox(height: 24.h),
                        
                        // الأزرار
                        _buildButtons(),
                      ],
                    ),
                  ),
                  
                  // زر الإغلاق
                  _buildCloseButton(),
                  
                  // شارة urgent
                  if (widget.banner.priority == BannerPriority.urgent)
                    _buildUrgentBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.15,
        child: Image.network(
          widget.banner.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 64.r,
      height: 64.r,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2.w,
        ),
      ),
      child: Center(
        child: Text(
          widget.banner.icon,
          style: TextStyle(fontSize: 32.sp),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.banner.title,
      style: context.headlineSmall?.copyWith(
        color: Colors.white,
        fontWeight: ThemeConstants.bold,
        fontSize: 20.sp,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Text(
        widget.banner.description,
        style: context.bodyMedium?.copyWith(
          color: Colors.white.withOpacity(0.95),
          fontSize: 14.sp,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // زر الإجراء
        if (widget.banner.actionText.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: _handleAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: widget.banner.gradientColors.first,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.banner.actionText,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: ThemeConstants.bold,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.arrow_forward_rounded, size: 18.sp),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
        ],
        
        // زر الإغلاق
        TextButton(
          onPressed: _handleDismiss,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.8),
          ),
          child: Text(
            'إغلاق',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: ThemeConstants.medium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 8.h,
      right: 8.w,
      child: IconButton(
        onPressed: _handleDismiss,
        icon: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 18.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentBadge() {
    return Positioned(
      top: 12.h,
      left: 12.w,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 4.h,
        ),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(999.r),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 8.r,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.priority_high,
              color: Colors.white,
              size: 14.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              'عاجل',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: ThemeConstants.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}