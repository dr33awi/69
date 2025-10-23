// lib/features/asma_allah/screens/asma_detail_screen.dart
import 'dart:ui';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/core/infrastructure/services/share/share_extensions.dart';
import 'package:athkar_app/core/infrastructure/services/text/extensions/text_settings_extensions.dart';
import 'package:athkar_app/core/infrastructure/services/text/models/text_settings_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  bool _isFavorite = false;
  
  // إعدادات النص الموحدة
  TextSettings? _textSettings;
  DisplaySettings? _displaySettings;

  @override
  void initState() {
    super.initState();
    
    final list = widget.service.asmaAllahList;
    final initialIndex = list.indexWhere((e) => e.id == widget.item.id);
    _currentIndex = initialIndex >= 0 ? initialIndex : 0;
    _currentItem = list[_currentIndex];

    _pageController = PageController(initialPage: _currentIndex);
    _loadTextSettings();
    _loadFavoriteStatus();
  }

  /// تحميل حالة المفضلة
  Future<void> _loadFavoriteStatus() async {
    try {
      final isFavorite = await widget.service.isFavorite(_currentItem.id.toString());
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
        });
      }
    } catch (e) {
      // في حالة الخطأ، نبقي الحالة الافتراضية
    }
  }
  
  Future<void> _loadTextSettings() async {
    _textSettings = await context.getTextSettings(ContentType.asmaAllah);
    _displaySettings = await context.getDisplaySettings(ContentType.asmaAllah);
    if (mounted) setState(() {});
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
                  // تحديث حالة المفضلة عند تغيير الصفحة
                  _loadFavoriteStatus();
                  HapticFeedback.lightImpact();
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
            icon: Icons.text_fields_rounded,
            onTap: () async {
              await context.showGlobalTextSettings(
                initialContentType: ContentType.asmaAllah,
              );
              await _loadTextSettings();
            },
            isPrimary: true,
          ),
          
          _buildActionButton(
            icon: Icons.copy_rounded,
            onTap: () => _copyContent(_currentItem),
          ),
          
          _buildActionButton(
            icon: _isFavorite ? Icons.bookmark : Icons.bookmark_outline,
            onTap: _toggleFavorite,
            isPrimary: _isFavorite,
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
    bool isPrimary = false,
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
              color: isPrimary 
                  ? ThemeConstants.tertiary 
                  : isSecondary 
                      ? context.textSecondaryColor 
                      : _currentItem.getColor(),
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
    final showTashkeel = _displaySettings?.showTashkeel ?? true;
    
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
        child: AdaptiveText(
          showTashkeel ? item.name : item.name.removeTashkeel(),
          contentType: ContentType.asmaAllah,
          color: Colors.white,
          fontWeight: ThemeConstants.bold,
          textAlign: TextAlign.center,
          applyDisplaySettings: false,
        ),
      ),
    );
  }

  Widget _buildEnhancedExplanationCard(AsmaAllahModel item) {
    final textStyle = _textSettings?.toTextStyle() ?? TextStyle(
      fontSize: 15.sp,
      height: 2.0,
      letterSpacing: 0.3,
    );
    
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
          
          _buildFormattedExplanationText(item, textStyle),
        ],
      ),
    );
  }

  Widget _buildFormattedExplanationText(AsmaAllahModel item, TextStyle baseStyle) {
    final showTashkeel = _displaySettings?.showTashkeel ?? true;
    final text = showTashkeel ? item.explanation : item.explanation.removeTashkeel();
    
    return RichText(
      textAlign: TextAlign.justify,
      text: _buildFormattedTextSpan(text, context, item.getColor(), baseStyle),
    );
  }

  TextSpan _buildFormattedTextSpan(String text, BuildContext context, Color itemColor, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    
    final RegExp ayahPattern = RegExp(r'﴿([^﴾]+)﴾');
    int lastIndex = 0;
    
    for (final match in ayahPattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle.copyWith(
            color: context.textPrimaryColor,
          ),
        ));
      }
      
      spans.add(TextSpan(
        text: match.group(0),
        style: baseStyle.copyWith(
          color: ThemeConstants.tertiary,
          fontFamily: ThemeConstants.fontFamilyQuran,
          fontSize: (baseStyle.fontSize ?? 16).sp + 1,
          fontWeight: ThemeConstants.medium,
          backgroundColor: ThemeConstants.tertiary.withValues(alpha: 0.08),
        ),
      ));
      
      lastIndex = match.end;
    }
    
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle.copyWith(
          color: context.textPrimaryColor,
        ),
      ));
    }
    
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: baseStyle.copyWith(
          color: context.textPrimaryColor,
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

  void _shareContent(AsmaAllahModel item) {
    context.shareAsmaAllah(
      item.name,
      item.explanation,
      meaning: item.meaning,
    );
  }

  /// تبديل حالة المفضلة
  Future<void> _toggleFavorite() async {
    try {
      HapticFeedback.lightImpact();
      
      final newState = await widget.service.toggleFavorite(_currentItem);
      
      if (mounted) {
        setState(() {
          _isFavorite = newState;
        });
      }
      
      // إظهار رسالة تأكيد
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'تمت إضافة الاسم للمفضلة' : 'تمت إزالة الاسم من المفضلة',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحديث المفضلة'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _copyContent(AsmaAllahModel item) {
    context.copyAsmaAllah(
      item.name,
      item.explanation,
      meaning: item.meaning,
    );
  }
}