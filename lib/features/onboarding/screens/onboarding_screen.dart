// lib/features/onboarding/screens/onboarding_screen.dart
// بدون تأثير الانتقال التلقائي - PageView عادي

import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:athkar_app/features/onboarding/models/onboarding_item.dart';
import 'package:athkar_app/features/onboarding/widgets/page_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../features/home/screens/home_screen.dart';
import '../data/onboarding_data.dart';
import '../widgets/onboarding_page.dart';
import '../config/onboarding_responsive_config.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  late final PermissionService _permissionService;
  
  int _currentIndex = 0;
  bool _isLastPage = false;
  bool _isProcessingPermissions = false;
  bool _hasNavigated = false;
  final List<OnboardingItem> _items = OnboardingData.items;

  double get _indicatorTopPosition {
    if (OnboardingResponsiveConfig.isTablet) {
      return MediaQuery.of(context).padding.top + 28.h;
    }
    if (OnboardingResponsiveConfig.isTallScreen) {
      return MediaQuery.of(context).padding.top + 24.h;
    }
    return MediaQuery.of(context).padding.top + 20.h;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _permissionService = getIt<PermissionService>();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ServiceLocator.registerFeatureServices();
      
      if (kDebugMode) {
        OnboardingResponsiveConfig.printDeviceInfo();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_hasNavigated) return;
    
    setState(() {
      _currentIndex = index;
      _isLastPage = index == _items.length - 1;
    });
    
    HapticFeedback.lightImpact();
  }

  Future<void> _handleNext() async {
    if (_hasNavigated || _isProcessingPermissions) {
      debugPrint('⚠️ Already processing, ignoring tap');
      return;
    }
    
    debugPrint('🔘 Button pressed - Current page: $_currentIndex, Is last: $_isLastPage');
    
    if (_isLastPage) {
      debugPrint('✅ Last page detected, starting finish process');
      await _handleFinish();
    } else {
      debugPrint('➡️ Moving to next page');
      if (_pageController.hasClients && mounted) {
        _pageController.nextPage(
          duration: ThemeConstants.durationNormal,
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  Future<void> _handleFinish() async {
    if (_hasNavigated || _isProcessingPermissions) {
      debugPrint('⚠️ Already processing finish, returning');
      return;
    }
    
    debugPrint('🚀 Starting finish process...');
    
    setState(() {
      _isProcessingPermissions = true;
      _hasNavigated = true;
    });
    
    try {
      HapticFeedback.mediumImpact();
      
      await _markOnboardingCompleted();
      
      debugPrint('✅ Onboarding completed, navigating to home...');
      
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (mounted) {
          await Navigator.of(context).pushReplacement(
            _buildTransition(),
          );
          debugPrint('✅ Navigation completed');
        }
      }
      
    } catch (e) {
      debugPrint('❌ Error in onboarding finish: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  PageRouteBuilder _buildTransition() {
    final transitionDuration = OnboardingResponsiveConfig.isTablet
        ? const Duration(milliseconds: 1200)
        : const Duration(milliseconds: 1000);

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
      transitionDuration: transitionDuration,
      reverseTransitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = OnboardingResponsiveConfig.isTablet
            ? Tween<double>(begin: 0.92, end: 1.0)
            : Tween<double>(begin: 0.95, end: 1.0);

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: ScaleTransition(
            scale: scaleTween.animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _markOnboardingCompleted() async {
    try {
      final storage = getIt<StorageService>();
      await storage.setBool('onboarding_completed', true);
      await storage.setString(
        'onboarding_completed_at', 
        DateTime.now().toIso8601String(),
      );
      
      await _saveDeviceInfo(storage);
      
      debugPrint('✅ Onboarding marked as completed');
    } catch (e) {
      debugPrint('❌ Error marking onboarding completed: $e');
    }
  }

  Future<void> _saveDeviceInfo(StorageService storage) async {
    try {
      final deviceInfo = OnboardingResponsiveConfig.toMap();
      await storage.setString(
        'device_info',
        deviceInfo.toString(),
      );
      
      if (OnboardingResponsiveConfig.isTablet) {
        await storage.setString('device_type', 'tablet');
      } else if (OnboardingResponsiveConfig.isLargePhone) {
        await storage.setString('device_type', 'large_phone');
      } else {
        await storage.setString('device_type', 'small_phone');
      }
      
      debugPrint('📱 Device info saved');
    } catch (e) {
      debugPrint('⚠️ Error saving device info: $e');
    }
  }

  void _goToPage(int index) {
    if (_hasNavigated || _isProcessingPermissions || _isLastPage) return;
    
    if (_pageController.hasClients && mounted) {
      _pageController.animateToPage(
        index,
        duration: ThemeConstants.durationNormal,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isProcessingPermissions && !_hasNavigated,
      child: Scaffold(
        body: Stack(
          children: [
            // الخلفية المتدرجة
            AnimatedContainer(
              duration: ThemeConstants.durationNormal,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _items[_currentIndex].primaryColor,
                    _items[_currentIndex].secondaryColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            
            // PageView بسيط بدون تأثيرات
            IgnorePointer(
              ignoring: _hasNavigated || _isProcessingPermissions,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                // منع التمرير في الصفحة الأخيرة
                physics: (_hasNavigated || _isProcessingPermissions || _isLastPage)
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                itemCount: _items.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    item: _items[index],
                    isLastPage: index == _items.length - 1,
                    onNext: _handleNext,
                    isProcessing: _isProcessingPermissions,
                  );
                },
              ),
            ),
            
            // مؤشر الصفحات
            if (!_hasNavigated)
              Positioned(
                top: _indicatorTopPosition,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: _isProcessingPermissions || _isLastPage,
                  child: Center(
                    child: PageIndicator(
                      currentIndex: _currentIndex,
                      items: _items,
                      onPageTap: _goToPage,
                    ),
                  ),
                ),
              ),
            
            // Overlay المعالجة
            if (_isProcessingPermissions)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3.w,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'جاري التحضير...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}