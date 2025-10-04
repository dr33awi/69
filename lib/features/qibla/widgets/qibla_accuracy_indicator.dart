// lib/features/qibla/widgets/qibla_accuracy_indicator.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';

class QiblaAccuracyIndicator extends StatefulWidget {
  final double accuracy; // Accuracy from 0.0 to 100.0 (percentage)
  final bool isCalibrated;
  final VoidCallback? onCalibrate;

  const QiblaAccuracyIndicator({
    super.key,
    required this.accuracy,
    required this.isCalibrated,
    this.onCalibrate,
  });

  @override
  State<QiblaAccuracyIndicator> createState() => _QiblaAccuracyIndicatorState();
}

class _QiblaAccuracyIndicatorState extends State<QiblaAccuracyIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _previousAccuracy = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ThemeConstants.durationNormal,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.accuracy,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ThemeConstants.curveSmooth,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(QiblaAccuracyIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accuracy != widget.accuracy) {
      _previousAccuracy = oldWidget.accuracy;
      _progressAnimation = Tween<double>(
        begin: _previousAccuracy,
        end: widget.accuracy,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: ThemeConstants.curveSmooth,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 16.r,
      child: Column(
        children: [
          // رأس البطاقة
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getAccuracyColor(widget.accuracy).withOpacity(0.1),
                  _getAccuracyColor(widget.accuracy).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _getAccuracyColor(widget.accuracy).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getAccuracyIcon(widget.accuracy),
                    color: _getAccuracyColor(widget.accuracy),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'دقة البوصلة',
                        style: TextStyle(
                          fontWeight: ThemeConstants.semiBold,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        _getAccuracyDescription(widget.accuracy),
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.isCalibrated && widget.onCalibrate != null)
                  AppButton.outline(
                    text: 'معايرة',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onCalibrate?.call();
                    },
                    size: ButtonSize.small,
                    icon: Icons.compass_calibration,
                    color: ThemeConstants.warning,
                  ),
              ],
            ),
          ),
          
          // مؤشر الدقة
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // شريط التقدم
                SizedBox(
                  height: 120.h,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(double.infinity, 120.h),
                        painter: AccuracyGaugePainter(
                          progress: _progressAnimation.value / 100,
                          color: _getAccuracyColor(_progressAnimation.value),
                          backgroundColor: context.dividerColor.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_progressAnimation.value.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: _getAccuracyColor(_progressAnimation.value),
                                  fontWeight: ThemeConstants.bold,
                                  fontSize: 32.sp,
                                ),
                              ),
                              Text(
                                'الدقة',
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // معلومات إضافية
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: context.dividerColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildStatusRow(
                        context,
                        'المعايرة',
                        widget.isCalibrated ? 'مكتملة' : 'مطلوبة',
                        widget.isCalibrated ? ThemeConstants.success : ThemeConstants.warning,
                      ),
                      SizedBox(height: 8.h),
                      Divider(color: context.dividerColor.withOpacity(0.2)),
                      SizedBox(height: 8.h),
                      _buildStatusRow(
                        context,
                        'التداخل المغناطيسي',
                        _getMagneticInterferenceText(widget.accuracy),
                        _getMagneticInterferenceColor(widget.accuracy),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                // نصائح لتحسين الدقة
                if (widget.accuracy < 70)
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
                          Icons.lightbulb_outline,
                          color: ThemeConstants.info,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نصائح لتحسين الدقة:',
                                style: TextStyle(
                                  fontWeight: ThemeConstants.semiBold,
                                  color: ThemeConstants.info,
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              ..._getTips(widget.accuracy).map((tip) => Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ',
                                      style: TextStyle(
                                        color: context.textSecondaryColor,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: TextStyle(
                                          color: context.textSecondaryColor,
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 12.sp,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: 4.h,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: ThemeConstants.medium,
              fontSize: 11.sp,
            ),
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return ThemeConstants.success;
    if (accuracy >= 50) return ThemeConstants.warning;
    return ThemeConstants.error;
  }

  IconData _getAccuracyIcon(double accuracy) {
    if (accuracy >= 80) return Icons.gps_fixed;
    if (accuracy >= 50) return Icons.gps_not_fixed;
    return Icons.gps_off;
  }

  String _getAccuracyDescription(double accuracy) {
    if (accuracy >= 80) return 'دقة ممتازة';
    if (accuracy >= 60) return 'دقة جيدة';
    if (accuracy >= 40) return 'دقة متوسطة';
    return 'دقة ضعيفة جداً';
  }

  String _getMagneticInterferenceText(double accuracy) {
    if (accuracy >= 70) return 'منخفض';
    if (accuracy >= 40) return 'متوسط';
    return 'عالي';
  }

  Color _getMagneticInterferenceColor(double accuracy) {
    if (accuracy >= 70) return ThemeConstants.success;
    if (accuracy >= 40) return ThemeConstants.warning;
    return ThemeConstants.error;
  }

  List<String> _getTips(double accuracy) {
    final tips = <String>[];
    
    if (accuracy < 70) {
      tips.add('ابتعد عن الأجهزة الإلكترونية والمعادن');
    }
    if (!widget.isCalibrated) {
      tips.add('قم بمعايرة البوصلة بتحريك الجهاز في شكل رقم 8');
    }
    if (accuracy < 50) {
      tips.add('انتقل إلى مكان مفتوح في الهواء الطلق');
      tips.add('تأكد من عدم وجود مغناطيس أو سماعات قريبة');
    }
    
    return tips;
  }
}

// رسام مؤشر الدقة (Gauge)
class AccuracyGaugePainter extends CustomPainter {
  final double progress; // Progress from 0.0 to 1.0
  final Color color;
  final Color backgroundColor;

  AccuracyGaugePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20.h);
    final radius = math.min(size.width / 2, size.height - 40.h);

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.w
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.w
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * progress,
      false,
      progressPaint,
    );
    
    // Indicator (thumb)
    final indicatorAngle = math.pi + (math.pi * progress);
    final indicatorX = center.dx + radius * math.cos(indicatorAngle);
    final indicatorY = center.dy + radius * math.sin(indicatorAngle);
    
    final indicatorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(indicatorX, indicatorY), 10.w, indicatorPaint);
    
    // White border for indicator
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.w;
    
    canvas.drawCircle(Offset(indicatorX, indicatorY), 10.w, borderPaint);
  }

  @override
  bool shouldRepaint(covariant AccuracyGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}