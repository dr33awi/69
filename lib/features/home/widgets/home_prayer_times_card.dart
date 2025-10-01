// lib/features/home/widgets/home_prayer_times_card.dart - محدث مع flutter_screenutil

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../app/themes/app_theme.dart';
import '../../prayer_times/models/prayer_time_model.dart';
import '../../prayer_times/services/prayer_times_service.dart';
import '../../prayer_times/utils/prayer_utils.dart';
import '../../prayer_times/widgets/shared/prayer_state_widgets.dart';
import '../../../app/di/service_locator.dart';

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
      await _refreshPrayerTimes();
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastError = e;
          _isLoading = false;
        });
      }
    }
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
        context.showErrorSnackBar('فشل في تحديث المواقيت: ${PrayerUtils.getErrorMessage(e)}');
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
        borderRadius: BorderRadius.circular(24.r),
        gradient: PrayerUtils.getPrayerGradient(_nextPrayer?.type ?? PrayerType.fajr),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _navigateToPrayerTimes,
            borderRadius: BorderRadius.circular(24.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.w,
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Column(
                children: [
                  _buildCompactHeader(context),
                  SizedBox(height: 16.h),
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
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.mosque,
            color: Colors.white,
            size: 32.sp,
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
                    'الصلاة القادمة: ',
                    style: context.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    _nextPrayer?.nameAr ?? 'غير محدد',
                    style: context.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: ThemeConstants.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _nextPrayer != null 
                        ? PrayerUtils.formatTime(_nextPrayer!.time)
                        : '--:--',
                      style: context.titleSmall?.copyWith(
                        color: PrayerUtils.getPrayerColor(_nextPrayer?.type ?? PrayerType.fajr),
                        fontWeight: ThemeConstants.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.schedule_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      _nextPrayer != null
                        ? PrayerUtils.formatRemainingTime(_nextPrayer!.remainingTime)
                        : 'غير محدد',
                      style: context.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
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
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildSimplePrayerPoints(BuildContext context) {
    final prayers = _dailyTimes?.prayers.where((p) => p.type != PrayerType.sunrise).toList() ?? [];
    
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: isActive ? 32.w : 28.w,
              height: isActive ? 32.h : 28.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPassed || isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.w,
                ),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3 + (_pulseAnimation.value * 0.2)),
                    blurRadius: (4 + (_pulseAnimation.value * 6)).r,
                    spreadRadius: (1 + (_pulseAnimation.value * 1)).r,
                  ),
                ] : null,
              ),
              child: Center(
                child: Transform.scale(
                  scale: isActive ? 1.0 + (_pulseAnimation.value * 0.1) : 1.0,
                  child: Icon(
                    prayer.icon,
                    color: isPassed || isActive ? prayer.color : Colors.white,
                    size: isActive ? 16.sp : 14.sp,
                  ),
                ),
              ),
            );
          },
        ),
        
        SizedBox(height: 8.h),
        
        Text(
          prayer.nameAr,
          style: context.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.7),
            fontWeight: isActive ? ThemeConstants.semiBold : ThemeConstants.regular,
            fontSize: 11.sp,
          ),
        ),
        
        Text(
          prayer.formattedTime,
          style: context.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: isActive ? 0.9 : 0.6),
            fontSize: 9.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLoadingCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: const PrayerLoadingWidget(
        message: 'جاري تحميل مواقيت الصلاة...',
        isCompact: true,
      ),
    );
  }

  Widget _buildCompactErrorCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: ThemeConstants.error.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: PrayerErrorWidget(
        error: _lastError,
        onRetry: _retryLoadPrayerTimes,
        isCompact: true,
      ),
    );
  }

  Widget _buildCompactEmptyCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            color: context.textSecondaryColor,
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            'لا توجد بيانات مواقيت الصلاة',
            style: context.labelMedium?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          RetryButton(
            onRetry: _retryLoadPrayerTimes,
            text: 'تحديث',
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