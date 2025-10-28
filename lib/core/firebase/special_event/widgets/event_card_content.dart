// lib/core/firebase/special_event/widgets/event_card_content.dart
// ✅ محدث - نفس تصميم كارد "الأقسام الرئيسية"

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:athkar_app/core/firebase/special_event/modals/special_event_model.dart';
import '../services/event_navigation_handler.dart';
import 'event_widgets.dart';

/// محتوى كارد المناسبة الرئيسي
class EventCardContent extends StatelessWidget {
  final SpecialEventModel event;
  
  const EventCardContent({
    super.key,
    required this.event,
  });
  
  void _handleTap(BuildContext context) {
    if (event.actionUrl.isEmpty) {
      return;
    }
    
    HapticFeedback.lightImpact();
    EventNavigationHandler.handle(
      context: context,
      url: event.actionUrl,
      event: event,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isInteractive = event.actionUrl.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ✅ نفس تصميم كارد "الأقسام الرئيسية"
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: event.gradientColors.map((c) => c.withOpacity(0.95)).toList(),
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: event.gradientColors.first.withOpacity(isDark ? 0.3 : 0.25),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.08 : 0.03),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: isInteractive 
          ? InkWell(
              onTap: () => _handleTap(context),
              borderRadius: BorderRadius.circular(20.r),
              splashColor: Colors.white.withOpacity(0.2),
              child: _buildContent(context),
            )
          : _buildContent(context),
      ),
    );
  }
  
  /// بناء المحتوى الداخلي
  Widget _buildContent(BuildContext context) {
    final hasDescription = event.descriptionLines.isNotEmpty && 
                           event.descriptionLines.any((line) => line.trim().isNotEmpty);
    final hasTitle = event.title.isNotEmpty;
    final hasIcon = event.icon.isNotEmpty;
    
    return Stack(
      children: [
        // ✅ خلفية الصورة مع دعم GIF (خفيفة جداً في الخلفية)
        if (event.backgroundImage.isNotEmpty)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Opacity(
                opacity: 0.08,
                child: EventBackground(
                  imageUrl: event.backgroundImage,
                  isGif: event.isGif,
                ),
              ),
            ),
          ),
        
        // ✅ المحتوى الرئيسي - بدون شريط جانبي
        Row(
          children: [
            // الأيقونة (إذا كانت موجودة)
            if (hasIcon)
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.15),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Text(
                  event.icon,
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
            
            if (hasIcon)
              SizedBox(width: 10.w),
            
            // النص (العنوان والوصف)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // العنوان
                  if (hasTitle)
                    Text(
                      event.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14.sp,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: Offset(0, 1.h),
                            blurRadius: 2.r,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  // الوصف (سطر واحد)
                  if (hasDescription)
                    Text(
                      event.descriptionLines.first,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10.sp,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: Offset(0, 1.h),
                            blurRadius: 2.r,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            
            // ✅ زر أو نص الإجراء (action_text)
            if (event.actionText.isNotEmpty && event.actionUrl.isNotEmpty)
              Container(
                margin: EdgeInsets.only(left: 8.w),
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.actionText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: Offset(0, 1.h),
                            blurRadius: 2.r,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 10.sp,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}