// lib/examples/unified_text_settings_example.dart
// مثال على كيفية استخدام النظام الموحد لإعدادات النصوص

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app/themes/app_theme.dart';
import '../core/infrastructure/services/text/models/text_settings_models.dart';
import '../core/infrastructure/services/text/extensions/text_settings_extensions.dart';

/// مثال شامل على استخدام النظام الموحد لإعدادات النصوص
class UnifiedTextSettingsExample extends StatefulWidget {
  const UnifiedTextSettingsExample({super.key});

  @override
  State<UnifiedTextSettingsExample> createState() => _UnifiedTextSettingsExampleState();
}

class _UnifiedTextSettingsExampleState extends State<UnifiedTextSettingsExample> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال النظام الموحد للنصوص'),
        backgroundColor: context.backgroundColor,
        foregroundColor: context.textPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroSection(),
            SizedBox(height: 24.h),
            _buildExamplesSection(),
            SizedBox(height: 24.h),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  /// قسم التقديم
  Widget _buildIntroSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ThemeConstants.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ThemeConstants.primary.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: ThemeConstants.primary,
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            'النظام الموحد لإعدادات النصوص',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: ThemeConstants.bold,
              color: ThemeConstants.primary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'يتيح هذا النظام إدارة موحدة لجميع إعدادات النصوص في التطبيق من مكان واحد، مع دعم أنواع مختلفة من المحتوى (أذكار، دعاء، أسماء الله، قرآن) وقوالب جاهزة للاستخدام.',
            style: TextStyle(
              fontSize: 14.sp,
              height: 1.6,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// قسم الأمثلة
  Widget _buildExamplesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أمثلة الاستخدام',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: ThemeConstants.bold,
            color: context.textPrimaryColor,
          ),
        ),
        SizedBox(height: 16.h),
        
        // مثال الأذكار
        _buildContentExample(
          ContentType.athkar,
          'بِسْمِ اللَّهِ الَّذِي لا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
          Icons.article_rounded,
        ),
        
        SizedBox(height: 16.h),
        
        // مثال الدعاء
        _buildContentExample(
          ContentType.dua,
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
          Icons.volunteer_activism_rounded,
        ),
        
        SizedBox(height: 16.h),
        
        // مثال أسماء الله
        _buildContentExample(
          ContentType.asmaAllah,
          'الرَّحْمَنُ الرَّحِيمُ • الْمَلِكُ الْقُدُّوسُ السَّلَامُ',
          Icons.star_rounded,
        ),
      ],
    );
  }

  /// مثال لنوع محتوى معين
  Widget _buildContentExample(ContentType contentType, String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ThemeConstants.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                contentType.displayName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: ThemeConstants.bold,
                  color: ThemeConstants.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // النص مع الإعدادات الموحدة
          AdaptiveText(
            text,
            contentType: contentType,
            color: context.textPrimaryColor,
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 12.h),
          
          // معلومات الإعدادات
          FutureBuilder<TextSettings>(
            future: context.getTextSettings(contentType),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final settings = snapshot.data!;
              return Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ThemeConstants.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    _buildSettingInfo('حجم الخط', '${settings.fontSize.round()}'),
                    _buildSettingInfo('نوع الخط', settings.fontFamily),
                    _buildSettingInfo('تباعد الأسطر', settings.lineHeight.toStringAsFixed(1)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// عرض معلومة إعداد
  Widget _buildSettingInfo(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: ThemeConstants.medium,
              color: ThemeConstants.info,
            ),
          ),
        ],
      ),
    );
  }

  /// قسم الإجراءات
  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجراءات المتاحة',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: ThemeConstants.bold,
            color: context.textPrimaryColor,
          ),
        ),
        SizedBox(height: 16.h),
        
        // زر فتح الإعدادات العامة
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.showGlobalTextSettings(),
            icon: Icon(Icons.settings_rounded, size: 20.sp),
            label: const Text('فتح الإعدادات العامة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // أزرار الأمثلة السريعة
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _applyPresetExample(),
                icon: Icon(Icons.auto_fix_high_rounded, size: 18.sp),
                label: const Text('قالب جاهز'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeConstants.accent,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showQuickSettingsExample(),
                icon: Icon(Icons.tune_rounded, size: 18.sp),
                label: const Text('إعدادات سريعة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeConstants.tertiary,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12.h),
        
        // زر إعادة التعيين
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _resetAllSettingsExample(),
            icon: Icon(Icons.restore_rounded, size: 18.sp),
            label: const Text('إعادة تعيين جميع الإعدادات'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ThemeConstants.warning,
              side: BorderSide(color: ThemeConstants.warning),
            ),
          ),
        ),
      ],
    );
  }

  /// مثال تطبيق قالب جاهز
  Future<void> _applyPresetExample() async {
    try {
      // تطبيق قالب "قراءة مريحة" على الأذكار
      await context.applyPresetToContent(
        ContentType.athkar,
        TextStylePresets.comfortable,
      );
      
      setState(() {}); // لتحديث الواجهة
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تطبيق القالب الجاهز على الأذكار'),
            backgroundColor: ThemeConstants.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: ThemeConstants.error,
          ),
        );
      }
    }
  }

  /// مثال الإعدادات السريعة
  Future<void> _showQuickSettingsExample() async {
    await context.showQuickTextSettings(ContentType.dua);
  }

  /// مثال إعادة تعيين جميع الإعدادات
  Future<void> _resetAllSettingsExample() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد'),
        content: const Text('هل تريد إعادة تعيين جميع إعدادات النصوص؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.warning,
            ),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.resetAllTextSettings();
        setState(() {});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم إعادة تعيين جميع الإعدادات'),
              backgroundColor: ThemeConstants.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
              backgroundColor: ThemeConstants.error,
            ),
          );
        }
      }
    }
  }
}