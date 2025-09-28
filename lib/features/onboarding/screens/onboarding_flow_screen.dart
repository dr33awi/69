// lib/features/onboarding/screens/onboarding_flow_screen.dart
import 'package:athkar_app/core/infrastructure/services/permissions/permission_service.dart';
import 'package:athkar_app/features/onboarding/models/onboarding_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/core/infrastructure/services/permissions/permission_manager.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:athkar_app/app/routes/app_router.dart';
import '../data/onboarding_screens_data.dart';
import '../widgets/onboarding_screen.dart';
import '../widgets/progress_indicator.dart';
import '../widgets/navigation_controls.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late UnifiedPermissionManager _permissionManager;
  late StorageService _storage;

  int _currentIndex = 0;
  List<AppPermissionType> _grantedPermissions = [];
  bool _isAnimating = false;
  bool _isRequestingPermissions = false;

  final List<OnboardingScreen> _screens = OnboardingScreensData.getScreens();

  @override
  void initState() {
    super.initState();
    
    _pageController = PageController();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _permissionManager = getIt<UnifiedPermissionManager>();
    _storage = getIt<StorageService>();
    
    // تطبيق الستايل للشريط العلوي
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_isAnimating || _currentIndex >= _screens.length - 1) return;
    
    _animateToPage(_currentIndex + 1);
  }

  void _previousPage() {
    if (_isAnimating || _currentIndex <= 0) return;
    
    _animateToPage(_currentIndex - 1);
  }

  void _animateToPage(int index) {
    setState(() => _isAnimating = true);
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    ).then((_) {
      setState(() => _isAnimating = false);
    });
  }

  void _goToPage(int index) {
    if (_isAnimating) return;
    _animateToPage(index);
  }

  Future<void> _handlePermissionRequest(AppPermissionType permission) async {
    if (_isRequestingPermissions) return;
    
    setState(() => _isRequestingPermissions = true);
    
    try {
      HapticFeedback.lightImpact();
      
      final granted = await _permissionManager.requestPermissionWithExplanation(
        context,
        permission,
        forceRequest: true,
      );
      
      if (granted && !_grantedPermissions.contains(permission)) {
        setState(() {
          _grantedPermissions.add(permission);
        });
        
        HapticFeedback.heavyImpact();
        
        // إظهار رسالة نجاح
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: ThemeConstants.space3),
                  Text('تم تفعيل إذن ${_getPermissionName(permission)}'),
                ],
              ),
              backgroundColor: ThemeConstants.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    } finally {
      setState(() => _isRequestingPermissions = false);
    }
  }

  String _getPermissionName(AppPermissionType permission) {
    switch (permission) {
      case AppPermissionType.notification:
        return 'الإشعارات';
      case AppPermissionType.location:
        return 'الموقع';
      case AppPermissionType.batteryOptimization:
        return 'تحسين البطارية';
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      HapticFeedback.heavyImpact();
      
      // حفظ حالة إكمال الـ onboarding
      await _storage.setBool('onboarding_completed', true);
      await _storage.setString('onboarding_completed_at', DateTime.now().toIso8601String());
      
      // حفظ الأذونات المفعلة
      final permissionNames = _grantedPermissions.map((p) => p.toString()).toList();
      await _storage.setStringList('granted_permissions', permissionNames);
      
      debugPrint('Onboarding completed successfully');
      debugPrint('Granted permissions: $_grantedPermissions');
      
      // الانتقال إلى الشاشة الرئيسية
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      }
      
    } catch (e) {
      debugPrint('Error finishing onboarding: $e');
      // في حالة حدوث خطأ، انتقل للشاشة الرئيسية على أي حال
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
      }
    }
  }

  bool get _canProceed {
    if (_currentIndex < _screens.length - 1) return true;
    
    // في الشاشة الأخيرة، تحقق من الأذونات المطلوبة
    final requiredPermissions = _screens.last.permissions
        ?.where((p) => p.isRequired)
        .map((p) => p.permissionType)
        .toList() ?? [];
    
    return requiredPermissions.every((p) => _grantedPermissions.contains(p));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // شريط التقدم
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(ThemeConstants.space4),
              child: Column(
                children: [
                  // Header مع اللوجو
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ThemeConstants.space2),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: ThemeConstants.space3),
                      Text(
                        'حصن المسلم',
                        style: AppTextStyles.h4.copyWith(
                          color: ThemeConstants.primary,
                          fontWeight: ThemeConstants.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_currentIndex < _screens.length - 1)
                        TextButton(
                          onPressed: () => _finishOnboarding(),
                          child: const Text('تخطي'),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: ThemeConstants.space4),
                  
                  // مؤشر التقدم
                  OnboardingProgressIndicator(
                    currentIndex: _currentIndex,
                    totalSteps: _screens.length,
                    onStepTap: _goToPage,
                  ),
                ],
              ),
            ),
          ),

          // المحتوى الرئيسي
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _progressAnimationController.animateTo(
                  index / (_screens.length - 1),
                );
              },
              itemCount: _screens.length,
              itemBuilder: (context, index) {
                return OnboardingScreenWidget(
                  screen: _screens[index],
                  isActive: index == _currentIndex,
                  grantedPermissions: _grantedPermissions,
                  onPermissionRequest: _handlePermissionRequest,
                );
              },
            ),
          ),

          // أزرار التنقل
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: ThemeConstants.lightDivider),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(ThemeConstants.space4),
                child: OnboardingNavigationControls(
                  currentIndex: _currentIndex,
                  totalSteps: _screens.length,
                  canProceed: _canProceed,
                  isLoading: _isRequestingPermissions,
                  onPrevious: _previousPage,
                  onNext: _nextPage,
                  onFinish: _finishOnboarding,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}