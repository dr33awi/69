// lib/features/prayer_times/widgets/prayer_method_info_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/prayer_time_model.dart';

/// Dialog يعرض شرح تفصيلي لطرق حساب الصلاة
class PrayerMethodInfoDialog extends StatelessWidget {
  const PrayerMethodInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      backgroundColor: context.cardColor,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: _buildContent(context),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شرح طرق الحساب',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: ThemeConstants.bold,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  'معلومات تفصيلية عن كل طريقة',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroSection(context),
          SizedBox(height: 16.h),
          _buildMethodsList(context),
          SizedBox(height: 16.h),
          _buildImportantNotes(context),
        ],
      ),
    );
  }

  Widget _buildIntroSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: ThemeConstants.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: ThemeConstants.info.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: ThemeConstants.info,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'ما هي طرق الحساب؟',
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  fontSize: 14.sp,
                  color: ThemeConstants.info,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'طرق حساب أوقات الصلاة هي معايير فلكية مختلفة تُستخدم لتحديد وقت الفجر والعشاء بناءً على زاوية الشمس تحت الأفق. تختلف هذه الطرق بين البلدان والمؤسسات الإسلامية بناءً على خطوط العرض والعوامل الجغرافية.',
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.6,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodsList(BuildContext context) {
    final methods = _getMethodsData();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الطرق المتاحة',
          style: TextStyle(
            fontWeight: ThemeConstants.bold,
            fontSize: 15.sp,
          ),
        ),
        SizedBox(height: 12.h),
        ...methods.map((method) => _buildMethodCard(context, method)),
      ],
    );
  }

  Widget _buildMethodCard(BuildContext context, _MethodInfo method) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.1 : 0.04),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          leading: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: method.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              method.icon,
              color: method.color,
              size: 20.sp,
            ),
          ),
          title: Text(
            method.name,
            style: TextStyle(
              fontWeight: ThemeConstants.semiBold,
              fontSize: 13.sp,
            ),
          ),
          subtitle: Text(
            method.region,
            style: TextStyle(
              fontSize: 11.sp,
              color: context.textSecondaryColor,
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: context.backgroundColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        context,
                        'زاوية الفجر:',
                        method.fajrAngle,
                        Icons.wb_twilight_rounded,
                      ),
                      SizedBox(height: 6.h),
                      _buildDetailRow(
                        context,
                        'زاوية العشاء:',
                        method.ishaAngle,
                        Icons.nightlight_round,
                      ),
                    ],
                  ),
                ),
                if (method.description.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Text(
                    method.description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                ],
                if (method.countries.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: method.countries.map((country) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: method.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: method.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        country,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: method.color,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: context.textSecondaryColor),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: context.textSecondaryColor,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: ThemeConstants.semiBold,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildImportantNotes(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: ThemeConstants.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: ThemeConstants.warning.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: ThemeConstants.warning,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'ملاحظات مهمة',
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  fontSize: 13.sp,
                  color: ThemeConstants.warning,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _buildNote(context, '• اختر الطريقة المعتمدة في بلدك أو منطقتك للحصول على أدق النتائج.'),
          SizedBox(height: 4.h),
          _buildNote(context, '• قد تحتاج لإجراء تعديلات يدوية بسيطة حسب موقعك الجغرافي.'),
          SizedBox(height: 4.h),
          _buildNote(context, '• في المناطق القطبية أو ذات خطوط العرض العالية، قد تحتاج لطرق حساب خاصة.'),
        ],
      ),
    );
  }

  Widget _buildNote(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.sp,
        color: context.textSecondaryColor,
        height: 1.5,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 10.h),
              ),
              child: Text(
                'فهمت',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: ThemeConstants.semiBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_MethodInfo> _getMethodsData() {
    return [
      _MethodInfo(
        name: 'رابطة العالم الإسلامي',
        region: 'معيار دولي',
        fajrAngle: '18°',
        ishaAngle: '17°',
        icon: Icons.public,
        color: ThemeConstants.primary,
        description: 'المعيار الأكثر استخداماً عالمياً. تأسست عام 1962 في مكة المكرمة وتُعتبر مرجعاً موثوقاً لحساب أوقات الصلاة.',
        countries: ['أوروبا', 'أمريكا', 'أفريقيا', 'آسيا'],
      ),
      _MethodInfo(
        name: 'أم القرى',
        region: 'السعودية',
        fajrAngle: '18.5°',
        ishaAngle: '90 دقيقة بعد المغرب',
        icon: Icons.mosque,
        color: ThemeConstants.success,
        description: 'تقويم أم القرى الرسمي في المملكة العربية السعودية. يستخدم وقتاً ثابتاً للعشاء (90 دقيقة بعد المغرب) خلال فترة رمضان.',
        countries: ['السعودية', 'دول الخليج'],
      ),
      _MethodInfo(
        name: 'الهيئة المصرية',
        region: 'مصر والشرق الأوسط',
        fajrAngle: '19.5°',
        ishaAngle: '17.5°',
        icon: Icons.place,
        color: Colors.orange,
        description: 'الهيئة المصرية العامة للمساحة. معتمدة في مصر ومعظم دول الشرق الأوسط وأفريقيا.',
        countries: ['مصر', 'السودان', 'لبنان', 'سوريا', 'العراق'],
      ),
      _MethodInfo(
        name: 'جامعة كراتشي',
        region: 'باكستان والهند',
        fajrAngle: '18°',
        ishaAngle: '18°',
        icon: Icons.school,
        color: Colors.green,
        description: 'جامعة العلوم الإسلامية في كراتشي. مناسبة للمناطق ذات خطوط العرض المتوسطة.',
        countries: ['باكستان', 'الهند', 'بنغلاديش', 'أفغانستان'],
      ),
      _MethodInfo(
        name: 'دبي',
        region: 'الإمارات',
        fajrAngle: '18.2°',
        ishaAngle: '18.2°',
        icon: Icons.location_city,
        color: Colors.blue,
        description: 'طريقة دائرة الشؤون الإسلامية والعمل الخيري في دبي.',
        countries: ['الإمارات'],
      ),
      _MethodInfo(
        name: 'قطر',
        region: 'قطر',
        fajrAngle: '18°',
        ishaAngle: '90 دقيقة بعد المغرب',
        icon: Icons.flag,
        color: Colors.purple,
        description: 'معتمدة من وزارة الأوقاف القطرية.',
        countries: ['قطر'],
      ),
      _MethodInfo(
        name: 'الكويت',
        region: 'الكويت',
        fajrAngle: '18°',
        ishaAngle: '17.5°',
        icon: Icons.location_on,
        color: Colors.teal,
        description: 'معتمدة من وزارة الأوقاف الكويتية.',
        countries: ['الكويت'],
      ),
      _MethodInfo(
        name: 'سنغافورة',
        region: 'جنوب شرق آسيا',
        fajrAngle: '20°',
        ishaAngle: '18°',
        icon: Icons.explore,
        color: Colors.red,
        description: 'مجلس الشؤون الدينية الإسلامية في سنغافورة. مناسبة للمناطق الاستوائية.',
        countries: ['سنغافورة', 'ماليزيا', 'إندونيسيا'],
      ),
      _MethodInfo(
        name: 'أمريكا الشمالية',
        region: 'أمريكا وكندا',
        fajrAngle: '15°',
        ishaAngle: '15°',
        icon: Icons.map,
        color: Colors.indigo,
        description: 'الجمعية الإسلامية لأمريكا الشمالية (ISNA). مُحسّنة لخطوط العرض العالية.',
        countries: ['الولايات المتحدة', 'كندا', 'المكسيك'],
      ),
    ];
  }
}

class _MethodInfo {
  final String name;
  final String region;
  final String fajrAngle;
  final String ishaAngle;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> countries;

  const _MethodInfo({
    required this.name,
    required this.region,
    required this.fajrAngle,
    required this.ishaAngle,
    required this.icon,
    required this.color,
    required this.description,
    required this.countries,
  });
}