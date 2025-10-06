// lib/features/onboarding/widgets/onboarding_page.dart - Updated
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../../app/themes/widgets/core/islamic_pattern_painter.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../../../core/infrastructure/services/permissions/permission_manager.dart';
import '../models/onboarding_item.dart';
import '../data/onboarding_data.dart';
import 'onboarding_permission_request.dart';

class OnboardingPage extends StatefulWidget {
  final OnboardingItem item;
  final bool isLastPage;
  final VoidCallback onNext;
  final bool isProcessing;
  final UnifiedPermissionManager? permissionManager;

  const OnboardingPage({
    super.key,
    required this.item,
    required this.isLastPage,
    required this.onNext,
    this.isProcessing = false,
    this.permissionManager,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _isPermissionPage => widget.isLastPage && 
      widget.item.animationType == OnboardingAnimationType.permissions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.sw,
      height: 1.sh,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: IslamicPatternPainter(
                rotation: 0,
                color: Colors.white,
                opacity: 0.05,
                patternType: PatternType.standard,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                             MediaQuery.of(context).padding.top - 
                             MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: 30.h),
                          
                          // إذا كانت صفحة الأذونات، نعرض UI مخصص
                          if (_isPermissionPage)
                            _buildPermissionContent()
                          else
                            _buildNormalContent(),
                        ],
                      ),
                      
                      // زر الأكشن للصفحات العادية فقط
                      if (!_isPermissionPage)
                        Column(
                          children: [
                            SizedBox(height: 20.h),
                            _buildActionButton(),
                            SizedBox(height: 12.h),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalContent() {
    return Column(
      children: [
        _buildAnimationWidget(),
        SizedBox(height: 20.h),
        
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 15.h * (1 - _fadeAnimation.value)),
                child: Text(
                  widget.item.title,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
        
        if (widget.item.features != null && widget.item.features!.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildFeaturesList(),
        ],
      ],
    );
  }

  Widget _buildPermissionContent() {
    if (widget.permissionManager == null) {
      return const SizedBox.shrink();
    }
    
    return OnboardingPermissionRequest(
      permissions: const [
        AppPermissionType.notification,
        AppPermissionType.location,
        AppPermissionType.batteryOptimization,
      ],
      onComplete: widget.onNext,
      primaryColor: widget.item.primaryColor,
      permissionManager: widget.permissionManager!,
    );
  }

  Widget _buildAnimationWidget() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
                  blurRadius: 25.r,
                  spreadRadius: 4.r,
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 95.w,
                height: 95.w,
                child: widget.item.hasValidLottie
                    ? _buildLottieAnimation()
                    : _buildFallbackIcon(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLottieAnimation() {
    final config = OnboardingData.lottieConfigs[widget.item.animationType] ?? 
                   const LottieConfig();
    
    return Lottie.asset(
      widget.item.lottiePath!,
      width: 95.w,
      height: 95.w,
      fit: BoxFit.contain,
      repeat: config.repeat,
      animate: config.autoStart,
      options: LottieOptions(
        enableMergePaths: true,
      ),
      onLoaded: (composition) {
        debugPrint('✅ Lottie animation loaded: ${widget.item.lottiePath}');
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Lottie error: $error');
        return _buildFallbackIcon();
      },
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 70.w,
      height: 70.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Icon(
        widget.item.iconData,
        size: 35.sp,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFeaturesList() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value * 0.9,
          child: Transform.translate(
            offset: Offset(0, 25.h * (1 - _fadeAnimation.value)),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Column(
                children: widget.item.features!
                    .map((feature) => _buildFeatureItem(feature))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 3.r,
                  spreadRadius: 0.5.r,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 30.h * (1 - _fadeAnimation.value)),
            child: Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.2.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 12.r,
                    spreadRadius: 1.5.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isProcessing ? null : widget.onNext,
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    alignment: Alignment.center,
                    child: widget.isProcessing
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'التالي',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}