// lib/core/infrastructure/firebase/special_event/services/event_navigation_handler.dart
// ✅ محدث - إلغاء عرض EventDetailsModal

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:athkar_app/core/firebase/special_event/modals/special_event_model.dart';

/// معالج التنقل للمناسبات الخاصة
class EventNavigationHandler {
  /// معالجة التنقل حسب نوع الرابط
  static void handle({
    required BuildContext context,
    required String url,
    required SpecialEventModel event,
  }) async {
    // ✅ إذا كان الرابط فارغاً، لا نفعل شيء (بدلاً من عرض Modal)
    if (url.isEmpty) {
      debugPrint('ℹ️ [Navigation] No action URL - ignoring tap');
      return;
    }
    
    if (url.startsWith('athkar://')) {
      _handleInternalNavigation(context, url, event);
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      await _handleExternalUrl(context, url, event);
    } else {
      // ✅ رابط غير معروف - لا نفعل شيء
      debugPrint('⚠️ [Navigation] Unknown URL format: $url');
    }
  }
  
  /// معالجة الروابط الداخلية
  static void _handleInternalNavigation(
    BuildContext context,
    String url,
    SpecialEventModel event,
  ) {
    try {
      final uri = Uri.parse(url);
      final path = uri.host;
      
      debugPrint('🔗 [Navigation] Internal path: $path');
      
      switch (path) {
        // ========== روابط رمضان ==========
        case 'ramadan-duas':
          Navigator.pushNamed(context, '/dua', arguments: {'category': 'ramadan'});
          break;
        case 'iftar-dua':
          Navigator.pushNamed(context, '/dua', arguments: {'category': 'iftar'});
          break;
        case 'suhoor-dua':
          Navigator.pushNamed(context, '/dua', arguments: {'category': 'suhoor'});
          break;
        case 'laylat-alqadr':
          Navigator.pushNamed(context, '/dua', arguments: {'category': 'laylat_alqadr'});
          break;
        case 'itikaf':
          Navigator.pushNamed(context, '/guides', arguments: {'type': 'itikaf'});
          break;
          
        // ========== روابط العيد ==========
        case 'eid-takbeer':
          Navigator.pushNamed(context, '/athkar', arguments: {'category': 'eid'});
          break;
        case 'eid-greetings':
          Navigator.pushNamed(context, '/greetings', arguments: {'type': 'eid'});
          break;
        case 'eid-prayer':
          Navigator.pushNamed(context, '/guides', arguments: {'type': 'eid_prayer'});
          break;
        case 'zakat-alfitr':
          Navigator.pushNamed(context, '/calculator', arguments: {'type': 'zakat_fitr'});
          break;
          
        // ========== روابط الحج والعمرة ==========
        case 'hajj-duas':
          Navigator.pushNamed(context, '/dua', arguments: {'category': 'hajj'});
          break;
        case 'umrah-guide':
          Navigator.pushNamed(context, '/guides', arguments: {'type': 'umrah'});
          break;
        case 'hajj-guide':
          Navigator.pushNamed(context, '/guides', arguments: {'type': 'hajj'});
          break;
        case 'ihram-guide':
          Navigator.pushNamed(context, '/guides', arguments: {'type': 'ihram'});
          break;
        case 'tawaf-counter':
          Navigator.pushNamed(context, '/counter', arguments: {'type': 'tawaf'});
          break;
          
        // ========== الأذكار اليومية ==========
        case 'morning-athkar':
          Navigator.pushNamed(context, '/athkar', arguments: {'type': 'morning'});
          break;
        case 'evening-athkar':
          Navigator.pushNamed(context, '/athkar', arguments: {'type': 'evening'});
          break;
        case 'sleep-athkar':
          Navigator.pushNamed(context, '/athkar', arguments: {'type': 'sleep'});
          break;
        case 'wakeup-athkar':
          Navigator.pushNamed(context, '/athkar', arguments: {'type': 'wakeup'});
          break;
        case 'prayer-athkar':
          Navigator.pushNamed(context, '/athkar', arguments: {'type': 'after_prayer'});
          break;
          
        // ========== الصلاة ==========
        case 'prayer-times':
          Navigator.pushNamed(context, '/prayer');
          break;
        case 'qibla':
          Navigator.pushNamed(context, '/qibla');
          break;
        case 'prayer-guide':
          Navigator.pushNamed(context, '/guides', arguments: {'type': 'prayer'});
          break;
        case 'tahajjud-reminder':
          Navigator.pushNamed(context, '/reminders', arguments: {'type': 'tahajjud'});
          break;
          
        // ========== القرآن الكريم ==========
        case 'quran':
          Navigator.pushNamed(context, '/quran');
          break;
        case 'quran-bookmark':
          Navigator.pushNamed(context, '/quran', arguments: {'tab': 'bookmarks'});
          break;
        case 'daily-wird':
          Navigator.pushNamed(context, '/daily-wird');
          break;
        case 'juz-amma':
          Navigator.pushNamed(context, '/quran', arguments: {'juz': 30});
          break;
          
        // ========== التسبيح والذكر ==========
        case 'tasbih':
          Navigator.pushNamed(context, '/tasbih');
          break;
        case 'tasbih-counter':
          Navigator.pushNamed(context, '/counter', arguments: {'type': 'tasbih'});
          break;
        case 'istighfar-counter':
          Navigator.pushNamed(context, '/counter', arguments: {'type': 'istighfar'});
          break;
          
        // ========== أدوات أخرى ==========
        case 'names-of-allah':
          Navigator.pushNamed(context, '/names-of-allah');
          break;
        case 'dua-list':
          Navigator.pushNamed(context, '/dua');
          break;
        case 'islamic-calendar':
          Navigator.pushNamed(context, '/calendar', arguments: {'type': 'hijri'});
          break;
        case 'zakat-calculator':
          Navigator.pushNamed(context, '/calculator', arguments: {'type': 'zakat'});
          break;
        case 'islamic-events':
          Navigator.pushNamed(context, '/events');
          break;
          
        // ========== المناسبات الوطنية ==========
        case 'national-day':
          Navigator.pushNamed(context, '/celebration', arguments: {'type': 'national'});
          break;
        case 'flag-day':
          Navigator.pushNamed(context, '/celebration', arguments: {'type': 'flag'});
          break;
          
        // ========== افتراضي ==========
        default:
          debugPrint('⚠️ [Navigation] Unknown path: $path - ignoring');
          // ✅ لا نعرض Modal، فقط نتجاهل
      }
    } catch (e) {
      debugPrint('❌ [Navigation] Error handling internal navigation: $e');
      // ✅ لا نعرض Modal عند الخطأ
    }
  }
  
  /// معالجة الروابط الخارجية
  static Future<void> _handleExternalUrl(
    BuildContext context,
    String url,
    SpecialEventModel event,
  ) async {
    try {
      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        debugPrint('🌐 [Navigation] Launching external URL: $url');
        
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('⚠️ [Navigation] Cannot launch URL: $url');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يمكن فتح الرابط: $url'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [Navigation] Error launching external URL: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في فتح الرابط'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  /// التحقق من نوع الرابط
  static LinkType getLinkType(String url) {
    if (url.isEmpty) return LinkType.none;
    if (url.startsWith('athkar://')) return LinkType.internal;
    if (url.startsWith('http://') || url.startsWith('https://')) return LinkType.external;
    return LinkType.unknown;
  }
}

/// أنواع الروابط
enum LinkType {
  none,       // لا يوجد رابط
  internal,   // رابط داخلي
  external,   // رابط خارجي
  unknown,    // نوع غير معروف
}