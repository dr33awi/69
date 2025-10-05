// lib/core/infrastructure/firebase/widgets/force_update_screen.dart
// شاشة التحديث الإجباري الكاملة مع قائمة الميزات من Firebase

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get_it/get_it.dart';
import '../remote_config_service.dart';
import '../remote_config_manager.dart';

// تعريف getIt محلياً
final GetIt getIt = GetIt.instance;

/// شاشة التحديث الإجباري - Android Only
class ForceUpdateScreen extends StatefulWidget {
  final FirebaseRemoteConfigService? remoteConfig;
  
  const ForceUpdateScreen({
    super.key,
    this.remoteConfig,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  
  String _currentVersion = 'جاري التحميل...';
  String _targetVersion = 'جاري التحميل...';
  String _updateUrl = '';
  List<String> _featuresList = []; // قائمة الميزات من Firebase
  bool _isLoading = false;
  bool _isLoadingVersions = true;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _bounceController.forward();
    });
    
    _loadVersionInfo();
  }

  /// تحميل معلومات الإصدار وقائمة الميزات من Firebase
  Future<void> _loadVersionInfo() async {
    try {
      setState(() => _isLoadingVersions = true);
      
      // 1. جلب الإصدار الحالي من PackageInfo
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      debugPrint('📱 Package Version: $currentVersion');
      
      // 2. جلب البيانات من Remote Config
      String targetVersion = '';
      String updateUrl = '';
      List<String> features = [];
      
      // محاولة من widget.remoteConfig أولاً
      if (widget.remoteConfig != null && widget.remoteConfig!.isInitialized) {
        targetVersion = widget.remoteConfig!.requiredAppVersion;
        updateUrl = widget.remoteConfig!.updateUrl;
        features = widget.remoteConfig!.updateFeaturesList;
        debugPrint('✅ Got data from widget.remoteConfig');
      } 
      // محاولة من RemoteConfigManager
      else if (getIt.isRegistered<RemoteConfigManager>()) {
        final manager = getIt<RemoteConfigManager>();
        if (manager.isInitialized) {
          targetVersion = manager.requiredAppVersion;
          updateUrl = manager.updateUrl;
          // نحتاج لجلب الميزات من FirebaseRemoteConfigService
          if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
            final service = getIt<FirebaseRemoteConfigService>();
            features = service.updateFeaturesList;
          }
          debugPrint('✅ Got data from RemoteConfigManager');
        }
      }
      // محاولة من FirebaseRemoteConfigService مباشرة
      else if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final service = getIt<FirebaseRemoteConfigService>();
        if (service.isInitialized) {
          targetVersion = service.requiredAppVersion;
          updateUrl = service.updateUrl;
          features = service.updateFeaturesList;
          debugPrint('✅ Got data from FirebaseRemoteConfigService');
        }
      }
      
      // إذا لم نحصل على قيم، استخدم الافتراضية
      if (targetVersion.isEmpty) {
        targetVersion = '2.0.0';
        debugPrint('⚠️ Using default target version');
      }
      
      if (updateUrl.isEmpty) {
        updateUrl = 'https://play.google.com/store/apps/details?id=com.example.athkar_app';
        debugPrint('⚠️ Using default update URL');
      }
      
      if (features.isEmpty) {
        features = ['تحسينات الأداء', 'إصلاح الأخطاء', 'ميزات جديدة'];
        debugPrint('⚠️ Using default features list');
      }
      
      setState(() {
        _currentVersion = currentVersion;
        _targetVersion = targetVersion;
        _updateUrl = updateUrl;
        _featuresList = features;
        _isLoadingVersions = false;
      });
      
      debugPrint('📊 Version Info Loaded:');
      debugPrint('  - Current: $_currentVersion');
      debugPrint('  - Target: $_targetVersion');
      debugPrint('  - URL: $_updateUrl');
      debugPrint('  - Features: $_featuresList');
      
    } catch (e) {
      debugPrint('❌ Error loading version info: $e');
      setState(() {
        _currentVersion = '1.0.0';
        _targetVersion = '2.0.0';
        _updateUrl = 'https://play.google.com/store/apps/details?id=com.example.athkar_app';
        _featuresList = ['تحسينات الأداء', 'إصلاح الأخطاء', 'ميزات جديدة'];
        _isLoadingVersions = false;
      });
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1421),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1421),
                  Color(0xFF1A2332),
                  Color(0xFF0D1421),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 16.h,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    
                    // أيقونة التحديث
                    ScaleTransition(
                      scale: _bounceAnimation,
                      child: Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.system_update,
                          size: 60.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // العنوان
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'تحديث مطلوب',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    // الوصف
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'يجب تحديث التطبيق للإصدار الأحدث\nللاستمرار في الاستخدام',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade300,
                          height: 1.5,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // معلومات الإصدار
                    ScaleTransition(
                      scale: _bounceAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.blue.shade700.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: _isLoadingVersions 
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                              ),
                            )
                          : Column(
                              children: [
                                _buildVersionRow(
                                  'الإصدار الحالي:',
                                  _currentVersion,
                                  isHighlighted: false,
                                ),
                                
                                SizedBox(height: 12.h),
                                
                                _buildVersionRow(
                                  'الإصدار المطلوب:',
                                  _targetVersion,
                                  isHighlighted: true,
                                ),
                              ],
                            ),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // مميزات التحديث (من Firebase)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.green.shade700.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.new_releases,
                                  color: Colors.green.shade300,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'ميزات جديدة في هذا التحديث:',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade300,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 12.h),
                            
                            ..._buildFeaturesList(),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // الأزرار
                    _buildActionButtons(),
                    
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildVersionRow(String label, String version, {required bool isHighlighted}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.grey.shade400,
            fontFamily: 'Cairo',
          ),
        ),
        if (isHighlighted)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              version,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          )
        else
          Text(
            version,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
      ],
    );
  }
  
  /// بناء قائمة الميزات من Firebase
  List<Widget> _buildFeaturesList() {
    // استخدم القائمة المحفوظة من Firebase
    final features = _featuresList.isNotEmpty 
        ? _featuresList 
        : ['تحسينات الأداء', 'إصلاح الأخطاء', 'ميزات جديدة'];
    
    return features.map((feature) => Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade400,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade300,
                fontFamily: 'Cairo',
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    )).toList();
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        // زر التحديث
        ScaleTransition(
          scale: _bounceAnimation,
          child: SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _updateApp,
              icon: _isLoading 
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.download, size: 20.sp),
              label: Text(
                _isLoading ? 'جارٍ فتح المتجر...' : 'تحديث التطبيق الآن',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // زر إغلاق
        FadeTransition(
          opacity: _fadeAnimation,
          child: TextButton.icon(
            onPressed: _exitApp,
            icon: Icon(
              Icons.exit_to_app,
              color: Colors.grey.shade400,
              size: 18.sp,
            ),
            label: Text(
              'إغلاق التطبيق',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade400,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// تحديث التطبيق - فتح المتجر أو الرابط
  Future<void> _updateApp() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    try {
      // استخدم الرابط المحدث
      String storeUrl = _updateUrl.isNotEmpty 
          ? _updateUrl 
          : 'https://play.google.com/store/apps/details?id=com.example.athkar_app';
      
      debugPrint('🔗 Opening URL: $storeUrl');
      
      final Uri url = Uri.parse(storeUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackBar('لا يمكن فتح الرابط');
      }
    } catch (e) {
      debugPrint('❌ Error opening URL: $e');
      _showErrorSnackBar('حدث خطأ أثناء فتح المتجر');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _exitApp() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'إغلاق التطبيق',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontFamily: 'Cairo',
          ),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في إغلاق التطبيق؟',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14.sp,
            fontFamily: 'Cairo',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14.sp,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'إغلاق',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}