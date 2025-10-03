// lib/features/qibla/widgets/compass_calibration_sheet.dart - نسخة كاملة محسّنة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../app/themes/app_theme.dart';
import '../services/qibla_service.dart';

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
    final accuracyPercentage = (widget.initialAccuracy * 100).clamp(0, 100).toInt();
    final accuracyColor = _getAccuracyColor(accuracyPercentage);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8, // تحديد ارتفاع أقصى
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 16.h,
      ),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 12.h), // تقليل المسافة
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
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ThemeConstants.warning.withValues(alpha: 0.1),
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
                style: context.titleLarge?.copyWith(
                  fontWeight: ThemeConstants.bold,
                  fontSize: context.titleLarge?.fontSize?.sp,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h), // تقليل المسافة
          
          // Warning message
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w), // تقليل الحشو
            decoration: BoxDecoration(
              color: ThemeConstants.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: ThemeConstants.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: ThemeConstants.warning,
                  size: 20.sp, // تقليل حجم الأيقونة
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'البوصلة تحتاج إلى معايرة',
                    style: context.bodyLarge?.copyWith(
                      color: ThemeConstants.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp, // تحديد حجم نص صغير
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12.h), // تقليل المسافة
          
          // Accuracy indicator
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'دقة البوصلة:',
                      style: context.bodyLarge?.copyWith(
                        fontSize: context.bodyLarge?.fontSize?.sp,
                      ),
                    ),
                    Text(
                      '$accuracyPercentage%',
                      style: context.titleMedium?.copyWith(
                        color: accuracyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: context.titleMedium?.fontSize?.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                LinearProgressIndicator(
                  value: accuracyPercentage / 100,
                  backgroundColor: context.dividerColor.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
                  minHeight: 8.h,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20.h),
          
          // Phone animation with figure-8 motion
          Container(
            height: 120.h, // تقليل الارتفاع
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Figure-8 background
                CustomPaint(
                  size: Size(240.w, 100.h),
                  painter: Figure8BackgroundPainter(
                    color: ThemeConstants.primary.withValues(alpha: 0.4),
                  ),
                ),
                // Animated phone
                AnimatedBuilder(
                  animation: _figure8Animation,
                  builder: (context, child) {
                    final t = _figure8Animation.value;
                    final x = math.sin(t) * 75.w;
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
            style: context.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: context.titleMedium?.fontSize?.sp,
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
            text: 'انتظر حتى تستقر القراءات (15-20 ثانية)',
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
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                    ),
                    side: BorderSide(
                      color: context.dividerColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'إغلاق',
                    style: context.bodyLarge?.copyWith(
                      fontSize: context.bodyLarge?.fontSize?.sp,
                    ),
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
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                    ),
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
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
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
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: context.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeConstants.primary,
                  fontSize: context.bodyMedium?.fontSize?.sp,
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
              style: context.bodyMedium?.copyWith(
                fontSize: context.bodyMedium?.fontSize?.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getAccuracyColor(int percentage) {
    if (percentage >= 80) return ThemeConstants.success;
    if (percentage >= 50) return ThemeConstants.warning;
    return ThemeConstants.error;
  }
}

// Shared Phone Widget
class PhoneAnimationWidget extends StatelessWidget {
  const PhoneAnimationWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90.w,
      height: 55.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConstants.primary,
            ThemeConstants.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: ThemeConstants.primary.withValues(alpha: 0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 7.h,
            left: 12.w,
            right: 12.w,
            bottom: 7.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore,
                    color: ThemeConstants.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  ...List.generate(3, (index) => Container(
                    width: 3.w,
                    height: (14 - (index * 2)).h,
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primary.withValues(
                        alpha: 0.7 - (index * 0.2),
                      ),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  )),
                ],
              ),
            ),
          ),
          Positioned(
            top: 2.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 5.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            right: 4.w,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 4.w,
                height: 22.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
          ),
          Positioned(
            left: 4.w,
            top: 14.h,
            child: Container(
              width: 3.w,
              height: 10.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Positioned(
            left: 4.w,
            bottom: 14.h,
            child: Container(
              width: 3.w,
              height: 10.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
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
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radiusX = size.width * 0.42;
    final radiusY = size.height * 0.4;
    
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
    
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
    
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final x = centerX + math.sin(angle) * radiusX * 0.95;
      final y = centerY + math.sin(2 * angle) * radiusY * 0.95;
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
    
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final leftArrowPath = Path();
    leftArrowPath.moveTo(centerX - radiusX * 0.65, centerY - 8);
    leftArrowPath.lineTo(centerX - radiusX * 0.75, centerY);
    leftArrowPath.lineTo(centerX - radiusX * 0.65, centerY + 8);
    canvas.drawPath(leftArrowPath, arrowPaint);
    
    final rightArrowPath = Path();
    rightArrowPath.moveTo(centerX + radiusX * 0.65, centerY - 8);
    rightArrowPath.lineTo(centerX + radiusX * 0.75, centerY);
    rightArrowPath.lineTo(centerX + radiusX * 0.65, centerY + 8);
    canvas.drawPath(rightArrowPath, arrowPaint);
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
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radiusX = size.width * 0.4;
    final radiusY = size.height * 0.35;
    
    path.moveTo(centerX - radiusX, centerY);
    
    path.cubicTo(
      centerX - radiusX, centerY - radiusY,
      centerX - radiusX * 0.3, centerY - radiusY,
      centerX, centerY,
    );
    
    path.cubicTo(
      centerX + radiusX * 0.3, centerY + radiusY,
      centerX + radiusX, centerY + radiusY,
      centerX + radiusX, centerY,
    );
    
    path.cubicTo(
      centerX + radiusX, centerY - radiusY,
      centerX + radiusX * 0.3, centerY - radiusY,
      centerX, centerY,
    );
    
    path.cubicTo(
      centerX - radiusX * 0.3, centerY + radiusY,
      centerX - radiusX, centerY + radiusY,
      centerX - radiusX, centerY,
    );
    
    canvas.drawPath(path, paint);
    
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(centerX - radiusX * 0.5, centerY), 1, dotPaint);
    canvas.drawCircle(Offset(centerX + radiusX * 0.5, centerY), 1, dotPaint);
    canvas.drawCircle(Offset(centerX, centerY), 1.5, dotPaint);
  }
  
  @override
  bool shouldRepaint(SmallFigure8Painter oldDelegate) {
    return color != oldDelegate.color;
  }
}

// Calibration Progress Dialog
class CalibrationProgressDialog extends StatefulWidget {
  final VoidCallback onStartCalibration;
  
  const CalibrationProgressDialog({
    super.key,
    required this.onStartCalibration,
  });
  
  @override
  State<CalibrationProgressDialog> createState() => _CalibrationProgressDialogState();
}

class _CalibrationProgressDialogState extends State<CalibrationProgressDialog>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _figure8Animation;
  bool _hasStartedCalibration = false;
  bool _hasCompleted = false;
  
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
    
    widget.onStartCalibration();
    _hasStartedCalibration = true;
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<QiblaService>(
      builder: (context, qiblaService, child) {
        if (qiblaService.calibrationProgress >= 100 && 
            !qiblaService.isCalibrating && 
            _hasStartedCalibration &&
            !_hasCompleted) {
          
          _hasCompleted = true;
          
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
        
        return WillPopScope(
          onWillPop: () async => !qiblaService.isCalibrating,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  qiblaService.calibrationProgress >= 100
                      ? Icons.check_circle_outline
                      : Icons.compass_calibration,
                  color: qiblaService.calibrationProgress >= 100
                      ? ThemeConstants.success
                      : ThemeConstants.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  qiblaService.calibrationProgress >= 100
                      ? 'اكتملت المعايرة!'
                      : 'جاري المعايرة...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 150.h,
                  width: 280.w,
                  decoration: BoxDecoration(
                    color: context.cardColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(240.w, 100.h),
                        painter: Figure8BackgroundPainter(
                          color: qiblaService.calibrationProgress >= 100
                              ? ThemeConstants.success.withValues(alpha: 0.4)
                              : ThemeConstants.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      if (qiblaService.isCalibrating)
                        AnimatedBuilder(
                          animation: _figure8Animation,
                          builder: (context, child) {
                            final t = _figure8Animation.value;
                            final x = math.sin(t) * 75.w;
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
                        )
                      else
                        const PhoneAnimationWidget(),
                    ],
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    qiblaService.calibrationMessage,
                    key: ValueKey(qiblaService.calibrationMessage),
                    textAlign: TextAlign.center,
                    style: context.bodyLarge?.copyWith(
                      fontWeight: qiblaService.calibrationProgress >= 100
                          ? ThemeConstants.bold
                          : ThemeConstants.medium,
                      color: qiblaService.calibrationProgress >= 100
                          ? ThemeConstants.success
                          : context.textPrimaryColor,
                      fontSize: context.bodyLarge?.fontSize?.sp,
                    ),
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                if (qiblaService.calibrationProgress >= 100)
                  Icon(
                    Icons.check_circle,
                    color: ThemeConstants.success,
                    size: 32.sp,
                  ),
              ],
            ),
            actions: [
              if (qiblaService.isCalibrating)
                TextButton(
                  onPressed: () {
                    qiblaService.resetCalibration();
                    Navigator.of(context).pop();
                  },
                  child: const Text('إلغاء'),
                ),
              
              if (!qiblaService.isCalibrating && qiblaService.calibrationProgress >= 100)
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('تم'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.success,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Helper function
void showCompassCalibrationSheet({
  required BuildContext context,
  required VoidCallback onStartCalibration,
  double initialAccuracy = 0.0,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CompassCalibrationSheet(
      onStartCalibration: onStartCalibration,
      initialAccuracy: initialAccuracy,
    ),
  );
}