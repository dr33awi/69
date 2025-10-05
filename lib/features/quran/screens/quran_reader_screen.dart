// lib/features/quran/screens/quran_reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../services/quran_service.dart';
import '../widgets/verse_card.dart';
import '../widgets/reader_settings_sheet.dart';

class QuranReaderScreen extends StatefulWidget {
  final int surahNumber;
  final int initialAyah;
  
  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah = 1,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late final QuranService _quranService;
  late final ScrollController _scrollController;
  
  late SurahInfo _surahInfo;
  List<VerseData> _verses = [];
  Set<int> _bookmarkedVerses = {};
  
  double _fontSize = 22.0;
  bool _isLoading = true;
  bool _showAppBar = true;
  
  @override
  void initState() {
    super.initState();
    _quranService = getIt<QuranService>();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _surahInfo = _quranService.getSurahInfo(widget.surahNumber);
    _verses = _quranService.getSurahVerses(widget.surahNumber);
    _fontSize = await _quranService.getFontSize();
    
    // تحميل الإشارات المرجعية
    final bookmarks = await _quranService.getBookmarks();
    _bookmarkedVerses = bookmarks
        .where((b) => b.surahNumber == widget.surahNumber)
        .map((b) => b.verseNumber)
        .toSet();
    
    setState(() => _isLoading = false);
    
    // التمرير للآية المحددة
    if (widget.initialAyah > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToVerse(widget.initialAyah);
      });
    }
  }
  
  void _onScroll() {
    if (_scrollController.offset > 100 && _showAppBar) {
      setState(() => _showAppBar = false);
    } else if (_scrollController.offset <= 100 && !_showAppBar) {
      setState(() => _showAppBar = true);
    }
  }
  
  void _scrollToVerse(int verseNumber) {
    final index = verseNumber - 1;
    if (index >= 0 && index < _verses.length) {
      _scrollController.animateTo(
        index * 120.h,
        duration: ThemeConstants.durationNormal,
        curve: Curves.easeInOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(context),
          
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: ThemeConstants.primary,
                ),
              ),
            )
          else ...[
            _buildSurahHeader(),
            _buildVersesList(),
          ],
        ],
      ),
      
      bottomNavigationBar: _buildBottomBar(context),
    );
  }
  
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.h,
      floating: true,
      pinned: true,
      backgroundColor: ThemeConstants.primary,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedOpacity(
          opacity: _showAppBar ? 1.0 : 0.0,
          duration: ThemeConstants.durationFast,
          child: Text(
            _surahInfo.nameArabic,
            style: AppTextStyles.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: ThemeConstants.primaryGradient,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.white, size: 24.sp),
          onPressed: () => _showSearchDialog(context),
        ),
        IconButton(
          icon: Icon(Icons.settings, color: Colors.white, size: 24.sp),
          onPressed: () => _showSettingsSheet(context),
        ),
      ],
    );
  }
  
  Widget _buildSurahHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: ThemeConstants.primaryGradient,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: ThemeConstants.shadowMd,
        ),
        child: Column(
          children: [
            Text(
              _surahInfo.nameArabic,
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 8.h),
            
            Text(
              _surahInfo.name,
              style: AppTextStyles.body1.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            
            SizedBox(height: 12.h),
            
            Wrap(
              spacing: 12.w,
              runSpacing: 8.h,
              alignment: WrapAlignment.center,
              children: [
                _buildInfoChip(
                  icon: Icons.place,
                  label: _surahInfo.revelationTypeArabic,
                ),
                _buildInfoChip(
                  icon: Icons.format_list_numbered,
                  label: '${_surahInfo.totalVerses} آية',
                ),
                _buildInfoChip(
                  icon: Icons.tag,
                  label: 'رقم ${_surahInfo.number}',
                ),
              ],
            ),
            
            // البسملة (ما عدا سورة التوبة)
            if (widget.surahNumber != 9) ...[
              SizedBox(height: 20.h),
              Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: AppTextStyles.quranMedium.copyWith(
                  color: Colors.white,
                  fontSize: 24.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVersesList() {
    return SliverPadding(
      padding: EdgeInsets.all(16.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final verse = _verses[index];
            final isBookmarked = _bookmarkedVerses.contains(verse.verseNumber);
            
            return VerseCard(
              verse: verse,
              fontSize: _fontSize,
              isBookmarked: isBookmarked,
              onTap: () => _showVerseActions(context, verse),
              onBookmarkToggle: () => _toggleBookmark(verse),
            );
          },
          childCount: _verses.length,
        ),
      ),
    );
  }
  
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ThemeConstants.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomButton(
              icon: Icons.bookmark_border,
              label: 'المحفوظات',
              onTap: () => _showBookmarks(context),
            ),
            _buildBottomButton(
              icon: Icons.format_size,
              label: 'حجم الخط',
              onTap: () => _showFontSizeDialog(context),
            ),
            _buildBottomButton(
              icon: Icons.share,
              label: 'مشاركة',
              onTap: () => _shareSurah(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: ThemeConstants.primary,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: ThemeConstants.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ==================== Actions ====================
  
  void _showVerseActions(BuildContext context, VerseData verse) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeConstants.card(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
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
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'الآية ${verse.verseNumber}',
                style: AppTextStyles.h5.copyWith(
                  color: ThemeConstants.textPrimary(context),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            _buildActionTile(
              context,
              icon: Icons.copy,
              title: 'نسخ الآية',
              onTap: () {
                _copyVerse(verse);
                Navigator.pop(context);
              },
            ),
            
            _buildActionTile(
              context,
              icon: Icons.share,
              title: 'مشاركة الآية',
              onTap: () {
                _shareVerse(verse);
                Navigator.pop(context);
              },
            ),
            
            _buildActionTile(
              context,
              icon: _bookmarkedVerses.contains(verse.verseNumber)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              title: _bookmarkedVerses.contains(verse.verseNumber)
                  ? 'إزالة الإشارة المرجعية'
                  : 'إضافة إشارة مرجعية',
              onTap: () {
                _toggleBookmark(verse);
                Navigator.pop(context);
              },
            ),
            
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: ThemeConstants.primary, size: 24.sp),
      title: Text(
        title,
        style: AppTextStyles.body1.copyWith(
          color: ThemeConstants.textPrimary(context),
        ),
      ),
      onTap: onTap,
    );
  }
  
  Future<void> _toggleBookmark(VerseData verse) async {
    final isBookmarked = _bookmarkedVerses.contains(verse.verseNumber);
    
    if (isBookmarked) {
      await _quranService.removeBookmark(
        verse.surahNumber,
        verse.verseNumber,
      );
      setState(() {
        _bookmarkedVerses.remove(verse.verseNumber);
      });
      _showSnackBar('تم إزالة الإشارة المرجعية');
    } else {
      await _quranService.addBookmark(
        BookmarkData(
          surahNumber: verse.surahNumber,
          verseNumber: verse.verseNumber,
          surahName: _surahInfo.nameArabic,
          addedAt: DateTime.now(),
        ),
      );
      setState(() {
        _bookmarkedVerses.add(verse.verseNumber);
      });
      _showSnackBar('تمت إضافة إشارة مرجعية');
    }
  }
  
  void _copyVerse(VerseData verse) {
    // سيتم تنفيذه في الجزء التالي
  }
  
  void _shareVerse(VerseData verse) {
    final text = '${verse.text}\n\n'
        '(${_surahInfo.nameArabic} - الآية ${verse.verseNumber})';
    Share.share(text);
  }
  
  void _shareSurah() {
    final text = 'سورة ${_surahInfo.nameArabic}\n'
        '${_surahInfo.revelationTypeArabic} - ${_surahInfo.totalVerses} آية';
    Share.share(text);
  }
  
  void _showSearchDialog(BuildContext context) {
    // سيتم تنفيذه في الجزء التالي
  }
  
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReaderSettingsSheet(
        currentFontSize: _fontSize,
        onFontSizeChanged: (size) {
          setState(() => _fontSize = size);
          _quranService.setFontSize(size);
        },
      ),
    );
  }
  
  void _showFontSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'حجم الخط',
          style: AppTextStyles.h5.copyWith(
            color: ThemeConstants.textPrimary(context),
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مثال على النص',
                  style: AppTextStyles.quran.copyWith(
                    fontSize: _fontSize.sp,
                    color: ThemeConstants.textPrimary(context),
                  ),
                ),
                SizedBox(height: 20.h),
                Slider(
                  value: _fontSize,
                  min: 16.0,
                  max: 32.0,
                  divisions: 16,
                  label: _fontSize.toStringAsFixed(0),
                  activeColor: ThemeConstants.primary,
                  onChanged: (value) {
                    setState(() => _fontSize = value);
                    this.setState(() {});
                    _quranService.setFontSize(value);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
  
  void _showBookmarks(BuildContext context) {
    // سيتم تنفيذه في الجزء التالي
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
    _scrollController.dispose();
    // حفظ آخر موضع قراءة
    if (_verses.isNotEmpty) {
      _quranService.saveReadingPosition(
        widget.surahNumber,
        _verses.first.verseNumber,
      );
    }
    super.dispose();
  }
}