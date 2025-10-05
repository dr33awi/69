// lib/core/infrastructure/firebase/widgets/special_event/modals/event_details_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import 'package:athkar_app/core/infrastructure/firebase/special_event/modals/special_event_model.dart';
import '../utils/time_formatter.dart';

/// مودال عرض تفاصيل المناسبة
class EventDetailsModal extends StatelessWidget {
  final SpecialEventModel event;
  
  const EventDetailsModal({
    super.key,
    required this.event,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // المقبض العلوي
          _buildHandle(context),
          
          // المحتوى القابل للتمرير
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  // رأس المودال
                  _buildHeader(context),
                  
                  SizedBox(height: 20.h),
                  
                  // الوصف
                  _buildDescriptionSection(context),
                  
                  // معلومات التواريخ
                  if (event.startDate != null || event.endDate != null) ...[
                    SizedBox(height: 16.h),
                    _buildDateSection(context),
                  ],
                  
                  SizedBox(height: 24.h),
                  
                  // زر الإغلاق
                  _buildCloseButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// المقبض العلوي
  Widget _buildHandle(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: context.dividerColor,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }
  
  /// رأس المودال
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: event.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          // الأيقونة
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                event.icon,
                style: TextStyle(fontSize: 32.sp),
              ),
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // العنوان
          Text(
            event.title,
            style: context.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: ThemeConstants.bold,
              fontSize: 20.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// قسم الوصف
  Widget _buildDescriptionSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Text(
        event.description,
        style: context.bodyMedium?.copyWith(
          height: 1.5,
          fontSize: 14.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  /// قسم التواريخ
  Widget _buildDateSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: event.gradientColors.first.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: event.gradientColors.first.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          // عنوان القسم
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_rounded,
                size: 16.sp,
                color: event.gradientColors.first,
              ),
              SizedBox(width: 6.w),
              Text(
                'فترة المناسبة',
                style: context.titleSmall?.copyWith(
                  color: event.gradientColors.first,
                  fontWeight: ThemeConstants.semiBold,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // تاريخ البداية
          if (event.startDate != null)
            Text(
              'من: ${TimeFormatter.formatDate(event.startDate!)}',
              style: context.bodySmall?.copyWith(
                color: context.textSecondaryColor,
                fontSize: 12.sp,
              ),
            ),
          
          // تاريخ النهاية
          if (event.endDate != null) ...[
            SizedBox(height: 4.h),
            Text(
              'إلى: ${TimeFormatter.formatDate(event.endDate!)}',
              style: context.bodySmall?.copyWith(
                color: context.textSecondaryColor,
                fontSize: 12.sp,
              ),
            ),
          ],
          
          // الوقت المتبقي
          if (event.remainingTime != null) ...[
            SizedBox(height: 8.h),
            _buildRemainingTimeBadge(context),
          ],
        ],
      ),
    );
  }
  
  /// شارة الوقت المتبقي
  Widget _buildRemainingTimeBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            color: Colors.green,
            size: 14.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            TimeFormatter.formatRemainingTime(event.remainingTime!),
            style: context.labelSmall?.copyWith(
              color: Colors.green,
              fontWeight: ThemeConstants.semiBold,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
  
  /// زر الإغلاق
  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: event.gradientColors.first,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          'إغلاق',
          style: context.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: ThemeConstants.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}