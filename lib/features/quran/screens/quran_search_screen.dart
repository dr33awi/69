// lib/features/quran/screens/quran_search_screen.dart
// شاشة البحث في القرآن الكريم (ميزة اختيارية متقدمة)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/features/quran/services/quran_service.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  late final QuranService _quranService;
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _quranService = getIt<QuranService>();
  }

  void _performSearch(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // تأخير بسيط لتحسين الأداء
      await Future.delayed(const Duration(milliseconds: 300));
      
      final results = _quranService.searchInQuran(query.trim());
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('❌ خطأ في البحث: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _navigateToVerse(SearchResult result) {
    Navigator.pushNamed(
      context,
      '/quran-reader',
      arguments: {
        'surahNumber': result.surahNumber,
        'surahName': result.surahName,
        'verseNumber': result.verseNumber,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: ThemeConstants.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.2),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البحث في القرآن',
                  style: context.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: ThemeConstants.bold,
                    fontSize: 22.sp,
                  ),
                ),
                if (_hasSearched && !_isSearching)
                  Text(
                    '${_searchResults.length} نتيجة',
                    style: context.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.sp,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.search,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(20.w),
      child: TextField(
        controller: _searchController,
        onChanged: _performSearch,
        autofocus: true,
        style: context.bodyLarge?.copyWith(
          fontSize: 16.sp,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن كلمة أو جملة (3 أحرف على الأقل)...',
          hintStyle: context.bodySmall?.copyWith(
            color: context.textSecondaryColor,
            fontSize: 14.sp,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.primaryColor,
            size: 24.sp,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: context.textSecondaryColor,
                    size: 20.sp,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                    HapticFeedback.lightImpact();
                  },
                )
              : null,
          filled: true,
          fillColor: context.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: context.dividerColor.withValues(alpha: 0.3),
              width: 1.w,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: context.primaryColor,
              width: 2.w,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return _buildLoadingState();
    }

    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50.w,
            height: 50.h,
            child: CircularProgressIndicator(
              strokeWidth: 3.w,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.primaryColor,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'جارٍ البحث...',
            style: context.bodyLarge?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
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
                gradient: ThemeConstants.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 60.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'ابحث في القرآن الكريم',
              style: context.titleLarge?.copyWith(
                fontWeight: ThemeConstants.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'أدخل كلمة أو جملة للبحث عنها في آيات القرآن الكريم',
              style: context.bodyMedium?.copyWith(
                color: context.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            _buildSearchTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTips() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: context.primaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'نصائح البحث:',
                style: context.titleSmall?.copyWith(
                  color: context.primaryColor,
                  fontWeight: ThemeConstants.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildTip('الحد الأدنى 3 أحرف للبحث'),
          _buildTip('يمكنك البحث بكلمة واحدة أو جملة كاملة'),
          _buildTip('البحث حساس للتشكيل'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            margin: EdgeInsets.only(top: 6.h),
            decoration: BoxDecoration(
              color: context.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: context.bodySmall?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: context.textSecondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 50.sp,
                color: context.textSecondaryColor,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'لا توجد نتائج',
              style: context.titleLarge?.copyWith(
                fontWeight: ThemeConstants.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'لم نعثر على آيات تحتوي على "${_searchController.text}"',
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
                'جرب كلمات أخرى أو تحقق من التشكيل',
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

  Widget _buildResultsList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.3),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _navigateToVerse(result);
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // رأس البطاقة
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: ThemeConstants.primaryGradient,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            result.surahName,
                            style: context.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: ThemeConstants.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'آية ${result.verseNumber}',
                        style: context.labelMedium?.copyWith(
                          color: context.primaryColor,
                          fontWeight: ThemeConstants.semiBold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: context.textSecondaryColor,
                      size: 16.sp,
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // نص الآية مع التمييز
                RichText(
                  text: TextSpan(
                    children: _buildHighlightedText(result),
                    style: TextStyle(
                      fontSize: 18.sp,
                      height: 1.8,
                      color: context.textPrimaryColor,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(SearchResult result) {
    final parts = result.highlightedText.split('【');
    final spans = <TextSpan>[];

    for (var part in parts) {
      if (part.contains('】')) {
        final innerParts = part.split('】');
        // النص المميز
        spans.add(TextSpan(
          text: innerParts[0],
          style: TextStyle(
            backgroundColor: context.primaryColor.withValues(alpha: 0.2),
            color: context.primaryColor,
            fontWeight: ThemeConstants.bold,
          ),
        ));
        // النص العادي بعده
        if (innerParts.length > 1 && innerParts[1].isNotEmpty) {
          spans.add(TextSpan(text: innerParts[1]));
        }
      } else {
        spans.add(TextSpan(text: part));
      }
    }

    return spans;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}