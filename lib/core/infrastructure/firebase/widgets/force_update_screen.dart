// lib/core/infrastructure/firebase/widgets/force_update_screen.dart
// Android Only - iOS support removed

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../remote_config_service.dart';

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
  
  String _currentVersion = '1.0.0';
  String _targetVersion = '';
  bool _isLoading = false;

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

  void _loadVersionInfo() {
    setState(() {
      _targetVersion = widget.remoteConfig?.requiredAppVersion ?? '1.1.0';
    });
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(),
                    
                    // أيقونة التحديث
                    ScaleTransition(
                      scale: _bounceAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(32),
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
                        child: const Icon(
                          Icons.system_update,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'تحديث مطلوب',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'يجب تحديث التطبيق للإصدار الأحدث\nللاستمرار في الاستخدام',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade300,
                          height: 1.6,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // معلومات الإصدار
                    ScaleTransition(
                      scale: _bounceAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.shade700.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الإصدار الحالي:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                Text(
                                  _currentVersion,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الإصدار المطلوب:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade600,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _targetVersion,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // مميزات التحديث
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
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
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ميزات جديدة في هذا التحديث:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade300,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            ...['تحسينات الأداء', 'إصلاح الأخطاء', 'ميزات جديدة']
                                .map((feature) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade400,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade300,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // الأزرار
                    Column(
                      children: [
                        // زر التحديث
                        ScaleTransition(
                          scale: _bounceAnimation,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _updateApp,
                              icon: _isLoading 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.download),
                              label: Text(
                                _isLoading ? 'جارٍ فتح المتجر...' : 'تحديث التطبيق الآن',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // زر إغلاق
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: TextButton.icon(
                            onPressed: _exitApp,
                            icon: Icon(
                              Icons.exit_to_app,
                              color: Colors.grey.shade400,
                            ),
                            label: Text(
                              'إغلاق التطبيق',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // زر فحص التحديث
                        if (widget.remoteConfig != null)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: TextButton.icon(
                              onPressed: _checkForUpdates,
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.orange.shade400,
                                size: 18,
                              ),
                              label: Text(
                                'فحص التحديثات',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade400,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// تحديث التطبيق - Android Only
  Future<void> _updateApp() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    try {
      // رابط Google Play Store
      String storeUrl = widget.remoteConfig?.updateUrlAndroid ?? 
          'https://play.google.com/store/apps/details?id=com.example.test_athkar_app';
      
      final Uri url = Uri.parse(storeUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackBar('لا يمكن فتح متجر Google Play');
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء فتح المتجر');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _checkForUpdates() async {
    try {
      HapticFeedback.lightImpact();
      
      if (widget.remoteConfig != null) {
        final success = await widget.remoteConfig!.refresh();
        
        if (success && !widget.remoteConfig!.isForceUpdateRequired) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          _showInfoSnackBar('لا توجد تحديثات جديدة');
        }
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء فحص التحديثات');
    }
  }
  
  void _exitApp() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'إغلاق التطبيق',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في إغلاق التطبيق؟',
          style: TextStyle(
            color: Colors.grey,
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
                fontFamily: 'Cairo',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text(
              'إغلاق',
              style: TextStyle(
                color: Colors.white,
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
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}