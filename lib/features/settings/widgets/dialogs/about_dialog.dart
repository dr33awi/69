// lib/features/settings/widgets/dialogs/app_about_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../app/themes/app_theme.dart';

/// حوار معلومات عن التطبيق المحسّن
class AppAboutDialog extends StatefulWidget {
  const AppAboutDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => const AppAboutDialog(),
    );
  }

  @override
  State<AppAboutDialog> createState() => _AppAboutDialogState();
}

class _AppAboutDialogState extends State<AppAboutDialog> {
  String _version = '1.0.0';
  String _buildNumber = '1';
  
  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }
  
  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
      }
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withOpacitySafe(0.1),
              blurRadius: 20.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildContent(context),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withOpacitySafe(0.08),
            context.primaryColor.withOpacitySafe(0.03),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم التطبيق والشعار على اليمين
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم التطبيق
                Text(
                  'ذكرني',
                  style: context.headlineMedium?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: context.primaryColor,
                    fontSize: 26.sp,
                  ),
                ),
                
                SizedBox(height: 4.h),
                
                // الشعار
                Text(
                  'رفيقك اليومي للأذكار والأدعية',
                  style: context.bodyMedium?.copyWith(
                    color: context.textSecondaryColor.withOpacitySafe(0.8),
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // زر الإغلاق على اليسار
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: context.textSecondaryColor.withOpacitySafe(0.08),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 20.sp,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          _buildInfoCard(
            context,
            icon: Icons.task_alt_rounded,
            iconColor: context.primaryColor,
            title: 'رسالة التطبيق',
            description: 'تطبيق ذكرني صُمم لمساعدة المسلمين على المحافظة على أذكارهم اليومية بسهولة ويسر، مع توفير تجربة استخدام سلسة وموثوقة تجمع بين التقنيات الحديثة وروح الإيمان.',
            gradient: LinearGradient(
              colors: [
                context.primaryColor.withOpacitySafe(0.1),
                context.primaryColor.withOpacitySafe(0.05),
              ],
            ),
          ),
          
          SizedBox(height: 12.h),
          
          _buildInfoCard(
            context,
            icon: Icons.visibility_rounded,
            iconColor: AppColors.accent,
            title: 'رؤية التطبيق',
            description: 'أن نصبح التطبيق الإسلامي الأول والأكثر ثقة وتميّزًا في تقديم الأذكار والأدعية للمستخدمين في العالمين العربي والإسلامي.',
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withOpacitySafe(0.1),
                AppColors.accent.withOpacitySafe(0.05),
              ],
            ),
          ),
          
          SizedBox(height: 12.h),
          
          _buildValuesCard(context),
          
          SizedBox(height: 12.h),
          
          _buildFeaturesCard(context),
          
          SizedBox(height: 12.h),
          
          _buildDisclaimerCard(context),
          
          SizedBox(height: 12.h),
          
          _buildInfoCard(
            context,
            icon: Icons.favorite_rounded,
            iconColor: AppColors.success,
            title: 'شكر وتقدير',
            description: 'الحمد لله على توفيقه في إنجاز هذا التطبيق، ونسأل الله أن يجعله عملًا خالصًا لوجهه الكريم، وأن ينفع به المسلمين في كل مكان.',
            gradient: LinearGradient(
              colors: [
                AppColors.success.withOpacitySafe(0.1),
                AppColors.success.withOpacitySafe(0.05),
              ],
            ),
            footer: Container(
              margin: EdgeInsets.only(top: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: context.dividerColor,
                  width: 1.w,
                ),
              ),
              child: Text(
                'تم تطوير التطبيق بواسطة فاعل خير بهدف خدمة الإسلام والمسلمين، ونشر المعرفة الدينية بطريقة عملية وسهلة الوصول للجميع.',
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required LinearGradient gradient,
    Widget? footer,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: iconColor.withOpacitySafe(0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacitySafe(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  size: 20.sp,
                  color: iconColor,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: context.titleMedium?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            description,
            style: context.bodyMedium?.copyWith(
              height: 1.7,
              color: context.textSecondaryColor,
            ),
          ),
          if (footer != null) footer,
        ],
      ),
    );
  }

  // بطاقة التنويه مع خلفية خاصة للنص الإضافي
  Widget _buildDisclaimerCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacitySafe(0.1),
            AppColors.info.withOpacitySafe(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.info.withOpacitySafe(0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacitySafe(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 20.sp,
                  color: AppColors.info,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'تنويه',
                  style: context.titleMedium?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          RichText(
            text: TextSpan(
              style: context.bodyMedium?.copyWith(
                height: 1.7,
                color: context.textSecondaryColor,
              ),
              children: [
                TextSpan(
                  text: 'جميع الأذكار والأدعية والمحتويات الدينية مأخوذة من مصادر موثوقة من القرآن الكريم والسنة النبوية الصحيحة، وتمت مراجعتها بعناية لضمان دقتها وصحتها.',
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacitySafe(0.15),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppColors.warning.withOpacitySafe(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: Text('في حال وجود أي خطأ في أي نص أو مصدر، يرجى التواصل معنا', 
                        style: context.bodySmall?.copyWith(
                        color: AppColors.warning.darken(0.2),
                        fontWeight: ThemeConstants.medium,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuesCard(BuildContext context) {
    final values = [
      {
        'icon': FlutterIslamicIcons.solidQuran2,
        'title': 'الأصالة',
        'desc': 'نحرص على تقديم محتوى موثوق من القرآن الكريم والسنة النبوية الصحيحة',
        'color': context.primaryColor,
      },
      {
        'icon': Icons.touch_app_rounded,
        'title': 'البساطة',
        'desc': 'واجهة استخدام واضحة وسهلة لجميع الفئات',
        'color': AppColors.accent,
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'title': 'الجودة',
        'desc': 'تصميم أنيق وأداء محسن لضمان تجربة مريحة ومستقرة',
        'color': AppColors.tertiary,
      },
      {
        'icon': Icons.volunteer_activism_rounded,
        'title': 'المجانية',
        'desc': 'خدمة مجانية بالكامل لنشر الخير واحتساب الأجر',
        'color': AppColors.success,
      },
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor,
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacitySafe(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  FlutterIslamicIcons.solidMosque,
                  size: 20.sp,
                  color: context.primaryColor,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'القيم الأساسية',
                style: context.titleMedium?.copyWith(
                  fontWeight: ThemeConstants.bold,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...values.map((value) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: (value['color'] as Color).withOpacitySafe(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    value['icon'] as IconData,
                    size: 18.sp,
                    color: value['color'] as Color,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value['title'] as String,
                        style: context.titleSmall?.copyWith(
                          fontWeight: ThemeConstants.bold,
                          color: value['color'] as Color,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        value['desc'] as String,
                        style: context.bodySmall?.copyWith(
                          height: 1.5,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard(BuildContext context) {
    final features = [
      {'icon': Icons.menu_book_rounded, 'text': 'الأذكار اليومية الشاملة'},
      {'icon': FlutterIslamicIcons.solidPrayer, 'text': 'الأدعية الإسلامية الموثقة'},
      {'icon': FlutterIslamicIcons.solidTasbihHand, 'text': 'التسبيح الرقمي الذكي'},
      {'icon': FlutterIslamicIcons.solidMosque, 'text': 'أوقات الصلاة الدقيقة'},
      {'icon': FlutterIslamicIcons.solidQibla, 'text': 'اتجاه القبلة بدقة'},
      {'icon': FlutterIslamicIcons.solidAllah, 'text': 'أسماء الله الحسنى'},
      {'icon': Icons.notifications_active_rounded, 'text': 'نظام إشعارات ذكي'},
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacitySafe(0.05),
            AppColors.primary.withOpacitySafe(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.primaryColor.withOpacitySafe(0.15),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacitySafe(0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: 20.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'الميزات الرئيسية',
                style: context.titleMedium?.copyWith(
                  fontWeight: ThemeConstants.bold,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            final color = AppColors.getAsmaAllahColorByIndex(index);
            
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: color.withOpacitySafe(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      size: 16.sp,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      feature['text'] as String,
                      style: context.bodyMedium?.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: ThemeConstants.medium,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          Divider(
            height: 1.h,
            color: context.dividerColor,
          ),
          
          SizedBox(height: 16.h),
          
          // حقوق النشر
          Text(
            '© ${DateTime.now().year} ذكرني. جميع الحقوق محفوظة',
            style: context.bodySmall?.copyWith(
              color: context.textSecondaryColor.withOpacitySafe(0.7),
              fontSize: 11.sp,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 12.h),
          
          // صنع بحب
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'صُنع بـ',
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor.withOpacitySafe(0.8),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.favorite,
                size: 13.sp,
                color: AppColors.error.withOpacitySafe(0.8),
              ),
              SizedBox(width: 4.w),
              Text(
                'لوجه الله تعالى',
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor.withOpacitySafe(0.8),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // رقم الإصدار
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacitySafe(0.06),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'v$_version',
              style: context.labelSmall?.copyWith(
                color: context.textSecondaryColor.withOpacitySafe(0.7),
                fontSize: 10.sp,
                fontWeight: ThemeConstants.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}