// lib/core/infrastructure/firebase/widgets/force_update_screen.dart
// مع تسجيل المشاهدة لمنع الظهور بعد التحديث

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get_it/get_it.dart';
import '../remote_config_service.dart';
import '../remote_config_manager.dart';

final GetIt getIt = GetIt.instance;

/// شاشة التحديث الإجباري - مع منع الظهور بعد التحديث
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
  List<String> _featuresList = [];
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
    _acknowledgeUpdateScreen();
  }

  /// تسجيل أن المستخدم شاهد شاشة التحديث
  Future<void> _acknowledgeUpdateScreen() async {
    try {
      if (getIt.isRegistered<RemoteConfigManager>()) {
        final manager = getIt<RemoteConfigManager>();
        await manager.acknowledgeUpdateShown();
      }
    } catch (e) {
    }
  }

  Future<void> _loadVersionInfo() async {
    try {
      setState(() => _isLoadingVersions = true);
      
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      String targetVersion = '';
      String updateUrl = '';
      List<String> features = [];
      
      if (widget.remoteConfig != null && widget.remoteConfig!.isInitialized) {
        targetVersion = widget.remoteConfig!.requiredAppVersion;
        updateUrl = widget.remoteConfig!.updateUrl;
        features = widget.remoteConfig!.updateFeaturesList;
      } 
      else if (getIt.isRegistered<RemoteConfigManager>()) {
        final manager = getIt<RemoteConfigManager>();
        if (manager.isInitialized) {
          targetVersion = manager.requiredAppVersion;
          updateUrl = manager.updateUrl;
          if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
            final service = getIt<FirebaseRemoteConfigService>();
            features = service.updateFeaturesList;
          }
        }
      }
      else if (getIt.isRegistered<FirebaseRemoteConfigService>()) {
        final service = getIt<FirebaseRemoteConfigService>();
        if (service.isInitialized) {
          targetVersion = service.requiredAppVersion;
          updateUrl = service.updateUrl;
          features = service.updateFeaturesList;
        }
      }
      
      if (targetVersion.isEmpty) {
        targetVersion = '2.0.0';
      }
      
      if (updateUrl.isEmpty) {
        updateUrl = 'https://play.google.com/store/apps/details?id=com.example.athkar_app';
      }
      
      if (features.isEmpty) {
        features = ['تحسينات الأداء', 'إصلاح الأخطاء', 'ميزات جديدة'];
      }
      
      setState(() {
        _currentVersion = currentVersion;
        _targetVersion = targetVersion;
        _updateUrl = updateUrl;
        _featuresList = features;
        _isLoadingVersions = false;
      });
    } catch (e) {
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
  
  List<Widget> _buildFeaturesList() {
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
  
  Future<void> _updateApp() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    try {
      String storeUrl = _updateUrl.isNotEmpty 
          ? _updateUrl 
          : 'https://play.google.com/store/apps/details?id=com.example.athkar_app';
      final Uri url = Uri.parse(storeUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        
        // بعد فتح المتجر، تسجيل أن المستخدم قام بمحاولة التحديث
      } else {
        _showErrorSnackBar('لا يمكن فتح الرابط');
      }
    } catch (e) {
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