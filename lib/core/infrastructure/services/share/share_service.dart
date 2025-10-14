// lib/core/infrastructure/services/share/share_service.dart - النسخة النهائية المنقحة
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// خدمة موحدة للمشاركة والنسخ في جميع أنحاء التطبيق
class ShareService {
  // ==================== ثوابت التطبيق ====================
  
  /// رابط التطبيق على Google Play Store
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.athkar.dhakerni';
  
  /// رابط التطبيق على App Store (إذا كان متاحاً)
  static const String appStoreUrl = 'https://apps.apple.com/app/id123456789';
  
  /// اسم التطبيق
  static const String appName = 'ذكرني';
  
  /// وصف التطبيق المختصر
  static const String appTagline = 'رفيقك في الذكر والعبادة';
  
  /// Footer موحد لجميع المشاركات
  String get _shareFooter {
    return '''

━━━━━━━━━━━━━━━━━━━
📱 من تطبيق $appName
$appTagline

📥 حمّل التطبيق الآن:
$playStoreUrl''';
  }
  
  /// Footer مختصر (بدون emoji كثيرة)
  String get _shareFooterCompact {
    return '''

───────────────────
من تطبيق $appName
$playStoreUrl''';
  }

  // ==================== Core Functions (Private) ====================

  /// نسخ نص إلى الحافظة (دالة خاصة داخلية)
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      debugPrint('ShareService Copy Error: $e');
      rethrow;
    }
  }

  // ==================== أذكار ====================

  /// بناء نص ذكر كامل مع كل التفاصيل
  String _buildAthkarText(
    String athkarText, {
    String? fadl,
    String? source,
    String? categoryTitle,
  }) {
    final buffer = StringBuffer();
    
    if (categoryTitle != null) {
      buffer.writeln('📿 $categoryTitle');
      buffer.writeln();
    }
    
    buffer.writeln(athkarText);
    
    if (fadl != null) {
      buffer.writeln();
      buffer.writeln('✨ الفضيلة:');
      buffer.writeln(fadl);
    }
    
    if (source != null) {
      buffer.writeln();
      buffer.writeln('📚 المصدر: $source');
    }
    
    buffer.write(_shareFooter);
    
    return buffer.toString();
  }

  /// مشاركة ذكر واحد
  Future<void> shareAthkar(
    String athkarText, {
    String? fadl,
    String? source,
    String? categoryTitle,
  }) async {
    final content = _buildAthkarText(
      athkarText,
      fadl: fadl,
      source: source,
      categoryTitle: categoryTitle,
    );
    
    await Share.share(content);
  }

  /// نسخ ذكر واحد مع كل التفاصيل
  Future<void> copyAthkar(
    String athkarText, {
    String? fadl,
    String? source,
    String? categoryTitle,
  }) async {
    final content = _buildAthkarText(
      athkarText,
      fadl: fadl,
      source: source,
      categoryTitle: categoryTitle,
    );
    
    await _copyToClipboard(content);
  }

  /// مشاركة تقدم الأذكار
  Future<void> shareAthkarProgress(
    String categoryTitle,
    List<String> completedAthkar,
  ) async {
    final buffer = StringBuffer();
    
    buffer.writeln('📿 أكملت أذكار: $categoryTitle');
    buffer.writeln();
    buffer.writeln('✅ الأذكار المكتملة (${completedAthkar.length}):');
    buffer.writeln();
    
    for (int i = 0; i < completedAthkar.length; i++) {
      buffer.writeln('${i + 1}. ${completedAthkar[i]}');
    }
    
    buffer.writeln();
    buffer.writeln('الحمد لله الذي بنعمته تتم الصالحات 🤲');
    
    buffer.write(_shareFooter);
    
    await Share.share(buffer.toString());
  }

  // ==================== أدعية ====================

  /// بناء نص دعاء كامل مع كل التفاصيل
  String _buildDuaText(
    String title,
    String arabicText, {
    String? transliteration,
    String? translation,
    String? virtue,
    String? source,
    String? reference,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('🤲 $title');
    buffer.writeln();
    buffer.writeln(arabicText);
    
    if (transliteration != null) {
      buffer.writeln();
      buffer.writeln('📝 النطق:');
      buffer.writeln(transliteration);
    }
    
    if (translation != null) {
      buffer.writeln();
      buffer.writeln('📖 المعنى:');
      buffer.writeln(translation);
    }
    
    if (virtue != null) {
      buffer.writeln();
      buffer.writeln('✨ الفضيلة:');
      buffer.writeln(virtue);
    }
    
    if (source != null && reference != null) {
      buffer.writeln();
      buffer.writeln('📚 المصدر: $source - $reference');
    }
    
    buffer.write(_shareFooter);
    
    return buffer.toString();
  }

  /// مشاركة دعاء واحد
  Future<void> shareDua(
    String title,
    String arabicText, {
    String? transliteration,
    String? translation,
    String? virtue,
    String? source,
    String? reference,
  }) async {
    final content = _buildDuaText(
      title,
      arabicText,
      transliteration: transliteration,
      translation: translation,
      virtue: virtue,
      source: source,
      reference: reference,
    );
    
    await Share.share(content);
  }

  /// نسخ دعاء واحد مع كل التفاصيل
  Future<void> copyDua(
    String title,
    String arabicText, {
    String? transliteration,
    String? translation,
    String? virtue,
    String? source,
    String? reference,
  }) async {
    final content = _buildDuaText(
      title,
      arabicText,
      transliteration: transliteration,
      translation: translation,
      virtue: virtue,
      source: source,
      reference: reference,
    );
    
    await _copyToClipboard(content);
  }

  /// مشاركة عدة أدعية مفضلة
  Future<void> shareFavoriteDuas(List<Map<String, String>> duas) async {
    final buffer = StringBuffer();
    
    buffer.writeln('🤲 أدعيتي المفضلة (${duas.length})');
    buffer.writeln();
    
    for (int i = 0; i < duas.length; i++) {
      final dua = duas[i];
      
      buffer.writeln('${i + 1}. ${dua['title'] ?? 'دعاء'}');
      buffer.writeln(dua['text'] ?? '');
      
      if (dua['source'] != null) {
        buffer.writeln('   📚 ${dua['source']}');
      }
      
      if (i < duas.length - 1) {
        buffer.writeln();
      }
    }
    
    buffer.write(_shareFooter);
    
    await Share.share(buffer.toString());
  }

  // ==================== أسماء الله الحسنى ====================

  /// بناء نص اسم من أسماء الله كامل مع كل التفاصيل
  String _buildAsmaAllahText(
    String name,
    String explanation, {
    String? meaning,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('✨ $name');
    buffer.writeln();
    
    if (meaning != null) {
      buffer.writeln('💫 المعنى:');
      buffer.writeln(meaning);
      buffer.writeln();
    }
    
    buffer.writeln('📖 الشرح والتفسير:');
    buffer.writeln(explanation);
    
    buffer.write(_shareFooter);
    
    return buffer.toString();
  }

  /// مشاركة اسم من أسماء الله
  Future<void> shareAsmaAllah(
    String name,
    String explanation, {
    String? meaning,
  }) async {
    final content = _buildAsmaAllahText(name, explanation, meaning: meaning);
    
    await Share.share(content);
  }

  /// نسخ اسم من أسماء الله مع كل التفاصيل
  Future<void> copyAsmaAllah(
    String name,
    String explanation, {
    String? meaning,
  }) async {
    final content = _buildAsmaAllahText(name, explanation, meaning: meaning);
    
    await _copyToClipboard(content);
  }

  // ==================== الاقتباس اليومي ====================

  /// بناء نص اقتباس يومي كامل
  String _buildDailyQuoteText(
    String content,
    String source, {
    String? theme,
  }) {
    final buffer = StringBuffer();
    
    if (theme != null) {
      buffer.writeln('📖 $theme');
      buffer.writeln();
    }
    
    buffer.writeln('❝ $content ❞');
    
    buffer.writeln();
    buffer.writeln('— $source');
    
    buffer.write(_shareFooterCompact);
    
    return buffer.toString();
  }

  /// مشاركة اقتباس يومي
  Future<void> shareDailyQuote(
    String content,
    String source, {
    String? theme,
  }) async {
    final text = _buildDailyQuoteText(content, source, theme: theme);
    
    await Share.share(text);
  }

  /// نسخ اقتباس يومي مع كل التفاصيل
  Future<void> copyDailyQuote(
    String content,
    String source, {
    String? theme,
  }) async {
    final text = _buildDailyQuoteText(content, source, theme: theme);
    
    await _copyToClipboard(text);
  }

  // ==================== التسبيح ====================

  /// بناء نص إحصائيات التسبيح
  String _buildTasbihStatsText({
    required int totalCount,
    required int sessionsCount,
    String? currentTasbih,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('📿 إحصائيات التسبيح');
    buffer.writeln();
    buffer.writeln('🔢 إجمالي التسبيحات: ${_formatNumber(totalCount)}');
    buffer.writeln('📊 عدد الجلسات: ${_formatNumber(sessionsCount)}');
    
    if (currentTasbih != null) {
      buffer.writeln();
      buffer.writeln('📝 التسبيح الحالي:');
      buffer.writeln(currentTasbih);
    }
    
    buffer.writeln();
    buffer.writeln('الحمد لله على نعمة الذكر 🤲');
    
    buffer.write(_shareFooter);
    
    return buffer.toString();
  }

  /// مشاركة إحصائيات التسبيح
  Future<void> shareTasbihStats({
    required int totalCount,
    required int sessionsCount,
    String? currentTasbih,
  }) async {
    final content = _buildTasbihStatsText(
      totalCount: totalCount,
      sessionsCount: sessionsCount,
      currentTasbih: currentTasbih,
    );
    
    await Share.share(content);
  }

  /// نسخ إحصائيات التسبيح مع كل التفاصيل
  Future<void> copyTasbihStats({
    required int totalCount,
    required int sessionsCount,
    String? currentTasbih,
  }) async {
    final content = _buildTasbihStatsText(
      totalCount: totalCount,
      sessionsCount: sessionsCount,
      currentTasbih: currentTasbih,
    );
    
    await _copyToClipboard(content);
  }

  // ==================== التطبيق ====================

  /// مشاركة التطبيق
  Future<void> shareApp() async {
    final buffer = StringBuffer();
    
    buffer.writeln('🌟 تطبيق $appName');
    buffer.writeln(appTagline);
    buffer.writeln();
    buffer.writeln('✨ مميزات التطبيق:');
    buffer.writeln('📿 أذكار الصباح والمساء');
    buffer.writeln('🤲 الأدعية المأثورة');
    buffer.writeln('✨ أسماء الله الحسنى');
    buffer.writeln('📖 اقتباسات يومية');
    buffer.writeln('📿 مسبحة إلكترونية');
    buffer.writeln('🔔 تذكيرات ذكية');
    buffer.writeln();
    buffer.writeln('📥 حمّل التطبيق مجاناً:');
    buffer.writeln(playStoreUrl);
    
    await Share.share(
      buffer.toString(),
      subject: 'تطبيق $appName - $appTagline',
    );
  }

  // ==================== Helper Methods ====================

  /// تنسيق الأرقام بفواصل
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}