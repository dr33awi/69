// lib/features/qibla/widgets/compass_calibration_sheet.dart - نسخة مصغرة

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
        maxHeight: 0.7.sh, // تصغير من 0.85 إلى 0.7
      ),
      padding: EdgeInsets.all(12.w), // تصغير من 14 إلى 12
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
              margin: EdgeInsets.only(bottom: 8.h), // تصغير من 10 إلى 8
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Title - مدمج ومصغر
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(6.r), // تصغير من 8 إلى 6
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
                    size: 16.sp, // تصغير من 20 إلى 16
                  ),
                ),
                SizedBox(width: 8.w), // تصغير من 10 إلى 8
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معايرة البوصلة',
                      style: TextStyle(
                        fontWeight: ThemeConstants.bold,
                        fontSize: 15.sp, // تصغير من 17 إلى 15
                      ),
                    ),
                    Text(
                      '10-15 ثانية',
                      style: TextStyle(
                        color: ThemeConstants.success,
                        fontSize: 9.sp, // تصغير من 10 إلى 9
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 12.h), // تصغير من 16 إلى 12
            
            // Animated demo - مصغر
            Container(
              height: 110.h, // تصغير من 140 إلى 110
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
                borderRadius: BorderRadius.circular(12.r), // تصغير من 16 إلى 12
                border: Border.all(
                  color: ThemeConstants.primary.withOpacity(0.2),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Figure-8 path
                  CustomPaint(
                    size: Size(140.w, 70.h), // تصغير من 180x90 إلى 140x70
                    painter: Figure8BackgroundPainter(
                      color: ThemeConstants.primary.withOpacity(0.4),
                    ),
                  ),
                  
                  // Animated phone
                  AnimatedBuilder(
                    animation: _figure8Animation,
                    builder: (context, child) {
                      final t = _figure8Animation.value;
                      final x = math.sin(t) * 40.w; // تصغير من 50 إلى 40
                      final y = math.sin(2 * t) * 24.h; // تصغير من 30 إلى 24
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
                  

                ],
              ),
            ),
            
            SizedBox(height: 12.h), // تصغير من 20 إلى 12
            
            // Quick steps - مصغر
            _buildQuickSteps(),
            
            SizedBox(height: 10.h), // تصغير من 20 إلى 10
            
            // Tips - مصغر ومختصر
            Container(
              padding: EdgeInsets.all(10.w), // تصغير من 12 إلى 10
              decoration: BoxDecoration(
                color: ThemeConstants.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r), // تصغير من 12 إلى 10
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
                    size: 16.sp, // تصغير من 20 إلى 16
                  ),
                  SizedBox(width: 6.w), // تصغير من 8 إلى 6
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نصائح:',
                          style: TextStyle(
                            fontWeight: ThemeConstants.semiBold,
                            color: ThemeConstants.info,
                            fontSize: 11.sp, // تصغير من 12 إلى 11
                          ),
                        ),
                        SizedBox(height: 2.h), // تصغير من 4 إلى 2
                        Text(
                          '• ابتعد عن المعادن\n'
                          '• حرك الجهاز ببطء',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 9.sp, // تصغير من 10 إلى 9
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12.h), // تصغير من 20 إلى 12
            
            // Action buttons - مصغر
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.h), // تصغير من 12 إلى 10
                      side: BorderSide(color: context.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r), // تصغير من 12 إلى 10
                      ),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(fontSize: 12.sp), // تصغير من 13 إلى 12
                    ),
                  ),
                ),
                SizedBox(width: 10.w), // تصغير من 12 إلى 10
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
                      padding: EdgeInsets.symmetric(vertical: 10.h), // تصغير من 12 إلى 10
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r), // تصغير من 12 إلى 10
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(Icons.play_arrow, size: 18.sp, color: Colors.white), // تصغير من 20 إلى 18
                    label: Text(
                      'بدء المعايرة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp, // تصغير من 14 إلى 13
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 4.h), // تصغير من 6 إلى 4
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
          padding: EdgeInsets.only(right: 4.w, bottom: 8.h), // تصغير من 10 إلى 8
          child: Text(
            'خطوات سريعة:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.sp, // تصغير من 14 إلى 12
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
          text: 'ارسم شكل ∞ في الهواء',
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
              width: 28.r, // تصغير من 32 إلى 28
              height: 28.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 3.r, // تصغير من 4 إلى 3
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
                    fontSize: 12.sp, // تصغير من 14 إلى 12
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 24.h, // تصغير من 30 إلى 24
                margin: EdgeInsets.symmetric(vertical: 3.h), // تصغير من 4 إلى 3
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
        SizedBox(width: 10.w), // تصغير من 12 إلى 10
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 27.h), // تصغير من 34 إلى 27
            padding: EdgeInsets.all(10.w), // تصغير من 12 إلى 10
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(8.r), // تصغير من 10 إلى 8
              border: Border.all(
                color: context.dividerColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16.sp, // تصغير من 20 إلى 16
                  color: color,
                ),
                SizedBox(width: 8.w), // تصغير من 10 إلى 8
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 11.sp, // تصغير من 12 إلى 11
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

// Phone Widget - مصغر
class PhoneAnimationWidget extends StatelessWidget {
  const PhoneAnimationWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45.w, // تصغير من 55 إلى 45
      height: 40.h, // تصغير من 48 إلى 40
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConstants.primary,
            ThemeConstants.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(6.r), // تصغير من 8 إلى 6
        boxShadow: [
          BoxShadow(
            color: ThemeConstants.primary.withOpacity(0.5),
            blurRadius: 10.r, // تصغير من 12 إلى 10
            offset: Offset(0, 4.h), // تصغير من 6 إلى 4
          ),
        ],
      ),
      child: Stack(
        children: [
          // Screen
          Positioned(
            top: 6.h, // تصغير من 8 إلى 6
            left: 6.w,
            right: 6.w,
            bottom: 6.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3.r), // تصغير من 4 إلى 3
              ),
              child: Center(
                child: Icon(
                  Icons.explore,
                  color: ThemeConstants.primary,
                  size: 16.sp, // تصغير من 20 إلى 16
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
      ..strokeWidth = 2.5 // تصغير من 3.0 إلى 2.5
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
      canvas.drawCircle(point, 2.5.r, dotPaint); // تصغير من 3 إلى 2.5
    }
  }
  
  @override
  bool shouldRepaint(Figure8BackgroundPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}