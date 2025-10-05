// lib/features/tasbih/screens/tasbih_screen.dart - محسّن للشاشات الصغيرة
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/tasbih_service.dart';
import '../models/dhikr_model.dart';
import '../widgets/tasbih_bead_widget.dart';
import '../widgets/tasbih_counter_ring.dart';
import 'package:athkar_app/app/themes/widgets/core/islamic_pattern_painter.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with TickerProviderStateMixin {
  late TasbihService _service;
  late AnimationController _beadController;
  late AnimationController _rippleController;
  late AnimationController _rotationController;
  late Animation<double> _beadAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isPressed = false;
  DhikrItem _currentDhikr = DefaultAdhkar.getAll().first;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
  }

  void _initializeServices() {
    _service = TasbihService(
      storage: getIt<StorageService>(),
    );
    
    _service.startSession(_currentDhikr.text);
  }

  void _setupAnimations() {
    _beadController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _beadAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _beadController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotationController);
  }

  @override
  void dispose() {
    _service.endSession();
    
    _beadController.dispose();
    _rippleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _service,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: Stack(
          children: [
            _buildAnimatedBackground(),
            
            SafeArea(
              child: Column(
                children: [
                  _buildCustomAppBar(context),
                  
                  _buildDhikrSelector(),
                  
                  Expanded(
                    child: _buildMainTasbihArea(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: IslamicPatternPainter(
              rotation: _rotationAnimation.value,
              color: _currentDhikr.primaryColor.withOpacity(0.05),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 8.w),
          
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentDhikr.gradient,
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.radio_button_checked,
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
                  'المسبحة الرقمية',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  'اذكر الله كثيراً',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          
          Consumer<TasbihService>(
            builder: (context, service, _) {
              return Container(
                margin: EdgeInsets.only(left: 6.w),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    onTap: () => _showResetDialog(service),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: context.dividerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: ThemeConstants.error,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: _showDhikrSelectionModal,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _currentDhikr.gradient),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: _currentDhikr.primaryColor.withOpacity(0.25),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    _currentDhikr.category.icon,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                
                SizedBox(width: 10.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentDhikr.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 13.sp,
                          height: 1.3,
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Text(
                            _currentDhikr.category.title,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11.sp,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11.sp,
                            ),
                          ),
                          Text(
                            '${_currentDhikr.recommendedCount}×',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTasbihArea(BuildContext context) {
    return Consumer<TasbihService>(
      builder: (context, service, _) {
        final progress = (service.count % _currentDhikr.recommendedCount) / _currentDhikr.recommendedCount;
        
        return Container(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: size * 0.9,
                            height: size * 0.9,
                            child: TasbihCounterRing(
                              progress: progress,
                              gradient: _currentDhikr.gradient,
                              strokeWidth: 6.w,
                            ),
                          ),
                          
                          SizedBox(
                            width: size * 0.75,
                            height: size * 0.75,
                            child: TasbihCounterRing(
                              progress: service.count / 1000,
                              gradient: [
                                context.textSecondaryColor.withOpacity(0.2),
                                context.textSecondaryColor.withOpacity(0.1),
                              ],
                              strokeWidth: 3.w,
                            ),
                          ),
                          
                          AnimatedBuilder(
                            animation: _beadAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _beadAnimation.value,
                                child: GestureDetector(
                                  onTapDown: (_) {
                                    setState(() => _isPressed = true);
                                    _beadController.forward();
                                    HapticFeedback.lightImpact();
                                  },
                                  onTapUp: (_) {
                                    setState(() => _isPressed = false);
                                    _beadController.reverse();
                                    _incrementCounter(service);
                                  },
                                  onTapCancel: () {
                                    setState(() => _isPressed = false);
                                    _beadController.reverse();
                                  },
                                  child: TasbihBeadWidget(
                                    size: size * 0.6,
                                    gradient: _currentDhikr.gradient,
                                    isPressed: _isPressed,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${service.count}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: ThemeConstants.bold,
                                            fontSize: 32.sp,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(0.3),
                                                offset: Offset(0, 2.h),
                                                blurRadius: 4.r,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 3.h),
                                        Text(
                                          'اضغط للتسبيح',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          if (_isPressed)
                            AnimatedBuilder(
                              animation: _rippleAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: (size * 0.6) + (_rippleAnimation.value * 35.w),
                                  height: (size * 0.6) + (_rippleAnimation.value * 35.w),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _currentDhikr.primaryColor.withOpacity(
                                        (1 - _rippleAnimation.value) * 0.5,
                                      ),
                                      width: 1.5.w,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              
              SizedBox(height: 20.h),
              
              _buildProgressInfo(service, _currentDhikr),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressInfo(TasbihService service, DhikrItem currentDhikr) {
    final currentRound = service.count % currentDhikr.recommendedCount;
    final completedRounds = service.count ~/ currentDhikr.recommendedCount;
    
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildInfoItem(
              'الجولة الحالية',
              '$currentRound / ${currentDhikr.recommendedCount}',
              Icons.radio_button_checked,
              currentDhikr.primaryColor,
            ),
          ),
          
          Container(
            width: 1.w,
            height: 32.h,
            color: context.dividerColor,
          ),
          
          Expanded(
            child: _buildInfoItem(
              'الجولات',
              '$completedRounds',
              Icons.check_circle,
              ThemeConstants.success,
            ),
          ),
          
          Container(
            width: 1.w,
            height: 32.h,
            color: context.dividerColor,
          ),
          
          Expanded(
            child: _buildInfoItem(
              'اليوم',
              '${service.todayCount}',
              Icons.star,
              ThemeConstants.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 20.sp,
        ),
        SizedBox(height: 3.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: ThemeConstants.bold,
              fontSize: 13.sp,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 9.sp,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _incrementCounter(TasbihService service) {
    service.increment(dhikrType: _currentDhikr.text);
    
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
    
    if (service.count % _currentDhikr.recommendedCount == 0) {
      HapticFeedback.mediumImpact();
      _showCompletionCelebration(_currentDhikr);
    }
    
    debugPrint('[TasbihScreen] increment - count: ${service.count}, dhikr: ${_currentDhikr.text}');
  }

  void _showCompletionCelebration(DhikrItem dhikr) {
    context.showSuccessSnackBar(
      'تم إكمال جولة ${dhikr.category.title} 🎉',
    );
  }

  void _showResetDialog(TasbihService service) {
    AppInfoDialog.showConfirmation(
      context: context,
      title: 'تصفير العداد',
      content: 'هل أنت متأكد من أنك تريد تصفير العداد؟ سيتم فقدان العد الحالي.',
      confirmText: 'تصفير',
      cancelText: 'إلغاء',
      icon: Icons.refresh_rounded,
      destructive: true,
    ).then((confirmed) {
      if (confirmed == true) {
        service.reset();
        HapticFeedback.mediumImpact();
        context.showSuccessSnackBar(
          'تم تصفير العداد',
        );
      }
    });
  }
  
  void _showDhikrSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 10.h),
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            Container(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.list_alt_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر الذكر',
                          style: TextStyle(
                            fontWeight: ThemeConstants.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        Text(
                          'اختر الذكر الذي تريد تسبيحه',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: context.textSecondaryColor,
                      size: 22.sp,
                    ),
                    padding: EdgeInsets.all(6.r),
                    constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                  ),
                ],
              ),
            ),
            
            Flexible(
              child: _buildDhikrCategoriesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDhikrCategoriesList() {
    final Map<DhikrCategory, List<DhikrItem>> categorizedAdhkar = {};
    
    for (final dhikr in DefaultAdhkar.getAll()) {
      if (!categorizedAdhkar.containsKey(dhikr.category)) {
        categorizedAdhkar[dhikr.category] = [];
      }
      categorizedAdhkar[dhikr.category]!.add(dhikr);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.r),
      itemCount: categorizedAdhkar.keys.length,
      itemBuilder: (context, index) {
        final category = categorizedAdhkar.keys.elementAt(index);
        final adhkar = categorizedAdhkar[category]!;
        
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeConstants.primary.withOpacity(0.1),
                      ThemeConstants.primaryLight.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: ThemeConstants.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      category.icon,
                      color: ThemeConstants.primary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      category.title,
                      style: TextStyle(
                        color: ThemeConstants.primary,
                        fontWeight: ThemeConstants.semiBold,
                        fontSize: 14.sp,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: ThemeConstants.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${adhkar.length}',
                        style: TextStyle(
                          color: ThemeConstants.primary,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 10.h),
              
              ...adhkar.map((dhikr) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _service.endSession();
                        _currentDhikr = dhikr;
                        _service.startSession(dhikr.text);
                      });
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();
                      context.showSuccessSnackBar(
                        'تم تغيير الذكر إلى: ${dhikr.text}',
                      );
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: _currentDhikr.id == dhikr.id 
                            ? dhikr.primaryColor.withOpacity(0.1)
                            : context.cardColor,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: _currentDhikr.id == dhikr.id 
                              ? dhikr.primaryColor.withOpacity(0.3)
                              : context.dividerColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: dhikr.gradient),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              dhikr.category.icon,
                              color: Colors.white,
                              size: 14.sp,
                            ),
                          ),
                          
                          SizedBox(width: 10.w),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dhikr.text,
                                  style: TextStyle(
                                    fontWeight: _currentDhikr.id == dhikr.id 
                                        ? ThemeConstants.semiBold 
                                        : ThemeConstants.regular,
                                    color: _currentDhikr.id == dhikr.id 
                                        ? dhikr.primaryColor
                                        : context.textPrimaryColor,
                                    fontSize: 12.sp,
                                    height: 1.4,
                                  ),
                                  maxLines: null,
                                  overflow: TextOverflow.visible,
                                ),
                                
                                if (dhikr.virtue != null) ...[
                                  SizedBox(height: 6.h),
                                  Container(
                                    padding: EdgeInsets.all(6.r),
                                    decoration: BoxDecoration(
                                      color: _currentDhikr.id == dhikr.id 
                                          ? dhikr.primaryColor.withOpacity(0.1)
                                          : ThemeConstants.accent.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: _currentDhikr.id == dhikr.id 
                                            ? dhikr.primaryColor.withOpacity(0.2)
                                            : ThemeConstants.accent.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 11.sp,
                                          color: _currentDhikr.id == dhikr.id 
                                              ? dhikr.primaryColor
                                              : ThemeConstants.accent,
                                        ),
                                        SizedBox(width: 5.w),
                                        Expanded(
                                          child: Text(
                                            dhikr.virtue!,
                                            style: TextStyle(
                                              color: context.textSecondaryColor,
                                              fontSize: 10.sp,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          SizedBox(width: 10.w),
                          
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: dhikr.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '${dhikr.recommendedCount}×',
                              style: TextStyle(
                                color: dhikr.primaryColor,
                                fontWeight: ThemeConstants.semiBold,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          
                          if (_currentDhikr.id == dhikr.id) ...[
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.check_circle,
                              color: dhikr.primaryColor,
                              size: 18.sp,
                            ),
                          ] else ...[
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.radio_button_unchecked,
                              color: context.textSecondaryColor.withOpacity(0.3),
                              size: 18.sp,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}