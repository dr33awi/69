// lib\core\infrastructure\services\text\extensions\text_settings_extensions.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app/di/service_locator.dart';
import '../text_settings_service.dart';
import '../models/text_settings_models.dart';
import '../screens/global_text_settings_screen.dart';

/// Extensions للوصول السهل لخدمة إعدادات النصوص من BuildContext
extension TextSettingsContextExtensions on BuildContext {
  
  /// الحصول على خدمة إعدادات النصوص
  TextSettingsService get textSettingsService => getIt<TextSettingsService>();
  
  // ==================== الوصول للإعدادات ====================
  
  /// الحصول على إعدادات نص لنوع محتوى معين
  Future<TextSettings> getTextSettings(ContentType contentType) async {
    return await textSettingsService.getTextSettings(contentType);
  }
  
  /// الحصول على إعدادات العرض لنوع محتوى معين
  Future<DisplaySettings> getDisplaySettings(ContentType contentType) async {
    return await textSettingsService.getDisplaySettings(contentType);
  }
  
  // ==================== إعدادات سريعة ====================
  
  /// الحصول على TextStyle مخصص لنوع محتوى معين
  Future<TextStyle> getContentTextStyle(
    ContentType contentType, {
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? lineHeight,
    double? letterSpacing,
  }) async {
    final settings = await getTextSettings(contentType);
    
    return TextStyle(
      fontSize: fontSize ?? settings.fontSize,
      fontFamily: settings.fontFamily,
      height: lineHeight ?? settings.lineHeight,
      letterSpacing: letterSpacing ?? settings.letterSpacing,
      color: color,
      fontWeight: fontWeight,
    );
  }
  
