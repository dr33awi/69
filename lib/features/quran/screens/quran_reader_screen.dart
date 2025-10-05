// lib/features/quran/screens/quran_reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/features/quran/services/quran_service.dart';
import 'package:share_plus/share_plus.dart';

class QuranReaderScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? initialVerse;

  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    this.initialVerse,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late final QuranService _quranService;
  late SurahInfo _surahInfo;
  List<VerseInfo> _verses = [];
  final ScrollController _scrollController = ScrollController();
  double _fontSize = 22.0;
  bool _isLoading = true;
  int? _selectedVerseNumber;

  @override
  void initState() {
    super.initState();
    _quranService = getIt<QuranService>();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      _surahInfo = _quranService.getSurahInfo(widget.surahNumber);
      _verses = _quranService.getVerses(widget.surahNumber);
      _fontSize = await _quranService.getFontSize();
      
      setState(() => _isLoading = false);
      
      // التمرير إلى الآية المحددة
      if (widget.initialVerse != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToVerse(widget.initialVerse!);
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل السورة: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollToVerse(int verseNumber) {
    final index = verseNumber - 1;
    if (index >= 0 && index < _verses.length) {
      _scrollController.animateTo(
        index * 150.h,
        duration: ThemeConstants.durationNormal,
        curve: Curves.easeInOut,
      );
    }
  }

  void _changeFontSize(double delta) async {
    final newSize = (_fontSize + delta).clamp(16.0, 32.0);
    setState(() => _fontSize = newSize);
    await _quranService.setFontSize(newSize);
    HapticFeedback.lightImpact();
  }

  void _shareVerse(VerseInfo verse) {
    final text = '''
${_surahInfo.nameArabic} - آية ${verse.verseNumber}

${verse.text}

من تطبيق أذكار المسلم
''';
    Share.share(text);
  }

  void _copyVerse(VerseInfo verse) {
    Clipboard.setData(ClipboardData(
      text: '${_surahInfo.nameArabic} - آية ${verse.verseNumber}\n\n${verse.text}',
    ));
    context.showSuccessSnackBar('تم نسخ الآية');
    HapticFeedback.mediumImpact();
  }

  void _savePosition(int verseNumber) async {
    await _quranService.saveLastReadPosition(widget.surahNumber, verseNumber);
    if (mounted) {
      context.showSuccessSnackBar('تم حفظ الموضع');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(child: _buildVersesList()),
            
            _buildBottomBar(),
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _surahInfo.nameArabic,
                      style: context.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: ThemeConstants.bold,
                        fontSize: 22.sp,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_surahInfo.isMakki ? 'مكية' : 'مدنية'} • ${_surahInfo.totalAyahs} آية',
                      style: context.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showSettingsSheet(),
                icon: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersesList() {
    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.all(20.w),
      itemCount: _verses.length + 1, // +1 للبسملة
      separatorBuilder: (context, index) => Divider(
        height: 24.h,
        color: context.dividerColor.withValues(alpha: 0.3),
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildBasmala();
        }
        
        final verse = _verses[index - 1];
        return _buildVerseCard(verse);
      },
    );
  }

  Widget _buildBasmala() {
    // عدم عرض البسملة للسورة التوبة
    if (widget.surahNumber == 9) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        style: TextStyle(
          fontSize: _fontSize + 4.sp,
          fontWeight: FontWeight.w600,
          color: context.primaryColor,
          fontFamily: 'Amiri',
          height: 2.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildVerseCard(VerseInfo verse) {
    final isSelected = _selectedVerseNumber == verse.verseNumber;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVerseNumber = isSelected ? null : verse.verseNumber;
        });
        HapticFeedback.lightImpact();
      },
      onLongPress: () => _showVerseOptions(verse),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? context.primaryColor.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رقم الآية والمعلومات
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    gradient: ThemeConstants.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${verse.verseNumber}',
                      style: context.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: ThemeConstants.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'جزء ${verse.juz} • صفحة ${verse.page}',
                  style: context.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Row(
                    children: [
                      _buildIconButton(
                        Icons.copy,
                        () => _copyVerse(verse),
                        'نسخ',
                      ),
                      SizedBox(width: 8.w),
                      _buildIconButton(
                        Icons.share,
                        () => _shareVerse(verse),
                        'مشاركة',
                      ),
                      SizedBox(width: 8.w),
                      _buildIconButton(
                        Icons.bookmark_add,
                        () => _savePosition(verse.verseNumber),
                        'حفظ',
                      ),
                    ],
                  ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // نص الآية
            Text(
              verse.text,
              style: TextStyle(
                fontSize: _fontSize.sp,
                fontWeight: FontWeight.normal,
                color: context.textPrimaryColor,
                fontFamily: 'Amiri',
                height: 2.0,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: context.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: context.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          top: BorderSide(
            color: context.dividerColor.withValues(alpha: 0.3),
            width: 1.w,
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomButton(
            Icons.text_decrease,
            'تصغير',
            () => _changeFontSize(-2),
            enabled: _fontSize > 16,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '${_fontSize.toInt()}',
              style: context.titleMedium?.copyWith(
                color: context.primaryColor,
                fontWeight: ThemeConstants.bold,
              ),
            ),
          ),
          _buildBottomButton(
            Icons.text_increase,
            'تكبير',
            () => _changeFontSize(2),
            enabled: _fontSize < 32,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: enabled
              ? context.primaryColor.withValues(alpha: 0.1)
              : context.dividerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: enabled ? context.primaryColor : context.textSecondaryColor,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: context.labelMedium?.copyWith(
                color: enabled ? context.primaryColor : context.textSecondaryColor,
                fontWeight: ThemeConstants.semiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerseOptions(VerseInfo verse) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'آية ${verse.verseNumber}',
              style: context.titleMedium?.copyWith(
                fontWeight: ThemeConstants.bold,
              ),
            ),
            SizedBox(height: 24.h),
            _buildOptionTile(
              Icons.copy,
              'نسخ الآية',
              () {
                Navigator.pop(context);
                _copyVerse(verse);
              },
            ),
            _buildOptionTile(
              Icons.share,
              'مشاركة الآية',
              () {
                Navigator.pop(context);
                _shareVerse(verse);
              },
            ),
            _buildOptionTile(
              Icons.bookmark_add,
              'حفظ الموضع',
              () {
                Navigator.pop(context);
                _savePosition(verse.verseNumber);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: context.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          icon,
          color: context.primaryColor,
          size: 20.sp,
        ),
      ),
      title: Text(
        title,
        style: context.bodyLarge,
      ),
      onTap: onTap,
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'إعدادات القراءة',
              style: context.titleLarge?.copyWith(
                fontWeight: ThemeConstants.bold,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'حجم الخط',
              style: context.titleSmall?.copyWith(
                fontWeight: ThemeConstants.semiBold,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                IconButton(
                  onPressed: _fontSize > 16 ? () => _changeFontSize(-2) : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 16,
                    max: 32,
                    divisions: 8,
                    label: _fontSize.toInt().toString(),
                    onChanged: (value) {
                      setState(() => _fontSize = value);
                    },
                    onChangeEnd: (value) async {
                      await _quranService.setFontSize(value);
                    },
                  ),
                ),
                IconButton(
                  onPressed: _fontSize < 32 ? () => _changeFontSize(2) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}