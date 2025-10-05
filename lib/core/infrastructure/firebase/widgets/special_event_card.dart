// lib/core/infrastructure/firebase/widgets/special_event_card.dart
// كارد المناسبات الإسلامية والوطنية - نسخة بدون أنيميشن

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get_it/get_it.dart';
import '../../../../app/themes/app_theme.dart';
import '../remote_config_service.dart';
import '../remote_config_manager.dart';

// الحصول على GetIt instance
final GetIt _getIt = GetIt.instance;

/// كارد المناسبات الخاصة - يظهر في المناسبات الإسلامية والوطنية حسب التاريخ
class SpecialEventCard extends StatefulWidget {
  const SpecialEventCard({super.key});

  @override
  State<SpecialEventCard> createState() => _SpecialEventCardState();
}

class _SpecialEventCardState extends State<SpecialEventCard> {
  
  // بيانات المناسبة من Firebase
  bool _isEventActive = false;
  String _eventTitle = '';
  String _eventDescription = '';
  String _eventIcon = '🌙';
  String _eventBackgroundImage = '';
  List<Color> _eventGradientColors = [Colors.purple, Colors.deepPurple];
  String _eventActionText = '';
  String _eventActionUrl = '';
  DateTime? _eventStartDate;
  DateTime? _eventEndDate;
  