  /// الحصول على TextStyle للأذكار
  Future<TextStyle> getAthkarTextStyle({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) async {
    return await getContentTextStyle(
      ContentType.athkar,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }
  
  /// الحصول على TextStyle للدعاء
  Future<TextStyle> getDuaTextStyle({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) async {
    return await getContentTextStyle(
      ContentType.dua,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }
  
  /// الحصول على TextStyle لأسماء الله
  Future<TextStyle> getAsmaAllahTextStyle({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) async {
    return await getContentTextStyle(
      ContentType.asmaAllah,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }
  
  /// الحصول على TextStyle للقرآن
  Future<TextStyle> getQuranTextStyle({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) async {
    return await getContentTextStyle(
      ContentType.quran,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }
  
  // ==================== تحديث سريع للإعدادات ====================
  
  /// تحديث حجم الخط لنوع محتوى معين
  Future<void> updateContentFontSize(ContentType contentType, double fontSize) async {
    await textSettingsService.updateFontSize(contentType, fontSize);
  }
  
  /// تحديث نوع الخط لنوع محتوى معين
  Future<void> updateContentFontFamily(ContentType contentType, String fontFamily) async {
    await textSettingsService.updateFontFamily(contentType, fontFamily);
  }
  
  /// تحديث تباعد الأسطر لنوع محتوى معين
  Future<void> updateContentLineHeight(ContentType contentType, double lineHeight) async {
    await textSettingsService.updateLineHeight(contentType, lineHeight);
  }
  
  /// تحديث تباعد الأحرف لنوع محتوى معين
  Future<void> updateContentLetterSpacing(ContentType contentType, double letterSpacing) async {
    await textSettingsService.updateLetterSpacing(contentType, letterSpacing);
  }
  
  // ==================== تطبيق القوالب ====================
  
  /// تطبيق قالب جاهز على نوع محتوى معين
  Future<void> applyPresetToContent(ContentType contentType, TextStylePreset preset) async {
    await textSettingsService.applyPreset(contentType, preset);
  }
  
  /// تطبيق قالب على جميع أنواع المحتوى
  Future<void> applyPresetToAllContent(TextStylePreset preset) async {
    await textSettingsService.applyPresetToAll(preset);
  }
  
  // ==================== إعدادات عامة ====================
  
  /// تعيين خط عام لجميع أنواع المحتوى
  Future<void> setGlobalFont(String? fontFamily) async {
    await textSettingsService.setGlobalFontFamily(fontFamily);
  }
  
  /// إعادة تعيين إعدادات نوع محتوى معين
  Future<void> resetContentSettings(ContentType contentType) async {
    await textSettingsService.resetToDefault(contentType);
  }
  
  /// إعادة تعيين جميع الإعدادات
  Future<void> resetAllTextSettings() async {
    await textSettingsService.resetAllToDefault();
  }
  
  // ==================== المساعدات ====================
  
  /// عرض شاشة إعدادات النصوص العامة
  Future<void> showGlobalTextSettings({ContentType? initialContentType}) async {
    await Navigator.push(
      this,
      MaterialPageRoute(
        builder: (context) => GlobalTextSettingsScreen(
          initialContentType: initialContentType,
        ),
      ),
    );
  }
  
  /// عرض dialog لاختيار القوالب الجاهزة
  Future<void> showTextPresetDialog(ContentType contentType) async {
    await showDialog(
      context: this,
      builder: (context) => TextPresetDialog(contentType: contentType),
    );
  }
  
  /// عرض bottom sheet لإعدادات سريعة
  Future<void> showQuickTextSettings(ContentType contentType) async {
    await showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      builder: (context) => QuickTextSettingsSheet(contentType: contentType),
    );
  }
  
  // ==================== Share and Copy helpers ====================
  
  /// نسخ ذكر مع التفاصيل
  Future<void> copyAthkar(
    String text, {
    String? fadl,
    String? source,
    String? categoryTitle,
  }) async {
    final formattedText = text.formatForSharing(
      source: source,
      fadl: fadl,
      categoryTitle: categoryTitle,
    );
    
    await Clipboard.setData(ClipboardData(text: formattedText));
    
    if (mounted) {
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          content: const Text('تم نسخ الذكر بنجاح'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  /// مشاركة ذكر مع التفاصيل
  Future<void> shareAthkar(
    String text, {
    String? fadl,
    String? source,
    String? categoryTitle,
  }) async {
    final formattedText = text.formatForSharing(
      source: source,
      fadl: fadl,
      categoryTitle: categoryTitle,
    );
    
    // استخدام Share plugin هنا (سيحتاج إلى تنفيذ لاحقاً)
    debugPrint('Share: $formattedText');
  }
}

/// Extensions للنصوص مع إزالة التشكيل
extension TextProcessingExtensions on String {
  
  /// إزالة التشكيل من النص العربي
  String removeTashkeel() {
    final tashkeelRegex = RegExp(r'[\u0617-\u061A\u064B-\u0652]');
    return replaceAll(tashkeelRegex, '');
  }
  
  /// تطبيق إعدادات العرض على النص
  String applyDisplaySettings(DisplaySettings displaySettings) {
    String processedText = this;
    
    // إزالة التشكيل إذا لم يكن مطلوباً
    if (!displaySettings.showTashkeel) {
      processedText = processedText.removeTashkeel();
    }
    
    return processedText;
  }
  
  /// تنسيق النص للمشاركة أو النسخ
  String formatForSharing({
    String? source,
    String? fadl,
    String? categoryTitle,
    bool includeAppInfo = true,
  }) {
    final buffer = StringBuffer();
    
    // إضافة عنوان الفئة إذا كان متوفراً
    if (categoryTitle != null) {
      buffer.writeln('📿 $categoryTitle');
      buffer.writeln();
    }
    
    // إضافة النص الأساسي
    buffer.writeln(this);
    
    // إضافة الفضيلة إذا كانت متوفرة
    if (fadl != null && fadl.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('✨ الفضيلة:');
      buffer.writeln(fadl);
    }
    
    // إضافة المصدر إذا كان متوفراً
    if (source != null && source.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📚 المصدر: $source');
    }
    
    // إضافة معلومات التطبيق
    if (includeAppInfo) {
      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━');
      buffer.writeln('🌙 تطبيق ذكرني');
      buffer.writeln('للأذكار والأدعية الصحيحة');
    }
    
    return buffer.toString();
  }
}

/// Widget مخصص لعرض النصوص مع الإعدادات الموحدة
class AdaptiveText extends StatelessWidget {
  final String text;
  final ContentType contentType;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool applyDisplaySettings;
  final double? fontSizeMultiplier;
  
  const AdaptiveText(
    this.text, {
    super.key,
    required this.contentType,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.applyDisplaySettings = true,
    this.fontSizeMultiplier,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TextStyle>(
      future: context.getContentTextStyle(
        contentType,
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSizeMultiplier != null 
            ? null // سيتم حسابه داخلياً
            : null,
      ),
      builder: (context, styleSnapshot) {
        if (!styleSnapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        return FutureBuilder<String>(
          future: applyDisplaySettings
              ? _getProcessedText(context)
              : Future.value(text),
          builder: (context, textSnapshot) {
            if (!textSnapshot.hasData) {
              return const SizedBox.shrink();
            }
            
            TextStyle finalStyle = styleSnapshot.data!;
            
            // تطبيق مضاعف حجم الخط إذا كان محدداً
            if (fontSizeMultiplier != null) {
              finalStyle = finalStyle.copyWith(
                fontSize: (finalStyle.fontSize ?? 16.0) * fontSizeMultiplier!,
              );
            }
            
            return Text(
              textSnapshot.data!,
              style: finalStyle,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
              textDirection: TextDirection.rtl,
            );
          },
        );
      },
    );
  }
  
  Future<String> _getProcessedText(BuildContext context) async {
    if (!applyDisplaySettings) return text;
    
    final displaySettings = await context.getDisplaySettings(contentType);
    return text.applyDisplaySettings(displaySettings);
  }
}

// تم نقل GlobalTextSettingsScreen إلى ملف منفصل
// import '../screens/global_text_settings_screen.dart';

class TextPresetDialog extends StatelessWidget {
  final ContentType contentType;
  
  const TextPresetDialog({
    super.key,
    required this.contentType,
  });
  
  @override
  Widget build(BuildContext context) {
    // سيتم تنفيذها لاحقاً
    return AlertDialog(
      title: Text('قوالب ${contentType.displayName}'),
      content: const Text('قريباً'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}

class QuickTextSettingsSheet extends StatelessWidget {
  final ContentType contentType;
  
  const QuickTextSettingsSheet({
    super.key,
    required this.contentType,
  });
  
  @override
  Widget build(BuildContext context) {
    // سيتم تنفيذها لاحقاً
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('إعدادات سريعة - ${contentType.displayName}'),
          const SizedBox(height: 16),
          const Text('قريباً'),
        ],
      ),
    );
  }
}