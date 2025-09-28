// lib/features/onboarding/screens/onboarding_screen.dart
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:concentric_transition/concentric_transition.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/permissions/permission_manager.dart';
import '../../../features/home/screens/home_screen.dart';
import '../data/onboarding_data.dart';
import '../widgets/onboarding_page.dart';
import '../widgets/page_indicator.dart';

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
      _isLastPage = index == OnboardingData.items.length - 1;
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

  void _skipOnboarding() async {
    HapticFeedback.lightImpact();
    
    try {
      final storage = getIt<StorageService>();
      await storage.setBool('onboarding_skipped', true);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error skipping onboarding: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Concentric Transition PageView
          ConcentricPageView(
            colors: OnboardingData.items.map((item) => item.primaryColor).toList(),
            radius: MediaQuery.of(context).size.width * 0.8,
            curve: Curves.easeInOutCubic,
            duration: ThemeConstants.durationSlow,
            opacityFactor: 2.0,
            scaleFactor: 0.2,
            verticalPosition: 0.8,
            direction: Axis.vertical,
            itemCount: OnboardingData.items.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (index) {
              return OnboardingPage(
                item: OnboardingData.items[index],
                isLastPage: index == OnboardingData.items.length - 1,
                onNext: _handleNext,
                isProcessing: _isProcessingPermissions,
              );
            },
            onFinish: _handleFinish,
          ),
          
          // مؤشر الصفحات
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 120,
            left: 0,
            right: 0,
            child: Center(
              child: PageIndicator(
                currentIndex: _currentIndex,
                itemCount: OnboardingData.items.length,
                colors: OnboardingData.items.map((item) => item.primaryColor).toList(),
              ),
            ),
          ),
          
          // زر التخطي
          if (!_isLastPage)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              child: TextButton(
                onPressed: _isProcessingPermissions ? null : _skipOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'تخطي',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}