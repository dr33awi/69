// lib/features/prayer_times/widgets/juristic_method_info_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';

/// Dialog يشرح المذاهب الفقهية وتأثيرها على حساب وقت صلاة العصر
class JuristicMethodInfoDialog extends StatelessWidget {
  const JuristicMethodInfoDialog({super.key});

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
                  'شرح المذاهب الفقهية',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: ThemeConstants.bold,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  'الفرق في حساب وقت صلاة العصر',
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
          _buildAsrCalculationSection(context),
          SizedBox(height: 16.h),
          _buildIshaCalculationSection(context),
          SizedBox(height: 16.h),
          _buildMadhabsList(context),
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
                'ما هو الاختلاف بين المذاهب؟',
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
            'يتلخص الاختلاف بين المذهب الحنفي ومذهب الجمهور في مسألتين:',
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.6,
              color: context.textSecondaryColor,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: ThemeConstants.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '1',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: ThemeConstants.bold,
                    color: const Color(0xFF5D7052),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'وقت دخول صلاة العصر (الاختلاف الرئيسي)',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: ThemeConstants.medium,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D7052).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '2',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: ThemeConstants.bold,
                    color: const Color(0xFF5D7052),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'وقت دخول صلاة العشاء (اختلاف بسيط)',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: ThemeConstants.medium,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAsrCalculationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'كيف يُحسب وقت العصر؟',
          style: TextStyle(
            fontWeight: ThemeConstants.bold,
            fontSize: 15.sp,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'يعتمد حساب وقت العصر على طول ظل الشيء:',
          style: TextStyle(
            fontSize: 12.sp,
            color: context.textSecondaryColor,
          ),
        ),
        SizedBox(height: 10.h),
        _buildShadowExplanationCard(
          context,
          'وقت الزوال (الظهر)',
          'عندما تكون الشمس في أعلى نقطة، يكون الظل في أقصر حالاته',
          Icons.wb_sunny,
          Colors.amber,
          '0',
        ),
        SizedBox(height: 8.h),
        _buildShadowExplanationCard(
          context,
          'مذهب الجمهور',
          'يدخل وقت العصر عندما يصير ظل كل شيء مثله (1x)',
          Icons.straighten,
          ThemeConstants.success,
          '1x',
        ),
        SizedBox(height: 8.h),
        _buildShadowExplanationCard(
          context,
          'المذهب الحنفي',
          'يدخل وقت العصر عندما يصير ظل كل شيء مثليه (2x)',
          Icons.straighten,
          ThemeConstants.primary,
          '2x',
        ),
      ],
    );
  }

  Widget _buildShadowExplanationCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    String ratio,
  ) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16.sp, color: color),
                Text(
                  ratio,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: ThemeConstants.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: ThemeConstants.semiBold,
                    fontSize: 12.sp,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: context.textSecondaryColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIshaCalculationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الاختلاف في وقت العشاء',
          style: TextStyle(
            fontWeight: ThemeConstants.bold,
            fontSize: 15.sp,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'يختلف المذهبان في تحديد نهاية المغرب (بداية العشاء) بناءً على الشفق:',
          style: TextStyle(
            fontSize: 12.sp,
            color: context.textSecondaryColor,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: context.backgroundColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: context.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildShafaqCard(
                context,
                'مذهب الجمهور',
                'غياب الشفق الأحمر',
                'بمجرد اختفاء الحمرة من السماء',
                ThemeConstants.success,
                Icons.nights_stay,
                'أسرع',
              ),
              SizedBox(height: 8.h),
              _buildShafaqCard(
                context,
                'المذهب الحنفي',
                'غياب الشفق الأبيض',
                'بعد اختفاء البياض الذي يعقب الحمرة',
                ThemeConstants.primary,
                Icons.bedtime,
                '+12 دقيقة',
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: const Color(0xFF5D7052).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: const Color(0xFF5D7052).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14.sp,
                color: const Color(0xFF5D7052),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'الفرق: حوالي 12 دقيقة فقط، وهو اختلاف بسيط مقارنة بالعصر',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: ThemeConstants.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShafaqCard(
    BuildContext context,
    String madhab,
    String title,
    String description,
    Color color,
    IconData icon,
    String timing,
  ) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 18.sp, color: color),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    madhab,
                    style: TextStyle(
                      fontWeight: ThemeConstants.semiBold,
                      fontSize: 12.sp,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      timing,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: color,
                        fontWeight: ThemeConstants.semiBold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: ThemeConstants.medium,
                  color: context.textPrimaryColor,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMadhabsList(BuildContext context) {
    final madhabs = _getMadhabsData();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المذاهب الأربعة',
          style: TextStyle(
            fontWeight: ThemeConstants.bold,
            fontSize: 15.sp,
          ),
        ),
        SizedBox(height: 12.h),
        ...madhabs.map((madhab) => _buildMadhabCard(context, madhab)),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: ThemeConstants.info.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: ThemeConstants.info.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16.sp,
                    color: ThemeConstants.info,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'الفروقات الزمنية بين المذهبين',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: ThemeConstants.info,
                        fontWeight: ThemeConstants.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D7052).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFF5D7052).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.wb_cloudy, size: 20.sp, color: const Color(0xFF5D7052)),
                          SizedBox(height: 4.h),
                          Text(
                            'العصر',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: ThemeConstants.semiBold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          Text(
                            '30-80 دقيقة',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D7052).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFF5D7052).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.nights_stay, size: 20.sp, color: const Color(0xFF5D7052)),
                          SizedBox(height: 4.h),
                          Text(
                            'العشاء',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: ThemeConstants.semiBold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          Text(
                            '12 دقيقة',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'يختلف الفرق حسب الموسم والموقع الجغرافي',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: context.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMadhabCard(BuildContext context, _MadhabInfo madhab) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: madhab.isDefault 
            ? madhab.color.withOpacity(0.3)
            : context.dividerColor.withOpacity(0.1),
          width: madhab.isDefault ? 1.5 : 1,
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
              color: madhab.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              madhab.icon,
              color: madhab.color,
              size: 20.sp,
            ),
          ),
          title: Row(
            children: [
              Text(
                madhab.name,
                style: TextStyle(
                  fontWeight: ThemeConstants.semiBold,
                  fontSize: 13.sp,
                ),
              ),
              if (madhab.isDefault) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: madhab.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                      color: madhab.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'الافتراضي',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: madhab.color,
                      fontWeight: ThemeConstants.semiBold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            madhab.subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              color: context.textSecondaryColor,
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (madhab.description.isNotEmpty) ...[
                  Text(
                    madhab.description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
                ...madhab.points.map((point) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 4.h),
                        width: 4.w,
                        height: 4.w,
                        decoration: BoxDecoration(
                          color: madhab.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: context.textSecondaryColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                if (madhab.countries.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: madhab.countries.map((country) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: madhab.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: madhab.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        country,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: madhab.color,
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
          _buildNote(context, '• كلا المذهبين صحيح ومعتبر شرعاً ولكل منهما أدلته'),
          SizedBox(height: 4.h),
          _buildNote(context, '• الأصوب والراجح عند العلماء هو مذهب الجمهور'),
          SizedBox(height: 4.h),
          _buildNote(context, '• يُنصح باتباع المذهب السائد في بلدك والصلاة مع الجماعة'),
          SizedBox(height: 4.h),
          _buildNote(context, '• يُسن تعجيل العصر في أول وقتها لعموم الأدلة'),
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

  List<_MadhabInfo> _getMadhabsData() {
    return [
      _MadhabInfo(
        name: 'مذهب الجمهور',
        subtitle: 'الشافعي، المالكي، الحنبلي، وأبو يوسف ومحمد من الحنفية',
        description: 'الرأي الذي عليه أغلب العلماء، وهو المعمول به في معظم البلاد الإسلامية.',
        points: [
          'العصر يبدأ عند مصير ظل كل شيء مثله (1x)',
          'العشاء يبدأ بغياب الشفق الأحمر',
          'يُعطي وقتاً أطول لصلاة الظهر',
          'الدليل: حديث إمامة جبريل "صلى العصر حين صار ظل كل شيء مثله"',
          'كان النبي ﷺ يصلي العصر والشمس مرتفعة حية',
        ],
        countries: [],
        color: ThemeConstants.success,
        icon: Icons.groups,
        isDefault: true,
      ),
      _MadhabInfo(
        name: 'المذهب الحنفي',
        subtitle: 'الإمام أبو حنيفة النعمان',
        description: 'رأي الإمام أبي حنيفة، وعليه معظم المتأخرين من الحنفية.',
        points: [
          'العصر يبدأ عند مصير ظل كل شيء مثليه (2x)',
          'العشاء يبدأ بغياب الشفق الأبيض (متأخر 12 دقيقة)',
          'يُعطي وقتاً أطول لصلاة العصر',
          'يُراعي ظروف العمل والانشغال',
          'الاحتياط واليقين في دخول الوقت',
        ],
        countries: [],
        color: ThemeConstants.primary,
        icon: Icons.person,
        isDefault: false,
      ),
    ];
  }
}

class _MadhabInfo {
  final String name;
  final String subtitle;
  final String description;
  final List<String> points;
  final List<String> countries;
  final Color color;
  final IconData icon;
  final bool isDefault;

  const _MadhabInfo({
    required this.name,
    required this.subtitle,
    required this.description,
    required this.points,
    required this.countries,
    required this.color,
    required this.icon,
    required this.isDefault,
  });
}