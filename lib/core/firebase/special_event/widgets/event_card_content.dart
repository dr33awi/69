// lib/core/infrastructure/firebase/special_event/widgets/event_card_content.dart
// ✅ محدث - تمرير حقل isGif للخلفية

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
      debugPrint('ℹ️ [EventCard] No action URL - ignoring tap');
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
          child: isInteractive 
            ? InkWell(
                onTap: () => _handleTap(context),
                borderRadius: BorderRadius.circular(20.r),
                splashColor: Colors.white.withOpacity(0.2),
                child: _buildContent(context),
              )
            : _buildContent(context),
        ),
      ),
    );
  }
  
  /// بناء المحتوى الداخلي
  Widget _buildContent(BuildContext context) {
    final hasDescription = event.descriptionLines.isNotEmpty && 
                           event.descriptionLines.any((line) => line.trim().isNotEmpty);
    
    return Stack(
      children: [
        // ✅ خلفية الصورة مع دعم GIF
        if (event.backgroundImage.isNotEmpty)
          EventBackground(
            imageUrl: event.backgroundImage,
            isGif: event.isGif, // ✅ تمرير حقل isGif
          ),
        
        // المحتوى الرئيسي
        Container(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventHeader(event: event),
              
              if (hasDescription) ...[
                SizedBox(height: 12.h),
                EventDescription(event: event),
              ],
              
              if (event.actionText.isNotEmpty && event.actionUrl.isNotEmpty) ...[
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
    );
  }
}