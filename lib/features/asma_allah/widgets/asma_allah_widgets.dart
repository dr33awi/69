// lib/features/asma_allah/widgets/asma_allah_widgets.dart
import 'package:athkar_app/core/infrastructure/services/share/share_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import '../../../core/infrastructure/services/text_settings/extensions/text_settings_extensions.dart';
import '../../../core/infrastructure/services/text_settings/models/text_settings_models.dart';
import '../models/asma_allah_model.dart';
import '../extensions/asma_allah_extensions.dart';

// ============================================================================
// CompactAsmaAllahCard - البطاقة المضغوطة البسيطة
// ============================================================================
class CompactAsmaAllahCard extends StatefulWidget {
  final AsmaAllahModel item;
  final VoidCallback onTap;

  const CompactAsmaAllahCard({
    super.key,
    required this.item,
    required this.onTap,
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
            borderRadius: BorderRadius.circular(18.r),
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
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: _isPressed 
                        ? color.withValues(alpha: 0.4)
                        : color.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isPressed 
                          ? color.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.06),
                      blurRadius: _isPressed ? 14.r : 12.r,
                      offset: Offset(0, _isPressed ? 6.h : 4.h),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: context.isDarkMode ? 0.08 : 0.03),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildNumberBadge(color),
                    SizedBox(width: 12.w),
                    Expanded(child: _buildNameSection(color)),
                    SizedBox(width: 8.w),
                    _buildDetailsButton(color),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumberBadge(Color color) {
    return Container(
      width: 42.w,
      height: 42.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.15 : 0.06,
            ),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.08 : 0.03,
            ),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
            spreadRadius: -1,
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
    );
  }

  Widget _buildNameSection(Color color) {
    return FutureBuilder<TextStyle>(
      future: context.getAsmaAllahTextStyle(
        color: color,
        fontWeight: ThemeConstants.bold,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            widget.item.name,
            style: TextStyle(
              color: color,
              fontWeight: ThemeConstants.bold,
              fontFamily: 'Amiri',
              fontSize: 40.sp,
            ),
          );
        }
        
        return Text(
          widget.item.name,
          style: snapshot.data!.copyWith(
            color: color,
          ),
        );
      },
    );
  }

  Widget _buildDetailsButton(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'التفاصيل',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: ThemeConstants.bold,
              color: color,
            ),
          ),
          SizedBox(width: 6.w),
          Icon(
            Icons.arrow_back_ios_rounded,
            color: color,
            size: 16.sp,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DetailedAsmaAllahCard - البطاقة المفصلة البسيطة
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
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: color.withOpacity(0.2),
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
            child: Row(
              children: [
                _buildNumberBadge(context, color),
                SizedBox(width: 14.w),
                Expanded(child: _buildNameSection(context, color)),
                SizedBox(width: 10.w),
                _buildDetailsButton(color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberBadge(BuildContext context, Color color) {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
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
          '${item.id}',
          style: context.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: ThemeConstants.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildNameSection(BuildContext context, Color color) {
    return FutureBuilder<TextStyle>(
      future: context.getAsmaAllahTextStyle(
        color: color,
        fontWeight: ThemeConstants.bold,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            item.name,
            style: TextStyle(
              color: color,
              fontWeight: ThemeConstants.bold,
              fontFamily: 'Amiri',
              fontSize: 40.sp,
            ),
          );
        }
        
        return Text(
          item.name,
          style: snapshot.data!.copyWith(
            color: color,
          ),
        );
      },
    );
  }

  Widget _buildDetailsButton(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'عرض التفاصيل',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: ThemeConstants.bold,
              color: color,
            ),
          ),
          SizedBox(width: 6.w),
          Icon(
            Icons.visibility_rounded,
            color: color,
            size: 16.sp,
          ),
        ],
      ),
    );
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
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: context.dividerColor.withValues(alpha: 0.2),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: context.textSecondaryColor.withValues(
                    alpha: 0.1 + (_shimmerAnimation.value * 0.1),
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              
              SizedBox(width: 12.w),
              
              Expanded(
                child: Container(
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: context.textSecondaryColor.withValues(
                      alpha: 0.1 + (_shimmerAnimation.value * 0.1),
                    ),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              
              SizedBox(width: 12.w),
              
              Container(
                width: 80.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: context.textSecondaryColor.withValues(
                    alpha: 0.1 + (_shimmerAnimation.value * 0.1),
                  ),
                  borderRadius: BorderRadius.circular(10.r),
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
// Wrappers للتوافق مع الكود القديم
// ============================================================================

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
    );
  }
}

class UnifiedAsmaAllahCard extends StatelessWidget {
  final AsmaAllahModel item;
  final VoidCallback onTap;
  final bool showActions;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const UnifiedAsmaAllahCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showActions = false,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return CompactAsmaAllahCard(
      item: item,
      onTap: onTap,
    );
  }
}

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
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: context.bodyMedium?.copyWith(fontSize: 13.sp),
        decoration: InputDecoration(
          hintText: 'ابحث في أسماء الله الحسنى...',
          hintStyle: TextStyle(
            color: context.textSecondaryColor.withValues(alpha: 0.7),
            fontSize: 12.sp,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(10.w),
            child: Icon(
              Icons.search_rounded,
              color: context.textSecondaryColor,
              size: 20.sp,
            ),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: context.textSecondaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.clear_rounded,
                      color: context.textSecondaryColor,
                      size: 14.sp,
                    ),
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
          ),
        ),
      ),
    );
  }
}
