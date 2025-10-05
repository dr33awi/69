// lib/core/infrastructure/firebase/widgets/special_event/widgets/event_card_content.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:athkar_app/core/infrastructure/firebase/special_event/modals/special_event_model.dart';
import '../services/event_navigation_handler.dart';
import 'package:athkar_app/core/infrastructure/firebase/special_event/special_event_card.dart';

/// محتوى كارد المناسبة الرئيسي
class EventCardContent extends StatelessWidget {
  final SpecialEventModel event;
  
  const EventCardContent({
    super.key,
    required this.event,
  });
  
  void _handleTap(BuildContext context) {
    HapticFeedback.lightImpact();
    EventNavigationHandler.handle(
      context: context,
      url: event.actionUrl,
      event: event,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: event.gradientColors.map((c) => c.withOpacity(0.95)).toList(),
        ),
        boxShadow: [
          BoxShadow(
            color: event.gradientColors.first.withOpacity(0.3),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleTap(context),
            borderRadius: BorderRadius.circular(20.r),
            splashColor: Colors.white.withOpacity(0.2),
            child: Stack(
              children: [
                // خلفية الصورة
                if (event.backgroundImage.isNotEmpty)
                  EventBackground(imageUrl: event.backgroundImage),
                
                // المحتوى الرئيسي
                Container(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الهيدر
                      EventHeader(event: event),
                      
                      SizedBox(height: 12.h),
                      
                      // الوصف
                      EventDescription(description: event.description),
                      
                      // زر الإجراء
                      if (event.actionText.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        EventActionButton(
                          text: event.actionText,
                          onTap: () => _handleTap(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}