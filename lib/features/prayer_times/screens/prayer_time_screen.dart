// lib/features/prayer_times/screens/prayer_time_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/prayer_times_service.dart';
import '../models/prayer_time_model.dart';
import '../utils/prayer_utils.dart';
import '../widgets/shared/prayer_state_widgets.dart';
import 'package:athkar_app/features/prayer_times/widgets/prayer_times_card.dart';
import '../widgets/next_prayer_countdown.dart';
import 'package:athkar_app/features/prayer_times/widgets/location_header.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late final PrayerTimesService _prayerService;
  
  final _scrollController = ScrollController();
  
  DailyPrayerTimes? _dailyTimes;
  PrayerTime? _nextPrayer;
  bool _isLoading = true;
  bool _isRetryingLocation = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  dynamic _lastError;
  
  StreamSubscription<DailyPrayerTimes>? _timesSubscription;
  StreamSubscription<PrayerTime?>? _nextPrayerSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadPrayerTimes();
  }

  void _initializeServices() {
    _prayerService = getIt<PrayerTimesService>();
    
    _timesSubscription = _prayerService.prayerTimesStream.listen(
      (times) {
        if (mounted) {
          setState(() {
            _dailyTimes = times;
            _isLoading = false;
            _isRefreshing = false;
            _errorMessage = null;
            _lastError = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _lastError = error;
            _errorMessage = PrayerUtils.getErrorMessage(error);
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      },
    );
    
    _nextPrayerSubscription = _prayerService.nextPrayerStream.listen(
      (prayer) {
        if (mounted) {
          setState(() {
            _nextPrayer = prayer;
          });
        }
      },
    );
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastError = null;
    });
    
    try {
      final cachedTimes = await _prayerService.getCachedPrayerTimes(DateTime.now());
      if (cachedTimes != null && mounted) {
        setState(() {
          _dailyTimes = cachedTimes;
          _nextPrayer = cachedTimes.nextPrayer;
          _isLoading = false;
        });
      }
      
      if (_prayerService.currentLocation == null) {
        await _requestLocation();
      } else {
        await _prayerService.updatePrayerTimes();
      }
    } catch (e) {
      setState(() {
        _lastError = e;
        _errorMessage = PrayerUtils.getErrorMessage(e);
        _isLoading = false;
      });
      
      debugPrint('خطأ في تحميل مواقيت الصلاة: $e');
    }
  }

  Future<void> _requestLocation() async {
    setState(() {
      _isRetryingLocation = true;
    });
    
    try {
      final location = await _prayerService.getCurrentLocation(forceUpdate: true);
      
      debugPrint('تم تحديد الموقع بنجاح: ${location.cityName}, ${location.countryName}');
      
      await _prayerService.updatePrayerTimes();
      
      if (mounted) {
        setState(() {
          _isRetryingLocation = false;
        });
        
        context.showSuccessSnackBar('تم تحديد الموقع وتحميل المواقيت بنجاح');
      }
    } catch (e) {
      debugPrint('فشل الحصول على الموقع: $e');
      
      if (mounted) {
        setState(() {
          _lastError = e;
          _errorMessage = PrayerUtils.getErrorMessage(e);
          _isLoading = false;
          _isRetryingLocation = false;
        });
        
        context.showErrorSnackBar(
          PrayerUtils.getErrorMessage(e),
          action: SnackBarAction(
            label: 'حاول مجدداً',
            onPressed: _requestLocation,
          ),
        );
      }
    }
  }

  Future<void> _refreshPrayerTimes() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
      _lastError = null;
    });
    
    HapticFeedback.lightImpact();
    
    try {
      await _prayerService.getCurrentLocation(forceUpdate: true);
      await _prayerService.updatePrayerTimes();
      
      if (mounted) {
        context.showSuccessSnackBar('تم تحديث مواقيت الصلاة بنجاح');
      }
    } catch (e) {
      debugPrint('فشل تحديث مواقيت الصلاة: $e');
      
      if (mounted) {
        setState(() {
          _lastError = e;
          _errorMessage = PrayerUtils.getErrorMessage(e);
        });
        context.showErrorSnackBar('فشل التحديث: ${PrayerUtils.getErrorMessage(e)}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timesSubscription?.cancel();
    _nextPrayerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshPrayerTimes,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (_isLoading && _dailyTimes == null)
                      const SliverFillRemaining(
                        child: PrayerLoadingWidget(
                          message: 'جاري تحميل مواقيت الصلاة...',
                        ),
                      )
                    else if (_errorMessage != null && _dailyTimes == null)
                      SliverFillRemaining(
                        child: PrayerErrorWidget(
                          error: _lastError,
                          onRetry: _loadPrayerTimes,
                          showSettings: true,
                        ),
                      )
                    else if (_dailyTimes != null)
                      ..._buildContent()
                    else
                      SliverFillRemaining(
                        child: PrayerEmptyWidget(
                          title: 'لم يتم تحديد الموقع',
                          message: 'نحتاج لتحديد موقعك لعرض مواقيت الصلاة الصحيحة',
                          icon: Icons.location_off,
                          actionText: 'تحديد الموقع',
                          onAction: _requestLocation,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    const gradient = LinearGradient(
      colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 8.w),
          
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withOpacity(0.3),
                  blurRadius: 6.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          
          SizedBox(width: 8.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مواقيت الصلاة',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 18.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _nextPrayer != null 
                      ? 'الصلاة التالية: ${_nextPrayer!.nameAr}'
                      : 'وَأَقِمِ الصَّلَاةَ لِذِكْرِي',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          _buildActionButton(
            icon: (_isRetryingLocation || _isRefreshing)
                ? Icons.hourglass_empty
                : Icons.my_location_rounded,
            onTap: (_isRetryingLocation || _isRefreshing) ? null : _requestLocation,
            isLoading: _isRetryingLocation || _isRefreshing,
          ),
          
          _buildActionButton(
            icon: Icons.notifications_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/prayer-notifications-settings');
            },
          ),
          
          _buildActionButton(
            icon: Icons.settings_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/prayer-settings');
            },
            isSecondary: true,
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
      margin: EdgeInsets.only(left: 6.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: context.dividerColor.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor: const AlwaysStoppedAnimation<Color>(ThemeConstants.primary),
                    ),
                  )
                : Icon(
                    icon,
                    color: isSecondary ? context.textSecondaryColor : ThemeConstants.primary,
                    size: 20.sp,
                  ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    return [
      SliverToBoxAdapter(
        child: LocationHeader(
          initialLocation: _dailyTimes?.location,
          showRefreshButton: true,
          onTap: _refreshPrayerTimes,
        ),
      ),
      
      if (_nextPrayer != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: NextPrayerCountdown(
              nextPrayer: _nextPrayer!,
              currentPrayer: _dailyTimes!.currentPrayer,
            ),
          ),
        ),
      
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final prayer = _dailyTimes!.prayers[index];
              
              if (prayer.type == PrayerType.sunrise) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: PrayerTimeCard(
                  prayer: prayer,
                  forceColored: true,
                ),
              );
            },
            childCount: _dailyTimes!.prayers.length,
          ),
        ),
      ),
      
      SliverToBoxAdapter(
        child: SizedBox(height: 20.h),
      ),
    ];
  }
}