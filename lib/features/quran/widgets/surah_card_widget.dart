// lib/features/quran/widgets/surah_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/features/quran/services/quran_service.dart';

/// ويدجت بطاقة السورة - قابلة لإعادة الاستخدام
class SurahCardWidget extends StatelessWidget {
  final SurahInfo surah;
  final VoidCallback onTap;
  final bool isLastRead;

  const SurahCardWidget({
    super.key,
    required this.surah,
    required this.onTap,
    this.isLastRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isLastRead
              ? context.primaryColor.withValues(alpha: 0.5)
              : context.dividerColor.withValues(alpha: 0.3),
          width: isLastRead ? 2.w : 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isLastRead
                ? context.primaryColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isLastRead ? 12.r : 8.r,
            offset: Offset(0, isLastRead ? 4.h : 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                _buildSurahNumber(context),
                SizedBox(width: 16.w),
                _buildSurahInfo(context),
                _buildArrowIcon(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahNumber(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // الخلفية المزخرفة
        Container(
          width: 52.w,
          height: 52.h,
          decoration: BoxDecoration(
            gradient: isLastRead
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.primaryColor,
                      context.primaryColor.darken(0.2),
                    ],
                  )
                : ThemeConstants.primaryGradient,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
        ),
        // الرقم
        Text(
          '${surah.number}',
          style: context.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: ThemeConstants.bold,
            fontSize: 20.sp,
          ),
        ),
        // شارة "آخر قراءة"
        if (isLastRead)
          Positioned(
            top: -4.h,
            right: -4.w,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: ThemeConstants.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.cardColor,
                  width: 2.w,
                ),
              ),
              child: Icon(
                Icons.bookmark,
                color: Colors.white,
                size: 12.sp,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSurahInfo(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم السورة بالعربي
          Text(
            surah.nameArabic,
            style: context.titleMedium?.copyWith(
              fontWeight: ThemeConstants.bold,
              fontSize: 18.sp,
              color: isLastRead ? context.primaryColor : context.textPrimaryColor,
            ),
          ),
          SizedBox(height: 6.h),
          // معلومات السورة
          Row(
            children: [
              // مكية/مدنية
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 3.h,
                ),
                decoration: BoxDecoration(
                  color: surah.isMakki
                      ? ThemeConstants.primary.withValues(alpha: 0.15)
                      : ThemeConstants.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: surah.isMakki
                        ? ThemeConstants.primary.withValues(alpha: 0.3)
                        : ThemeConstants.accent.withValues(alpha: 0.3),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      surah.isMakki ? Icons.brightness_7 : Icons.brightness_4,
                      size: 12.sp,
                      color: surah.isMakki
                          ? ThemeConstants.primary
                          : ThemeConstants.accent,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      surah.isMakki ? 'مكية' : 'مدنية',
                      style: context.labelSmall?.copyWith(
                        color: surah.isMakki
                            ? ThemeConstants.primary
                            : ThemeConstants.accent,
                        fontSize: 11.sp,
                        fontWeight: ThemeConstants.semiBold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // فاصل
              Container(
                width: 1.w,
                height: 12.h,
                color: context.dividerColor,
              ),
              SizedBox(width: 8.w),
              // عدد الآيات
              Icon(
                Icons.format_list_numbered,
                size: 14.sp,
                color: context.textSecondaryColor,
              ),
              SizedBox(width: 4.w),
              Text(
                '${surah.totalAyahs} آية',
                style: context.bodySmall?.copyWith(
                  color: context.textSecondaryColor,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArrowIcon(BuildContext context) {
    return Container(
      width: 32.w,
      height: 32.h,
      decoration: BoxDecoration(
        color: isLastRead
            ? context.primaryColor.withValues(alpha: 0.15)
            : context.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        Icons.arrow_forward_ios,
        color: isLastRead ? context.primaryColor : context.textSecondaryColor,
        size: 16.sp,
      ),
    );
  }
}

/// ويدجت بطاقة "تابع القراءة"
class ContinueReadingCard extends StatelessWidget {
  final ReadingPosition position;
  final VoidCallback onTap;

  const ContinueReadingCard({
    super.key,
    required this.position,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConstants.accent,
            ThemeConstants.accent.darken(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: ThemeConstants.accent.withValues(alpha: 0.4),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                // أيقونة التشغيل
                Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2.w,
                    ),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                // المعلومات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تابع القراءة',
                        style: context.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark,
                              color: Colors.white,
                              size: 14.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${position.surahName} - آية ${position.verseNumber}',
                              style: context.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 13.sp,
                                fontWeight: ThemeConstants.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // السهم
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ويدجت حالة فارغة للبحث
class EmptySearchState extends StatelessWidget {
  final String query;

  const EmptySearchState({
    super.key,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 60.sp,
                color: context.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'لا توجد نتائج',
              style: context.titleLarge?.copyWith(
                color: context.textPrimaryColor,
                fontWeight: ThemeConstants.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'لم نعثر على سور تطابق "$query"',
              style: context.bodyMedium?.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'جرب البحث بكلمات أخرى',
                style: context.bodySmall?.copyWith(
                  color: context.primaryColor,
                  fontWeight: ThemeConstants.medium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ويدجت حالة التحميل
class QuranLoadingState extends StatelessWidget {
  const QuranLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60.w,
            height: 60.h,
            child: CircularProgressIndicator(
              strokeWidth: 3.w,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.primaryColor,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'جارٍ تحميل القرآن الكريم...',
            style: context.bodyLarge?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}