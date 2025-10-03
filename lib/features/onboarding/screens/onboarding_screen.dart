// lib/features/onboarding/screens/onboarding_screen.dart - محدث مع flutter_screenutil
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:athkar_app/features/onboarding/models/onboarding_item.dart';
import 'package:athkar_app/features/onboarding/widgets/page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:concentric_transition/concentric_transition.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/permissions/permission_manager.dart';
import '../../../features/home/screens/home_screen.dart';
import '../data/onboarding_data.dart';
import '../widgets/onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  late final UnifiedPermissionManager _permissionManager;
  
  int _currentIndex = 0;
  bool _isLastPage = false;
  bool _isProcessingPermissions = false;
  final List<OnboardingItem> _items = OnboardingData.items;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _permissionManager = getIt<UnifiedPermissionManager>();
    
    // تسجيل خدمات الميزات بمجرد الدخول
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ServiceLocator.registerFeatureServices();
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
      
      // طلب الأذونات الحرجة
      final result = await _permissionManager.requestMultiplePermissions(
        context,
        [
          AppPermissionType.notification,
          AppPermissionType.location,
          AppPermissionType.batteryOptimization,
        ],
        showExplanation: false, // لأننا شرحناها في الـ onboarding
      );
      
      // حفظ اكتمال الـ onboarding
      await _markOnboardingCompleted();
      
      // الانتقال للصفحة الرئيسية
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
          ),
        );
      }
      
    } catch (e) {
      debugPrint('Error in onboarding finish: $e');
      // في حالة الخطأ، ننتقل للصفحة الرئيسية أيضاً
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _markOnboardingCompleted() async {
    try {
      final storage = getIt<StorageService>();
      await storage.setBool('onboarding_completed', true);
      await storage.setString(
        'onboarding_completed_at', 
        DateTime.now().toIso8601String(),
      );
      
      debugPrint('✅ Onboarding marked as completed');
    } catch (e) {
      debugPrint('❌ Error marking onboarding completed: $e');
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
      body: Stack(
        children: [
          // Concentric Transition PageView
          ConcentricPageView(
            colors: _items.map((item) => item.primaryColor).toList(),
            radius: MediaQuery.of(context).size.width * 0.85,
            curve: Curves.easeInOutCubic,
            duration: ThemeConstants.durationSlow,
            opacityFactor: 2.5,
            scaleFactor: 0.3,
            verticalPosition: 0.82,
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
            onFinish: _handleFinish,
          ),
          
          // مؤشر الصفحات في الأعلى
          Positioned(
            top: MediaQuery.of(context).padding.top + 20.h,
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
}