// lib/features/onboarding/widgets/lottie_animation_widget.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/onboarding_item.dart';

class LottieAnimationWidget extends StatefulWidget {
  final OnboardingItem item;
  final double size;
  final bool autoPlay;
  final bool repeat;

  const LottieAnimationWidget({
    super.key,
    required this.item,
    this.size = 200,
    this.autoPlay = true,
    this.repeat = true,
  });

  @override
  State<LottieAnimationWidget> createState() => _LottieAnimationWidgetState();
}

class _LottieAnimationWidgetState extends State<LottieAnimationWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _lottieController;
  late AnimationController _containerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // كونترولر الـ Lottie
    _lottieController = AnimationController(vsync: this);
    
    // كونترولر الحاوية
    _containerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // تأثير التحجيم
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _containerController,
      curve: Curves.easeInOut,
    ));
    
    // تأثير الدوران الخفيف
    _rotationAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _containerController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.repeat) {
      _containerController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _containerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _containerController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: _buildAnimationContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimationContent() {
    // إذا كان هناك ملف Lottie، استخدمه
    if (widget.item.animationPath != null) {
      return _buildLottieAnimation();
    }
    
    // وإلا استخدم animation مخصص حسب النوع
    return _buildCustomAnimation();
  }

  Widget _buildLottieAnimation() {
    return ClipOval(
      child: Lottie.asset(
        widget.item.animationPath!,
        controller: _lottieController,
        width: widget.size * 0.7,
        height: widget.size * 0.7,
        fit: BoxFit.contain,
        repeat: widget.repeat,
        animate: widget.autoPlay,
        onLoaded: (composition) {
          _lottieController.duration = composition.duration;
          if (widget.autoPlay) {
            _lottieController.forward();
            if (widget.repeat) {
              _lottieController.repeat();
            }
          }
        },
        // تخصيص الألوان إذا أمكن
        delegates: LottieDelegates(
          values: [
            // يمكن تخصيص الألوان هنا حسب الحاجة
            ValueDelegate.color(
              const ['**'],
              value: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAnimation() {
    switch (widget.item.animationType) {
      case OnboardingAnimationType.mosque:
        return _MosqueAnimation(size: widget.size * 0.6);
      case OnboardingAnimationType.book:
        return _BookAnimation(size: widget.size * 0.6);
      case OnboardingAnimationType.clock:
        return _ClockAnimation(size: widget.size * 0.6);
      case OnboardingAnimationType.compass:
        return _CompassAnimation(size: widget.size * 0.6);
      case OnboardingAnimationType.security:
        return _SecurityAnimation(size: widget.size * 0.6);
      default:
        return Icon(
          Icons.star,
          size: widget.size * 0.6,
          color: Colors.white,
        );
    }
  }
}

// Custom Animations للحالات التي لا تحتوي على Lottie

class _MosqueAnimation extends StatefulWidget {
  final double size;
  
  const _MosqueAnimation({required this.size});

  @override
  State<_MosqueAnimation> createState() => _MosqueAnimationState();
}

class _MosqueAnimationState extends State<_MosqueAnimation>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Icon(
            Icons.mosque,
            size: widget.size,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

class _BookAnimation extends StatefulWidget {
  final double size;
  
  const _BookAnimation({required this.size});

  @override
  State<_BookAnimation> createState() => _BookAnimationState();
}

class _BookAnimationState extends State<_BookAnimation>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _openAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _openAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _openAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // الكتاب المغلق
            Transform.scale(
              scale: 1.0 - (_openAnimation.value * 0.2),
              child: Icon(
                Icons.menu_book,
                size: widget.size,
                color: Colors.white.withValues(alpha: 1.0 - _openAnimation.value),
              ),
            ),
            // الكتاب المفتوح
            Transform.scale(
              scale: 0.8 + (_openAnimation.value * 0.2),
              child: Icon(
                Icons.book_outlined,
                size: widget.size,
                color: Colors.white.withValues(alpha: _openAnimation.value),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClockAnimation extends StatefulWidget {
  final double size;
  
  const _ClockAnimation({required this.size});

  @override
  State<_ClockAnimation> createState() => _ClockAnimationState();
}

class _ClockAnimationState extends State<_ClockAnimation>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // الساعة الخلفية
            Icon(
              Icons.access_time,
              size: widget.size,
              color: Colors.white,
            ),
            // العقرب المتحرك
            Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: Container(
                width: widget.size * 0.4,
                height: 2,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompassAnimation extends StatefulWidget {
  final double size;
  
  const _CompassAnimation({required this.size});

  @override
  State<_CompassAnimation> createState() => _CompassAnimationState();
}

class _CompassAnimationState extends State<_CompassAnimation>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _needleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _needleAnimation = Tween<double>(
      begin: -0.2,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _needleAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // البوصلة
            Icon(
              Icons.explore,
              size: widget.size,
              color: Colors.white,
            ),
            // الإبرة المتحركة
            Transform.rotate(
              angle: _needleAnimation.value,
              child: Container(
                width: 2,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SecurityAnimation extends StatefulWidget {
  final double size;
  
  const _SecurityAnimation({required this.size});

  @override
  State<_SecurityAnimation> createState() => _SecurityAnimationState();
}

class _SecurityAnimationState extends State<_SecurityAnimation>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _shieldAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _shieldAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shieldAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _shieldAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.security,
                size: widget.size,
                color: Colors.white,
              ),
              Icon(
                Icons.check,
                size: widget.size * 0.4,
                color: Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }
}