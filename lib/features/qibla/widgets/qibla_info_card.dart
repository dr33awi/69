// lib/features/qibla/widgets/qibla_info_card.dart - محسّن
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../../../app/themes/app_theme.dart';
import '../models/qibla_model.dart';

class QiblaInfoCard extends StatefulWidget {
  final QiblaModel qiblaData;
  final double currentDirection;
  final double compassAccuracy; // إضافة دقة البوصلة
  final bool showDetailedInfo;
  final bool enableInteraction;

  const QiblaInfoCard({
    super.key,
    required this.qiblaData,
    required this.currentDirection,
    this.compassAccuracy = 0.8, // قيمة افتراضية
    this.showDetailedInfo = true,
    this.enableInteraction = true,
  });

  @override
  State<QiblaInfoCard> createState() => _QiblaInfoCardState();
}

class _QiblaInfoCardState extends State<QiblaInfoCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _expandController;

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
      borderRadius: 20.r,
      child: Column(
        children: [
          _buildHeader(context),
          _buildBasicInfo(context),
          _buildWarnings(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withOpacity(0.1),
            context.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: _getAccuracyColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: _getAccuracyColor().withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getAccuracyColor().withValues(alpha: 0.15),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: _getAccuracyColor(),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موقعك الحالي',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 10.sp,
                  ),
                ),
                Text(
                  _getLocationName(),
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    fontSize: 14.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getDataStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.w),
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
                height: 50.h,
                color: context.dividerColor.withOpacity(0.5),
                margin: EdgeInsets.symmetric(horizontal: 10.w),
              ),
              Expanded(
                child: _buildInfoTile(
                  context: context,
                  icon: Icons.explore,
                  title: 'الاتجاه الحالي',
                  value: '${widget.currentDirection.toStringAsFixed(1)}°',
                  subtitle: _getDirectionName(widget.currentDirection),
                  color: ThemeConstants.info,
                  onTap: null,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // المسافة إلى الكعبة
          _buildDistanceToKaaba(context),

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
        left: 12.w,
        right: 12.w,
        bottom: 12.h,
      ),
      child: Column(children: warnings),
    );
  }

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
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28.sp),
              SizedBox(height: 6.h),
              Text(
                title,
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 10.sp,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  color: color,
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.textSecondaryColor.withOpacity(0.7),
                  fontSize: 9.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: ThemeConstants.semiBold,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  message,
                  style: TextStyle(
                    color: color.darken(0.1),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  String _getDirectionName(double direction) {
    if (direction >= 337.5 || direction < 22.5) return 'شمال';
    if (direction >= 22.5 && direction < 67.5) return 'شمال شرق';
    if (direction >= 67.5 && direction < 112.5) return 'شرق';
    if (direction >= 112.5 && direction < 157.5) return 'جنوب شرق';
    if (direction >= 157.5 && direction < 202.5) return 'جنوب';
    if (direction >= 202.5 && direction < 247.5) return 'جنوب غرب';
    if (direction >= 247.5 && direction < 292.5) return 'غرب';
    if (direction >= 292.5 && direction < 337.5) return 'شمال غرب';
    return 'غير محدد';
  }

  void _showDirectionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Row(
          children: [
            Icon(Icons.navigation, color: context.primaryColor, size: 20.sp),
            SizedBox(width: 6.w),
            Text('تفاصيل الاتجاه', style: TextStyle(fontSize: 15.sp)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('الاتجاه', '${widget.qiblaData.qiblaDirection.toStringAsFixed(2)}°'),
            _buildDetailItem('الوصف', widget.qiblaData.detailedDirectionDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.textSecondaryColor,
              fontWeight: ThemeConstants.medium,
              fontSize: 10.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  /// المسافة إلى الكعبة
  Widget _buildDistanceToKaaba(BuildContext context) {
    final distance = _calculateDistanceToKaaba();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConstants.accent.withOpacity(0.1),
            ThemeConstants.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ThemeConstants.accent.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: ThemeConstants.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              '🕋',
              style: TextStyle(fontSize: 18.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المسافة إلى الكعبة',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  distance >= 1000 
                      ? '${(distance / 1000).toStringAsFixed(1)} ألف كم'
                      : '${distance.toStringAsFixed(0)} كم',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: ThemeConstants.bold,
                    color: ThemeConstants.accent,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.route,
            color: ThemeConstants.accent.withOpacity(0.5),
            size: 24.sp,
          ),
        ],
      ),
    );
  }

  double _calculateDistanceToKaaba() {
    // إحداثيات الكعبة المشرفة
    const kaabaLat = 21.4225;
    const kaabaLon = 39.8262;
    
    return Geolocator.distanceBetween(
      widget.qiblaData.latitude,
      widget.qiblaData.longitude,
      kaabaLat,
      kaabaLon,
    ) / 1000; // تحويل لكيلومتر
  }
}
