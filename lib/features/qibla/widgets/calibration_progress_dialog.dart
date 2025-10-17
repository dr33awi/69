// lib/features/qibla/widgets/calibration_progress_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../../app/themes/app_theme.dart';
import '../services/qibla_service.dart';

/// Dialog لعرض تقدم معايرة البوصلة
class CalibrationProgressDialog extends StatefulWidget {
  final QiblaService qiblaService;
  
  const CalibrationProgressDialog({
    super.key,
    required this.qiblaService,
  });
  
  @override
  State<CalibrationProgressDialog> createState() => _CalibrationProgressDialogState();
}

class _CalibrationProgressDialogState extends State<CalibrationProgressDialog>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _figure8Animation;
  bool _hasCompleted = false;
  
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
    return ChangeNotifierProvider.value(
      value: widget.qiblaService,
      child: Consumer<QiblaService>(
        builder: (context, service, child) {
          // إغلاق تلقائي عند اكتمال المعايرة
          if (service.calibrationProgress >= 100 && 
              !service.isCalibrating && 
              !_hasCompleted) {
            
            _hasCompleted = true;
            
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          }
          
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            contentPadding: EdgeInsets.all(20.w),
            title: _buildTitle(service),
            content: _buildContent(service),
            actions: _buildActions(service),
          );
        },
      ),
    );
  }
  
  /// بناء العنوان
  Widget _buildTitle(QiblaService service) {
    final isCompleted = service.calibrationProgress >= 100;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isCompleted ? Icons.check_circle_outline : Icons.compass_calibration,
          color: isCompleted ? ThemeConstants.success : ThemeConstants.primary,
          size: 22.sp,
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            isCompleted ? 'اكتملت المعايرة!' : 'جاري المعايرة...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: ThemeConstants.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  /// بناء المحتوى
  Widget _buildContent(QiblaService service) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // أنيميشن Figure-8
        _buildFigure8Animation(service),
        
        SizedBox(height: 16.h),
        
        // رسالة التقدم
        _buildProgressMessage(service),
        
        SizedBox(height: 12.h),
        
        // شريط التقدم
        _buildProgressBar(service),
      ],
    );
  }
  
  /// بناء أنيميشن Figure-8
  Widget _buildFigure8Animation(QiblaService service) {
    final isCompleted = service.calibrationProgress >= 100;
    
    return Container(
      height: 160.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? [
                  ThemeConstants.success.withOpacity(0.1),
                  ThemeConstants.success.withOpacity(0.05),
                ]
              : [
                  ThemeConstants.primary.withOpacity(0.1),
                  ThemeConstants.primaryLight.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isCompleted
              ? ThemeConstants.success.withOpacity(0.3)
              : ThemeConstants.primary.withOpacity(0.2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Figure-8 path في الخلفية
          if (!isCompleted)
            CustomPaint(
              size: Size(180.w, 90.h),
              painter: Figure8PathPainter(
                color: ThemeConstants.primary.withOpacity(0.4),
              ),
            ),
          
          // الهاتف المتحرك أو أيقونة النجاح
          if (isCompleted)
            _buildSuccessIcon()
          else
            _buildMovingPhone(),
        ],
      ),
    );
  }
  
  /// بناء الهاتف المتحرك
  Widget _buildMovingPhone() {
    return AnimatedBuilder(
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
            child: _PhoneWidget(),
          ),
        );
      },
    );
  }
  
  /// بناء أيقونة النجاح
  Widget _buildSuccessIcon() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: ThemeConstants.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 60.sp,
              color: ThemeConstants.success,
            ),
          ),
        );
      },
    );
  }
  
  /// بناء رسالة التقدم
  Widget _buildProgressMessage(QiblaService service) {
    final isCompleted = service.calibrationProgress >= 100;
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(service.calibrationMessage),
        children: [
          Text(
            service.calibrationMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isCompleted ? ThemeConstants.bold : ThemeConstants.medium,
              color: isCompleted ? ThemeConstants.success : context.textPrimaryColor,
              fontSize: 13.sp,
            ),
          ),
          if (!isCompleted) ...[
            SizedBox(height: 6.h),
            Text(
              'حرك الجهاز في شكل ∞',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// بناء شريط التقدم
  Widget _buildProgressBar(QiblaService service) {
    final isCompleted = service.calibrationProgress >= 100;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${service.calibrationProgress.toInt()}%',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: isCompleted ? ThemeConstants.success : ThemeConstants.primary,
              ),
            ),
            Text(
              isCompleted ? 'مكتمل' : 'قيد التنفيذ',
              style: TextStyle(
                fontSize: 10.sp,
                color: context.textSecondaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: service.calibrationProgress / 100,
            backgroundColor: context.dividerColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? ThemeConstants.success : ThemeConstants.primary,
            ),
            minHeight: 6.h,
          ),
        ),
      ],
    );
  }
  
  /// بناء أزرار الإجراءات
  List<Widget> _buildActions(QiblaService service) {
    final isCompleted = service.calibrationProgress >= 100;
    
    if (service.isCalibrating) {
      return [
        TextButton(
          onPressed: () {
            service.resetCalibration();
            Navigator.of(context).pop();
          },
          child: Text(
            'إلغاء',
            style: TextStyle(fontSize: 13.sp),
          ),
        ),
      ];
    }
    
    if (!service.isCalibrating && isCompleted) {
      return [
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.check, size: 16.sp),
          label: Text(
            'تم',
            style: TextStyle(fontSize: 13.sp),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeConstants.success,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
      ];
    }
    
    return [];
  }
}

/// Widget الهاتف
class _PhoneWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 44.h,
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
          // الشاشة
          Positioned(
            top: 7.h,
            left: 7.w,
            right: 7.w,
            bottom: 7.h,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Center(
                child: Icon(
                  Icons.explore,
                  color: ThemeConstants.primary,
                  size: 18.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter لرسم مسار Figure-8
class Figure8PathPainter extends CustomPainter {
  final Color color;
  
  Figure8PathPainter({required this.color});
  
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
    
    // رسم شكل Figure-8
    path.moveTo(centerX - radiusX, centerY);
    
    // الحلقة اليسرى
    path.cubicTo(
      centerX - radiusX, centerY - radiusY,
      centerX - radiusX * 0.2, centerY - radiusY,
      centerX, centerY,
    );
    
    // الحلقة اليمنى
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
    
    // إكمال الشكل
    path.cubicTo(
      centerX - radiusX * 0.2, centerY + radiusY,
      centerX - radiusX, centerY + radiusY,
      centerX - radiusX, centerY,
    );
    
    canvas.drawPath(path, paint);
    
    // رسم نقاط عند الاتجاهات الرئيسية
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
  bool shouldRepaint(Figure8PathPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

/// دالة مساعدة لعرض الـ Dialog
void showCalibrationProgressDialog({
  required BuildContext context,
  required QiblaService qiblaService,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => CalibrationProgressDialog(
      qiblaService: qiblaService,
    ),
  ).then((_) {
    if (qiblaService.isCalibrated) {
      // عرض رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            qiblaService.calibrationMessage,
            style: TextStyle(fontSize: 12.sp),
          ),
          backgroundColor: ThemeConstants.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  });
}