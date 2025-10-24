// lib/features/onboarding/screens/permissions_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/routes/app_router.dart';
import '../../../core/infrastructure/services/permissions/simple_permission_service.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';

/// شاشة إعداد الأذونات - مُحدّثة لاستخدام smart_permission
///
/// المميزات:
/// - استخدام SimplePermissionService المحسّن
/// - Dialogs تكيفية من smart_permission
/// - Retry logic تلقائي
/// - Cache ذكي لمدة ساعة
class PermissionsSetupScreen extends StatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen> 
    with SingleTickerProviderStateMixin {
  late final SimplePermissionService _permissionService;
  late final StorageService _storage;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _notificationGranted = false;
  bool _locationGranted = false;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _permissionService = getIt<SimplePermissionService>();
    _storage = getIt<StorageService>();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    _animationController.forward();
    _checkPermissions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await _permissionService.checkAllPermissions();
      setState(() {
        _notificationGranted = results.notification;
        _locationGranted = results.location;
        _isLoading = false;
      });
      
      // إذا كانت جميع الأذونات ممنوحة، انتقل مباشرة
      if (results.allGranted) {
        _completeSetup();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    HapticFeedback.lightImpact();
    
    setState(() => _isLoading = true);
    
    try {
      final granted = await _permissionService.requestNotificationPermission(context);
      setState(() {
        _notificationGranted = granted;
        _isLoading = false;
        if (granted) _currentStep = 1;
      });
      
      if (granted) {
        _showSuccessMessage('تم منح إذن الإشعارات بنجاح');
      } else {
        _showErrorMessage('لم يتم منح إذن الإشعارات');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('حدث خطأ أثناء طلب الإذن');
    }
  }

  Future<void> _requestLocationPermission() async {
    HapticFeedback.lightImpact();
    
    setState(() => _isLoading = true);
    
    try {
      final granted = await _permissionService.requestLocationPermission(context);
      setState(() {
        _locationGranted = granted;
        _isLoading = false;
      });
      
      if (granted) {
        _showSuccessMessage('تم منح إذن الموقع بنجاح');
        await Future.delayed(const Duration(milliseconds: 500));
        _completeSetup();
      } else {
        _showErrorMessage('لم يتم منح إذن الموقع');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('حدث خطأ أثناء طلب الإذن');
    }
  }

  Future<void> _completeSetup() async {
    await _storage.setBool('permissions_setup_completed', true);
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    }
  }

  Future<void> _skipPermissions() async {
    HapticFeedback.lightImpact();
    
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'تخطي الأذونات؟',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'يمكنك منح الأذونات لاحقاً من الإعدادات، لكن بعض الميزات قد لا تعمل بشكل صحيح.',
          style: TextStyle(fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'تخطي',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
    
    if (shouldSkip == true) {
      _completeSetup();
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(child: Text(message, style: TextStyle(fontSize: 13.sp))),
          ],
        ),
        backgroundColor: ThemeConstants.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(child: Text(message, style: TextStyle(fontSize: 13.sp))),
          ],
        ),
        backgroundColor: ThemeConstants.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _buildContent(),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إعداد الأذونات',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              if (!_isLoading)
                TextButton(
                  onPressed: _skipPermissions,
                  child: Text(
                    'تخطي',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'امنح الأذونات للحصول على أفضل تجربة',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textSecondaryColor,
            ),
          ),
          SizedBox(height: 20.h),
          _buildProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      height: 4.h,
      decoration: BoxDecoration(
        color: context.dividerColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2.r),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: _notificationGranted 
                    ? ThemeConstants.success 
                    : (_currentStep >= 0 ? ThemeConstants.primary : Colors.transparent),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: _locationGranted 
                    ? ThemeConstants.success 
                    : (_currentStep >= 1 ? ThemeConstants.primary : Colors.transparent),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          _buildPermissionCard(
            icon: Icons.notifications_active_rounded,
            title: 'الإشعارات',
            description: 'تلقي تنبيهات بمواقيت الصلاة والأذكار اليومية',
            isGranted: _notificationGranted,
            isActive: _currentStep == 0,
            onRequest: _notificationGranted ? null : _requestNotificationPermission,
            benefits: [
              'تذكير بمواقيت الصلاة',
              'تنبيهات الأذكار اليومية',
              'إشعارات مخصصة حسب تفضيلاتك',
            ],
          ),
          SizedBox(height: 20.h),
          _buildPermissionCard(
            icon: Icons.location_on_rounded,
            title: 'الموقع',
            description: 'حساب مواقيت الصلاة بدقة وتحديد اتجاه القبلة',
            isGranted: _locationGranted,
            isActive: _currentStep == 1,
            onRequest: _locationGranted ? null : _requestLocationPermission,
            benefits: [
              'مواقيت صلاة دقيقة لموقعك',
              'اتجاه القبلة الصحيح',
              'تحديث تلقائي عند السفر',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required bool isActive,
    required VoidCallback? onRequest,
    required List<String> benefits,
  }) {
    final cardColor = isGranted 
        ? ThemeConstants.success.withOpacity(0.1)
        : (isActive ? ThemeConstants.primary.withOpacity(0.05) : context.cardColor);
    
    final iconColor = isGranted 
        ? ThemeConstants.success
        : (isActive ? ThemeConstants.primary : context.textSecondaryColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isActive 
              ? ThemeConstants.primary.withOpacity(0.3)
              : context.dividerColor.withOpacity(0.2),
          width: isActive ? 2.w : 1.w,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: ThemeConstants.primary.withOpacity(0.1),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
          ),
        ] : [],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          if (isGranted) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeConstants.success,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'ممنوح',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...benefits.map((benefit) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16.sp,
                    color: isGranted ? ThemeConstants.success : iconColor,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            if (onRequest != null && isActive) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'منح الإذن',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final allGranted = _notificationGranted && _locationGranted;
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (allGranted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConstants.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'البدء في استخدام التطبيق',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _skipPermissions,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(
                          color: context.dividerColor,
                          width: 1.w,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'لاحقاً',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        if (!_notificationGranted) {
                          _requestNotificationPermission();
                        } else if (!_locationGranted) {
                          _requestLocationPermission();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'التالي',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 8.h),
            Text(
              'يمكنك تغيير الأذونات لاحقاً من إعدادات التطبيق',
              style: TextStyle(
                fontSize: 11.sp,
                color: context.textSecondaryColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}