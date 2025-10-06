// lib/features/onboarding/widgets/success_celebration_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget احتفالي عند إتمام جميع الأذونات
class SuccessCelebrationWidget extends StatefulWidget {
  final VoidCallback? onComplete;

  const SuccessCelebrationWidget({
    super.key,
    this.onComplete,
  });

  @override
  State<SuccessCelebrationWidget> createState() => _SuccessCelebrationWidgetState();
}

class _SuccessCelebrationWidgetState extends State<SuccessCelebrationWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late AnimationController _rotationController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<Confetti> _confettiList = [];

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeIn,
    ));
    
    _initConfetti();
    _startAnimation();
    
    HapticFeedback.heavyImpact();
  }

  void _initConfetti() {
    final random = math.Random();
    for (int i = 0; i < 40; i++) {
      _confettiList.add(
        Confetti(
          x: random.nextDouble(),
          y: -0.1,
          speedY: 0.3 + random.nextDouble() * 0.5,
          speedX: (random.nextDouble() - 0.5) * 0.3,
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
          color: _getRandomColor(),
          size: 5.0 + random.nextDouble() * 5.0,
        ),
      );
    }
  }

  Color _getRandomColor() {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.yellow,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _scaleController.forward();
      _confettiController.forward();
      _rotationController.repeat();
    }
    
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      _rotationController.stop();
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleController,
        _confettiController,
        _rotationController,
      ]),
      builder: (context, child) {
        return Stack(
          children: [
            // Confetti
            ..._buildConfetti(),
            
            // Success Card
            Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildSuccessCard(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildConfetti() {
    return _confettiList.map((confetti) {
      final progress = _confettiController.value;
      final x = confetti.x + (confetti.speedX * progress);
      final y = confetti.y + (confetti.speedY * progress);
      final rotation = confetti.rotation + (confetti.rotationSpeed * progress * 10);
      
      if (y > 1.2) return const SizedBox.shrink();
      
      return Positioned(
        left: x * 1.sw,
        top: y * 1.sh,
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            width: confetti.size.w,
            height: confetti.size.w,
            decoration: BoxDecoration(
              color: confetti.color,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(1.5.r),
              boxShadow: [
                BoxShadow(
                  color: confetti.color.withOpacity(0.5),
                  blurRadius: 3.r,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSuccessCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 25.r,
            spreadRadius: 4.r,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success Icon
          Transform.rotate(
            angle: _rotationController.value * math.pi * 2,
            child: Container(
              width: 65.w,
              height: 65.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 15.r,
                    spreadRadius: 3.r,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 40.sp,
              ),
            ),
          ),
          
          SizedBox(height: 20.h),
          
          // Success Text
          Text(
            'رائع! 🎉',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 10.h),
          
          Text(
            'تم تفعيل جميع الأذونات بنجاح',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.95),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 6.h),
          
          Text(
            'أنت الآن جاهز للاستمتاع بجميع ميزات التطبيق',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withOpacity(0.85),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// نموذج بيانات الـ Confetti
class Confetti {
  final double x;
  final double y;
  final double speedY;
  final double speedX;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double size;

  Confetti({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
  });
}

/// رسالة تحفيزية بسيطة
class SimpleSuccessMessage extends StatefulWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onDismiss;

  const SimpleSuccessMessage({
    super.key,
    required this.message,
    this.icon = Icons.check_circle_rounded,
    this.onDismiss,
  });

  @override
  State<SimpleSuccessMessage> createState() => _SimpleSuccessMessageState();
}

class _SimpleSuccessMessageState extends State<SimpleSuccessMessage>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    
    _controller.forward();
    HapticFeedback.mediumImpact();
    
    // Auto dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade400,
                    Colors.green.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12.r,
                    spreadRadius: 1.r,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}