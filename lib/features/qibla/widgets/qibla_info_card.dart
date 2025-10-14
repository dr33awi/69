// lib/features/qibla/widgets/qibla_info_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/qibla_model.dart';

class QiblaInfoCard extends StatelessWidget {
  final QiblaModel qiblaData;

  const QiblaInfoCard({
    super.key,
    required this.qiblaData,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 18.r,
      child: _buildHeader(context),
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
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: _getAccuracyColor().withOpacity(0.1),
              shape: BoxShape.circle,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocationName() {
    if (qiblaData.cityName != null && qiblaData.countryName != null) {
      return '${qiblaData.cityName}، ${qiblaData.countryName}';
    } else if (qiblaData.cityName != null) {
      return qiblaData.cityName!;
    } else if (qiblaData.countryName != null) {
      return qiblaData.countryName!;
    }
    return 'موقع غير محدد';
  }

  Color _getAccuracyColor() {
    if (qiblaData.hasHighAccuracy) return ThemeConstants.success;
    if (qiblaData.hasMediumAccuracy) return ThemeConstants.warning;
    return ThemeConstants.error;
  }
}