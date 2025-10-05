// lib/features/quran/screens/quran_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../services/quran_service.dart';
import 'quran_reader_screen.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  late final QuranService _quranService;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _lastSearchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _quranService = getIt<QuranService>();
  }
  
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _lastSearchQuery = '';
      });
      return;
    }
    
    // تجنب البحث المتكرر لنفس النص
    if (query.trim() == _lastSearchQuery) return;
    
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _lastSearchQuery = query.trim();
    });
    
    // تأخير بسيط لتحسين الأداء أثناء الكتابة
    await Future.delayed(const Duration(milliseconds: 500));
    
    // التحقق من أن النص لم يتغير أثناء الانتظار
    if (_lastSearchQuery != query.trim()) return;
    
    try {
      final results = _quranService.searchInQuran(query.trim());
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('خطأ في البحث: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        _showErrorSnackBar('حدث خطأ أثناء البحث');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.background(context),
      appBar: AppBar(
        title: const Text('البحث في القرآن'),
        backgroundColor: ThemeConstants.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
                _searchFocusNode.requestFocus();
              },
              tooltip: 'مسح البحث',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildSearchStats(context),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ThemeConstants.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeConstants.surface(context),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: _searchFocusNode.hasFocus
                ? ThemeConstants.primary
                : ThemeConstants.divider(context),
            width: 1.5.w,
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _performSearch,
          autofocus: true,
          style: AppTextStyles.body1.copyWith(
            color: ThemeConstants.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: 'ابحث في القرآن الكريم...',
            hintStyle: AppTextStyles.body2.copyWith(
              color: ThemeConstants.textSecondary(context),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: ThemeConstants.primary,
              size: 24.sp,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20.sp,
                      color: ThemeConstants.textSecondary(context),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                      _searchFocusNode.requestFocus();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSearchStats(BuildContext context) {
    if (!_hasSearched || _isSearching) return const SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ThemeConstants.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: ThemeConstants.divider(context),
            width: 1.w,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _searchResults.isEmpty ? Icons.search_off : Icons.check_circle,
            color: _searchResults.isEmpty 
                ? ThemeConstants.textSecondary(context)
                : ThemeConstants.primary,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _searchResults.isEmpty
                  ? 'لم يتم العثور على نتائج'
                  : 'تم العثور على ${_searchResults.length} نتيجة',
              style: AppTextStyles.body2.copyWith(
                color: ThemeConstants.textPrimary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: ThemeConstants.primary,
              strokeWidth: 3.w,
            ),
            SizedBox(height: 16.h),
            Text(
              'جارٍ البحث...',
              style: AppTextStyles.body2.copyWith(
                color: ThemeConstants.textSecondary(context),
              ),
            ),
          ],
        ),
      );
    }
    
    if (!_hasSearched) {
      return _buildInitialState(context);
    }
    
    if (_searchResults.isEmpty) {
      return _buildEmptyResults(context);
    }
    
    return _buildResultsList(context);
  }
  
  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
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
              style: AppTextStyles.h4.copyWith(
                color: ThemeConstants.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'اكتب كلمة أو جزء من آية للبحث عنها',
              style: AppTextStyles.body2.copyWith(
                color: ThemeConstants.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            _buildSearchTips(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchTips(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ThemeConstants.card(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ThemeConstants.divider(context),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                color: ThemeConstants.accent,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'نصائح للبحث',
                style: AppTextStyles.body1.copyWith(
                  color: ThemeConstants.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildTipItem(context, 'ابحث بالكلمات الدقيقة للحصول على أفضل النتائج'),
          _buildTipItem(context, 'يمكنك البحث بجزء من الآية'),
          _buildTipItem(context, 'البحث حساس للتشكيل'),
        ],
      ),
    );
  }
  
  Widget _buildTipItem(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: ThemeConstants.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body2.copyWith(
                color: ThemeConstants.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyResults(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: ThemeConstants.textSecondary(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 60.sp,
                color: ThemeConstants.textSecondary(context).withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'لا توجد نتائج',
              style: AppTextStyles.h4.copyWith(
                color: ThemeConstants.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'لم نتمكن من العثور على نتائج لـ "${_lastSearchQuery}"',
              style: AppTextStyles.body2.copyWith(
                color: ThemeConstants.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                _performSearch('');
                _searchFocusNode.requestFocus();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('بحث جديد'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeConstants.primary,
                side: BorderSide(color: ThemeConstants.primary, width: 1.5.w),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
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
  
  Widget _buildResultsList(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildResultCard(context, result, index);
      },
    );
  }
  
  Widget _buildResultCard(BuildContext context, SearchResult result, int index) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeConstants.card(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: ThemeConstants.shadowSm,
        border: Border.all(
          color: ThemeConstants.divider(context).withValues(alpha: 0.5),
          width: 1.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToVerse(result),
          onLongPress: () => _showVerseOptions(context, result),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس النتيجة
                Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        gradient: ThemeConstants.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                            result.surahName,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ThemeConstants.primary,
                            ),
                          ),
                          Text(
                            'الآية ${result.verseNumber}',
                            style: AppTextStyles.caption.copyWith(
                              color: ThemeConstants.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: ThemeConstants.textSecondary(context),
                        size: 20.sp,
                      ),
                      onPressed: () => _showVerseOptions(context, result),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // نص الآية
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: ThemeConstants.surface(context),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    result.verseText,
                    style: AppTextStyles.quranMedium.copyWith(
                      color: ThemeConstants.textPrimary(context),
                      height: 1.8,
                      fontSize: 18.sp,
                    ),
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _navigateToVerse(SearchResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranReaderScreen(
          surahNumber: result.surahNumber,
          initialAyah: result.verseNumber,
        ),
      ),
    );
  }
  
  void _showVerseOptions(BuildContext context, SearchResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeConstants.card(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: ThemeConstants.divider(context),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              
              _buildOptionTile(
                context,
                icon: Icons.copy,
                title: 'نسخ الآية',
                onTap: () {
                  _copyVerse(result);
                  Navigator.pop(context);
                },
              ),
              
              _buildOptionTile(
                context,
                icon: Icons.share,
                title: 'مشاركة الآية',
                onTap: () {
                  _shareVerse(result);
                  Navigator.pop(context);
                },
              ),
              
              _buildOptionTile(
                context,
                icon: Icons.open_in_new,
                title: 'فتح في القارئ',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToVerse(result);
                },
              ),
              
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: ThemeConstants.primary,
        size: 24.sp,
      ),
      title: Text(
        title,
        style: AppTextStyles.body1.copyWith(
          color: ThemeConstants.textPrimary(context),
        ),
      ),
      onTap: onTap,
    );
  }
  
  void _copyVerse(SearchResult result) {
    final text = '${result.verseText}\n\n'
        '(${result.surahName} - الآية ${result.verseNumber})';
    
    Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar('تم نسخ الآية');
  }
  
  void _shareVerse(SearchResult result) {
    final text = '${result.verseText}\n\n'
        '(${result.surahName} - الآية ${result.verseNumber})';
    Share.share(text);
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Text(message),
          ],
        ),
        backgroundColor: ThemeConstants.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Text(message),
          ],
        ),
        backgroundColor: ThemeConstants.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}