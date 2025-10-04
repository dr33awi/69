// lib/features/asma_allah/screens/asma_detail_screen.dart - محدث مع flutter_screenutil
import 'dart:ui';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../models/asma_allah_model.dart';
import '../services/asma_allah_service.dart';
import '../extensions/asma_allah_extensions.dart';

class UnifiedAsmaAllahDetailsScreen extends StatefulWidget {
  final AsmaAllahModel item;
  final AsmaAllahService service;

  const UnifiedAsmaAllahDetailsScreen({
    super.key,
    required this.item,
    required this.service,
  });

  @override
  State<UnifiedAsmaAllahDetailsScreen> createState() => 
      _UnifiedAsmaAllahDetailsScreenState();
}

class _UnifiedAsmaAllahDetailsScreenState 
    extends State<UnifiedAsmaAllahDetailsScreen> {
  
  late AsmaAllahModel _currentItem;
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    
    final list = widget.service.asmaAllahList;
    final initialIndex = list.indexWhere((e) => e.id == widget.item.id);
    _currentIndex = initialIndex >= 0 ? initialIndex : 0;
    _currentItem = list[_currentIndex];

    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // شريط التطبيق المحسن (متناسق مع صفحة الصلوات)
            _buildEnhancedAppBar(),
            
            // المحتوى الرئيسي مع PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.service.asmaAllahList.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _currentItem = widget.service.asmaAllahList[index];
                  });
                  HapticFeedback.selectionClick();
                },
                itemBuilder: (_, index) {
                  final item = widget.service.asmaAllahList[index];
                  return _buildContentPage(item);
                },
              ),
            ),
            
            // شريط التنقل السفلي
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    final total = widget.service.asmaAllahList.length;
    final color = _currentItem.getColor();
    
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // زر الرجوع (متناسق مع صفحة الصلوات)
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 12.w),
          
          // أيقونة مميزة (نفس ستايل صفحة الصلوات)
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Text(
              '${_currentItem.id}',
              style: context.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: ThemeConstants.bold,
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // معلومات الاسم الحالي
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentItem.name,
                  style: context.titleLarge?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: color,
                    fontFamily: ThemeConstants.fontFamilyArabic,
                  ),
                ),
                Text(
                  '${_currentIndex + 1} من $total',
                  style: context.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // أزرار الإجراءات (نفس ستايل صفحة الصلوات)
          _buildActionButton(
            icon: Icons.copy_rounded,
            onTap: () => _copyContent(_currentItem),
          ),
          
          _buildActionButton(
            icon: Icons.share_rounded,
            onTap: () => _shareContent(_currentItem),
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.dividerColor.withValues(alpha: 0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isSecondary ? context.textSecondaryColor : _currentItem.getColor(),
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentPage(AsmaAllahModel item) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // بطاقة الاسم الرئيسية
          _buildMainNameCard(item),
          
          SizedBox(height: 16.h),
          
          // بطاقة الشرح المفصل مع الآيات المميزة
          _buildEnhancedExplanationCard(item),
          
          // مساحة إضافية في الأسفل
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildMainNameCard(AsmaAllahModel item) {
    final color = item.getColor();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Center(
        child: Text(
          item.name,
          style: context.displayMedium?.copyWith(
            color: Colors.white,
            fontWeight: ThemeConstants.bold,
            fontFamily: ThemeConstants.fontFamilyArabic,
            height: 1.h,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: Offset(0, 2.h),
                blurRadius: 4.r,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEnhancedExplanationCard(AsmaAllahModel item) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: item.getColor().withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: item.getColor().withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: item.getColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: item.getColor(),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'الشرح والتفسير',
                style: context.titleLarge?.copyWith(
                  fontWeight: ThemeConstants.bold,
                  color: item.getColor(),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // خط فاصل
          Container(
            height: 2.h,
            width: 80.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.getColor(), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // نص الشرح المفصل مع الآيات المميزة
          _buildFormattedExplanationText(item),
        ],
      ),
    );
  }

  Widget _buildFormattedExplanationText(AsmaAllahModel item) {
    return RichText(
      textAlign: TextAlign.justify,
      text: _buildFormattedTextSpan(item.explanation, context, item.getColor()),
    );
  }

  TextSpan _buildFormattedTextSpan(String text, BuildContext context, Color itemColor) {
    final List<TextSpan> spans = [];
    
    // البحث عن الآيات بين ﴿ و ﴾
    final RegExp ayahPattern = RegExp(r'﴿([^﴾]+)﴾');
    int lastIndex = 0;
    
    for (final match in ayahPattern.allMatches(text)) {
      // إضافة النص العادي قبل الآية
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: context.bodyLarge?.copyWith(
            height: 2.2.sp,
            fontSize: 17.sp,
            color: context.textPrimaryColor,
            letterSpacing: 0.3,
          ),
        ));
      }
      
      // إضافة الآية مميزة
      spans.add(TextSpan(
        text: match.group(0), // النص الكامل مع ﴿ و ﴾
        style: context.titleMedium?.copyWith(
          color: ThemeConstants.tertiary,
          fontFamily: ThemeConstants.fontFamilyQuran,
          fontSize: 18.sp,
          fontWeight: ThemeConstants.medium,
          height: 2.0,
          backgroundColor: ThemeConstants.tertiary.withValues(alpha: 0.08),
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // إضافة باقي النص بعد آخر آية
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: context.bodyLarge?.copyWith(
          height: 2.2,
          fontSize: 17.sp,
          color: context.textPrimaryColor,
          letterSpacing: 0.3,
        ),
      ));
    }
    
    // إذا لم توجد آيات، عرض النص كاملاً بالتنسيق العادي
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: context.bodyLarge?.copyWith(
          height: 2.2,
          fontSize: 17.sp,
          color: context.textPrimaryColor,
          letterSpacing: 0.3,
        ),
      ));
    }
    
    return TextSpan(children: spans);
  }

  Widget _buildBottomNavigationBar() {
    final canPrev = _currentIndex > 0;
    final canNext = _currentIndex < widget.service.asmaAllahList.length - 1;
    final color = _currentItem.getColor();
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          top: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.2),
            width: 1.h,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر السابق
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canPrev ? _goToPrevious : null,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('السابق'),
              style: ElevatedButton.styleFrom(
                backgroundColor: canPrev ? context.surfaceColor : context.surfaceColor.withOpacity(0.5),
                foregroundColor: canPrev 
                    ? context.textPrimaryColor 
                    : context.textSecondaryColor.withOpacity(0.5),
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                side: BorderSide(
                  color: context.dividerColor.withValues(alpha: 0.3),
                  width: 1.w,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // مؤشر الصفحة
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.w,
              ),
            ),
            child: Text(
              '${_currentIndex + 1} / ${widget.service.asmaAllahList.length}',
              style: context.labelMedium?.copyWith(
                color: color,
                fontWeight: ThemeConstants.bold,
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // زر التالي
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canNext ? _goToNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('التالي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: canNext ? color : context.surfaceColor.withOpacity(0.5),
                foregroundColor: canNext 
                    ? Colors.white 
                    : context.textSecondaryColor.withOpacity(0.5),
                elevation: canNext ? 2 : 0,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                side: canNext 
                    ? null
                    : BorderSide(
                        color: context.dividerColor.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                shadowColor: canNext ? color.withValues(alpha: 0.3) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.service.asmaAllahList.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _copyContent(AsmaAllahModel item) {
    final content = '''${item.name}

الشرح والتفسير: ${item.explanation}

من تطبيق أذكاري - أسماء الله الحسنى''';

    Clipboard.setData(ClipboardData(text: content));
    
    context.showSuccessSnackBar('تم نسخ المحتوى بنجاح');
    HapticFeedback.mediumImpact();
  }

  void _shareContent(AsmaAllahModel item) {
    final content = '''${item.name}

الشرح والتفسير: ${item.explanation}

من تطبيق أذكاري - أسماء الله الحسنى''';

    Share.share(
      content,
      subject: 'أسماء الله الحسنى - ${item.name}',
    );
    
    HapticFeedback.lightImpact();
  }
}