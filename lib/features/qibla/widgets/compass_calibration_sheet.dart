// lib/features/qibla/widgets/compass_calibration_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      duration: const Duration(seconds: 4),
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
        maxHeight: 0.85.sh, // 85% من ارتفاع الشاشة
      ),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Title with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: ThemeConstants.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.explore_rounded,
                    color: ThemeConstants.warning,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'معايرة البوصلة',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    fontSize: 20.sp,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Warning message
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: ThemeConstants.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: ThemeConstants.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: ThemeConstants.warning,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'البوصلة تحتاج إلى معايرة',
                      style: TextStyle(
                        color: ThemeConstants.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Phone animation with figure-8 motion
            Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Figure-8 background
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
                      final tilt = math.sin(t) * 0.2;
                      
                      return Transform.translate(
                        offset: Offset(x, y),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateY(tilt)
                            ..rotateZ(tilt * 0.5),
                          child: const PhoneAnimationWidget(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Instructions title
            Text(
              'كيفية معايرة البوصلة:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            
            SizedBox(height: 12.h),
            
            // Calibration steps
            _buildCalibrationStep(
              context: context,
              number: '1',
              text: 'ابتعد عن الأجهزة الإلكترونية والمعادن',
              icon: Icons.phone_android_rounded,
            ),
            _buildCalibrationStep(
              context: context,
              number: '2',
              text: 'احمل الهاتف وحركه على شكل رقم 8',
              icon: Icons.gesture,
            ),
            _buildCalibrationStep(
              context: context,
              number: '3',
              text: 'كرر الحركة 3-4 مرات ببطء',
              icon: Icons.loop_rounded,
            ),
            _buildCalibrationStep(
              context: context,
              number: '4',
              text: 'انتظر حتى تستقر القراءات',
              icon: Icons.check_circle_outline,
            ),
            
            SizedBox(height: 24.h),
            
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
                      'إغلاق',
                      style: TextStyle(fontSize: 15.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onStartCalibration();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConstants.primary,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'بدء المعايرة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Safe area for bottom sheet
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8.h),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCalibrationStep({
    required BuildContext context,
    required String number,
    required String text,
    required IconData icon,
  }) {
    final bool isStep2 = number == '2';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.dividerColor.withOpacity(0.5),
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ThemeConstants.primary,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          if (isStep2) ...[
            CustomPaint(
              size: Size(30.w, 15.h),
              painter: SmallFigure8Painter(
                color: ThemeConstants.primary,
              ),
            ),
            SizedBox(width: 8.w),
          ] else ...[
            Icon(
              icon,
              size: 20.sp,
              color: context.textSecondaryColor,
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}

// Shared Phone Widget
class PhoneAnimationWidget extends StatelessWidget {
  const PhoneAnimationWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60.w,
      height: 50.h,
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
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8.h,
            left: 8.w,
            right: 8.w,
            bottom: 8.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore,
                    color: ThemeConstants.primary,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  ...List.generate(3, (index) => Container(
                    width: 3.w,
                    height: (14 - (index * 3)).h,
                    margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primary.withOpacity(
                        0.7 - (index * 0.2),
                      ),
                      borderRadius: BorderRadius.circular(1.5.r),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for drawing figure-8 path
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
    final radiusX = size.width * 0.4;
    final radiusY = size.height * 0.35;
    
    // Draw figure-8 path
    path.moveTo(centerX - radiusX, centerY);
    path.cubicTo(
      centerX - radiusX, centerY - radiusY,
      centerX - radiusX * 0.2, centerY - radiusY,
      centerX, centerY,
    );
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
    path.cubicTo(
      centerX - radiusX * 0.2, centerY + radiusY,
      centerX - radiusX, centerY + radiusY,
      centerX - radiusX, centerY,
    );
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(Figure8BackgroundPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

// Small Figure-8 painter
class SmallFigure8Painter extends CustomPainter {
  final Color color;
  
  SmallFigure8Painter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radiusX = size.width * 0.35;
    final radiusY = size.height * 0.3;
    
    // Draw small figure-8
    path.moveTo(centerX - radiusX, centerY);
    path.cubicTo(
      centerX - radiusX, centerY - radiusY,
      centerX, centerY - radiusY,
      centerX, centerY,
    );
    path.cubicTo(
      centerX, centerY + radiusY,
      centerX + radiusX, centerY + radiusY,
      centerX + radiusX, centerY,
    );
    path.cubicTo(
      centerX + radiusX, centerY - radiusY,
      centerX, centerY - radiusY,
      centerX, centerY,
    );
    path.cubicTo(
      centerX, centerY + radiusY,
      centerX - radiusX, centerY + radiusY,
      centerX - radiusX, centerY,
    );
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(SmallFigure8Painter oldDelegate) {
    return color != oldDelegate.color;
  }
}