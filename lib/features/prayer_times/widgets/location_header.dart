// 4. location_header.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../models/prayer_time_model.dart';
import '../services/prayer_times_service.dart';
import '../utils/prayer_utils.dart';
import 'shared/prayer_state_widgets.dart';

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
  }

  Future<void> _updateLocation() async {
    if (_isUpdating) return;
    
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
        context.showErrorSnackBar('فشل تحديث الموقع: ${PrayerUtils.getErrorMessage(e)}');
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
    
    return Container(
      margin: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasError 
            ? ThemeConstants.error.withOpacity(0.3)
            : context.dividerColor.withOpacity(0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: widget.showRefreshButton ? _updateLocation : widget.onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              children: [
                Row(
                  children: [
                    // أيقونة الموقع
                    Container(
                      width: 45.r,
                      height: 45.r,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: hasError
                            ? [ThemeConstants.error, ThemeConstants.error.darken(0.1)]
                            : [context.primaryColor, context.primaryColor.darken(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: (hasError ? ThemeConstants.error : context.primaryColor)
                                .withOpacity(0.3),
                            blurRadius: 6.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        hasError ? Icons.location_off_rounded : Icons.location_on_rounded,
                        color: Colors.white,
                        size: 26.sp,
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
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
                                  style: context.titleLarge?.copyWith(
                                    fontWeight: ThemeConstants.bold,
                                    color: hasError 
                                      ? ThemeConstants.error 
                                      : context.textPrimaryColor,
                                    fontSize: 15.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (_isUpdating) ...[
                                SizedBox(width: 6.w),
                                RotationTransition(
                                  turns: _refreshAnimationController,
                                  child: Icon(
                                    Icons.refresh,
                                    size: 16.sp,
                                    color: context.primaryColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          SizedBox(height: 3.h),
                          
                          if (hasError)
                            Text(
                              PrayerUtils.getErrorMessage(_lastError),
                              style: context.bodyMedium?.copyWith(
                                color: ThemeConstants.error,
                                fontWeight: ThemeConstants.medium,
                                fontSize: 11.sp,
                              ),
                            )
                          else
                            Text(
                              _getCoordinatesText(),
                              style: context.bodyMedium?.copyWith(
                                color: context.textSecondaryColor,
                                fontSize: 11.sp,
                              ),
                            ),
                          
                          if (_currentLocation?.timezone != null && !hasError) ...[
                            SizedBox(height: 3.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 11.sp,
                                  color: context.textSecondaryColor,
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  _currentLocation!.timezone,
                                  style: context.bodySmall?.copyWith(
                                    color: context.textSecondaryColor,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    if (widget.showRefreshButton) ...[
                      SizedBox(width: 10.w),
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: (hasError ? ThemeConstants.error : context.primaryColor)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: (hasError ? ThemeConstants.error : context.primaryColor)
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          _isUpdating 
                            ? Icons.hourglass_empty 
                            : (hasError ? Icons.error_outline : Icons.refresh_rounded),
                          color: hasError ? ThemeConstants.error : context.primaryColor,
                          size: 20.sp,
                        ),
                      ),
                    ],
                  ],
                ),
                
                if (hasError) ...[
                  SizedBox(height: 10.h),
                  RetryButton(
                    onRetry: _updateLocation,
                    isLoading: _isUpdating,
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