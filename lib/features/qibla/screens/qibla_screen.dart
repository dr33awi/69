// lib/features/qibla/screens/qibla_screen.dart - نسخة كاملة محسّنة
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/permissions/permission_service.dart';
import '../services/qibla_service.dart';
import '../widgets/qibla_compass.dart';
import '../widgets/qibla_info_card.dart';
import '../widgets/compass_calibration_sheet.dart';

/// شاشة القبلة
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  
  late final QiblaService _qiblaService;
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
      _qiblaService = QiblaService(
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

  void _startCalibration() async {
    if (_disposed) return;
    
    HapticFeedback.lightImpact();
    
    // Show calibration sheet
    showCompassCalibrationSheet(
      context: context,
      onStartCalibration: () async {
        await _qiblaService.startCalibration();
        
        // Show progress dialog with Provider
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => ChangeNotifierProvider.value(
              value: _qiblaService,
              child: CalibrationProgressDialog(
                onStartCalibration: () {}, // Already started
              ),
            ),
          ).then((_) {
            if (_qiblaService.isCalibrated) {
              _showSuccessSnackbar(_qiblaService.calibrationMessage);
            }
          });
        }
      },
      initialAccuracy: _qiblaService.compassAccuracy,
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeConstants.error,
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          onPressed: () => _updateQiblaData(forceUpdate: true),
          textColor: Colors.white,
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ThemeConstants.success,
        duration: const Duration(seconds: 2),
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
        child: Consumer<QiblaService>(
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 16.h),
                              _buildMainContent(service),
                              SizedBox(height: 24.h),
                              
                              if (service.qiblaData != null) ...[
                                QiblaInfoCard(qiblaData: service.qiblaData!),
                                SizedBox(height: 16.h),
                              ],
                              
                              SizedBox(height: 48.h),
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

  Widget _buildCustomAppBar(BuildContext context, QiblaService service) {
    const gradient = LinearGradient(
      colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // زر الرجوع
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 12.w),
          
          // أيقونة القبلة مع التدرج اللوني
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.explore_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // العنوان والحالة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اتجاه القبلة',
                  style: context.titleLarge?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: context.titleLarge?.fontSize?.sp,
                  ),
                ),
                Text(
                  _getStatusText(service),
                  style: context.bodySmall?.copyWith(
                    color: _getStatusColor(service),
                    fontSize: context.bodySmall?.fontSize?.sp,
                  ),
                ),
              ],
            ),
          ),
          
          // زر التحديث
          _buildActionButton(
            icon: service.isLoading
                ? Icons.hourglass_empty
                : Icons.refresh_rounded,
            onTap: service.isLoading 
                ? null 
                : () => _updateQiblaData(forceUpdate: true),
            isLoading: service.isLoading,
          ),
          
          // زر المعايرة
          _buildActionButton(
            icon: Icons.compass_calibration_outlined,
            onTap: _startCalibration,
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
      margin: EdgeInsets.only(left: 8.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.dividerColor.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isLoading
                ? SizedBox(
                    width: 24.sp,
                    height: 24.sp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primary),
                    ),
                  )
                : Icon(
                    icon,
                    color: isSecondary ? context.textSecondaryColor : ThemeConstants.primary,
                    size: 24.sp,
                  ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(QiblaService service) {
    if (service.isLoading) {
      return 'جاري التحديث...';
    } else if (service.errorMessage != null) {
      return 'خطأ في التحديث';
    } else if (service.qiblaData != null) {
      return 'الاتجاه: ${service.qiblaData!.qiblaDirection.toStringAsFixed(1)}°';
    }
    return 'البوصلة الذكية';
  }

  Color _getStatusColor(QiblaService service) {
    if (service.isLoading) return ThemeConstants.warning;
    if (service.errorMessage != null) return ThemeConstants.error;
    if (service.qiblaData != null) return context.primaryColor;
    return context.textSecondaryColor;
  }

  Widget _buildMainContent(QiblaService service) {
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

  Widget _buildCompassView(QiblaService service) {
    return SizedBox(
      height: 350.h,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: QiblaCompass(
              qiblaDirection: service.qiblaData!.qiblaDirection,
              currentDirection: service.currentDirection,
              accuracy: service.compassAccuracy,
              isCalibrated: service.isCalibrated,
              onCalibrate: _startCalibration,
            ),
          ),
          
          if (service.isLoading)
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: context.cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8.w),
                    const Text('تحديث...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 350.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200.w,
            height: 200.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.cardColor,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'جاري تحديد موقعك...',
            style: context.bodyLarge?.medium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(QiblaService service) {
    return SizedBox(
      height: 350.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: ThemeConstants.error,
            ),
            SizedBox(height: 16.h),
            Text(
              service.errorMessage ?? 'فشل تحميل البيانات',
              style: context.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _updateQiblaData(forceUpdate: true),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCompassState(QiblaService service) {
    return Container(
      height: 350.h,
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compass_calibration_outlined,
            size: 64.sp,
            color: Colors.amber[700],
          ),
          SizedBox(height: 16.h),
          Text(
            'البوصلة غير متوفرة',
            style: context.titleLarge?.bold,
          ),
          SizedBox(height: 8.h),
          const Text(
            'جهازك لا يدعم البوصلة. يمكنك استخدام اتجاه القبلة من موقعك.',
            textAlign: TextAlign.center,
          ),
          if (service.qiblaData != null) ...[
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Text(
                    'اتجاه القبلة: ${service.qiblaData!.qiblaDirection.toStringAsFixed(1)}°',
                    style: context.headlineMedium?.bold.textColor(context.primaryColor),
                  ),
                  Text(
                    service.qiblaData!.directionDescription,
                    style: context.bodyLarge,
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
    return SizedBox(
      height: 350.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching,
              size: 64.sp,
              color: ThemeConstants.primary,
            ),
            SizedBox(height: 16.h),
            Text(
              'حدد موقعك',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            const Text(
              'اضغط على زر التحديث لتحديد موقعك',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _updateQiblaData(forceUpdate: true),
              icon: const Icon(Icons.my_location),
              label: const Text('تحديد الموقع'),
            ),
          ],
        ),
      ),
    );
  }
}