// lib/features/tasbih/widgets/tasbih_main_area.dart
import 'package:athkar_app/features/tasbih/models/dhikr_model.dart';
import 'package:athkar_app/features/tasbih/services/tasbih_service.dart';
import 'package:athkar_app/features/tasbih/widgets/tasbih_bead_widget.dart';
import 'package:athkar_app/features/tasbih/widgets/tasbih_counter_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../app/themes/app_theme.dart';


class TasbihMainArea extends StatelessWidget {
  final DhikrItem currentDhikr;
  final VoidCallback onIncrement;

  const TasbihMainArea({
    super.key,
    required this.currentDhikr,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TasbihService>(
      builder: (context, service, _) {
        final progress = (service.count % currentDhikr.recommendedCount) / 
                        currentDhikr.recommendedCount;
        
        return Container(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // الحلقة الخارجية (التقدم الحالي)
                          SizedBox(
                            width: size * 0.9,
                            height: size * 0.9,
                            child: TasbihCounterRing(
                              progress: progress,
                              gradient: currentDhikr.gradient,
                              strokeWidth: 6.w,
                            ),
                          ),
                          
                          // الحلقة الداخلية (الإجمالي)
                          SizedBox(
                            width: size * 0.75,
                            height: size * 0.75,
                            child: TasbihCounterRing(
                              progress: service.count / 1000,
                              gradient: [
                                context.textSecondaryColor.withOpacity(0.2),
                                context.textSecondaryColor.withOpacity(0.1),
                              ],
                              strokeWidth: 3.w,
                            ),
                          ),
                          
                          // الزر الرئيسي
                          GestureDetector(
                            onTap: onIncrement,
                            child: TasbihBeadWidget(
                              size: size * 0.6,
                              gradient: currentDhikr.gradient,
                              isPressed: false,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${service.count}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: ThemeConstants.bold,
                                      fontSize: 32.sp,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: Offset(0, 2.h),
                                          blurRadius: 4.r,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    'اضغط للتسبيح',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              
              SizedBox(height: 20.h),
              
              _buildProgressInfo(context, service),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressInfo(BuildContext context, TasbihService service) {
    final currentRound = service.count % currentDhikr.recommendedCount;
    final completedRounds = service.count ~/ currentDhikr.recommendedCount;
    
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildInfoItem(
              context,
              'الجولة الحالية',
              '$currentRound / ${currentDhikr.recommendedCount}',
              FlutterIslamicIcons.solidTasbihHand,
              currentDhikr.primaryColor,
            ),
          ),
          
          Container(
            width: 1.w,
            height: 32.h,
            color: context.dividerColor,
          ),
          
          Expanded(
            child: _buildInfoItem(
              context,
              'الجولات',
              '$completedRounds',
              Icons.check_circle,
              ThemeConstants.success,
            ),
          ),
          
          Container(
            width: 1.w,
            height: 32.h,
            color: context.dividerColor,
          ),
          
          Expanded(
            child: _buildInfoItem(
              context,
              'اليوم',
              '${service.todayCount}',
              Icons.star,
              ThemeConstants.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 20.sp,
        ),
        SizedBox(height: 3.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: ThemeConstants.bold,
              fontSize: 13.sp,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 9.sp,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}