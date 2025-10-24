// lib/features/prayer_times/screens/prayer_time_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/prayer_times_service.dart';
import '../models/prayer_time_model.dart';
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
  bool _isRefreshing = false;
  String? _errorMessage;
  
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
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
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
        _errorMessage = 'حدث خطأ في تحميل المواقيت';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestLocation() async {
    if (!mounted) return;
    
    try {
      await _prayerService.getCurrentLocation(forceUpdate: true);
      await _prayerService.updatePrayerTimes();
      
      if (mounted) {
        context.showSuccessSnackBar('تم تحديد الموقع وتحميل المواقيت بنجاح');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPrayerTimes() async {
    if (_isRefreshing || !mounted) return;
    
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });
    
    HapticFeedback.lightImpact();
    
    try {
      await _prayerService.getCurrentLocation(forceUpdate: true);
      await _prayerService.updatePrayerTimes();
      
      if (mounted) {
        context.showSuccessSnackBar('تم تحديث مواقيت الصلاة بنجاح');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحديث المواقيت';
        });
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
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppLoading.circular(size: LoadingSize.large),
                              SizedBox(height: 16.h),
                              Text(
                                'جاري تحميل مواقيت الصلاة...',
                                style: TextStyle(
                                  fontWeight: ThemeConstants.medium,
                                  color: context.textSecondaryColor,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_errorMessage != null && _dailyTimes == null)
                      SliverFillRemaining(
                        child: Center(
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
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                ElevatedButton.icon(
                                  onPressed: _loadPrayerTimes,
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
                        ),
                      )
                    else if (_dailyTimes != null)
                      ..._buildContent()
                    else
                      SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 64.sp,
                                  color: context.textSecondaryColor.withOpacity(0.5),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'لم يتم تحديد الموقع',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimaryColor,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'نحتاج لتحديد موقعك لعرض مواقيت الصلاة الصحيحة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                ElevatedButton.icon(
                                  onPressed: _requestLocation,
                                  icon: Icon(Icons.location_on, size: 20.sp),
                                  label: Text(
                                    'تحديد الموقع',
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 6.w),
          
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
            FlutterIslamicIcons.solidMosque,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
          
          SizedBox(width: 6.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مواقيت الصلاة',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 15.sp,
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
                    fontSize: 10.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
                  color: Colors.black.withOpacity(0.05),
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
                      strokeWidth: 1.5.w,
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
            padding: EdgeInsets.all(10.w),
            child: NextPrayerCountdown(
              nextPrayer: _nextPrayer!,
              currentPrayer: _dailyTimes!.currentPrayer,
            ),
          ),
        ),
      
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final prayer = _dailyTimes!.prayers[index];
              
              if (prayer.type == PrayerType.sunrise) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
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
        child: SizedBox(height: 16.h),
      ),
    ];
  }
}