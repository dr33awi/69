// lib/features/onboarding/widgets/onboarding_page.dart
// محدث: بدون أنيميشنات

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../../app/themes/widgets/core/islamic_pattern_painter.dart';
import '../models/onboarding_item.dart';
import '../data/onboarding_data.dart';
import '../permission/onboarding_permissions_page.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final bool isLastPage;
  final VoidCallback onNext;
  final bool isProcessing;

  const OnboardingPage({
    super.key,
    required this.item,
    required this.isLastPage,
    required this.onNext,
    this.isProcessing = false,
  });

  // حساب الأحجام المتجاوبة بناءً على حجم الشاشة
  double get _animationSize {
    if (1.sw > 600) return 180.w;
    if (1.sw > 400) return 150.w;
    return 130.w;
  }

  double get _lottieSize {
    if (1.sw > 600) return 130.w;
    if (1.sw > 400) return 105.w;
    return 90.w;
  }

  double get _titleSize {
    if (1.sw > 600) return 28.sp;
    if (1.sw > 400) return 24.sp;
    return 22.sp;
  }

  double get _featureSize {
    if (1.sw > 600) return 15.sp;
    if (1.sw > 400) return 13.sp;
    return 12.sp;
  }

  @override
  Widget build(BuildContext context) {
    // استخدام صفحة خاصة للأذونات
    if (item.animationType == OnboardingAnimationType.permissions) {
      return OnboardingPermissionsPage(
        item: item,
        onNext: onNext,
        isProcessing: isProcessing,
      );
    }
    
    // حساب المسافات بناءً على حجم الشاشة
    final verticalPadding = 1.sh > 700 ? 16.h : 12.h;
    final horizontalPadding = 1.sw > 600 ? 32.w : 20.w;
    final topSpacing = 1.sh > 700 ? 40.h : 25.h;
    final itemSpacing = 1.sh > 700 ? 24.h : 18.h;
    
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
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: topSpacing),
                          
                          _buildAnimationWidget(),
                          
                          SizedBox(height: itemSpacing),
                          
                          _buildTitle(),
                          
                          if (item.features != null && 
                              item.features!.isNotEmpty) ...[
                            SizedBox(height: itemSpacing * 0.75),
                            _buildFeaturesList(),
                          ],
                        ],
                      ),
                      
                      Column(
                        children: [
                          SizedBox(height: itemSpacing),
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

  Widget _buildAnimationWidget() {
    return Container(
      width: _animationSize,
      height: _animationSize,
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
          width: _lottieSize,
          height: _lottieSize,
          child: item.hasValidLottie
              ? _buildLottieAnimation()
              : _buildFallbackIcon(),
        ),
      ),
    );
  }

  Widget _buildLottieAnimation() {
    final config = OnboardingData.lottieConfigs[item.animationType] ?? 
                   const LottieConfig();
    
    return Lottie.asset(
      item.lottiePath!,
      width: _lottieSize,
      height: _lottieSize,
      fit: BoxFit.contain,
      repeat: config.repeat,
      animate: config.autoStart,
      options: LottieOptions(
        enableMergePaths: true,
      ),
      onLoaded: (composition) {
        debugPrint('✅ Lottie animation loaded: ${item.lottiePath}');
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Lottie error: $error');
        return _buildFallbackIcon();
      },
    );
  }

  Widget _buildFallbackIcon() {
    final iconSize = _lottieSize * 0.55;
    
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Icon(
        item.iconData,
        size: iconSize * 0.5,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      item.title,
      style: TextStyle(
        fontSize: _titleSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFeaturesList() {
    final containerPadding = 1.sw > 600 ? 16.w : 12.w;
    final itemVerticalPadding = 1.sh > 700 ? 5.h : 4.h;
    
    return Container(
      padding: EdgeInsets.all(containerPadding),
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
        children: item.features!
            .map((feature) => _buildFeatureItem(
              feature, 
              itemVerticalPadding,
            ))
            .toList(),
      ),
    );
  }

  Widget _buildFeatureItem(String feature, double verticalPadding) {
    final bulletSize = 1.sw > 600 ? 5.w : 4.w;
    final spacing = 1.sw > 600 ? 10.w : 8.w;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Container(
              width: bulletSize,
              height: bulletSize,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 3.r,
                    spreadRadius: 1.r,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: _featureSize,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final buttonHeight = 1.sh > 700 ? 52.h : 48.h;
    final buttonFontSize = 1.sw > 600 ? 16.sp : 14.sp;
    final iconSize = 1.sw > 600 ? 18.sp : 16.sp;
    
    return Container(
      width: double.infinity,
      height: buttonHeight,
      constraints: BoxConstraints(
        maxWidth: 1.sw > 600 ? 400.w : double.infinity,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(buttonHeight / 2),
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
            spreadRadius: 1.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isProcessing ? null : onNext,
          borderRadius: BorderRadius.circular(buttonHeight / 2),
          child: Container(
            alignment: Alignment.center,
            child: isProcessing
                ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastPage ? 'ابدأ الآن' : 'التالي',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        isLastPage 
                            ? Icons.check_rounded 
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}