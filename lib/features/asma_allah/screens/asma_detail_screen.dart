// lib/features/asma_allah/screens/asma_detail_screen.dart - محسن للشاشات الصغيرة
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
            _buildEnhancedAppBar(),
            
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
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 8.w),
          
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Text(
              '${_currentItem.id}',
              style: context.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: ThemeConstants.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          
          SizedBox(width: 8.w),
          
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
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  '${_currentIndex + 1} من $total',
                  style: context.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          
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
      margin: EdgeInsets.only(left: 6.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: context.dividerColor.withValues(alpha: 0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 3.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isSecondary ? context.textSecondaryColor : _currentItem.getColor(),
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentPage(AsmaAllahModel item) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(12.w),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildMainNameCard(item),
          
          SizedBox(height: 12.h),
          
          _buildEnhancedExplanationCard(item),
          
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildMainNameCard(AsmaAllahModel item) {
    final color = item.getColor();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
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
            fontSize: 32.sp,
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: item.getColor().withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: item.getColor().withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: item.getColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: item.getColor(),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'الشرح والتفسير',
                style: context.titleLarge?.copyWith(
                  fontWeight: ThemeConstants.bold,
                  color: item.getColor(),
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          Container(
            height: 2.h,
            width: 70.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.getColor(), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
          
          SizedBox(height: 12.h),
          
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
    
    final RegExp ayahPattern = RegExp(r'﴿([^﴾]+)﴾');
    int lastIndex = 0;
    
    for (final match in ayahPattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: context.bodyLarge?.copyWith(
            height: 2.0.sp,
            fontSize: 15.sp,
            color: context.textPrimaryColor,
            letterSpacing: 0.3,
          ),
        ));
      }
      
      spans.add(TextSpan(
        text: match.group(0),
        style: context.titleMedium?.copyWith(
          color: ThemeConstants.tertiary,
          fontFamily: ThemeConstants.fontFamilyQuran,
          fontSize: 16.sp,
          fontWeight: ThemeConstants.medium,
          height: 1.8,
          backgroundColor: ThemeConstants.tertiary.withValues(alpha: 0.08),
        ),
      ));
      
      lastIndex = match.end;
    }
    
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: context.bodyLarge?.copyWith(
          height: 2.0,
          fontSize: 15.sp,
          color: context.textPrimaryColor,
          letterSpacing: 0.3,
        ),
      ));
    }
    
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: context.bodyLarge?.copyWith(
          height: 2.0,
          fontSize: 15.sp,
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
      padding: EdgeInsets.all(12.w),
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
            blurRadius: 8.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canPrev ? _goToPrevious : null,
              icon: Icon(Icons.chevron_left_rounded, size: 18.sp),
              label: Text('السابق', style: TextStyle(fontSize: 12.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: canPrev ? context.surfaceColor : context.surfaceColor.withOpacity(0.5),
                foregroundColor: canPrev 
                    ? context.textPrimaryColor 
                    : context.textSecondaryColor.withOpacity(0.5),
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                side: BorderSide(
                  color: context.dividerColor.withValues(alpha: 0.3),
                  width: 1.w,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
          
          SizedBox(width: 10.w),
          
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 6.h,
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
                fontSize: 11.sp,
              ),
            ),
          ),
          
          SizedBox(width: 10.w),
          
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canNext ? _goToNext : null,
              icon: Icon(Icons.chevron_right_rounded, size: 18.sp),
              label: Text('التالي', style: TextStyle(fontSize: 12.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: canNext ? color : context.surfaceColor.withOpacity(0.5),
                foregroundColor: canNext 
                    ? Colors.white 
                    : context.textSecondaryColor.withOpacity(0.5),
                elevation: canNext ? 2 : 0,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                side: canNext 
                    ? null
                    : BorderSide(
                        color: context.dividerColor.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
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