// lib/features/qibla/widgets/qibla_info_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/qibla_model.dart';

class QiblaInfoCard extends StatelessWidget {
  final QiblaModel qiblaData;
  final double currentDirection;

  const QiblaInfoCard({
    super.key,
    required this.qiblaData,
    this.currentDirection = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 18.r,
      child: Column(
        children: [
          _buildHeader(context),
          Divider(height: 1.h, color: context.dividerColor.withOpacity(0.3)),
          _buildInfoGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withOpacity(0.1),
            context.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: context.primaryColor,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,children: [
                Text(
                  'موقعك الحالي',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _getLocationName(),
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    fontSize: 15.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(14.w),
      child: Column(
        children: [
          // الصف الوحيد - اتجاه القبلة والاتجاه الحالي
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context: context,
                  icon: Icons.explore,
                  iconColor: ThemeConstants.primary,
                  label: 'اتجاه القبلة',
                  value: qiblaData.detailedDirectionDescription,
                  iconBackground: ThemeConstants.primary.withOpacity(0.1),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildInfoItem(
                  context: context,
                  icon: Icons.navigation,
                  iconColor: ThemeConstants.success,
                  label: 'الاتجاه الحالي',
                  value: '${currentDirection.toStringAsFixed(1)}°',
                  iconBackground: ThemeConstants.success.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
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
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  size: 16.sp,
                  color: iconColor,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 10.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontWeight: ThemeConstants.bold,
              fontSize: 13.sp,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
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
}