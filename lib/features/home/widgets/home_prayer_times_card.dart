// lib/features/home/widgets/home_prayer_times_card.dart - محسن مع نظام الأذونات الموحد

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/permissions/simple_permission_extensions.dart';
import '../../../core/infrastructure/services/permissions/widgets/permission_warning_card.dart';
import '../../prayer_times/models/prayer_time_model.dart';
import '../../prayer_times/services/prayer_times_service.dart';
import '../../prayer_times/utils/prayer_utils.dart';

class PrayerTimesCard extends StatefulWidget {
  const PrayerTimesCard({super.key});

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  late PrayerTimesService _prayerTimesService;
  DailyPrayerTimes? _dailyTimes;
  PrayerTime? _nextPrayer;
  dynamic _lastError;
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  
  StreamSubscription<DailyPrayerTimes>? _timesSubscription;
  StreamSubscription<PrayerTime?>? _nextPrayerSubscription;

  @override
  void initState() {
    super.initState();
    _prayerTimesService = getService<PrayerTimesService>();
    _setupAnimations();
    _initializePrayerTimes();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializePrayerTimes() async {
    setState(() {
      _isLoading = true;
      _lastError = null;
    });

    // التحقق من إذن الموقع أولاً
    await _checkLocationPermission();

    try {
      final cachedTimes = await _prayerTimesService.getCachedPrayerTimes(DateTime.now());
      
      if (cachedTimes != null && mounted) {
        setState(() {
          _dailyTimes = cachedTimes.updatePrayerStates();
          _nextPrayer = _dailyTimes?.nextPrayer;
          _isLoading = false;
        });
      }
      
      _setupStreamListeners();
      
      // فقط إذا كان الإذن ممنوحاً
      if (_hasLocationPermission) {
        await _refreshPrayerTimes();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = e;
          _isLoading = false;
        });
      }
    }
  }

  /// التحقق من إذن الموقع
  Future<void> _checkLocationPermission() async {
    final hasPermission = await context.checkLocationPermission();
    if (mounted) {
      setState(() {
        _hasLocationPermission = hasPermission;
      });
    }
  }

  /// طلب إذن الموقع باستخدام النظام الموحد
  Future<bool> _requestLocationPermission() async {
    final granted = await context.requestPermissionWithMessages(
      requestFunction: () => context.requestLocationPermission(),
      permissionName: 'الموقع',
    );
    
    if (mounted) {
      setState(() {
        _hasLocationPermission = granted;
      });
    }
    
    return granted;
  }

  void _setupStreamListeners() {
    _timesSubscription?.cancel();
    _nextPrayerSubscription?.cancel();
    
    _timesSubscription = _prayerTimesService.prayerTimesStream.listen(
      (times) {
        if (mounted) {
          setState(() {
            _dailyTimes = times;
            _nextPrayer = times.nextPrayer;
            _isLoading = false;
            _lastError = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _lastError = error;
            _isLoading = false;
          });
        }
      },
    );
    
    _nextPrayerSubscription = _prayerTimesService.nextPrayerStream.listen(
      (prayer) {
        if (mounted) {
          setState(() {
            _nextPrayer = prayer;
          });
        }
      },
    );
  }

  Future<void> _refreshPrayerTimes() async {
    // التحقق من الإذن قبل المتابعة
    if (!_hasLocationPermission) {
      final granted = await _requestLocationPermission();
      if (!granted) {
        return;
      }
    }

    try {
      if (_prayerTimesService.currentLocation == null) {
        await _prayerTimesService.getCurrentLocation(forceUpdate: true);
      }
      await _prayerTimesService.updatePrayerTimes();
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = e;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _retryLoadPrayerTimes() async {
    setState(() {
      _lastError = null;
    });
    
    HapticFeedback.lightImpact();
    
    // التحقق من الإذن أولاً
    if (!_hasLocationPermission) {
      final granted = await _requestLocationPermission();
      if (!granted) {
        return;
      }
    }
    
    try {
      await _prayerTimesService.getCurrentLocation(forceUpdate: true);
      await _prayerTimesService.updatePrayerTimes();
      
      if (mounted) {
        context.showSuccessSnackBar('تم تحديث مواقيت الصلاة بنجاح');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = e;
        });
        context.showErrorSnackBar('فشل في تحديث المواقيت');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timesSubscription?.cancel();
    _nextPrayerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // عرض بطاقة الإذن إذا لم يكن ممنوحاً - استخدام Widget الموحد
    if (!_hasLocationPermission && !_isLoading) {
      return PermissionWarningCard.location(
        onGrantPermission: () async {
          final granted = await _requestLocationPermission();
          if (granted && mounted) {
            _initializePrayerTimes();
          }
        },
        margin: EdgeInsets.symmetric(horizontal: 12.w),
        padding: EdgeInsets.all(14.w),
        isCompact: true,
      );
    }
    
    if (_isLoading && _dailyTimes == null) {
      return _buildCompactLoadingCard(context);
    }
    
    if (_lastError != null && _dailyTimes == null) {
      return _buildCompactErrorCard(context);
    }
    
    if (_dailyTimes == null) {
      return _buildCompactEmptyCard(context);
    }

    return _buildPrayerCard(context);
  }

  Widget _buildPrayerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: PrayerUtils.getPrayerGradient(_nextPrayer?.type ?? PrayerType.fajr),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navigateToPrayerTimes,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.w,
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                children: [
                  _buildCompactHeader(context),
                  SizedBox(height: 10.h),
                  _buildSimplePrayerPoints(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            FlutterIslamicIcons.solidMosque,
            color: Colors.white,
            size: 18.sp,
          ),
        ),
        
        SizedBox(width: 10.w),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'التالية: ',
                    style: context.labelMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11.sp,
                    ),
                  ),
                  Text(
                    _nextPrayer?.nameAr ?? 'غير محدد',
                    style: context.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: ThemeConstants.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      _nextPrayer != null 
                        ? PrayerUtils.formatTime(_nextPrayer!.time)
                        : '--:--',
                      style: context.titleSmall?.copyWith(
                        color: PrayerUtils.getPrayerColor(_nextPrayer?.type ?? PrayerType.fajr),
                        fontWeight: ThemeConstants.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.schedule_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 14.sp,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      _nextPrayer != null
                        ? PrayerUtils.formatRemainingTime(_nextPrayer!.remainingTime)
                        : 'غير محدد',
                      style: context.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: ThemeConstants.semiBold,
                        fontSize: 11.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildSimplePrayerPoints(BuildContext context) {
    final prayers = _dailyTimes?.prayers.where((p) => p.type != PrayerType.sunrise).toList() ?? [];
    
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: prayers.map((prayer) => 
          _buildSimpleTimePoint(context, prayer)
        ).toList(),
      ),
    );
  }

  Widget _buildSimpleTimePoint(BuildContext context, PrayerTime prayer) {
    final isActive = prayer.isNext;
    final isPassed = prayer.isPassed;
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: isActive ? 24.r : 22.r,
                height: isActive ? 24.r : 22.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassed || isActive 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.4),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.w,
                  ),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(
                        0.3 + (_pulseAnimation.value * 0.2)
                      ),
                      blurRadius: (3 + (_pulseAnimation.value * 4)).r,
                      spreadRadius: (1 + (_pulseAnimation.value * 0.5)).r,
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Transform.scale(
                    scale: isActive ? 1.0 + (_pulseAnimation.value * 0.1) : 1.0,
                    child: Icon(
                      prayer.icon,
                      color: isPassed || isActive ? prayer.color : Colors.white,
                      size: isActive ? 12.sp : 11.sp,
                    ),
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: 4.h),
          
          Text(
            prayer.nameAr,
            style: context.labelSmall?.copyWith(
              color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
              fontWeight: isActive ? ThemeConstants.bold : ThemeConstants.medium,
              fontSize: 10.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          Text(
            prayer.formattedTime,
            style: context.labelSmall?.copyWith(
              color: Colors.white.withOpacity(isActive ? 0.9 : 0.6),
              fontWeight: ThemeConstants.semiBold,
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLoadingCard(BuildContext context) {
    return Container(
      height: 140.h,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24.r,
            height: 24.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'جاري تحميل مواقيت الصلاة...',
            style: context.labelMedium?.copyWith(
              color: context.textSecondaryColor,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactErrorCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: ThemeConstants.error.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: ThemeConstants.error,
                size: 20.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'حدث خطأ في تحميل المواقيت',
                  style: context.bodySmall?.copyWith(
                    color: ThemeConstants.error,
                    fontSize: 11.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 28.h,
            child: ElevatedButton(
              onPressed: _retryLoadPrayerTimes,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEmptyCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off,
            color: context.textSecondaryColor,
            size: 28.sp,
          ),
          SizedBox(height: 6.h),
          Text(
            'لا توجد بيانات مواقيت الصلاة',
            style: context.labelMedium?.copyWith(
              color: context.textSecondaryColor,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 28.h,
            child: ElevatedButton.icon(
              onPressed: _retryLoadPrayerTimes,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(Icons.refresh, size: 14.sp),
              label: Text(
                'تحديث',
                style: TextStyle(fontSize: 11.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPrayerTimes() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/prayer-times');
  }
}