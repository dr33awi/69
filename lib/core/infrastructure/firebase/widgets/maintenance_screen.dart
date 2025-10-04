// lib/core/infrastructure/firebase/widgets/maintenance_screen.dart - مصحح مع ScreenUtil

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شاشة الصيانة المصححة
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // بدء الأنيميشن
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // منع الرجوع
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1E1E),
                  Color(0xFF2C2C2C),
                  Color(0xFF1E1E1E),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // أيقونة الصيانة
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: EdgeInsets.all(32.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.build_circle_outlined,
                            size: 80.sp,
                            color: Colors.orange.shade300,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      // العنوان
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'التطبيق قيد الصيانة',
                          style: TextStyle(
                            fontSize: 24.sp,
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
                          'نعمل حالياً على تحسين التطبيق\nلتقديم تجربة أفضل لك',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey.shade300,
                            height: 1.5,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      // مؤشر التحميل
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.grey.shade700,
                              width: 1.w,
                            ),
                          ),
                          child: Column(
                            children: [
                              // مؤشر دوار
                              SizedBox(
                                height: 40.h,
                                width: 40.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.w,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange.shade300,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: 16.h),
                              
                              Text(
                                'جارٍ العمل على التحسينات...',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade400,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      // معلومات إضافية
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade900.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.blue.shade700.withValues(alpha: 0.5),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade300,
                                size: 20.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  'ستتم استعادة الخدمة في أقرب وقت ممكن\nشكراً لصبركم',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.blue.shade200,
                                    height: 1.4,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // زر إعادة المحاولة
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton.icon(
                          onPressed: _retryConnection,
                          icon: Icon(Icons.refresh),
                          label: Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32.w,
                              vertical: 16.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// إعادة المحاولة
  void _retryConnection() {
    HapticFeedback.lightImpact();
    
    // إعادة تشغيل الأنيميشن
    _scaleController.reset();
    _scaleController.forward();
    
    // يمكن إضافة منطق إعادة فحص الاتصال هنا
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'جارٍ فحص الاتصال...',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}