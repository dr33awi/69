// lib/features/quran/widgets/verse_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../services/quran_service.dart';

class VerseCard extends StatelessWidget {
  final VerseData verse;
  final double fontSize;
  final bool isBookmarked;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkToggle;
  
  const VerseCard({
    super.key,
    required this.verse,
    this.fontSize = 22.0,
    this.isBookmarked = false,
    this.onTap,
    this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: ThemeConstants.card(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: ThemeConstants.shadowSm,
        border: Border.all(
          color: isBookmarked
              ? ThemeConstants.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // رأس البطاقة
                Row(
                  children: [
                    // رقم الآية
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        gradient: ThemeConstants.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          verse.verseNumber.toString(),
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    // معلومات الآية
                    Expanded(
                      child: Row(
                        children: [
                          _buildInfoBadge(
                            context,
                            icon: Icons.book,
                            label: 'جزء ${verse.juzNumber}',
                          ),
                          SizedBox(width: 8.w),
                          _buildInfoBadge(
                            context,
                            icon: Icons.description,
                            label: 'ص ${verse.pageNumber}',
                          ),
                        ],
                      ),
                    ),
                    
                    // أيقونة الإشارة المرجعية
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked
                            ? ThemeConstants.primary
                            : ThemeConstants.textSecondary(context),
                        size: 24.sp,
                      ),
                      onPressed: onBookmarkToggle,
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // نص الآية
                Text(
                  verse.text,
                  style: AppTextStyles.quran.copyWith(
                    fontSize: fontSize.sp,
                    color: ThemeConstants.textPrimary(context),
                    height: 2.0,
                  ),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: ThemeConstants.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: ThemeConstants.primary,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: ThemeConstants.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}