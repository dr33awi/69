// lib/features/qibla/screens/qibla_screen.dart - محسن مع الخدمة الجديدة V2
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../services/qibla_service_v2.dart'; // الخدمة المحسنة
import '../widgets/qibla_compass.dart';
import '../widgets/qibla_info_card.dart';

/// شاشة القبلة - محسنة للشاشات الصغيرة
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  
  late final QiblaServiceV2 _qiblaService;
  late final AnimationController _refreshController;
  
  bool _disposed = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {      
      _qiblaService = QiblaServiceV2(
        storage: getIt<StorageService>(),
        permissionService: getIt<PermissionService>(),
      );

      _refreshController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );

      WidgetsBinding.instance.addObserver(this);
      _startAutoRefreshTimer();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          _updateQiblaData();
        }
      });
    } catch (e) {
      debugPrint('[QiblaScreen] خطأ في تهيئة الشاشة: $e');
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

    try {
      await _qiblaService.updateQiblaData(forceUpdate: forceUpdate);
      
      if (!_disposed) {
        _refreshController.forward().then((_) {
          if (!_disposed) {
            _refreshController.reset();
          }
        });
      }
    } catch (e) {
      debugPrint('[QiblaScreen] خطأ في تحديث البيانات: $e');
      if (mounted) {
        _showErrorSnackbar(e.toString());
      }
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
        child: Consumer<QiblaServiceV2>(
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
                              
                              if (service.qiblaData != null) ...[
                                QiblaInfoCard(
                                  qiblaData: service.qiblaData!,
                                  currentDirection: service.currentDirection,
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

  Widget _buildCustomAppBar(BuildContext context, QiblaServiceV2 service) {
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
                    fontSize: 15.sp,
                  ),
                ),
                Text(
                  _getStatusText(service),
                  style: TextStyle(
                    color: _getStatusColor(service),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          
          _buildActionButton(
            icon: service.isLoading
                ? Icons.hourglass_empty
                : Icons.refresh_rounded,
            onTap: service.isLoading 
                ? null 
                : () => _updateQiblaData(forceUpdate: true),
            isLoading: service.isLoading,
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

  String _getStatusText(QiblaServiceV2 service) {
    if (service.isLoading) {
      return 'جاري التحديث...';
    } else if (service.errorMessage != null) {
      return 'خطأ في التحديث';
    } else if (service.qiblaData != null) {
      return 'الاتجاه: ${service.qiblaData!.qiblaDirection.toStringAsFixed(1)}°';
    }
    return 'البوصلة الذكية';
  }

  Color _getStatusColor(QiblaServiceV2 service) {
    if (service.isLoading) return ThemeConstants.warning;
    if (service.errorMessage != null) return ThemeConstants.error;
    if (service.qiblaData != null) return context.primaryColor;
    return context.textSecondaryColor;
  }

  Widget _buildMainContent(QiblaServiceV2 service) {
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

  Widget _buildCompassView(QiblaServiceV2 service) {
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
              isCalibrated: true, // المعايرة تلقائية الآن
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
    return Container(
      constraints: BoxConstraints(
        minHeight: 220.h,
        maxHeight: 280.h,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.cardColor.withOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5.w,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحديد موقعك...',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'يرجى الانتظار لحظات قليلة',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(QiblaServiceV2 service) {
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
                color: ThemeConstants.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 36.sp,
                color: ThemeConstants.error,
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                service.errorMessage ?? 'فشل تحميل البيانات',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: ThemeConstants.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'تأكد من تفعيل الموقع والاتصال بالإنترنت',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _updateQiblaData(forceUpdate: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(Icons.refresh, size: 16.sp),
              label: Text(
                'إعادة المحاولة',
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

  Widget _buildNoCompassState(QiblaServiceV2 service) {
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
}