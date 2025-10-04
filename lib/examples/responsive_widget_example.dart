// مثال شامل لاستخدام flutter_screenutil في التطبيق الإسلامي
// lib/examples/responsive_widget_example.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مثال عملي لكيفية استخدام flutter_screenutil بشكل صحيح
class ResponsiveWidgetExample extends StatelessWidget {
  const ResponsiveWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مثال flutter_screenutil',
          style: TextStyle(fontSize: 18.sp), // ✅ استخدام .sp للنصوص
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w), // ✅ استخدام .w للأبعاد الأفقية
        child: Column(
          children: [
            // مثال على البطاقات المتجاوبة
            _buildResponsiveCard(),
            
            SizedBox(height: 16.h), // ✅ استخدام .h للأبعاد الرأسية
            
            // مثال على الأزرار المتجاوبة
            _buildResponsiveButton(),
            
            SizedBox(height: 16.h),
            
            // مثال على النصوص المتجاوبة
            _buildResponsiveText(),
            
            SizedBox(height: 16.h),
            
            // مثال على الصور المتجاوبة
            _buildResponsiveImage(),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w), // ✅ padding متجاوب
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16.r), // ✅ borderRadius متجاوب
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1.w, // ✅ عرض الحدود متجاوب
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 8.r, // ✅ blur متجاوب
            offset: Offset(0, 2.h), // ✅ offset متجاوب
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w, // ✅ عرض الأيقونة متجاوب
                height: 40.h, // ✅ ارتفاع الأيقونة متجاوب
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.mosque,
                  size: 24.sp, // ✅ حجم الأيقونة متجاوب
                  color: Colors.blue.shade600,
                ),
              ),
              
              SizedBox(width: 12.w), // ✅ مسافة أفقية متجاوبة
              
              Expanded(
                child: Text(
                  'بطاقة متجاوبة',
                  style: TextStyle(
                    fontSize: 16.sp, // ✅ حجم الخط متجاوب
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h), // ✅ مسافة رأسية متجاوبة
          
          Text(
            'هذا مثال على بطاقة تستخدم flutter_screenutil بشكل صحيح. جميع الأبعاد والخطوط متجاوبة.',
            style: TextStyle(
              fontSize: 14.sp, // ✅ نص ثانوي متجاوب
              color: Colors.grey.shade600,
              height: 1.4, // نسبة الارتفاع ثابتة
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveButton() {
    return Container(
      width: double.infinity,
      height: 50.h, // ✅ ارتفاع الزر متجاوب
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r), // ✅ زوايا متجاوبة
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24.w, // ✅ padding أفقي متجاوب
            vertical: 12.h, // ✅ padding رأسي متجاوب
          ),
        ),
        child: Text(
          'زر متجاوب',
          style: TextStyle(
            fontSize: 16.sp, // ✅ نص الزر متجاوب
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان رئيسي
        Text(
          'العناوين المتجاوبة',
          style: TextStyle(
            fontSize: 20.sp, // ✅ عنوان رئيسي
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        
        SizedBox(height: 8.h),
        
        // عنوان فرعي
        Text(
          'عنوان فرعي',
          style: TextStyle(
            fontSize: 16.sp, // ✅ عنوان فرعي
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        
        SizedBox(height: 6.h),
        
        // نص عادي
        Text(
          'نص عادي للقراءة. هذا النص يستخدم أحجام خطوط متجاوبة مع أحجام الشاشات المختلفة.',
          style: TextStyle(
            fontSize: 14.sp, // ✅ نص عادي
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        
        SizedBox(height: 4.h),
        
        // نص صغير
        Text(
          'نص صغير أو ملاحظة',
          style: TextStyle(
            fontSize: 12.sp, // ✅ نص صغير
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveImage() {
    return Container(
      width: double.infinity,
      height: 200.h, // ✅ ارتفاع الصورة متجاوب
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12.r), // ✅ زوايا متجاوبة
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.w,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 64.sp, // ✅ أيقونة كبيرة متجاوبة
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 8.h),
            Text(
              'صورة متجاوبة',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مثال على Grid متجاوب
class ResponsiveGridExample extends StatelessWidget {
  const ResponsiveGridExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'شبكة متجاوبة',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(), // عدد الأعمدة حسب الشاشة
            crossAxisSpacing: 12.w, // ✅ مسافة أفقية متجاوبة
            mainAxisSpacing: 12.h, // ✅ مسافة رأسية متجاوبة
            childAspectRatio: 1.2, // نسبة العرض للارتفاع
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            return _buildGridItem(index);
          },
        ),
      ),
    );
  }

  int _getCrossAxisCount() {
    final screenWidth = ScreenUtil().screenWidth;
    if (screenWidth > 1024) return 4; // Desktop
    if (screenWidth > 600) return 3;  // Tablet
    return 2; // Mobile
  }

  Widget _buildGridItem(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r), // ✅ زوايا متجاوبة
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            size: 32.sp, // ✅ أيقونة متجاوبة
            color: Colors.blue.shade600,
          ),
          SizedBox(height: 8.h),
          Text(
            'عنصر ${index + 1}',
            style: TextStyle(
              fontSize: 14.sp, // ✅ نص متجاوب
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// إرشادات الاستخدام
/// 
/// 1. استخدم .w للأبعاد الأفقية (width, horizontal padding, margin)
/// 2. استخدم .h للأبعاد الرأسية (height, vertical padding, margin)
/// 3. استخدم .sp للخطوط (fontSize)
/// 4. استخدم .r للأبعاد الدائرية (borderRadius, blur)
/// 
/// أمثلة:
/// ✅ width: 100.w
/// ✅ height: 50.h
/// ✅ fontSize: 16.sp
/// ✅ BorderRadius.circular(12.r)
/// ✅ EdgeInsets.all(16.w)
/// ✅ EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h)
/// 
/// تجنب:
/// ❌ width: 100
/// ❌ height: 50
/// ❌ fontSize: 16
/// ❌ BorderRadius.circular(12)
/// ❌ const EdgeInsets.all(16)