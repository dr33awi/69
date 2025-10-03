// lib/features/qibla/widgets/qibla_info_card.dart - نسخة منظفة
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/qibla_model.dart';

/// بطاقة معلومات القبلة
class QiblaInfoCard extends StatefulWidget {
  final QiblaModel qiblaData;
  final bool showDetailedInfo;
  final bool enableInteraction;

  const QiblaInfoCard({
    super.key,
    required this.qiblaData,
    this.showDetailedInfo = true,
    this.enableInteraction = true,
  });

  @override
  State<QiblaInfoCard> createState() => _QiblaInfoCardState();
}

class _QiblaInfoCardState extends State<QiblaInfoCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _expandController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: ThemeConstants.durationNormal,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 24.r,
      child: Column(
        children: [
          _buildHeader(context),
          _buildBasicInfo(context),
          if (widget.showDetailedInfo) _buildExpandableDetails(context),
          _buildWarnings(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withOpacity(0.1),
            context.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _getAccuracyColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: _getAccuracyColor(),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موقعك الحالي',
                  style: context.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: context.bodySmall?.fontSize?.sp,
                  ),
                ),
                Text(
                  _getLocationName(),
                  style: context.bodyLarge?.bold.copyWith(
                    fontSize: context.bodyLarge?.fontSize?.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getDataStatusText(),
                  style: context.bodySmall?.copyWith(
                    color: _getStatusColor(),
                    fontSize: context.bodySmall?.fontSize?.sp,
                  ),
                ),
              ],
            ),
          ),
          _buildQualityIndicator(context),
        ],
      ),
    );
  }

  Widget _buildQualityIndicator(BuildContext context) {
    final hasGoodQuality = widget.qiblaData.hasGoodQuality;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: hasGoodQuality 
            ? ThemeConstants.success.withOpacity(0.1)
            : ThemeConstants.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasGoodQuality 
              ? ThemeConstants.success.withOpacity(0.3)
              : ThemeConstants.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasGoodQuality ? Icons.verified : Icons.warning_amber,
            size: 20.sp,
            color: hasGoodQuality ? ThemeConstants.success : ThemeConstants.warning,
          ),
          SizedBox(width: 4.w),
          Text(
            hasGoodQuality ? 'موثوق' : 'محدود',
            style: context.bodySmall?.copyWith(
              color: hasGoodQuality ? ThemeConstants.success : ThemeConstants.warning,
              fontWeight: ThemeConstants.semiBold,
              fontSize: context.bodySmall?.fontSize?.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  context: context,
                  icon: Icons.navigation_outlined,
                  title: 'اتجاه القبلة',
                  value: '${widget.qiblaData.qiblaDirection.toStringAsFixed(1)}°',
                  subtitle: widget.qiblaData.directionDescription,
                  color: context.primaryColor,
                  onTap: widget.enableInteraction ? () => _showDirectionDetails(context) : null,
                ),
              ),
              Container(
                width: 1,
                height: 60.h,
                color: context.dividerColor.withOpacity(0.5),
                margin: EdgeInsets.symmetric(horizontal: 12.w),
              ),
              Expanded(
                child: _buildInfoTile(
                  context: context,
                  icon: Icons.straighten,
                  title: 'المسافة للكعبة',
                  value: widget.qiblaData.distanceDescription,
                  subtitle: 'خط مستقيم',
                  color: ThemeConstants.info,
                  onTap: widget.enableInteraction ? () => _showDistanceDetails(context) : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildQuickStats(context),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildStatRow(
            context: context,
            label: 'دقة الموقع',
            value: '± ${widget.qiblaData.accuracy.toStringAsFixed(0)} م',
            valueColor: _getAccuracyColor(),
            icon: _getAccuracyIcon(),
          ),
          SizedBox(height: 8.h),
          const Divider(height: 1),
          SizedBox(height: 8.h),
          _buildStatRow(
            context: context,
            label: 'عمر البيانات',
            value: widget.qiblaData.ageDescription,
            valueColor: _getAgeColor(),
            icon: Icons.schedule,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableDetails(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              if (_isExpanded) {
                _expandController.forward();
              } else {
                _expandController.reverse();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isExpanded ? 'إخفاء التفاصيل' : 'عرض المزيد',
                    style: context.bodyMedium?.copyWith(
                      color: context.primaryColor,
                      fontWeight: ThemeConstants.medium,
                      fontSize: context.bodyMedium?.fontSize?.sp,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: ThemeConstants.durationNormal,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.primaryColor,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: _expandController,
            curve: ThemeConstants.curveSmooth,
          ),
          child: _buildDetailedContent(context),
        ),
      ],
    );
  }

  Widget _buildDetailedContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection(
            context: context,
            title: 'الإحداثيات',
            icon: Icons.gps_fixed,
            children: [
              _buildDetailRow(
                context: context,
                label: 'خط العرض',
                value: '${widget.qiblaData.latitude.toStringAsFixed(6)}°',
                onTap: () => _copyToClipboard(context, widget.qiblaData.latitude.toString(), 'خط العرض'),
              ),
              _buildDetailRow(
                context: context,
                label: 'خط الطول',
                value: '${widget.qiblaData.longitude.toStringAsFixed(6)}°',
                onTap: () => _copyToClipboard(context, widget.qiblaData.longitude.toString(), 'خط الطول'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildDetailSection(
            context: context,
            title: 'معلومات السفر',
            icon: Icons.flight,
            children: [
              _buildDetailRow(
                context: context,
                label: 'وقت السفر المقدر',
                value: widget.qiblaData.estimatedTravelInfo,
              ),
              _buildDetailRow(
                context: context,
                label: 'وصف المسافة',
                value: widget.qiblaData.distanceContext,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings(BuildContext context) {
    final warnings = <Widget>[];
    
    if (widget.qiblaData.isStale) {
      warnings.add(_buildWarningCard(
        context: context,
        icon: Icons.warning_amber_rounded,
        title: 'بيانات قديمة',
        message: widget.qiblaData.dataStatusDescription,
        color: widget.qiblaData.isVeryStale ? ThemeConstants.error : ThemeConstants.warning,
      ));
    }
    
    if (widget.qiblaData.hasLowAccuracy) {
      warnings.add(_buildWarningCard(
        context: context,
        icon: Icons.gps_off,
        title: 'دقة منخفضة',
        message: widget.qiblaData.detailedAccuracyDescription,
        color: ThemeConstants.warning,
      ));
    }
    
    if (warnings.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: 16.h,
      ),
      child: Column(children: warnings),
    );
  }

  // Helper Widgets
  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32.sp),
              SizedBox(height: 8.h),
              Text(
                title,
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor,
                  fontSize: context.bodySmall?.fontSize?.sp,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                value,
                style: context.titleMedium?.bold.textColor(color).copyWith(
                  fontSize: context.titleMedium?.fontSize?.sp,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor.withOpacity(0.7),
                  fontSize: context.bodySmall?.fontSize?.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بقية الـ Helper methods
  Widget _buildStatRow({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20.sp, color: valueColor ?? context.textSecondaryColor),
          SizedBox(width: 8.w),
        ],
        Expanded(
          child: Text(
            label,
            style: context.bodySmall?.copyWith(
              color: context.textSecondaryColor,
              fontSize: context.bodySmall?.fontSize?.sp,
            ),
          ),
        ),
        Text(
          value,
          style: context.bodySmall?.copyWith(
            fontWeight: ThemeConstants.semiBold,
            color: valueColor ?? context.textPrimaryColor,
            fontSize: context.bodySmall?.fontSize?.sp,
          ),
        ),
      ],
    );
  }

  // ... بقية الكود (متابعة للملف الأصلي مع تطبيق ScreenUtil)

  // Helper Methods
  String _getLocationName() {
    if (widget.qiblaData.cityName != null && widget.qiblaData.countryName != null) {
      return '${widget.qiblaData.cityName}، ${widget.qiblaData.countryName}';
    } else if (widget.qiblaData.cityName != null) {
      return widget.qiblaData.cityName!;
    } else if (widget.qiblaData.countryName != null) {
      return widget.qiblaData.countryName!;
    }
    return 'موقع غير محدد';
  }

  String _getDataStatusText() {
    if (widget.qiblaData.isFresh) {
      return 'بيانات حديثة • ${widget.qiblaData.ageDescription}';
    } else if (widget.qiblaData.isStale) {
      return 'بيانات قديمة • ${widget.qiblaData.ageDescription}';
    }
    return 'محدث ${widget.qiblaData.ageDescription}';
  }

  Color _getStatusColor() {
    if (widget.qiblaData.isFresh) return ThemeConstants.success;
    if (widget.qiblaData.isStale) {
      return widget.qiblaData.isVeryStale ? ThemeConstants.error : ThemeConstants.warning;
    }
    return context.textSecondaryColor;
  }

  Color _getAccuracyColor() {
    if (widget.qiblaData.hasHighAccuracy) return ThemeConstants.success;
    if (widget.qiblaData.hasMediumAccuracy) return ThemeConstants.warning;
    return ThemeConstants.error;
  }

  IconData _getAccuracyIcon() {
    if (widget.qiblaData.hasHighAccuracy) return Icons.gps_fixed;
    if (widget.qiblaData.hasMediumAccuracy) return Icons.gps_not_fixed;
    return Icons.gps_off;
  }

  Color _getAgeColor() {
    if (widget.qiblaData.isFresh) return ThemeConstants.success;
    if (widget.qiblaData.isStale) return ThemeConstants.warning;
    if (widget.qiblaData.isVeryStale) return ThemeConstants.error;
    return context.textSecondaryColor;
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    if (!widget.enableInteraction) return;

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper widget methods remaining
  Widget _buildDetailSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24.sp, color: context.primaryColor),
              SizedBox(width: 8.w),
              Text(
                title,
                style: context.titleSmall?.semiBold.textColor(context.primaryColor).copyWith(
                  fontSize: context.titleSmall?.fontSize?.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 4.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: context.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                      fontSize: context.bodySmall?.fontSize?.sp,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: context.bodySmall?.copyWith(
                        fontWeight: ThemeConstants.medium,
                        color: valueColor ?? context.textPrimaryColor,
                        fontSize: context.bodySmall?.fontSize?.sp,
                      ),
                    ),
                    if (onTap != null) ...[
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.copy,
                        size: 20.sp,
                        color: context.textSecondaryColor.withOpacity(0.5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: ThemeConstants.semiBold,
                    fontSize: context.bodyMedium?.fontSize?.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  message,
                  style: context.bodySmall?.copyWith(
                    color: color.darken(0.1),
                    fontSize: context.bodySmall?.fontSize?.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog methods
  void _showDirectionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.navigation, color: context.primaryColor),
            SizedBox(width: 8.w),
            const Text('تفاصيل الاتجاه'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('الاتجاه', '${widget.qiblaData.qiblaDirection.toStringAsFixed(2)}°'),
            _buildDetailItem('الاتجاه المغناطيسي', '${widget.qiblaData.magneticQiblaDirection.toStringAsFixed(2)}°'),
            _buildDetailItem('الوصف', widget.qiblaData.detailedDirectionDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showDistanceDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.straighten, color: ThemeConstants.info),
            SizedBox(width: 8.w),
            const Text('تفاصيل المسافة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('المسافة', '${widget.qiblaData.distance.toStringAsFixed(2)} كم'),
            _buildDetailItem('الوصف', widget.qiblaData.distanceDescription),
            _buildDetailItem('السياق', widget.qiblaData.distanceContext),
            _buildDetailItem('وقت السفر', widget.qiblaData.estimatedTravelInfo),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.bodySmall?.copyWith(
              color: context.textSecondaryColor,
              fontWeight: ThemeConstants.medium,
              fontSize: context.bodySmall?.fontSize?.sp,
            ),
          ),
          Text(
            value,
            style: context.bodyMedium?.copyWith(
              fontSize: context.bodyMedium?.fontSize?.sp,
            ),
          ),
        ],
      ),
    );
  }
}