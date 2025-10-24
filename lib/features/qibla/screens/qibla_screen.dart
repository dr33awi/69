// lib/features/qibla/screens/qibla_screen.dart - محسن مع نظام الأذونات الجديد
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/simple_permission_service.dart';
import '../services/qibla_service_v3.dart';
import '../widgets/qibla_compass.dart';
import '../widgets/qibla_info_card.dart';
import '../widgets/phone_calibration_animation.dart';

/// شاشة القبلة - محسنة مع نظام الأذونات الجديد
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {

  late final QiblaServiceV3 _qiblaService;
  late final AnimationController _refreshController;
  
  bool _disposed = false;
  bool _hasLocationPermission = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {      
      _qiblaService = QiblaServiceV3(
        storage: getIt<StorageService>(),
        simplePermissionService: getIt<SimplePermissionService>(),
      );

      _refreshController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );

      WidgetsBinding.instance.addObserver(this);
      _startAutoRefreshTimer();

      // التحقق من إذن الموقع
      await _checkLocationPermission();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && _hasLocationPermission) {
          _updateQiblaData();
        }
      });
    } catch (e) {
      debugPrint('Error initializing Qibla screen: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    final permissionService = getIt<SimplePermissionService>();
    final hasPermission = await permissionService.checkLocationPermission();
    if (mounted) {
      setState(() {
        _hasLocationPermission = hasPermission;
      });
    }
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 10),
      (timer) {
        if (!_disposed && !_qiblaService.isLoading && !_qiblaService.hasRecentData) {
          _updateQiblaData();
        }
      },
    );
  }

  Future<void> _updateQiblaData({bool forceUpdate = false}) async {
    if (_disposed || _qiblaService.isLoading) return;

    // التحقق من إذن الموقع وطلبه إذا لزم الأمر
    if (!await _checkAndRequestLocationPermission()) {
      return;
    }

    try {
      await _qiblaService.updateQiblaData(forceUpdate: forceUpdate);
      
      if (!_disposed) {
        _refreshController.forward().then((_) {
          if (!_disposed) {
            _refreshController.reset();
          }
        });
        
        // عرض رسالة نجاح عند التحديث اليدوي
        if (forceUpdate && mounted) {
          context.showSuccessSnackBar('تم تحديث اتجاه القبلة بنجاح');
        }
      }
    } catch (e) {
      // الأخطاء تُعرض في UI
    }
  }

  /// التحقق من إذن الموقع وطلبه إذا لم يكن ممنوحاً
  Future<bool> _checkAndRequestLocationPermission() async {
    try {
      final permissionService = getIt<SimplePermissionService>();
      
      // فحص الإذن أولاً
      final hasPermission = await permissionService.checkLocationPermission();
      
      if (mounted) {
        setState(() {
          _hasLocationPermission = hasPermission;
        });
      }
      
      if (hasPermission) {
        return true;
      }

      // طلب الإذن باستخدام smart_permission
      if (!mounted) return false;
      
      final granted = await permissionService.requestLocationPermission(context);
      
      if (mounted) {
        setState(() {
          _hasLocationPermission = granted;
        });
      }
      
      if (granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'تم منح إذن الموقع بنجاح',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
              ],
            ),
            backgroundColor: ThemeConstants.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            margin: EdgeInsets.all(16.w),
          ),
        );
      } else if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_off, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'إذن الموقع مطلوب لتحديد اتجاه القبلة',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
              ],
            ),
            backgroundColor: ThemeConstants.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'الإعدادات',
              textColor: Colors.white,
              onPressed: () => permissionService.openAppSettings(),
            ),
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
      
      return granted;
    } catch (e) {
      debugPrint('Error checking/requesting location permission: $e');
      return false;
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 12.sp)),
        backgroundColor: ThemeConstants.error,
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          onPressed: () => _updateQiblaData(forceUpdate: true),
          textColor: Colors.white,
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (_disposed) return;

    if (state == AppLifecycleState.resumed && !_qiblaService.hasRecentData) {
      _updateQiblaData();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _refreshController.dispose();
    _qiblaService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: ChangeNotifierProvider.value(
        value: _qiblaService,
        child: Consumer<QiblaServiceV3>(
          builder: (context, service, _) {
            return SafeArea(
              child: Column(
                children: [
                  _buildCustomAppBar(context, service),
                  
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _updateQiblaData(forceUpdate: true),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Column(
                            children: [
                              SizedBox(height: 8.h),
                              _buildMainContent(service),
                              SizedBox(height: 12.h),
                              
                              if (_hasLocationPermission && service.qiblaData != null) ...[
                                QiblaInfoCard(
                                  qiblaData: service.qiblaData!,
                                  currentDirection: service.currentDirection,
                                  compassAccuracy: service.compassAccuracy,
                                ),
                                SizedBox(height: 12.h),
                              ],
                              
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, QiblaServiceV3 service) {
    const gradient = LinearGradient(
      colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return Container(
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 8.w),
          
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withOpacity(0.3),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              FlutterIslamicIcons.solidQibla,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
          
          SizedBox(width: 8.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اتجاه القبلة',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 17.sp,
                  ),
                ),
                Text(
                  _getStatusText(service),
                  style: TextStyle(
                    color: _getStatusColor(service),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          
          _buildActionButton(
            icon: Icons.explore,
            onTap: () => _showCalibrationDialog(context, service),
            tooltip: 'معايرة البوصلة',
          ),
          
          _buildActionButton(
            icon: service.isLoading
                ? Icons.hourglass_empty
                : Icons.refresh_rounded,
            onTap: service.isLoading 
                ? null 
                : () => _updateQiblaData(forceUpdate: true),
            isLoading: service.isLoading,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isSecondary = false,
    String? tooltip,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 4.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: context.dividerColor.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 2.r,
                  offset: Offset(0, 1.h),
                ),
              ],
            ),
            child: isLoading
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor: const AlwaysStoppedAnimation<Color>(ThemeConstants.primary),
                    ),
                  )
                : Icon(
                    icon,
                    color: isSecondary ? context.textSecondaryColor : ThemeConstants.primary,
                    size: 18.sp,
                  ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(QiblaServiceV3 service) {
    if (service.isLoading) {
      return 'جاري التحديث...';
    } else if (service.errorMessage != null) {
      return 'حدث خطأ';
    } else if (service.qiblaData != null) {
      return 'الاتجاه: ${service.qiblaData!.qiblaDirection.toStringAsFixed(1)}°';
    }
    return 'البوصلة الذكية';
  }

  Color _getStatusColor(QiblaServiceV3 service) {
    if (service.isLoading) return ThemeConstants.warning;
    if (service.errorMessage != null) return ThemeConstants.error;
    if (service.qiblaData != null) return context.primaryColor;
    return context.textSecondaryColor;
  }

  Widget _buildMainContent(QiblaServiceV3 service) {
    // التحقق من إذن الموقع أولاً
    if (!_hasLocationPermission) {
      return _buildPermissionWarningCard();
    }
    
    if (service.qiblaData != null) {
      return _buildCompassView(service);
    }
    
    if (service.isLoading) {
      return _buildLoadingState();
    }
    
    if (service.errorMessage != null) {
      return _buildErrorState(service);
    }
    
    if (!service.hasCompass) {
      return _buildNoCompassState(service);
    }
    
    return _buildInitialState();
  }

  Widget _buildCompassView(QiblaServiceV3 service) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 240.h,
        maxHeight: 300.h,
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(10.w),
            child: QiblaCompass(
              qiblaDirection: service.qiblaData!.qiblaDirection,
              currentDirection: service.currentDirection,
              accuracy: service.compassAccuracy,
              isCalibrated: true,
            ),
          ),
          
          if (service.isLoading)
            Positioned(
              top: 4.h,
              right: 4.w,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: context.cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2.r,
                      offset: Offset(0, 1.h),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12.w,
                      height: 12.w,
                      child: CircularProgressIndicator(strokeWidth: 1.5.w),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'تحديث...',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLoading.circular(size: LoadingSize.large),
          SizedBox(height: 16.h),
          Text(
            'جاري تحديد موقعك...',
            style: TextStyle(
              fontWeight: ThemeConstants.medium,
              color: context.textSecondaryColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(QiblaServiceV3 service) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: ThemeConstants.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48.sp,
                color: ThemeConstants.error,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              service.errorMessage ?? 'حدث خطأ في تحميل البيانات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.textSecondaryColor,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: () => _updateQiblaData(forceUpdate: true),
              icon: Icon(Icons.refresh, size: 20.sp),
              label: Text(
                'إعادة المحاولة',
                style: TextStyle(fontSize: 15.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCompassState(QiblaServiceV3 service) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 240.h,
        maxHeight: 320.h,
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.compass_calibration_outlined,
              size: 36.sp,
              color: Colors.amber.shade700,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'البوصلة غير متوفرة',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade700,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              'جهازك لا يدعم البوصلة. يمكنك استخدام اتجاه القبلة من موقعك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          if (service.qiblaData != null) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2.r,
                    offset: Offset(0, 1.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'اتجاه القبلة: ${service.qiblaData!.qiblaDirection.toStringAsFixed(1)}°',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    service.qiblaData!.directionDescription,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Container(
      constraints: BoxConstraints(
        minHeight: 220.h,
        maxHeight: 280.h,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ThemeConstants.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_searching,
                size: 36.sp,
                color: ThemeConstants.primary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'حدد موقعك',
              style: TextStyle(
                fontSize: 15.sp, 
                fontWeight: FontWeight.bold,
                color: ThemeConstants.primary,
              ),
            ),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                'اضغط على زر التحديث لتحديد موقعك واتجاه القبلة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _updateQiblaData(forceUpdate: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(Icons.my_location, size: 16.sp),
              label: Text(
                'تحديد الموقع',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة تحذير إذن الموقع
  Widget _buildPermissionWarningCard() {
    return Container(
      constraints: BoxConstraints(
        minHeight: 220.h,
        maxHeight: 320.h,
      ),
      margin: EdgeInsets.symmetric(vertical: 20.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ThemeConstants.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ThemeConstants.warning.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: ThemeConstants.warning.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off,
              size: 48.sp,
              color: ThemeConstants.warning,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'إذن الموقع مطلوب',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'لتحديد اتجاه القبلة، يجب منح التطبيق إذن الوصول إلى موقعك الحالي',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: context.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final granted = await _requestLocationPermission();
                if (granted && mounted) {
                  await _updateQiblaData(forceUpdate: true);
                }
              },
              icon: Icon(Icons.location_on, size: 20.sp),
              label: Text(
                'منح إذن الموقع',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.warning,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestLocationPermission() async {
    try {
      final permissionService = getIt<SimplePermissionService>();
      final granted = await permissionService.requestLocationPermission(context);
      
      if (mounted) {
        setState(() {
          _hasLocationPermission = granted;
        });
        
        if (granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'تم منح إذن الموقع بنجاح',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
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
      }
      
      return granted;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  void _showCalibrationDialog(BuildContext context, QiblaServiceV3 service) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: ThemeConstants.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore,
                color: ThemeConstants.info,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'معايرة البوصلة',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: ThemeConstants.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: ThemeConstants.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: ThemeConstants.info.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: ThemeConstants.info,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'للحصول على أفضل دقة في تحديد اتجاه القبلة',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: ThemeConstants.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              
              Container(
                height: 140.h,
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: context.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: PhoneCalibrationAnimation(
                  primaryColor: context.primaryColor,
                  width: double.infinity,
                  height: 140.h,
                  amplitudeX: 60.w,
                  amplitudeY: 35.h,
                  duration: const Duration(seconds: 4),
                ),
              ),
              
              SizedBox(height: 16.h),
              Text(
                'خطوات المعايرة:',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: ThemeConstants.semiBold,
                  color: context.primaryColor,
                ),
              ),
              SizedBox(height: 12.h),
              _buildCalibrationStepDialog('1', 'امسك الهاتف بشكل مريح', Icons.phone_android),
              _buildCalibrationStepDialog('2', 'ارسم شكل ∞ في الهواء', Icons.all_inclusive),
              _buildCalibrationStepDialog('3', 'ابتعد عن الأجهزة الإلكترونية والمعادن', Icons.devices_other),
              _buildCalibrationStepDialog('4', 'كرر رسم رقم ∞ عدة مرات حتى تستقر القراءات', Icons.repeat),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'إغلاق',
              style: TextStyle(
                fontSize: 13.sp,
                color: context.textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showCalibrationStartMessage(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'ابدأ المعايرة',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationStepDialog(String number, String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: ThemeConstants.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16.sp,
                  color: context.primaryColor,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: ThemeConstants.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCalibrationStartMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.all_inclusive, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'ابدأ برسم رقم ∞ في الهواء بالهاتف',
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ThemeConstants.info,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }
}