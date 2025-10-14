// lib/core/infrastructure/services/copy/copy_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// خدمة النسخ
class CopyService {
  CopyService._();
  static final instance = CopyService._();
  
  // معلومات التطبيق
  static const _appName = 'ذكرني';
  static const _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.yourcompany.athkar_app';
  
  // رسائل النجاح
  static const _successMessages = [
    'تم النسخ بنجاح ✓',
    'تم نسخ النص ✓',
    'تم النسخ إلى الحافظة ✓',
  ];
  
  // نسخ نص عادي
  Future<bool> copyText(
    String text, {
    BuildContext? context,
    String? successMessage,
    bool showSnackBar = true,
    bool includeAppInfo = false,
  }) async {
    try {
      if (text.isEmpty) return false;
      
      String textToCopy = text;
      if (includeAppInfo) {
        textToCopy += '\n\n📱 من تطبيق $_appName\n$_playStoreUrl';
      }
      
      await Clipboard.setData(ClipboardData(text: textToCopy));
      HapticFeedback.mediumImpact();
      
      if (showSnackBar && context?.mounted == true) {
        _showSnackBar(
          context!,
          successMessage ?? _successMessages[Random().nextInt(_successMessages.length)],
          isSuccess: true,
        );
      }
      
      return true;
    } catch (e) {
      if (showSnackBar && context?.mounted == true) {
        _showSnackBar(context!, 'فشل نسخ النص', isSuccess: false);
      }
      return false;
    }
  }
  
  // نسخ ذكر
  Future<bool> copyThikr({
    required String text,
    String? source,
    String? virtue,
    BuildContext? context,
    bool includeAppInfo = true,
  }) async {
    final buffer = StringBuffer()..writeln(text);
    
    if (virtue?.isNotEmpty ?? false) {
      buffer.writeln('\nالفضيلة: $virtue');
    }
    
    if (source?.isNotEmpty ?? false) {
      buffer.writeln('\nالمصدر: $source');
    }
    
    return await copyText(
      buffer.toString(),
      context: context,
      successMessage: 'تم نسخ الذكر ✓',
      includeAppInfo: includeAppInfo,
    );
  }
  
  // نسخ آية
  Future<bool> copyVerse({
    required String verse,
    required String source,
    BuildContext? context,
    bool includeAppInfo = true,
  }) async {
    final text = '$verse\n\n﴿ $source ﴾';
    
    return await copyText(
      text,
      context: context,
      successMessage: 'تم نسخ الآية ✓',
      includeAppInfo: includeAppInfo,
    );
  }
  
  // نسخ حديث
  Future<bool> copyHadith({
    required String hadith,
    required String source,
    String? narrator,
    BuildContext? context,
    bool includeAppInfo = true,
  }) async {
    final buffer = StringBuffer()
      ..writeln(hadith)
      ..writeln();
    
    if (narrator?.isNotEmpty ?? false) {
      buffer.writeln('الراوي: $narrator');
    }
    
    buffer.writeln('المصدر: $source');
    
    return await copyText(
      buffer.toString(),
      context: context,
      successMessage: 'تم نسخ الحديث ✓',
      includeAppInfo: includeAppInfo,
    );
  }
  
  // عرض SnackBar
  void _showSnackBar(BuildContext context, String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  // قراءة الحافظة
  Future<String?> getClipboardText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      return null;
    }
  }
  
  // مسح الحافظة
  Future<bool> clearClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Extension للوصول السريع
extension CopyExtension on BuildContext {
  Future<bool> copyText(String text, {String? successMessage, bool includeAppInfo = false}) =>
      CopyService.instance.copyText(
        text,
        context: this,
        successMessage: successMessage,
        includeAppInfo: includeAppInfo,
      );
  
  Future<bool> copyThikr({required String text, String? source, String? virtue, bool includeAppInfo = true}) =>
      CopyService.instance.copyThikr(
        text: text,
        source: source,
        virtue: virtue,
        context: this,
        includeAppInfo: includeAppInfo,
      );
  
  Future<bool> copyVerse({required String verse, required String source, bool includeAppInfo = true}) =>
      CopyService.instance.copyVerse(
        verse: verse,
        source: source,
        context: this,
        includeAppInfo: includeAppInfo,
      );
  
  Future<bool> copyHadith({required String hadith, required String source, String? narrator, bool includeAppInfo = true}) =>
      CopyService.instance.copyHadith(
        hadith: hadith,
        source: source,
        narrator: narrator,
        context: this,
        includeAppInfo: includeAppInfo,
      );
}