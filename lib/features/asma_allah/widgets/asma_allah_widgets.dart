// lib/features/asma_allah/widgets/asma_allah_widgets.dart - محدث مع flutter_screenutil
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import '../models/asma_allah_model.dart';
import '../extensions/asma_allah_extensions.dart';

// ============================================================================
// CompactAsmaAllahCard - البطاقة المضغوطة الموحدة مع الشرح المفصل
// ============================================================================
class CompactAsmaAllahCard extends StatefulWidget {
  final AsmaAllahModel item;
  final VoidCallback onTap;
  final bool showQuickActions;
  final bool showExplanationPreview;

  const CompactAsmaAllahCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showQuickActions = false,
    this.showExplanationPreview = true,
  });

  @override
  State<CompactAsmaAllahCard> createState() => _CompactAsmaAllahCardState();
}

class _CompactAsmaAllahCardState extends State<CompactAsmaAllahCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.item.getColor();
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) {
                setState(() => _isPressed = true);
                _controller.forward();
                HapticFeedback.lightImpact();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _controller.reverse();
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
                _controller.reverse();
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isPressed 
                        ? color.withOpacity(0.4)
                        : color.withOpacity(0.2),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isPressed 
                          ? color.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: _isPressed ? 12.r : 8.r,
                      offset: Offset(0, _isPressed ? 4.h : 2.h),
                    ),
                  ],
                ),
                child: _buildCardContent(color),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(Color color) {
    return Column(
      children: [
        // الصف الرئيسي
        Row(
          children: [
            // الرقم مع الخلفية الملونة
            Container(
              width: 44.w,
              height: 44.h,
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
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.item.id}',
                  style: context.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: ThemeConstants.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // محتوى الاسم والمعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم الله
                  Text(
                    widget.item.name,
                    style: context.titleMedium?.copyWith(
                      color: color,
                      fontWeight: ThemeConstants.bold,
                      fontFamily: ThemeConstants.fontFamilyArabic,
                      fontSize: 16.sp,
                    ),
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  // معاينة المعنى
                  Text(
                    _getTruncatedText(widget.item.meaning, 50),
                    style: context.bodySmall?.copyWith(
                      color: context.textSecondaryColor,
                      height: 1.3,
                      fontSize: 12.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // أيقونة التفاعل
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: color,
                size: 18.sp,
              ),
            ),
          ],
        ),
        
        // معاينة الشرح المفصل (اختيارية)
        if (widget.showExplanationPreview) ...[
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1.w,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 14.sp,
                      color: color,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'الشرح والتفسير',
                      style: context.labelSmall?.copyWith(
                        color: color,
                        fontWeight: ThemeConstants.medium,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                RichText(
                  text: _buildPreviewTextSpan(widget.item.explanation, context, 80),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
        
        // أزرار الإجراءات السريعة
        if (widget.showQuickActions) ...[
          SizedBox(height: 12.h),
          _buildQuickActions(color),
        ],
      ],
    );
  }

  Widget _buildQuickActions(Color color) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.copy_rounded,
            label: 'نسخ',
            color: ThemeConstants.primary,
            onTap: _copyName,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildActionButton(
            icon: Icons.share_rounded,
            label: 'مشاركة',
            color: color,
            onTap: _shareName,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: 4.h,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.sp,
                color: color,
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: context.labelSmall?.copyWith(
                  color: color,
                  fontWeight: ThemeConstants.medium,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _buildPreviewTextSpan(String text, BuildContext context, int maxLength) {
    // قطع النص إلى الطول المطلوب أولاً
    String truncatedText = _getTruncatedText(text, maxLength);
    
    final List<TextSpan> spans = [];
    
    // البحث عن الآيات بين ﴿ و ﴾
    final RegExp ayahPattern = RegExp(r'﴿([^﴾]+)﴾');
    int lastIndex = 0;
    
    for (final match in ayahPattern.allMatches(truncatedText)) {
      // إضافة النص العادي قبل الآية
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: truncatedText.substring(lastIndex, match.start),
          style: context.labelSmall?.copyWith(
            color: context.textSecondaryColor,
            height: 1.4,
            fontSize: 11.sp,
          ),
        ));
      }
      
      // إضافة الآية مميزة
      spans.add(TextSpan(
        text: match.group(0), // النص الكامل مع ﴿ و ﴾
        style: context.labelSmall?.copyWith(
          color: ThemeConstants.tertiary,
          fontFamily: ThemeConstants.fontFamilyQuran,
          fontWeight: ThemeConstants.medium,
          height: 1.4,
          fontSize: 11.sp,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // إضافة باقي النص بعد آخر آية
    if (lastIndex < truncatedText.length) {
      spans.add(TextSpan(
        text: truncatedText.substring(lastIndex),
        style: context.labelSmall?.copyWith(
          color: context.textSecondaryColor,
          height: 1.4,
          fontSize: 11.sp,
        ),
      ));
    }
    
    // إذا لم توجد آيات، عرض النص كاملاً بالتنسيق العادي
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: truncatedText,
        style: context.labelSmall?.copyWith(
          color: context.textSecondaryColor,
          height: 1.4,
          fontSize: 11.sp,
        ),
      ));
    }
    
    return TextSpan(children: spans);
  }

  String _getTruncatedText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    
    final words = text.split(' ');
    final truncatedWords = <String>[];
    var currentLength = 0;
    
    for (final word in words) {
      if (currentLength + word.length + 1 <= maxLength) {
        truncatedWords.add(word);
        currentLength += word.length + 1;
      } else {
        break;
      }
    }
    
    return '${truncatedWords.join(' ')}...';
  }

  void _copyName() {
    final text = '''${widget.item.name}

الشرح والتفسير: ${widget.item.explanation}

من تطبيق أذكاري - أسماء الله الحسنى''';

    Clipboard.setData(ClipboardData(text: text));
    
    context.showSuccessSnackBar('تم نسخ الاسم بنجاح');
    HapticFeedback.mediumImpact();
  }

  void _shareName() {
    final content = '''${widget.item.name}

الشرح والتفسير: ${widget.item.explanation}

من تطبيق أذكاري - أسماء الله الحسنى''';

    Share.share(
      content,
      subject: 'أسماء الله الحسنى - ${widget.item.name}',
    );
    
    HapticFeedback.lightImpact();
  }
}

// ============================================================================
// DetailedAsmaAllahCard - البطاقة المفصلة الجديدة
// ============================================================================
class DetailedAsmaAllahCard extends StatelessWidget {
  final AsmaAllahModel item;
  final VoidCallback onTap;

  const DetailedAsmaAllahCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.getColor();
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة مع الاسم والرقم
                _buildCardHeader(context, color),
                
                SizedBox(height: 12.h),
                
                // المعنى
                _buildMeaningSection(context),
                
                SizedBox(height: 12.h),
                
                // معاينة الشرح المفصل
                _buildExplanationPreview(context, color),
                
                SizedBox(height: 12.h),
                
                // زر المشاهدة التفصيلية
                _buildViewDetailsButton(context, color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, Color color) {
    return Row(
      children: [
        // رقم الاسم
        Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${item.id}',
              style: context.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: ThemeConstants.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
        
        SizedBox(width: 12.w),
        
        // اسم الله
        Expanded(
          child: Text(
            item.name,
            style: context.displaySmall?.copyWith(
              color: color,
              fontWeight: ThemeConstants.bold,
              fontFamily: ThemeConstants.fontFamilyArabic,
              fontSize: 24.sp,
            ),
          ),
        ),
        
        // أيقونة الانتقال
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: color,
          size: 20.sp,
        ),
      ],
    );
  }

  Widget _buildMeaningSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المعنى',
          style: context.titleSmall?.copyWith(
            color: context.textSecondaryColor,
            fontWeight: ThemeConstants.medium,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          item.meaning,
          style: context.bodyMedium?.copyWith(
            color: context.textPrimaryColor,
            height: 1.6,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationPreview(BuildContext context, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 16.sp,
                color: color,
              ),
              SizedBox(width: 4.w),
              Text(
                'الشرح والتفسير',
                style: context.titleSmall?.copyWith(
                  color: color,
                  fontWeight: ThemeConstants.medium,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          RichText(
            text: _buildDetailedPreviewTextSpan(item.explanation, context, 120),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildViewDetailsButton(BuildContext context, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          Icons.visibility_rounded,
          size: 18.sp,
        ),
        label: const Text('عرض التفاصيل الكاملة'),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          side: BorderSide(
            color: color.withValues(alpha: 0.3),
            width: 1.w,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  TextSpan _buildDetailedPreviewTextSpan(String text, BuildContext context, int maxLength) {
    // قطع النص إلى الطول المطلوب أولاً
    String truncatedText = _getTruncatedText(text, maxLength);
    
    final List<TextSpan> spans = [];
    
    // البحث عن الآيات بين ﴿ و ﴾
    final RegExp ayahPattern = RegExp(r'﴿([^﴾]+)﴾');
    int lastIndex = 0;
    
    for (final match in ayahPattern.allMatches(truncatedText)) {
      // إضافة النص العادي قبل الآية
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: truncatedText.substring(lastIndex, match.start),
          style: context.bodySmall?.copyWith(
            color: context.textSecondaryColor,
            height: 1.5,
            fontSize: 12.sp,
          ),
        ));
      }
      
      // إضافة الآية مميزة
      spans.add(TextSpan(
        text: match.group(0), // النص الكامل مع ﴿ و ﴾
        style: context.bodySmall?.copyWith(
          color: ThemeConstants.tertiary,
          fontFamily: ThemeConstants.fontFamilyQuran,
          fontWeight: ThemeConstants.medium,
          height: 1.5,
          fontSize: 12.sp,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // إضافة باقي النص بعد آخر آية
    if (lastIndex < truncatedText.length) {
      spans.add(TextSpan(
        text: truncatedText.substring(lastIndex),
        style: context.bodySmall?.copyWith(
          color: context.textSecondaryColor,
          height: 1.5,
          fontSize: 12.sp,
        ),
      ));
    }
    
    // إذا لم توجد آيات، عرض النص كاملاً بالتنسيق العادي
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: truncatedText,
        style: context.bodySmall?.copyWith(
          color: context.textSecondaryColor,
          height: 1.5,
          fontSize: 12.sp,
        ),
      ));
    }
    
    return TextSpan(children: spans);
  }

  String _getTruncatedText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    
    final words = text.split(' ');
    final truncatedWords = <String>[];
    var currentLength = 0;
    
    for (final word in words) {
      if (currentLength + word.length + 1 <= maxLength) {
        truncatedWords.add(word);
        currentLength += word.length + 1;
      } else {
        break;
      }
    }
    
    return '${truncatedWords.join(' ')}...';
  }
}

// ============================================================================
// LoadingCard - بطاقة التحميل
// ============================================================================
class AsmaAllahLoadingCard extends StatefulWidget {
  const AsmaAllahLoadingCard({super.key});

  @override
  State<AsmaAllahLoadingCard> createState() => _AsmaAllahLoadingCardState();
}

class _AsmaAllahLoadingCardState extends State<AsmaAllahLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: context.dividerColor.withValues(alpha: 0.2),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              // شكل الرقم
              Container(
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  color: context.textSecondaryColor.withValues(
                    alpha: 0.1 + (_shimmerAnimation.value * 0.1),
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // شكل النص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20.h,
                      width: double.infinity * 0.4,
                      decoration: BoxDecoration(
                        color: context.textSecondaryColor.withValues(
                          alpha: 0.1 + (_shimmerAnimation.value * 0.1),
                        ),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      height: 14.h,
                      width: double.infinity * 0.8,
                      decoration: BoxDecoration(
                        color: context.textSecondaryColor.withValues(
                          alpha: 0.05 + (_shimmerAnimation.value * 0.05),
                        ),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      height: 14.h,
                      width: double.infinity * 0.6,
                      decoration: BoxDecoration(
                        color: context.textSecondaryColor.withValues(
                          alpha: 0.05 + (_shimmerAnimation.value * 0.05),
                        ),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// للتوافق مع الكود الموجود - Wrappers
// ============================================================================

/// البطاقة المحسنة - للتوافق مع الكود الموجود
class EnhancedAsmaAllahCard extends StatelessWidget {
  final AsmaAllahModel item;
  final VoidCallback onTap;

  const EnhancedAsmaAllahCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CompactAsmaAllahCard(
      item: item,
      onTap: onTap,
      showExplanationPreview: true,
    );
  }
}

/// البطاقة الموحدة - للتوافق مع الكود الموجود
class UnifiedAsmaAllahCard extends StatelessWidget {
  final AsmaAllahModel item;
  final VoidCallback onTap;
  final bool showActions;

  const UnifiedAsmaAllahCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return CompactAsmaAllahCard(
      item: item,
      onTap: onTap,
      showQuickActions: showActions,
      showExplanationPreview: true,
    );
  }
}

/// البطاقة الأساسية - للتوافق مع الكود الموجود
class AsmaAllahCard extends StatelessWidget {
  final AsmaAllahModel item;
  final VoidCallback onTap;
  
  const AsmaAllahCard({
    super.key,
    required this.item,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return CompactAsmaAllahCard(
      item: item,
      onTap: onTap,
    );
  }
}

// ============================================================================
// Search Bar المحسن
// ============================================================================
class EnhancedAsmaAllahSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  
  const EnhancedAsmaAllahSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: context.bodyMedium?.copyWith(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'ابحث في أسماء الله الحسنى أو معانيها أو تفسيرها...',
          hintStyle: TextStyle(
            color: context.textSecondaryColor.withValues(alpha: 0.7),
            fontSize: 14.sp,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(12.w),
            child: Icon(
              Icons.search_rounded,
              color: context.textSecondaryColor,
              size: 24.sp,
            ),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: context.textSecondaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.clear_rounded,
                      color: context.textSecondaryColor,
                      size: 16.sp,
                    ),
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }
}