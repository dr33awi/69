// lib/features/quran/screens/quran_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_library/quran_library.dart';
import 'package:quran_library/src/audio/audio.dart';
import '../../../app/themes/app_theme.dart';
import 'dart:developer' as dev;

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeQuranLibrary();
  }

  Future<void> _initializeQuranLibrary() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      dev.log('✅ Quran Library initialized successfully');
    } catch (e) {
      dev.log('❌ Error initializing Quran Library: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل في تحميل القرآن الكريم';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: ThemeConstants.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القرآن الكريم',
                  style: context.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: ThemeConstants.bold,
                    fontSize: 20.sp,
                  ),
                ),
                Text(
                  'اقرأ وتدبر آيات الله',
                  style: context.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.book_outlined,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    return _buildQuranContent(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
              strokeWidth: 3.w,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'جاري تحميل القرآن الكريم...',
            style: context.titleMedium?.copyWith(
              color: context.textPrimaryColor,
              fontWeight: ThemeConstants.semiBold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'يرجى الانتظار قليلاً',
            style: context.bodySmall?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: ThemeConstants.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: ThemeConstants.error,
                size: 64.sp,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              _errorMessage ?? 'حدث خطأ',
              style: context.titleMedium?.copyWith(
                color: ThemeConstants.error,
                fontWeight: ThemeConstants.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'يرجى المحاولة مرة أخرى',
              style: context.bodySmall?.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _initializeQuranLibrary,
              icon: Icon(Icons.refresh, size: 20.sp),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuranContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return QuranLibraryScreen(
      parentContext: context,
      isDark: isDark,
      showAyahBookmarkedIcon: true,
      ayahIconColor: context.primaryColor,
      isFontsLocal: false,
      
      // زر تشغيل الآية الواحدة
      anotherMenuChild: Icon(
        Icons.play_arrow_outlined,
        size: 24.sp,
        color: context.primaryColor,
      ),
      anotherMenuChildOnTap: (ayah) {
        try {
          AudioCtrl.instance.playAyah(
            context,
            ayah.ayahUQNumber,
            playSingleAyah: true,
          );
          dev.log('Playing single ayah: ${ayah.ayahUQNumber}');
        } catch (e) {
          dev.log('Error playing ayah: $e');
          if (mounted) {
            context.showErrorSnackBar('فشل تشغيل الآية');
          }
        }
      },
      
      // زر تشغيل من الآية إلى نهاية السورة
      secondMenuChild: Icon(
        Icons.playlist_play,
        size: 24.sp,
        color: context.primaryColor,
      ),
      secondMenuChildOnTap: (ayah) {
        try {
          AudioCtrl.instance.playAyah(
            context,
            ayah.ayahUQNumber,
            playSingleAyah: false,
          );
          dev.log('Playing from ayah to end: ${ayah.ayahUQNumber}');
        } catch (e) {
          dev.log('Error playing continuous: $e');
          if (mounted) {
            context.showErrorSnackBar('فشل تشغيل التلاوة');
          }
        }
      },
    );
  }
}