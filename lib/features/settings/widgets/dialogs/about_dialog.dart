// lib/features/settings/widgets/dialogs/app_about_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/themes/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      contentPadding: EdgeInsets.zero,
      backgroundColor: context.cardColor,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              _buildContent(context),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // زر الإغلاق
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              iconSize: 20.sp,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // اسم التطبيق
          Text(
            'ذكرني',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          // الشعار
          Text(
            'رفيقك اليومي',
              style: TextStyle(
              fontSize: 12.sp,
              color: context.textSecondaryColor,
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
          // رسالة التطبيق
          _buildMissionCard(context),
          
          SizedBox(height: 16.h),
          
          // رؤية التطبيق
          _buildVisionCard(context),
          
          SizedBox(height: 16.h),
          
          // القيم الأساسية
          _buildValuesCard(context),
          
          SizedBox(height: 16.h),
          

          
          SizedBox(height: 16.h),
          
          // الميزات
          _buildFeaturesCard(context),
          
          SizedBox(height: 16.h),
          
          // تنويه
          _buildDisclaimerCard(context),
          
          SizedBox(height: 16.h),
          
          // شكر وتقدير
          _buildThanksCard(context),
        ],
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor.withValues(alpha: 0.1),
            context.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt, size: 18.sp, color: context.primaryColor),
              SizedBox(width: 8.w),
              Text(
                'رسالة التطبيق',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'تطبيق ذكرني صُمم لمساعدة المسلمين على المحافظة على أذكارهم اليومية بسهولة ويسر، مع توفير تجربة استخدام سلسة وموثوقة تجمع بين التقنيات الحديثة وروح الإيمان.',
            style: TextStyle(
              fontSize: 11.sp,
              height: 1.7,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisionCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.withValues(alpha: 0.1),
            Colors.amber.withValues(alpha: 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, size: 18.sp, color: Colors.amber[700]),
              SizedBox(width: 8.w),
              Text(
                'رؤية التطبيق',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'أن نصبح التطبيق الإسلامي الأول والأكثر ثقة وتميّزًا في تقديم الأذكار والأدعية للمستخدمين في العالمين العربي والإسلامي.',
            style: TextStyle(
              fontSize: 11.sp,
              height: 1.7,
              color: Colors.grey[700],
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
        'desc': 'نحرص على تقديم محتوى موثوق من القرآن الكريم والسنة النبوية الصحيحة'
      },
      {
        'icon': Icons.touch_app,
        'title': 'البساطة',
        'desc': 'واجهة استخدام واضحة وسهلة لجميع الفئات'
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'الجودة',
        'desc': 'تصميم أنيق وأداء محسن لضمان تجربة مريحة ومستقرة'
      },
      {
        'icon': Icons.volunteer_activism,
        'title': 'المجانية',
        'desc': 'خدمة مجانية بالكامل لنشر الخير واحتساب الأجر'
      },
    ];

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.1),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FlutterIslamicIcons.solidMosque, size: 18.sp, color: context.primaryColor),
              SizedBox(width: 8.w),
              Text(
                'القيم الأساسية',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...values.map((value) => Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    value['icon'] as IconData,
                    size: 16.sp,
                    color: context.primaryColor,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value['title'] as String,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        value['desc'] as String,
                        style: TextStyle(
                          fontSize: 10.sp,
                          height: 1.5,
                          color: Colors.grey[600],
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
      {'icon': Icons.notifications_active, 'text': 'نظام إشعارات ذكي'},
    ];

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, size: 18.sp, color: context.primaryColor),
              SizedBox(width: 8.w),
              Text(
                'الميزات الرئيسية',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...features.map((feature) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Icon(
                  feature['icon'] as IconData,
                  size: 14.sp,
                  color: context.primaryColor,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    feature['text'] as String,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, size: 18.sp, color: Colors.blue[700]),
              SizedBox(width: 8.w),
              Text(
                'تنويه',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'جميع الأذكار والأدعية والمحتويات الدينية مأخوذة من مصادر موثوقة من القرآن الكريم والسنة النبوية الصحيحة، وتمت مراجعتها بعناية لضمان دقتها وصحتها.',
            style: TextStyle(
              fontSize: 11.sp,
              height: 1.7,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThanksCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.green.withValues(alpha: 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, size: 18.sp, color: Colors.green[700]),
              SizedBox(width: 8.w),
              Text(
                'شكر وتقدير',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'الحمد لله على توفيقه في إنجاز هذا التطبيق، ونسأل الله أن يجعله عملًا خالصًا لوجهه الكريم، وأن ينفع به المسلمين في كل مكان، ويجزي كل من ساهم أو دعم هذا العمل خير الجزاء.',
            style: TextStyle(
              fontSize: 11.sp,
              height: 1.7,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'تم تطوير التطبيق بواسطة فاعل خير بهدف خدمة الإسلام والمسلمين، ونشر المعرفة الدينية بطريقة عملية وسهلة الوصول للجميع.',
              style: TextStyle(
                fontSize: 10.sp,
                height: 1.6,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          Divider(height: 1.h),
          SizedBox(height: 12.h),
          

          SizedBox(height: 12.h),
          
          // أزرار الإجراءات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                icon: Icons.email,
                label: 'تواصل',
                onTap: () => _launchUrl('dhakaranifeedback@gmail.com'),
              ),
              _buildActionButton(
                context,
                icon: Icons.bug_report,
                label: 'بلّغ عن خطأ',
                onTap: () => _launchUrl('dhakaranifeedback@gmail.com'),
              ),
              _buildActionButton(
                context,
                icon: Icons.share,
                label: 'مشاركة',
                onTap: _shareApp,
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // معلومات الإصدار
          Text(
            'الإصدار v$_version',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // حقوق النشر
          Text(
            '© ${DateTime.now().year} ذكرني. جميع الحقوق محفوظة',
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          children: [
            Icon(icon, size: 20.sp, color: context.primaryColor),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: context.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يمكن فتح الرابط'),
              backgroundColor: ThemeConstants.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _shareApp() {
    Navigator.pop(context);
    // هنا يمكنك إضافة كود المشاركة
  }
}