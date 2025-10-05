// lib/features/home/widgets/special_event_card.dart
// كارد المناسبات الإسلامية والوطنية

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/infrastructure/firebase/remote_config_service.dart';
import '../../../app/themes/app_theme.dart';

final GetIt getIt = GetIt.instance;

/// كارد المناسبات الخاصة - يظهر في المناسبات الإسلامية والوطنية
class SpecialEventCard extends StatefulWidget {
  const SpecialEventCard({super.key});

  @override
  State<SpecialEventCard> createState() => _SpecialEventCardState();
}

class _SpecialEventCardState extends State<SpecialEventCard> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // بيانات المناسبة من Firebase
  bool _isEventActive = false;
  String _eventTitle = '';
  String _eventDescription = '';
  String _eventIcon = '🌙'; // emoji أو رمز
  String _eventBackgroundImage = '';
  List<Color> _eventGradientColors = [Colors.purple, Colors.deepPurple];
  String _eventActionText = '';
  String _eventActionUrl = '';
  DateTime? _eventStartDate;
  DateTime? _eventEndDate;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _loadEventData();
  }
  
  /// جلب بيانات المناسبة من Firebase Remote Config
  Future<void> _loadEventData() async {
    try {
      if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final remoteConfig = getIt<FirebaseRemoteConfigService>();
        
        if (remoteConfig.isInitialized) {
          final eventData = remoteConfig.specialEventData;
          
          if (eventData != null && eventData['is_active'] == true) {
            setState(() {
              _isEventActive = true;
              _eventTitle = eventData['title'] ?? '';
              _eventDescription = eventData['description'] ?? '';
              _eventIcon = eventData['icon'] ?? '🌙';
              _eventBackgroundImage = eventData['background_image'] ?? '';
              _eventActionText = eventData['action_text'] ?? '';
              _eventActionUrl = eventData['action_url'] ?? '';
              
              // تحليل الألوان
              if (eventData['gradient_colors'] != null) {
                final colors = eventData['gradient_colors'] as List;
                _eventGradientColors = colors.map((colorHex) {
                  return Color(int.parse(colorHex.toString().replaceAll('#', '0xFF')));
                }).toList();
              }
              
              // تحليل التواريخ
              if (eventData['start_date'] != null) {
                _eventStartDate = DateTime.parse(eventData['start_date']);
              }
              if (eventData['end_date'] != null) {
                _eventEndDate = DateTime.parse(eventData['end_date']);
              }
              
              // التحقق من صلاحية التاريخ
              final now = DateTime.now();
              if (_eventStartDate != null && _eventEndDate != null) {
                _isEventActive = now.isAfter(_eventStartDate!) && 
                                now.isBefore(_eventEndDate!);
              }
            });
            
            if (_isEventActive) {
              _animationController.forward();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading event data: $e');
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // لا نعرض الكارد إذا لم تكن هناك مناسبة نشطة
    if (!_isEventActive || _eventTitle.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 10.h,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20.r),
            child: InkWell(
              onTap: _handleCardTap,
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                height: 180.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _eventGradientColors,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: _eventGradientColors.first.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  image: _eventBackgroundImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_eventBackgroundImage),
                        fit: BoxFit.cover,
                        opacity: 0.3,
                      )
                    : null,
                ),
                child: Stack(
                  children: [
                    // نقاط زخرفية
                    _buildDecorativeElements(),
                    
                    // المحتوى الرئيسي
                    Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              // الأيقونة
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  _eventIcon,
                                  style: TextStyle(fontSize: 24.sp),
                                ),
                              ),
                              
                              SizedBox(width: 16.w),
                              
                              // النص
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _eventTitle,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Cairo',
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    SizedBox(height: 4.h),
                                    
                                    Text(
                                      _eventDescription,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontFamily: 'Cairo',
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          if (_eventActionText.isNotEmpty) ...[
                            SizedBox(height: 16.h),
                            
                            // زر الإجراء
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(25.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _eventActionText,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // شارة "جديد" أو "مناسبة خاصة"
                    Positioned(
                      top: 12.h,
                      left: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'مناسبة خاصة',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// عناصر زخرفية
  Widget _buildDecorativeElements() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _EventCardPainter(),
      ),
    );
  }
  
  /// معالج النقر على الكارد
  void _handleCardTap() async {
    HapticFeedback.lightImpact();
    
    if (_eventActionUrl.isNotEmpty) {
      try {
        final Uri url = Uri.parse(_eventActionUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Error launching URL: $e');
        // يمكن عرض صفحة داخلية بدلاً من ذلك
        _showEventDetails();
      }
    } else {
      _showEventDetails();
    }
  }
  
  /// عرض تفاصيل المناسبة
  void _showEventDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(25.r),
          ),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            Text(
              _eventIcon,
              style: TextStyle(fontSize: 48.sp),
            ),
            
            SizedBox(height: 16.h),
            
            Text(
              _eventTitle,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            
            SizedBox(height: 12.h),
            
            Text(
              _eventDescription,
              style: TextStyle(
                fontSize: 14.sp,
                color: context.textSecondaryColor,
                fontFamily: 'Cairo',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 24.h),
            
            // يمكن إضافة أدعية أو أذكار خاصة بالمناسبة هنا
          ],
        ),
      ),
    );
  }
}

/// رسام العناصر الزخرفية
class _EventCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    // دوائر زخرفية
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.2),
      30,
      paint,
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      20,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}