// lib/core/infrastructure/services/share/share_extensions.dart - النسخة النهائية
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// Extensions للوصول السهل لخدمة المشاركة من أي BuildContext
extension ShareContextExtensions on BuildContext {
  
  // ==================== Copy Helpers - دائماً مع التفاصيل الكاملة ====================
  
  /// نسخ ذكر مع كل التفاصيل
  Future<void> copyAthkar(
    String text, {
    String? fadl,
    String? source,
    String? categoryTitle,
  }) async {
    try {
      await shareService.copyAthkar(
        text,
        fadl: fadl,
        source: source,
        categoryTitle: categoryTitle,
      );
      
      if (mounted) {
        _showCopySuccessMessage('الذكر');
      }
      
      HapticFeedback.lightImpact();
      
    } catch (e) {
      if (mounted) {
        _showCopyErrorMessage();
      }
    }
  }

  /// نسخ دعاء مع كل التفاصيل
  Future<void> copyDua(
    String title,
    String arabicText, {
    String? transliteration,
    String? translation,
    String? virtue,
    String? source,
    String? reference,
  }) async {
    try {
      await shareService.copyDua(
        title,
        arabicText,
        transliteration: transliteration,
        translation: translation,
        virtue: virtue,
        source: source,
        reference: reference,
      );
      
      if (mounted) {
        _showCopySuccessMessage('الدعاء');
      }
      
      HapticFeedback.lightImpact();
      
    } catch (e) {
      if (mounted) {
        _showCopyErrorMessage();
      }
    }
  }

  /// نسخ اسم من أسماء الله مع كل التفاصيل
  Future<void> copyAsmaAllah(
    String name,
    String explanation, {
    String? meaning,
  }) async {
    try {
      await shareService.copyAsmaAllah(
        name,
        explanation,
        meaning: meaning,
      );
      
      if (mounted) {
        _showCopySuccessMessage('الاسم');
      }
      
      HapticFeedback.lightImpact();
      
    } catch (e) {
      if (mounted) {
        _showCopyErrorMessage();
      }
    }
  }

  /// نسخ إحصائيات التسبيح مع كل التفاصيل
  Future<void> copyTasbihStats({
    required int totalCount,
    required int sessionsCount,
    String? currentTasbih,
  }) async {
    try {
      await shareService.copyTasbihStats(
        totalCount: totalCount,
        sessionsCount: sessionsCount,
        currentTasbih: currentTasbih,
      );
      
      if (mounted) {
        _showCopySuccessMessage('الإحصائيات');
      }
      
      HapticFeedback.lightImpact();
      
    } catch (e) {
      if (mounted) {
        _showCopyErrorMessage();
      }
    }
  }

  // ==================== Share Shortcuts ====================

  /// مشاركة ذكر
  Future<void> shareAthkar(
    String text, {
    String? fadl,
    String? source,
    String? categoryTitle,
  }) async {
    await shareService.shareAthkar(
      text,
      fadl: fadl,
      source: source,
      categoryTitle: categoryTitle,
    );
  }

  /// مشاركة تقدم الأذكار
  Future<void> shareAthkarProgress(
    String categoryTitle,
    List<String> completedAthkar,
  ) async {
    await shareService.shareAthkarProgress(categoryTitle, completedAthkar);
  }

  /// مشاركة دعاء
  Future<void> shareDua(
    String title,
    String arabicText, {
    String? transliteration,
    String? translation,
    String? virtue,
    String? source,
    String? reference,
  }) async {
    await shareService.shareDua(
      title,
      arabicText,
      transliteration: transliteration,
      translation: translation,
      virtue: virtue,
      source: source,
      reference: reference,
    );
  }

  /// مشاركة عدة أدعية مفضلة
  Future<void> shareFavoriteDuas(List<Map<String, String>> duas) async {
    await shareService.shareFavoriteDuas(duas);
  }

  /// مشاركة اسم من أسماء الله
  Future<void> shareAsmaAllah(
    String name,
    String explanation, {
    String? meaning,
  }) async {
    await shareService.shareAsmaAllah(
      name,
      explanation,
      meaning: meaning,
    );
  }

  /// مشاركة إحصائيات التسبيح
  Future<void> shareTasbihStats({
    required int totalCount,
    required int sessionsCount,
    String? currentTasbih,
  }) async {
    await shareService.shareTasbihStats(
      totalCount: totalCount,
      sessionsCount: sessionsCount,
      currentTasbih: currentTasbih,
    );
  }

  /// مشاركة التطبيق
  Future<void> shareApp() async {
    await shareService.shareApp();
  }

  // ==================== Private Helper Methods ====================

  void _showCopySuccessMessage(String itemName) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم نسخ $itemName بنجاح مع كل التفاصيل',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF5D7052),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showCopyErrorMessage() {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'فشل النسخ، حاول مرة أخرى',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ==================== General Message Helpers ====================

  /// إظهار رسالة نجاح
  void showSuccessMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF5D7052),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// إظهار رسالة خطأ
  void showErrorMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// إظهار رسالة معلومات
  void showInfoMessage(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}