  // حالة التحميل
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    // بدء تحميل البيانات
    _loadEventData();
  }
  
  /// جلب بيانات المناسبة من Firebase Remote Config
  Future<void> _loadEventData() async {
    try {
      debugPrint('🎉 [SpecialEventCard] Loading event data...');
      
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      // محاولة الحصول على البيانات من مصادر متعددة
      Map<String, dynamic>? eventData = await _fetchEventData();
      
      // معالجة البيانات
      if (eventData != null && eventData['is_active'] == true) {
        debugPrint('📅 [SpecialEventCard] Found active event data');
        
        // البيانات الأساسية
        _eventTitle = eventData['title']?.toString() ?? '';
        _eventDescription = eventData['description']?.toString() ?? '';
        _eventIcon = eventData['icon']?.toString() ?? '🌙';
        _eventBackgroundImage = eventData['background_image']?.toString() ?? '';
        _eventActionText = eventData['action_text']?.toString() ?? '';
        _eventActionUrl = eventData['action_url']?.toString() ?? '';
        
        // تحليل الألوان
        _parseGradientColors(eventData);
        
        // تحليل التواريخ
        _parseDates(eventData);
        
        // التحقق النهائي من الصلاحية
        _isEventActive = _validateEventData();
        
        setState(() {
          _isLoading = false;
        });
        
        if (_isEventActive) {
          _logEventDetails();
          debugPrint('✅ [SpecialEventCard] Event card activated: $_eventTitle');
        } else {
          debugPrint('⚠️ [SpecialEventCard] Event data invalid or out of date range');
        }
      } else {
        debugPrint('ℹ️ [SpecialEventCard] No active special event or is_active is false');
        setState(() {
          _isEventActive = false;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [SpecialEventCard] Error loading event data: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isEventActive = false;
      });
    }
  }
  
  /// جلب البيانات من المصادر المختلفة
  Future<Map<String, dynamic>?> _fetchEventData() async {
    Map<String, dynamic>? eventData;
    
    // 1. محاولة من FirebaseRemoteConfigService مباشرة
    try {
      if (_getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final remoteConfig = _getIt<FirebaseRemoteConfigService>();
        if (remoteConfig.isInitialized) {
          eventData = remoteConfig.specialEventData;
          if (eventData != null) {
            debugPrint('✅ Got event data from FirebaseRemoteConfigService');
            return eventData;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get from FirebaseRemoteConfigService: $e');
    }
    
    // 2. محاولة من RemoteConfigManager
    try {
      if (_getIt.isRegistered<RemoteConfigManager>()) {
        final manager = _getIt<RemoteConfigManager>();
        if (manager.isInitialized) {
          if (_getIt.isRegistered<FirebaseRemoteConfigService>()) {
            final service = _getIt<FirebaseRemoteConfigService>();
            eventData = service.specialEventData;
            if (eventData != null) {
              debugPrint('✅ Got event data via RemoteConfigManager');
              return eventData;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get from RemoteConfigManager: $e');
    }
    
    return eventData;
  }
  
  /// تحليل ألوان التدرج
  void _parseGradientColors(Map<String, dynamic> eventData) {
    try {
      if (eventData['gradient_colors'] != null) {
        final colors = eventData['gradient_colors'] as List;
        
        if (colors.isNotEmpty) {
          _eventGradientColors = colors.map((colorHex) {
            return _parseHexColor(colorHex.toString());
          }).where((color) => color != null).cast<Color>().toList();
        }
        
        // التأكد من وجود ألوان على الأقل
        if (_eventGradientColors.isEmpty) {
          _eventGradientColors = [Colors.purple, Colors.deepPurple];
        } else if (_eventGradientColors.length == 1) {
          // إضافة لون ثاني للتدرج
          _eventGradientColors.add(_eventGradientColors.first.withOpacity(0.7));
        }
        
        debugPrint('📎 Parsed ${_eventGradientColors.length} gradient colors');
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing gradient colors: $e');
      _eventGradientColors = [Colors.purple, Colors.deepPurple];
    }
  }
  
  /// تحويل hex إلى Color
  Color? _parseHexColor(String hexColor) {
    try {
      String hex = hexColor.trim();
      
      // إزالة # إذا موجود
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      }
      
      // التحقق من الطول
      if (hex.length == 6) {
        // إضافة FF للشفافية الكاملة
        hex = 'FF$hex';
      } else if (hex.length == 8) {
        // الشفافية موجودة بالفعل
      } else if (hex.length == 3) {
        // تحويل من 3 أحرف إلى 6
        hex = hex.split('').map((c) => '$c$c').join();
        hex = 'FF$hex';
      } else {
        throw FormatException('Invalid hex color length: ${hex.length}');
      }
      
      return Color(int.parse('0x$hex'));
    } catch (e) {
      debugPrint('⚠️ Error parsing hex color "$hexColor": $e');
      return null;
    }
  }
  
  /// تحليل التواريخ مع دعم UTC والتوقيت المحلي
  void _parseDates(Map<String, dynamic> eventData) {
    try {
      // تحليل تاريخ البداية
      if (eventData['start_date'] != null) {
        final startDateStr = eventData['start_date'].toString();
        if (startDateStr.isNotEmpty && startDateStr != 'null') {
          _eventStartDate = DateTime.tryParse(startDateStr);
          
          if (_eventStartDate != null) {
            // التأكد من أن التاريخ بصيغة UTC
            if (!startDateStr.endsWith('Z')) {
              debugPrint('⚠️ Start date missing Z timezone indicator, treating as UTC');
            }
            debugPrint('📅 Start date parsed: ${_eventStartDate!.toIso8601String()}');
          }
        }
      } else {
        debugPrint('ℹ️ No start date specified - event can start anytime');
      }
      
      // تحليل تاريخ النهاية
      if (eventData['end_date'] != null) {
        final endDateStr = eventData['end_date'].toString();
        if (endDateStr.isNotEmpty && endDateStr != 'null') {
          _eventEndDate = DateTime.tryParse(endDateStr);
          
          if (_eventEndDate != null) {
            // التأكد من أن التاريخ بصيغة UTC
            if (!endDateStr.endsWith('Z')) {
              debugPrint('⚠️ End date missing Z timezone indicator, treating as UTC');
            }
            debugPrint('📅 End date parsed: ${_eventEndDate!.toIso8601String()}');
          }
        }
      } else {
        debugPrint('ℹ️ No end date specified - event never expires');
      }
      
      // طباعة ملخص التواريخ
      _printDateSummary();
      
    } catch (e) {
      debugPrint('⚠️ Error parsing dates: $e');
      // في حالة الخطأ، اجعل المناسبة غير نشطة
      _eventStartDate = null;
      _eventEndDate = null;
    }
  }
  
  /// طباعة ملخص التواريخ
  void _printDateSummary() {
    if (_eventStartDate == null && _eventEndDate == null) {
      debugPrint('✨ Event is always active (no date restrictions)');
    } else if (_eventStartDate == null && _eventEndDate != null) {
      debugPrint('📅 Event active until: ${_formatDateForDisplay(_eventEndDate!)}');
    } else if (_eventStartDate != null && _eventEndDate == null) {
      debugPrint('📅 Event starts: ${_formatDateForDisplay(_eventStartDate!)} and never ends');
    } else if (_eventStartDate != null && _eventEndDate != null) {
      debugPrint('📅 Event period:');
      debugPrint('  From: ${_formatDateForDisplay(_eventStartDate!)}');
      debugPrint('  To: ${_formatDateForDisplay(_eventEndDate!)}');
    }
  }
  
  /// التحقق من صحة البيانات والتواريخ
  bool _validateEventData() {
    // التحقق من وجود البيانات الأساسية
    if (_eventTitle.isEmpty) {
      debugPrint('❌ Event validation failed: title is empty');
      return false;
    }
    
    // الحصول على الوقت الحالي بصيغة UTC للمقارنة الدقيقة
    final nowUtc = DateTime.now().toUtc();
    
    debugPrint('🕐 Current Time Check:');
    debugPrint('  Now (UTC): ${nowUtc.toIso8601String()}');
    debugPrint('  Now (Local): ${DateTime.now().toIso8601String()}');
    
    // إذا لم تكن هناك تواريخ، اعتبر المناسبة نشطة دائماً
    if (_eventStartDate == null && _eventEndDate == null) {
      debugPrint('✅ Event has no date restrictions - always active');
      return true;
    }
    
    // إذا كان هناك تاريخ بداية فقط
    if (_eventStartDate != null && _eventEndDate == null) {
      final startUtc = _eventStartDate!.isUtc ? _eventStartDate! : _eventStartDate!.toUtc();
      
      if (nowUtc.isBefore(startUtc)) {
        final timeUntilStart = startUtc.difference(nowUtc);
        debugPrint('❌ Event not started yet');
        debugPrint('  Starts in: ${_formatDuration(timeUntilStart)}');
        debugPrint('  Start time (UTC): ${startUtc.toIso8601String()}');
        debugPrint('  Start time (Local): ${startUtc.toLocal().toIso8601String()}');
        return false;
      }
      
      debugPrint('✅ Event started and has no end date - active forever');
      return true;
    }
    
    // إذا كان هناك تاريخ نهاية فقط
    if (_eventStartDate == null && _eventEndDate != null) {
      final endUtc = _eventEndDate!.isUtc ? _eventEndDate! : _eventEndDate!.toUtc();
      
      if (nowUtc.isAfter(endUtc)) {
        final timeSinceEnd = nowUtc.difference(endUtc);
        debugPrint('❌ Event has ended');
        debugPrint('  Ended: ${_formatDuration(timeSinceEnd)} ago');
        debugPrint('  End time (UTC): ${endUtc.toIso8601String()}');
        debugPrint('  End time (Local): ${endUtc.toLocal().toIso8601String()}');
        return false;
      }
      
      final timeRemaining = endUtc.difference(nowUtc);
      debugPrint('✅ Event active for: ${_formatDuration(timeRemaining)}');
      return true;
    }
    
    // إذا كان هناك تاريخ بداية ونهاية
    if (_eventStartDate != null && _eventEndDate != null) {
      final startUtc = _eventStartDate!.isUtc ? _eventStartDate! : _eventStartDate!.toUtc();
      final endUtc = _eventEndDate!.isUtc ? _eventEndDate! : _eventEndDate!.toUtc();
      
      debugPrint('📅 Full Date Range Check:');
      debugPrint('  Event Start (UTC): ${startUtc.toIso8601String()}');
      debugPrint('  Event Start (Local): ${startUtc.toLocal().toIso8601String()}');
      debugPrint('  Event End (UTC): ${endUtc.toIso8601String()}');
      debugPrint('  Event End (Local): ${endUtc.toLocal().toIso8601String()}');
      
      if (nowUtc.isBefore(startUtc)) {
        final timeUntilStart = startUtc.difference(nowUtc);
        debugPrint('❌ Event not started yet. Starts in: ${_formatDuration(timeUntilStart)}');
        return false;
      }
      
      if (nowUtc.isAfter(endUtc)) {
        final timeSinceEnd = nowUtc.difference(endUtc);
        debugPrint('❌ Event has ended. Ended: ${_formatDuration(timeSinceEnd)} ago');
        return false;
      }
      
      final timeRemaining = endUtc.difference(nowUtc);
      debugPrint('✅ Event is currently active!');
      debugPrint('  Time remaining: ${_formatDuration(timeRemaining)}');
      debugPrint('  Progress: ${_calculateEventProgress(startUtc, endUtc, nowUtc)}%');
      return true;
    }
    
    // التحقق من الألوان
    if (_eventGradientColors.isEmpty) {
      _eventGradientColors = [Colors.purple, Colors.deepPurple];
    }
    
    return true;
  }
  
  /// حساب نسبة تقدم المناسبة
  int _calculateEventProgress(DateTime start, DateTime end, DateTime now) {
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    if (total <= 0) return 100;
    return ((elapsed / total) * 100).clamp(0, 100).toInt();
  }
  
  /// تنسيق المدة الزمنية بشكل واضح
  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    final parts = <String>[];
    
    if (days > 0) {
      parts.add('$days ${days == 1 ? "يوم" : "أيام"}');
    }
    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? "ساعة" : "ساعات"}');
    }
    if (minutes > 0 && days == 0) {
      parts.add('$minutes ${minutes == 1 ? "دقيقة" : "دقائق"}');
    }
    if (seconds > 0 && days == 0 && hours == 0) {
      parts.add('$seconds ${seconds == 1 ? "ثانية" : "ثواني"}');
    }
    
    if (parts.isEmpty) {
      return 'أقل من ثانية';
    }
    
    if (parts.length == 1) {
      return parts.first;
    }
    
    return parts.take(2).join(' و ');
  }
  
  /// تنسيق التاريخ للعرض
  String _formatDateForDisplay(DateTime date) {
    // تحويل إلى التوقيت المحلي للعرض
    final localDate = date.toLocal();
    
    // الأشهر بالعربية
    const arabicMonths = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    
    final day = localDate.day;
    final month = arabicMonths[localDate.month - 1];
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    
    // إذا كان الوقت منتصف الليل، لا تعرض الوقت
    if (localDate.hour == 0 && localDate.minute == 0) {
      return '$day $month $year';
    }
    
    return '$day $month $year - $hour:$minute';
  }
  
  /// طباعة تفاصيل المناسبة للتصحيح
  void _logEventDetails() {
    debugPrint('========== Special Event Details ==========');
    debugPrint('Title: $_eventTitle');
    debugPrint('Description: $_eventDescription');
    debugPrint('Icon: $_eventIcon');
    debugPrint('Action Text: $_eventActionText');
    debugPrint('Action URL: $_eventActionUrl');
    debugPrint('Colors: ${_eventGradientColors.length} colors');
    debugPrint('Background Image: ${_eventBackgroundImage.isNotEmpty ? "Yes" : "No"}');
    if (_eventStartDate != null) {
      debugPrint('Start Date (UTC): ${_eventStartDate!.toIso8601String()}');
      debugPrint('Start Date (Local): ${_eventStartDate!.toLocal().toIso8601String()}');
    }
    if (_eventEndDate != null) {
      debugPrint('End Date (UTC): ${_eventEndDate!.toIso8601String()}');
      debugPrint('End Date (Local): ${_eventEndDate!.toLocal().toIso8601String()}');
    }
    debugPrint('==========================================');
  }
  
  @override
  Widget build(BuildContext context) {
    // حالة التحميل
    if (_isLoading) {
      return const SizedBox.shrink();
    }
    
    // لا نعرض الكارد إذا لم تكن هناك مناسبة نشطة
    if (!_isEventActive || _eventTitle.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 10.h,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        elevation: 8,
        shadowColor: _eventGradientColors.first.withOpacity(0.3),
        child: InkWell(
          onTap: _handleCardTap,
          borderRadius: BorderRadius.circular(20.r),
          splashColor: Colors.white.withOpacity(0.3),
          child: Container(
            height: 180.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _eventGradientColors.length >= 2
                    ? _eventGradientColors
                    : [_eventGradientColors.first, _eventGradientColors.first.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: _eventGradientColors.first.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              image: _eventBackgroundImage.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(_eventBackgroundImage),
                    fit: BoxFit.cover,
                    opacity: 0.3,
                    onError: (exception, stackTrace) {
                      debugPrint('Error loading background image: $exception');
                    },
                  )
                : null,
            ),
            child: Stack(
              children: [
                // نقاط زخرفية بسيطة (بدون أنيميشن)
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
                          // الأيقونة (بدون أنيميشن)
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
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
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                SizedBox(height: 4.h),
                                
                                Text(
                                  _eventDescription,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.white.withOpacity(0.9),
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
                        
                        // زر الإجراء (بدون أنيميشن)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(25.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
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
                
                // شارة "مناسبة خاصة"
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
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
    );
  }
  
  /// عناصر زخرفية بسيطة (بدون أنيميشن)
  Widget _buildDecorativeElements() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _EventCardPainter(
          primaryColor: _eventGradientColors.first,
        ),
      ),
    );
  }
  
  /// معالج النقر على الكارد
  void _handleCardTap() async {
    HapticFeedback.lightImpact();
    
    debugPrint('🔗 Card tapped. Action URL: $_eventActionUrl');
    
    if (_eventActionUrl.isNotEmpty) {
      // التحقق من نوع الرابط
      if (_eventActionUrl.startsWith('athkar://')) {
        // رابط داخلي
        _handleInternalNavigation(_eventActionUrl);
      } else if (_eventActionUrl.startsWith('http://') || 
                 _eventActionUrl.startsWith('https://')) {
        // رابط خارجي
        try {
          final Uri url = Uri.parse(_eventActionUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            debugPrint('✅ Launched external URL');
          } else {
            debugPrint('❌ Cannot launch URL');
            _showEventDetails();
          }
        } catch (e) {
          debugPrint('❌ Error launching URL: $e');
          _showEventDetails();
        }
      } else {
        // رابط غير معروف
        debugPrint('⚠️ Unknown URL scheme');
        _showEventDetails();
      }
    } else {
      _showEventDetails();
    }
  }
  
  /// معالج التنقل الداخلي
  void _handleInternalNavigation(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.host;
      
      debugPrint('🧭 Internal navigation to: $path');
      
      switch (path) {
        case 'ramadan-duas':
          Navigator.pushNamed(context, '/dua', arguments: {'category': 'ramadan'});
          break;
        case 'eid-takbeer':
          Navigator.pushNamed(context, '/athkar', arguments: {'category': 'eid'});
          break;
        case 'hajj-duas':
          Navigator.pushNamed(context, '/dua', arguments: {'category': 'hajj'});
          break;
        case 'salawat':
          Navigator.pushNamed(context, '/athkar', arguments: {'category': 'prophet'});
          break;
        case 'laylat-alqadr':
          Navigator.pushNamed(context, '/dua', arguments: {'category': 'qadr'});
          break;
        case 'isra-miraj':
          Navigator.pushNamed(context, '/athkar', arguments: {'category': 'isra'});
          break;
        case 'arafah-dua':
          Navigator.pushNamed(context, '/dua', arguments: {'category': 'arafah'});
          break;
        case 'ashura':
          Navigator.pushNamed(context, '/athkar', arguments: {'category': 'ashura'});
          break;
        default:
          _showEventDetails();
      }
    } catch (e) {
      debugPrint('❌ Error parsing internal URL: $e');
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
            // المقبض
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // الأيقونة
            Text(
              _eventIcon,
              style: TextStyle(fontSize: 48.sp),
            ),
            
            SizedBox(height: 16.h),
            
            // العنوان
            Text(
              _eventTitle,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12.h),
            
            // الوصف
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
            
            // معلومات التواريخ إذا كانت موجودة
            if (_eventStartDate != null || _eventEndDate != null) ...[
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16.sp,
                          color: context.primaryColor,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'فترة المناسبة',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: context.primaryColor,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    
                    if (_eventStartDate != null) ...[
                      Text(
                        'من: ${_formatDateForDisplay(_eventStartDate!)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.textSecondaryColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      SizedBox(height: 4.h),
                    ],
                    
                    if (_eventEndDate != null) ...[
                      Text(
                        'إلى: ${_formatDateForDisplay(_eventEndDate!)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.textSecondaryColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                    
                    // عرض الوقت المتبقي
                    if (_eventEndDate != null && DateTime.now().isBefore(_eventEndDate!)) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'متبقي: ${_formatDuration(_eventEndDate!.difference(DateTime.now()))}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.green,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 24.h),
            
            // زر الإغلاق
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'إغلاق',
                  style: TextStyle(
                    fontSize: 14.sp,
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
    );
  }
}

/// رسام العناصر الزخرفية البسيط (بدون أنيميشن)
class _EventCardPainter extends CustomPainter {
  final Color primaryColor;
  
  _EventCardPainter({
    required this.primaryColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // دوائر زخرفية ثابتة
    paint.color = Colors.white.withOpacity(0.08);
    
    // الدائرة الأولى
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.2),
      35,
      paint,
    );
    
    // الدائرة الثانية
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      25,
      paint,
    );
    
    // دائرة ثالثة
    paint.color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      45,
      paint,
    );
    
    // خطوط زخرفية
    paint.color = Colors.white.withOpacity(0.1);
    paint.strokeWidth = 1.0;
    paint.style = PaintingStyle.stroke;
    
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.2,
      size.width,
      size.height * 0.4,
    );
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}