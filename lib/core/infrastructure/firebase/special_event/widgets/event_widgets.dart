// lib/core/infrastructure/firebase/special_event/widgets/event_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import 'package:athkar_app/core/infrastructure/firebase/special_event/modals/special_event_model.dart';
import '../utils/time_formatter.dart';

/// رأس كارد المناسبة مع الأيقونة والعنوان
class EventHeader extends StatelessWidget {
  final SpecialEventModel event;
  
  const EventHeader({
    super.key,
    required this.event,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // حاوي الأيقونة - سيختفي إذا كانت فارغة
        _buildIconContainer(),
        
        // المسافة - تظهر فقط إذا كانت هناك أيقونة
        if (event.icon.isNotEmpty) SizedBox(width: 12.w),
        
        // النص والوقت المتبقي
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(context),
              
              // شارة الوقت المتبقي
              if (event.remainingTime != null)
                EventRemainingBadge(duration: event.remainingTime!),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildIconContainer() {
    // إذا كانت الأيقونة فارغة، لا نعرض شيء
    if (event.icon.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 48.r,
      height: 48.r,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5.w,
        ),
      ),
      child: Center(
        child: Text(
          event.icon,
          style: TextStyle(fontSize: 24.sp),
        ),
      ),
    );
  }
  
  Widget _buildTitle(BuildContext context) {
    return Text(
      event.title,
      style: context.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: ThemeConstants.bold,
        fontSize: 16.sp,
        height: 1.3,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(0, 2.h),
            blurRadius: 4.r,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ==================== وصف المناسبة (معدل لدعم نصوص متعددة) ====================

/// ويدجت عرض وصف المناسبة - يدعم نصوص متعددة
class EventDescription extends StatelessWidget {
  final SpecialEventModel event;
  
  const EventDescription({
    super.key,
    required this.event,
  });
  
  @override
  Widget build(BuildContext context) {
    final lines = event.descriptionLines;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: lines.length > 1 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines.asMap().entries.map((entry) => Padding(
              padding: EdgeInsets.only(
                top: entry.key > 0 ? 4.h : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.trim(),
                      style: context.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          )
        : Text(
            lines.isNotEmpty ? lines.first : '',
            style: context.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.95),
              fontSize: 12.sp,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
    );
  }
}

// ==================== زر الإجراء ====================

/// زر الإجراء مع السهم
class EventActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  
  const EventActionButton({
    super.key,
    required this.text,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1.w,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999.r),
            splashColor: Colors.white.withOpacity(0.3),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 6.h,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: context.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: ThemeConstants.semiBold,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== خلفية الصورة ====================

/// خلفية الصورة مع شفافية
class EventBackground extends StatelessWidget {
  final String imageUrl;
  
  const EventBackground({
    super.key,
    required this.imageUrl,
  });
  
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.15,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('⚠️ [EventBackground] Failed to load image: $error');
            return const SizedBox.shrink();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.white.withOpacity(0.05),
            );
          },
        ),
      ),
    );
  }
}

// ==================== شارة الوقت المتبقي ====================

/// شارة عرض الوقت المتبقي للمناسبة
class EventRemainingBadge extends StatelessWidget {
  final Duration duration;
  
  const EventRemainingBadge({
    super.key,
    required this.duration,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 10.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            TimeFormatter.formatRemainingTime(duration),
            style: context.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 9.sp,
              fontWeight: ThemeConstants.medium,
            ),
          ),
        ],
      ),
    );
  }
}