// lib/features/qibla/widgets/compass_calibration_sheet.dart - واجهة محسّنة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../../../app/themes/app_theme.dart';

class CompassCalibrationSheet extends StatefulWidget {
  final VoidCallback onStartCalibration;
  final double initialAccuracy;
  
  const CompassCalibrationSheet({
    super.key,
    required this.onStartCalibration,
    this.initialAccuracy = 0.0,
  });

  @override
  State<CompassCalibrationSheet> createState() => _CompassCalibrationSheetState();
}

class _CompassCalibrationSheetState extends State<CompassCalibrationSheet> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _figure8Animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _figure8Animation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: 0.85.sh,
      ),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.r),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36.w,
              height: 3.h,
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ThemeConstants.primary,
                        ThemeConstants.primaryLight,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FlutterIslamicIcons.solidQibla,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معايرة البوصلة',
                      style: TextStyle(
                        fontWeight: ThemeConstants.bold,
                        fontSize: 17.sp,
                      ),
                    ),
                    Text(
                      'تستغرق 10-15 ثانية فقط',
                      style: TextStyle(
                        color: ThemeConstants.success,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Animated demo
            Container(
              height: 140.h,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ThemeConstants.primary.withOpacity(0.1),
                    ThemeConstants.primaryLight.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: ThemeConstants.primary.withOpacity(0.2),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Figure-8 path
                  CustomPaint(
                    size: Size(180.w, 90.h),
                    painter: Figure8BackgroundPainter(
                      color: ThemeConstants.primary.withOpacity(0.4),
                    ),
                  ),
                  
                  // Animated phone
                  AnimatedBuilder(
                    animation: _figure8Animation,
                    builder: (context, child) {
                      final t = _figure8Animation.value;
                      final x = math.sin(t) * 50.w;
                      final y = math.sin(2 * t) * 30.h;
                      final tilt = math.sin(t) * 0.25;
                      
                      return Transform.translate(
                        offset: Offset(x, y),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateY(tilt)
                            ..rotateZ(tilt * 0.6),
                          child: const PhoneAnimationWidget(),
                        ),
                      );
                    },
                  ),
                  
                  // Instruction overlay
                  Positioned(
                    bottom: 12.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '∞',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'حرك الجهاز في شكل رقم 8',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Quick steps
            _buildQuickSteps(),
            
            SizedBox(height: 20.h),
            
            // Tips
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: ThemeConstants.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: ThemeConstants.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: ThemeConstants.info,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نصائح سريعة:',
                          style: TextStyle(
                            fontWeight: ThemeConstants.semiBold,
                            color: ThemeConstants.info,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '• ابتعد عن المعادن والأجهزة الإلكترونية\n'
                          '• حرك الجهاز ببطء وبشكل سلس\n'
                          '• غط جميع الاتجاهات (شمال، جنوب، شرق، غرب)',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 10.sp,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: BorderSide(color: context.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onStartCalibration();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.primary,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(Icons.play_arrow, size: 20.sp, color: Colors.white),
                    label: Text(
                      'بدء المعايرة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 6.h),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4.w, bottom: 10.h),
          child: Text(
            'خطوات سريعة:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
        
        _buildStepItem(
          number: '1',
          icon: Icons.phone_android,
          text: 'امسك الهاتف بشكل مريح',
          color: ThemeConstants.primary,
        ),
        
        _buildStepItem(
          number: '2',
          icon: Icons.all_inclusive,
          text: 'ارسم شكل ∞ (رقم 8) في الهواء',
          color: ThemeConstants.primary,
        ),
        
        _buildStepItem(
          number: '3',
          icon: Icons.check_circle,
          text: 'انتظر رسالة الإنجاز',
          color: ThemeConstants.success,
          isLast: true,
        ),
      ],
    );
  }
  
  Widget _buildStepItem({
    required String number,
    required IconData icon,
    required String text,
    required Color color,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 30.h,
                margin: EdgeInsets.symmetric(vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withOpacity(0.5),
                      color.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 34.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: context.dividerColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20.sp,
                  color: color,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Phone Widget
class PhoneAnimationWidget extends StatelessWidget {
  const PhoneAnimationWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55.w,
      height: 48.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConstants.primary,
            ThemeConstants.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: ThemeConstants.primary.withOpacity(0.5),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Screen
          Positioned(
            top: 8.h,
            left: 8.w,
            right: 8.w,
            bottom: 8.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Center(
                child: Icon(
                  Icons.explore,
                  color: ThemeConstants.primary,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Figure-8 Painter
class Figure8BackgroundPainter extends CustomPainter {
  final Color color;
  
  Figure8BackgroundPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radiusX = size.width * 0.35;
    final radiusY = size.height * 0.35;
    
    // Draw figure-8
    path.moveTo(centerX - radiusX, centerY);
    
    // Left loop
    path.cubicTo(
      centerX - radiusX, centerY - radiusY,
      centerX - radiusX * 0.2, centerY - radiusY,
      centerX, centerY,
    );
    
    // Right loop
    path.cubicTo(
      centerX + radiusX * 0.2, centerY + radiusY,
      centerX + radiusX, centerY + radiusY,
      centerX + radiusX, centerY,
    );
    
    path.cubicTo(
      centerX + radiusX, centerY - radiusY,
      centerX + radiusX * 0.2, centerY - radiusY,
      centerX, centerY,
    );
    
    // Complete
    path.cubicTo(
      centerX - radiusX * 0.2, centerY + radiusY,
      centerX - radiusX, centerY + radiusY,
      centerX - radiusX, centerY,
    );
    
    canvas.drawPath(path, paint);
    
    // Draw dots along the path for emphasis
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final points = [
      Offset(centerX - radiusX, centerY),
      Offset(centerX, centerY - radiusY),
      Offset(centerX + radiusX, centerY),
      Offset(centerX, centerY + radiusY),
    ];
    
    for (var point in points) {
      canvas.drawCircle(point, 3.r, dotPaint);
    }
  }
  
  @override
  bool shouldRepaint(Figure8BackgroundPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}