// lib/features/onboarding/screens/onboarding_screen.dart

import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:athkar_app/features/onboarding/models/onboarding_item.dart';
import 'package:athkar_app/features/onboarding/widgets/page_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:concentric_transition/concentric_transition.dart';
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
  final List<OnboardingItem> _items = OnboardingData.items;

  // الأحجام المتجاوبة
  double get _concentricRadius {
    if (OnboardingResponsiveConfig.isTablet) return 1.sw * 0.90;
    if (OnboardingResponsiveConfig.isLargePhone) return 1.sw * 0.87;
    return 1.sw * 0.85;
  }

  double get _verticalPosition {
    if (OnboardingResponsiveConfig.isTablet) return 0.80;
    if (OnboardingResponsiveConfig.isTallScreen) return 0.82;
    return 0.85;
  }

  double get _scaleFactor {
    if (OnboardingResponsiveConfig.isTablet) return 0.25;
    return 0.3;
  }

  double get _opacityFactor {
    if (OnboardingResponsiveConfig.isTablet) return 2.2;
    return 2.5;
  }

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
      
      // طباعة معلومات الجهاز في وضع Debug
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
    setState(() {
      _currentIndex = index;
      _isLastPage = index == _items.length - 1;
    });
    
    HapticFeedback.lightImpact();
  }

  Future<void> _handleNext() async {
    if (_isLastPage) {
      await _handleFinish();
    } else {
      _pageController.nextPage(
        duration: ThemeConstants.durationNormal,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleFinish() async {
    setState(() => _isProcessingPermissions = true);
    
    try {
      HapticFeedback.mediumImpact();
      
      // تسجيل اكتمال الـ Onboarding
      await _markOnboardingCompleted();
      
      if (mounted) {
        // انتقال سلس للصفحة الرئيسية
        await Navigator.of(context).pushReplacement(
          _buildTransition(),
        );
      }
      
    } catch (e) {
      debugPrint('Error in onboarding finish: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPermissions = false);
      }
    }
  }

  PageRouteBuilder _buildTransition() {
    // مدة الانتقال بناءً على حجم الشاشة
    final transitionDuration = OnboardingResponsiveConfig.isTablet
        ? const Duration(milliseconds: 1200)
        : const Duration(milliseconds: 1000);

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
      transitionDuration: transitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // تأثير Fade مع Scale متجاوب
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
      
      // حفظ معلومات الجهاز للإحصائيات
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
      
      // حفظ نوع الجهاز
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
    _pageController.animateToPage(
      index,
      duration: ThemeConstants.durationNormal,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _items[_currentIndex].primaryColor,
      body: Stack(
        children: [
          // الخلفية المتدرجة
          _buildGradientBackground(),
          
          // ConcentricPageView مع إعدادات متجاوبة
          ConcentricPageView(
            colors: _items.map((item) => item.primaryColor).toList(),
            radius: _concentricRadius,
            curve: Curves.easeInOutCubic,
            duration: ThemeConstants.durationSlow,
            opacityFactor: _opacityFactor,
            scaleFactor: _scaleFactor,
            verticalPosition: _verticalPosition,
            direction: Axis.vertical,
            itemCount: _items.length,
            physics: const BouncingScrollPhysics(),
            onChange: _onPageChanged,
            itemBuilder: (index) {
              return OnboardingPage(
                item: _items[index],
                isLastPage: index == _items.length - 1,
                onNext: _handleNext,
                isProcessing: _isProcessingPermissions,
              );
            },
            // إزالة onFinish لمنع التنفيذ التلقائي
            // سيتم التحكم في الانتقال من خلال زر "المتابعة" فقط
          ),
          
          // مؤشر الصفحات
          Positioned(
            top: _indicatorTopPosition,
            left: 0,
            right: 0,
            child: Center(
              child: PageIndicator(
                currentIndex: _currentIndex,
                items: _items,
                onPageTap: _goToPage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return AnimatedContainer(
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
    );
  }
}