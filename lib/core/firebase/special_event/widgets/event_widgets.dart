// lib/core/infrastructure/firebase/special_event/widgets/event_widgets.dart
// ✅ محدث - دعم GIF

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_theme.dart';
import 'package:athkar_app/core/firebase/special_event/modals/special_event_model.dart';
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
        _buildIconContainer(),
        
        if (event.icon.isNotEmpty) SizedBox(width: 12.w),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(context),
              
              if (event.remainingTime != null)
                EventRemainingBadge(duration: event.remainingTime!),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildIconContainer() {
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

// ==================== خلفية الصورة مع دعم GIF ====================

/// خلفية الصورة مع شفافية ودعم GIF
class EventBackground extends StatelessWidget {
  final String imageUrl;
  final bool isGif;
  
  const EventBackground({
    super.key,
    required this.imageUrl,
    this.isGif = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.15,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          // ✅ تفعيل الحركة للـ GIF
          gaplessPlayback: true,
          // ✅ عدم الحفظ في الكاش للـ GIF للتأكد من الحركة
          cacheWidth: isGif ? null : 800,
          cacheHeight: isGif ? null : 800,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              // ✅ عرض مؤشر للـ GIF
              if (isGif) {
              }
              return child;
            }
            
            // عرض مؤشر التحميل
            return Container(
              color: Colors.white.withOpacity(0.05),
              child: Center(
                child: SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2.w,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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