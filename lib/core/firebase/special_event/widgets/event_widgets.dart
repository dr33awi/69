// lib/core/firebase/special_event/widgets/event_widgets.dart
// ✅ محدث - دعم GIF ودعم العنوان الفارغ

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
    // ✅ إخفاء الهيدر كاملاً إذا لم يكن هناك أيقونة ولا عنوان
    if (event.icon.isEmpty && event.title.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Row(
      children: [
        if (event.icon.isNotEmpty)
          _buildIconContainer(),
        
        if (event.icon.isNotEmpty && event.title.isNotEmpty) 
          SizedBox(width: 12.w),
        
        // ✅ عرض العنوان فقط إذا كان موجوداً
        if (event.title.isNotEmpty)
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
        
        // ✅ إذا كان فقط الأيقونة موجودة وهناك وقت متبقي
        if (event.icon.isNotEmpty && event.title.isEmpty && event.remainingTime != null)
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: EventRemainingBadge(duration: event.remainingTime!),
            ),
          ),
      ],
    );
  }
  
  Widget _buildIconContainer() {
    return Container(
      width: 54.r,
      height: 54.r,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2.w,
        ),
        // ✅ ظلال متعددة الطبقات
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12.r,
            spreadRadius: 0,
            offset: Offset(0, 4.h),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6.r,
            spreadRadius: 0,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Center(
        child: Text(
          event.icon,
          style: TextStyle(fontSize: 26.sp),
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
        fontSize: 17.sp,
        height: 1.3,
        letterSpacing: 0.2,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(0, 2.h),
            blurRadius: 6.r,
          ),
          Shadow(
            color: Colors.black.withOpacity(0.15),
            offset: Offset(0, 1.h),
            blurRadius: 3.r,
          ),
        ],
      ),
      maxLines: 2, // ✅ زيادة عدد الأسطر
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
        horizontal: 14.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5.w,
        ),
        // ✅ ظلال للعمق
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            spreadRadius: 0,
            offset: Offset(0, 2.h),
          ),
        ],
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
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.trim(),
                      style: context.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.97),
                        fontSize: 13.sp,
                        height: 1.5,
                        letterSpacing: 0.1,
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
              color: Colors.white.withOpacity(0.97),
              fontSize: 13.sp,
              height: 1.5,
              letterSpacing: 0.1,
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
          color: Colors.white.withOpacity(0.28),
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1.5.w,
          ),
          // ✅ ظلال للزر
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10.r,
              spreadRadius: 0,
              offset: Offset(0, 3.h),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5.r,
              spreadRadius: 0,
              offset: Offset(0, 1.h),
            ),
          ],
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
                horizontal: 16.w,
                vertical: 8.h,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: context.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: ThemeConstants.semiBold,
                      fontSize: 13.sp,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16.sp,
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
      margin: EdgeInsets.only(top: 5.h),
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.w,
        ),
        // ✅ ظلال خفيفة
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6.r,
            spreadRadius: 0,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            color: Colors.white.withOpacity(0.95),
            size: 11.sp,
          ),
          SizedBox(width: 5.w),
          Text(
            TimeFormatter.formatRemainingTime(duration),
            style: context.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.95),
              fontSize: 10.sp,
              fontWeight: ThemeConstants.medium,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}