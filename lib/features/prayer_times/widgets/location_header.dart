// lib/features/prayer_times/widgets/location_header.dart - محسن مع نظام الأذونات الموحد

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/permissions/simple_permission_service.dart';
import '../models/prayer_time_model.dart';
import '../services/prayer_times_service.dart';

class LocationHeader extends StatefulWidget {
  final PrayerLocation? initialLocation;
  final VoidCallback? onTap;
  final bool showRefreshButton;

  const LocationHeader({
    super.key,
    this.initialLocation,
    this.onTap,
    this.showRefreshButton = true,
  });

  @override
  State<LocationHeader> createState() => _LocationHeaderState();
}

class _LocationHeaderState extends State<LocationHeader>
    with SingleTickerProviderStateMixin {
  late final PrayerTimesService _prayerService;
  late AnimationController _refreshAnimationController;
  
  PrayerLocation? _currentLocation;
  bool _isUpdating = false;
  bool _hasLocationPermission = false;
  dynamic _lastError;

  @override
  void initState() {
    super.initState();
    _prayerService = getIt<PrayerTimesService>();
    _currentLocation = widget.initialLocation ?? _prayerService.currentLocation;
    
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _prayerService.prayerTimesStream.listen((times) {
      if (mounted && times.location != _currentLocation) {
        setState(() {
          _currentLocation = times.location;
          _lastError = null;
        });
      }
    });
    
    // التحقق من إذن الموقع
    _checkLocationPermission();
  }

  /// التحقق من إذن الموقع
  Future<void> _checkLocationPermission() async {
    try {
      final permissionService = getIt<SimplePermissionService>();
      final hasPermission = await permissionService.checkLocationPermission();
      
      if (mounted) {
        setState(() {
          _hasLocationPermission = hasPermission;
        });
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      if (mounted) {
        setState(() {
          _hasLocationPermission = false;
        });
      }
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
                    'إذن الموقع مطلوب لتحديد موقعك',
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

  Future<void> _updateLocation() async {
    if (_isUpdating || !mounted) return;
    
    // التحقق من الإذن أولاً
    if (!await _checkAndRequestLocationPermission()) {
      return;
    }
    
    setState(() {
      _isUpdating = true;
      _lastError = null;
    });
    
    _refreshAnimationController.repeat();
    
    try {
      HapticFeedback.lightImpact();
      
      final newLocation = await _prayerService.getCurrentLocation(forceUpdate: true);
      
      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
        });
        
        await _prayerService.updatePrayerTimes();

        if (!mounted) return;
        context.showSuccessSnackBar('تم تحديث الموقع بنجاح');
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = e;
        });
        context.showErrorSnackBar('فشل تحديث الموقع');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
      }
    }
    
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _lastError != null;
    final needsPermission = !_hasLocationPermission && !_isUpdating;
    
    return Container(
      margin: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasError 
            ? ThemeConstants.error.withOpacity(0.3)
            : needsPermission
              ? ThemeConstants.warning.withOpacity(0.3)
              : context.dividerColor.withOpacity(0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: widget.showRefreshButton ? _updateLocation : widget.onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              children: [
                Row(
                  children: [
                    // أيقونة الموقع
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: hasError
                            ? [ThemeConstants.error, ThemeConstants.error.darken(0.1)]
                            : needsPermission
                              ? [ThemeConstants.warning, ThemeConstants.warning.darken(0.1)]
                              : [context.primaryColor, context.primaryColor.darken(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: (hasError 
                                ? ThemeConstants.error 
                                : needsPermission
                                  ? ThemeConstants.warning
                                  : context.primaryColor)
                                .withOpacity(0.3),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        hasError 
                          ? Icons.location_off_rounded 
                          : needsPermission
                            ? Icons.location_disabled_rounded
                            : Icons.location_on_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                    
                    SizedBox(width: 10.w),
                    
                    // معلومات الموقع
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getLocationDisplayName(),
                                  style: TextStyle(
                                    fontWeight: ThemeConstants.bold,
                                    color: hasError 
                                      ? ThemeConstants.error 
                                      : needsPermission
                                        ? ThemeConstants.warning
                                        : context.textPrimaryColor,
                                    fontSize: 13.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (_isUpdating) ...[
                                SizedBox(width: 4.w),
                                RotationTransition(
                                  turns: _refreshAnimationController,
                                  child: Icon(
                                    Icons.refresh,
                                    size: 14.sp,
                                    color: context.primaryColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          SizedBox(height: 2.h),
                          
                          if (hasError)
                            Text(
                              'حدث خطأ في تحديد الموقع',
                              style: TextStyle(
                                color: ThemeConstants.error,
                                fontWeight: ThemeConstants.medium,
                                fontSize: 10.sp,
                              ),
                            )
                          else if (needsPermission)
                            Text(
                              'يتطلب إذن الوصول إلى الموقع',
                              style: TextStyle(
                                color: ThemeConstants.warning,
                                fontWeight: ThemeConstants.medium,
                                fontSize: 10.sp,
                              ),
                            )
                          else
                            Text(
                              _getCoordinatesText(),
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 10.sp,
                              ),
                            ),
                          
                          if (_currentLocation?.timezone != null && !hasError && !needsPermission) ...[
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 10.sp,
                                  color: context.textSecondaryColor,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  _currentLocation!.timezone,
                                  style: TextStyle(
                                    color: context.textSecondaryColor,
                                    fontSize: 9.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    if (widget.showRefreshButton) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: (hasError 
                              ? ThemeConstants.error 
                              : needsPermission
                                ? ThemeConstants.warning
                                : context.primaryColor)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: (hasError 
                                ? ThemeConstants.error 
                                : needsPermission
                                  ? ThemeConstants.warning
                                  : context.primaryColor)
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          _isUpdating 
                            ? Icons.hourglass_empty 
                            : hasError 
                              ? Icons.error_outline
                              : needsPermission
                                ? Icons.lock_outline
                                : Icons.refresh_rounded,
                          color: hasError 
                            ? ThemeConstants.error 
                            : needsPermission
                              ? ThemeConstants.warning
                              : context.primaryColor,
                          size: 18.sp,
                        ),
                      ),
                    ],
                  ],
                ),
                
                if (hasError || needsPermission) ...[
                  SizedBox(height: 8.h),
                  ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _updateLocation,
                    icon: _isUpdating
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.w,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            needsPermission ? Icons.lock_open : Icons.refresh,
                            size: 18.sp,
                          ),
                    label: Text(
                      _isUpdating 
                        ? 'جاري المحاولة...' 
                        : needsPermission
                          ? 'منح إذن الموقع'
                          : 'إعادة المحاولة',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: needsPermission 
                        ? ThemeConstants.warning
                        : ThemeConstants.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLocationDisplayName() {
    if (_isUpdating) {
      return 'جاري تحديد الموقع...';
    }
    
    if (_lastError != null) {
      return 'خطأ في تحديد الموقع';
    }
    
    if (!_hasLocationPermission) {
      return 'يتطلب إذن الموقع';
    }
    
    if (_currentLocation == null) {
      return 'جاري تحديد الموقع...';
    }
    
    final city = _currentLocation!.cityName;
    final country = _currentLocation!.countryName;
    
    if (city != null && country != null && city != 'غير معروف' && country != 'غير معروف') {
      return '$city، $country';
    } else if (city != null && city != 'غير معروف') {
      return city;
    } else if (country != null && country != 'غير معروف') {
      return country;
    } else {
      return 'موقع غير محدد';
    }
  }

  String _getCoordinatesText() {
    if (_currentLocation == null) {
      return 'جاري تحديد الإحداثيات...';
    }
    
    return 'خط العرض: ${_currentLocation!.latitude.toStringAsFixed(4)}° • '
          'خط الطول: ${_currentLocation!.longitude.toStringAsFixed(4)}°';
  }
}