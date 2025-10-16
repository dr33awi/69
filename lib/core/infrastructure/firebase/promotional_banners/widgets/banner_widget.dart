// lib/core/infrastructure/firebase/promotional_banners/widgets/banner_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import '../models/promotional_banner_model.dart';
import '../services/banner_service.dart';
import '../services/banner_analytics_service.dart';
import '../../special_event/services/event_navigation_handler.dart';

/// ويدجت البانر الترويجي
class BannerWidget extends StatefulWidget {
  final PromotionalBanner banner;
  final String screenName;
  final VoidCallback? onDismiss;
  
  const BannerWidget({
    super.key,
    required this.banner,
    required this.screenName,
    this.onDismiss,
  });

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  final _bannerService = BannerService();
  final _analytics = BannerAnalyticsService();
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _recordImpression();
  }

  Future<void> _recordImpression() async {
    await _bannerService.recordBannerDisplay(widget.banner.id);
    await _analytics.trackBannerImpression(widget.banner, widget.screenName);
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _bannerService.recordBannerClick(widget.banner.id);
    _analytics.trackBannerClick(widget.banner, widget.screenName);
    
    EventNavigationHandler.handle(
      context: context,
      url: widget.banner.actionUrl,
      event: _convertToEventModel(),
    );
  }

  void _handleDismiss() {
    HapticFeedback.mediumImpact();
    setState(() => _isDismissed = true);
    
    _bannerService.recordBannerDismiss(widget.banner.id);
    _analytics.trackBannerDismiss(widget.banner, widget.screenName);
    
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: widget.banner.gradientColors.map((c) => c.withOpacity(0.95)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.banner.gradientColors.first.withOpacity(0.3),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(16.r),
            splashColor: Colors.white.withOpacity(0.1),
            child: Stack(
              children: [
                // صورة الخلفية
                if (widget.banner.imageUrl.isNotEmpty)
                  _buildBackgroundImage(),
                
                // المحتوى
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      // الأيقونة
                      if (widget.banner.icon.isNotEmpty) ...[
                        _buildIcon(),
                        SizedBox(width: 12.w),
                      ],
                      
                      // النص
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitle(),
                            SizedBox(height: 4.h),
                            _buildDescription(),
                            if (widget.banner.actionText.isNotEmpty) ...[
                              SizedBox(height: 8.h),
                              _buildActionButton(),
                            ],
                          ],
                        ),
                      ),
                      
                      // زر الإغلاق
                      _buildDismissButton(),
                    ],
                  ),
                ),
                
                // شارة الأولوية (urgent فقط)
                if (widget.banner.priority == BannerPriority.urgent)
                  _buildUrgentBadge(),
              ],
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
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.banner.icon,
          style: TextStyle(fontSize: 20.sp),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.banner.title,
      style: context.titleSmall?.copyWith(
        color: Colors.white,
        fontWeight: ThemeConstants.bold,
        fontSize: 14.sp,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.banner.description,
      style: context.bodySmall?.copyWith(
        color: Colors.white.withOpacity(0.9),
        fontSize: 11.sp,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.banner.actionText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: ThemeConstants.semiBold,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 12.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildDismissButton() {
    return IconButton(
      onPressed: _handleDismiss,
      icon: Icon(
        Icons.close_rounded,
        color: Colors.white.withOpacity(0.8),
        size: 18.sp,
      ),
      constraints: BoxConstraints(
        minWidth: 32.w,
        minHeight: 32.h,
      ),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildUrgentBadge() {
    return Positioned(
      top: 8.h,
      right: 8.w,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: 3.h,
        ),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.priority_high,
              color: Colors.white,
              size: 12.sp,
            ),
            SizedBox(width: 2.w),
            Text(
              'عاجل',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: ThemeConstants.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تحويل البانر لموديل المناسبة (للتوافق مع EventNavigationHandler)
  dynamic _convertToEventModel() {
    // استخدم نفس الموديل أو أنشئ wrapper بسيط
    return null; // يمكن تحسينها لاحقاً
  }
}