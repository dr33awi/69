// lib/core/infrastructure/firebase/promotional_banners/widgets/banner_carousel.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../models/promotional_banner_model.dart';
import 'banner_widget.dart';

/// Carousel للبانرات المتعددة
class BannerCarousel extends StatefulWidget {
  final List<PromotionalBanner> banners;
  final String screenName;
  final Duration autoPlayDuration;
  final bool enableAutoPlay;
  
  const BannerCarousel({
    super.key,
    required this.banners,
    required this.screenName,
    this.autoPlayDuration = const Duration(seconds: 5),
    this.enableAutoPlay = true,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  final List<PromotionalBanner> _activeBanners = [];

  @override
  void initState() {
    super.initState();
    _activeBanners.addAll(widget.banners);
    _pageController = PageController();
    
    if (widget.enableAutoPlay && _activeBanners.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.autoPlayDuration, (_) {
      if (_currentPage < _activeBanners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onBannerDismissed(int index) {
    setState(() {
      _activeBanners.removeAt(index);
      
      // إذا لم يبق أي بانرات
      if (_activeBanners.isEmpty) {
        _autoPlayTimer?.cancel();
        return;
      }
      
      // تعديل الصفحة الحالية
      if (_currentPage >= _activeBanners.length) {
        _currentPage = _activeBanners.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeBanners.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_activeBanners.length == 1) {
      return BannerWidget(
        banner: _activeBanners.first,
        screenName: widget.screenName,
        onDismiss: () => _onBannerDismissed(0),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 120.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _activeBanners.length,
            itemBuilder: (context, index) {
              return BannerWidget(
                banner: _activeBanners[index],
                screenName: widget.screenName,
                onDismiss: () => _onBannerDismissed(index),
              );
            },
          ),
        ),
        
        SizedBox(height: 8.h),
        
        // مؤشرات الصفحات
        _buildPageIndicators(),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _activeBanners.length,
        (index) => _buildIndicator(index),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = index == _currentPage;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      width: isActive ? 20.w : 6.w,
      height: 6.h,
      decoration: BoxDecoration(
        color: isActive 
            ? _activeBanners[index].gradientColors.first 
            : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(3.r),
      ),
    );
  }
}