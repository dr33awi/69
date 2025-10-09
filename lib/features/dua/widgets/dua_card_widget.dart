// lib/features/dua/widgets/dua_card_widget.dart - محسّن
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../models/dua_model.dart';

class DuaCardWidget extends StatefulWidget {
  final Dua dua;
  final int index;
  final double fontSize;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  const DuaCardWidget({
    super.key,
    required this.dua,
    required this.index,
    required this.fontSize,
    required this.onTap,
    required this.onShare,
    required this.onCopy,
  });

  @override
  State<DuaCardWidget> createState() => _DuaCardWidgetState();
}

class _DuaCardWidgetState extends State<DuaCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
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
    final isRead = widget.dua.readCount > 0;
    final cardColor = isRead ? ThemeConstants.accent : ThemeConstants.primary;
    
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
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isPressed 
                        ? cardColor.withOpacity(0.4)
                        : cardColor.withOpacity(0.2),
                    width: _isPressed ? 1.5.w : 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isPressed 
                          ? cardColor.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: _isPressed ? 10.r : 6.r,
                      offset: Offset(0, _isPressed ? 3.h : 2.h),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(cardColor),
                    SizedBox(height: 12.h),
                    _buildArabicText(),
                    SizedBox(height: 12.h),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color cardColor) {
    return Row(
      children: [
        Container(
          width: 34.r,
          height: 34.r,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardColor, cardColor.withOpacity(0.8)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cardColor.withValues(alpha: 0.25),
                blurRadius: 4.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${widget.index + 1}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: ThemeConstants.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        ),
        
        SizedBox(width: 10.w),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.dua.title,
                style: TextStyle(
                  fontWeight: ThemeConstants.bold,
                  color: cardColor,
                  fontSize: 14.sp,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              
              if (widget.dua.tags.isNotEmpty) ...[
                SizedBox(height: 3.h),
                Wrap(
                  spacing: 5.w,
                  runSpacing: 3.h,
                  children: widget.dua.tags.take(2).map((tag) => 
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999.r),
                        border: Border.all(
                          color: cardColor.withValues(alpha: 0.2),
                          width: 1.w,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: cardColor,
                          fontWeight: ThemeConstants.medium,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
        
        if (widget.dua.readCount > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: ThemeConstants.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(
                color: ThemeConstants.accent.withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: ThemeConstants.accent,
                  size: 11.sp,
                ),
                SizedBox(width: 3.w),
                Text(
                  '${widget.dua.readCount}',
                  style: TextStyle(
                    color: ThemeConstants.accent,
                    fontWeight: ThemeConstants.bold,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildArabicText() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(5.r),
            decoration: BoxDecoration(
              color: ThemeConstants.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.format_quote_rounded,
              color: ThemeConstants.primary,
              size: 14.sp,
            ),
          ),
          
          SizedBox(height: 10.h),
          
          Text(
            widget.dua.arabicText,
            style: TextStyle(
              fontSize: widget.fontSize.sp,
              fontFamily: ThemeConstants.fontFamilyArabic,
              height: 1.8,
              fontWeight: ThemeConstants.medium,
              color: context.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          
          SizedBox(height: 6.h),
          
          Container(
            width: 32.w,
            height: 2.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  ThemeConstants.primary.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        if (widget.dua.source != null)
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: ThemeConstants.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999.r),
                border: Border.all(
                  color: ThemeConstants.tertiary.withValues(alpha: 0.2),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.library_books_rounded,
                    color: ThemeConstants.tertiary,
                    size: 12.sp,
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      widget.dua.source!,
                      style: TextStyle(
                        color: ThemeConstants.tertiary,
                        fontWeight: ThemeConstants.semiBold,
                        fontSize: 12.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        if (widget.dua.source != null) SizedBox(width: 10.w),
        
        Row(
          children: [
            _buildActionButton(
              icon: Icons.share_rounded,
              onPressed: widget.onShare,
              tooltip: 'مشاركة',
            ),
            SizedBox(width: 6.w),
            _buildActionButton(
              icon: Icons.content_copy_rounded,
              onPressed: widget.onCopy,
              tooltip: 'نسخ',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.all(6.r),
            child: Icon(
              icon,
              color: context.textSecondaryColor,
              size: 14.sp,
            ),
          ),
        ),
      ),
    );
  }
}