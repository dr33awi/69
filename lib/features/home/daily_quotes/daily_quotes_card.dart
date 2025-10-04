// lib/features/home/widgets/daily_quotes_card.dart - محسن للشاشات الصغيرة
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;
import 'dart:convert';

class DailyQuotesCard extends StatefulWidget {
  const DailyQuotesCard({super.key});

  @override
  State<DailyQuotesCard> createState() => _DailyQuotesCardState();
}

class _DailyQuotesCardState extends State<DailyQuotesCard> {
  late PageController _pageController;
  
  int _currentPage = 0;
  List<QuoteData> quotes = [];
  Map<String, dynamic> quotesData = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadQuotesData();
  }

  void _loadQuotesData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final String jsonString = await rootBundle.loadString('assets/data/daily_quotes.json');
      quotesData = jsonDecode(jsonString);
      
      await _generateDailyQuotes();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في تحميل الاقتباسات: ${e.toString()}';
      });
      
      _loadFallbackData();
    }
  }

  void _loadFallbackData() {
    quotesData = {
      "verses": [
        {
          "text": "وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ",
          "source": "سورة الطلاق - آية 2-3",
          "theme": "التقوى والرزق",
          "reference": "القرآن الكريم"
        },
        {
          "text": "إِنَّ مَعَ الْعُسْرِ يُسْرًا",
          "source": "سورة الشرح - آية 6",
          "theme": "الأمل والفرج",
          "reference": "القرآن الكريم"
        }
      ],
      "hadiths": [
        {
          "text": "مَنْ قَالَ سُبْحَانَ اللَّهِ وَبِحَمْدِهِ فِي يَوْمٍ مِائَةَ مَرَّةٍ، حُطَّتْ خَطَايَاهُ",
          "source": "صحيح البخاري",
          "narrator": "أبو هريرة",
          "theme": "التسبيح",
          "reference": "السنة النبوية"
        }
      ],
      "duas": [
        {
          "text": "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
          "source": "سورة البقرة - آية 201",
          "theme": "دعاء شامل",
          "reference": "القرآن الكريم"
        }
      ]
    };
    
    _generateDailyQuotes();
  }

  Future<void> _generateDailyQuotes() async {
    quotes.clear();

    try {
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
      final dailySeed = now.year * 1000 + dayOfYear;
      final random = math.Random(dailySeed);

      final verses = quotesData['verses'] as List;
      if (verses.isNotEmpty) {
        final verseIndex = random.nextInt(verses.length);
        final selectedVerse = verses[verseIndex];
        quotes.add(QuoteData(
          type: QuoteType.verse,
          content: selectedVerse['text'],
          source: selectedVerse['source'],
          theme: selectedVerse['theme'],
          gradient: AppColors.getCategoryGradient('verse').colors,
        ));
      }

      final hadiths = quotesData['hadiths'] as List;
      if (hadiths.isNotEmpty) {
        final hadithIndex = random.nextInt(hadiths.length);
        final selectedHadith = hadiths[hadithIndex];
        quotes.add(QuoteData(
          type: QuoteType.hadith,
          content: selectedHadith['text'],
          source: selectedHadith['source'],
          theme: selectedHadith['theme'],
          gradient: AppColors.getCategoryGradient('hadith').colors,
        ));
      }

      final duas = quotesData['duas'] as List;
      if (duas.isNotEmpty) {
        final duaIndex = random.nextInt(duas.length);
        final selectedDua = duas[duaIndex];
        quotes.add(QuoteData(
          type: QuoteType.dua,
          content: selectedDua['text'],
          source: selectedDua['source'],
          theme: selectedDua['theme'],
          gradient: AppColors.getCategoryGradient('dua').colors,
        ));
      }

      setState(() {});
    } catch (e) {
      print('خطأ في توليد الاقتباسات: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // حساب أبعاد الشاشة
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    if (_isLoading) {
      return _buildLoadingCard(context);
    }

    if (_errorMessage != null) {
      return _buildErrorCard(context);
    }

    if (quotes.isEmpty) {
      return _buildEmptyCard(context);
    }

    return Column(
      children: [
        // عنوان القسم - مضغوط للشاشات الصغيرة
        _buildSectionHeader(context, isSmallScreen),
        
        SizedBox(height: isSmallScreen ? 12.h : 16.h),
        
        // بطاقة الاقتباسات - ارتفاع ديناميكي
        SizedBox(
          height: _getCardHeight(screenHeight, isSmallScreen, isVerySmallScreen),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              HapticFeedback.selectionClick();
            },
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              return _buildQuoteCard(
                context, 
                quotes[index], 
                isSmallScreen,
                isVerySmallScreen,
              );
            },
          ),
        ),
        
        SizedBox(height: isSmallScreen ? 12.h : 16.h),
        
        // مؤشر الصفحات
        _buildPageIndicator(context),
      ],
    );
  }

  double _getCardHeight(double screenHeight, bool isSmallScreen, bool isVerySmallScreen) {
    if (isVerySmallScreen) {
      return 220.h; // أقل ارتفاع للشاشات الصغيرة جداً
    } else if (isSmallScreen) {
      return 250.h; // ارتفاع متوسط للشاشات الصغيرة
    } else {
      return 280.h; // الارتفاع الأصلي للشاشات الكبيرة
    }
  }

  Widget _buildSectionHeader(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12.w : 16.w,
        vertical: isSmallScreen ? 8.h : 12.h,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14.r : 16.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withValues(alpha: 0.05),
            blurRadius: isSmallScreen ? 6.r : 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 32.w : 36.w,
            height: isSmallScreen ? 32.h : 36.h,
            decoration: BoxDecoration(
              gradient: ThemeConstants.primaryGradient,
              borderRadius: BorderRadius.circular(isSmallScreen ? 10.r : 12.r),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: isSmallScreen ? 18.sp : 20.sp,
            ),
          ),
          
          SizedBox(width: isSmallScreen ? 10.w : 12.w),
          
          Expanded(
            child: Text(
              'الاقتباس اليومي',
              style: context.titleMedium?.copyWith(
                fontWeight: ThemeConstants.bold,
                fontSize: isSmallScreen ? 14.sp : 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(
    BuildContext context, 
    QuoteData quote,
    bool isSmallScreen,
    bool isVerySmallScreen,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 20.r : 24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: quote.gradient.map((c) => c.withValues(alpha: 0.9)).toList(),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSmallScreen ? 20.r : 24.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showQuoteDetails(context, quote),
            borderRadius: BorderRadius.circular(isSmallScreen ? 20.r : 24.r),
            child: Stack(
              children: [
                _buildSimpleQuoteBackground(quote),
                
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16.w : 20.w),
                  child: _buildQuoteContent(
                    context, 
                    quote, 
                    isSmallScreen,
                    isVerySmallScreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteContent(
    BuildContext context, 
    QuoteData quote,
    bool isSmallScreen,
    bool isVerySmallScreen,
  ) {
    return Column(
      children: [
        // رأس البطاقة
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6.w : 8.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10.r : 12.r),
              ),
              child: Icon(
                _getQuoteIcon(quote.type),
                color: Colors.white,
                size: isSmallScreen ? 20.sp : 24.sp,
              ),
            ),
            
            SizedBox(width: isSmallScreen ? 10.w : 12.w),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getQuoteTitle(quote.type),
                    style: context.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: ThemeConstants.bold,
                      fontSize: isSmallScreen ? 14.sp : 16.sp,
                    ),
                  ),
                  if (quote.theme != null && !isVerySmallScreen) ...[
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8.w : 12.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        quote.theme!,
                        style: context.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: ThemeConstants.medium,
                          fontSize: isSmallScreen ? 10.sp : 11.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // أزرار الإجراءات
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _copyQuote(context, quote),
                  icon: Icon(
                    Icons.copy_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: isSmallScreen ? 18.sp : 20.sp,
                  ),
                  padding: EdgeInsets.all(isSmallScreen ? 4.w : 8.w),
                  constraints: BoxConstraints(
                    minWidth: isSmallScreen ? 32.w : 40.w,
                    minHeight: isSmallScreen ? 32.h : 40.h,
                  ),
                ),
                IconButton(
                  onPressed: () => _shareQuote(context, quote),
                  icon: Icon(
                    Icons.share_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: isSmallScreen ? 18.sp : 20.sp,
                  ),
                  padding: EdgeInsets.all(isSmallScreen ? 4.w : 8.w),
                  constraints: BoxConstraints(
                    minWidth: isSmallScreen ? 32.w : 40.w,
                    minHeight: isSmallScreen ? 32.h : 40.h,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const Spacer(),
        
        // النص الرئيسي - محسن للشاشات الصغيرة
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 12.w : 16.w),
          constraints: BoxConstraints(
            maxHeight: isVerySmallScreen ? 90.h : isSmallScreen ? 110.h : 130.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(isSmallScreen ? 16.r : 20.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.w,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isVerySmallScreen)
                  Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      Icons.format_quote,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: isSmallScreen ? 16.sp : 20.sp,
                    ),
                  ),
                
                if (!isVerySmallScreen) SizedBox(height: 4.h),
                
                Text(
                  quote.content,
                  textAlign: TextAlign.center,
                  style: context.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: _getQuoteFontSize(quote.content.length, isSmallScreen, isVerySmallScreen),
                    height: isVerySmallScreen ? 1.4 : isSmallScreen ? 1.6 : 1.8,
                    fontWeight: ThemeConstants.medium,
                    fontFamily: quote.type == QuoteType.verse 
                        ? ThemeConstants.fontFamilyQuran 
                        : ThemeConstants.fontFamily,
                  ),
                  maxLines: isVerySmallScreen ? 3 : isSmallScreen ? 4 : null,
                  overflow: isVerySmallScreen ? TextOverflow.ellipsis : TextOverflow.visible,
                ),
                
                if (!isVerySmallScreen) SizedBox(height: 4.h),
                
                if (!isVerySmallScreen)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Transform.rotate(
                      angle: math.pi,
                      child: Icon(
                        Icons.format_quote,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: isSmallScreen ? 16.sp : 20.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const Spacer(),
        
        // المصدر
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12.w : 16.w,
              vertical: isSmallScreen ? 6.h : 8.h,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              quote.source,
              style: context.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: ThemeConstants.semiBold,
                fontSize: isSmallScreen ? 11.sp : 12.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  double _getQuoteFontSize(int textLength, bool isSmallScreen, bool isVerySmallScreen) {
    if (isVerySmallScreen) {
      return textLength > 100 ? 12.sp : 13.sp;
    } else if (isSmallScreen) {
      return textLength > 100 ? 13.sp : 14.sp;
    } else {
      return textLength > 100 ? 14.sp : 16.sp;
    }
  }

  Widget _buildSimpleQuoteBackground(QuoteData quote) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -50.h,
            left: -50.w,
            child: Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      height: 180.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: context.primaryColor,
            strokeWidth: 2.w,
          ),
          SizedBox(height: 12.h),
          Text(
            'جاري تحميل الاقتباسات...',
            style: context.labelMedium?.copyWith(
              color: context.textSecondaryColor,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      height: 180.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: context.errorColor,
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            'خطأ في تحميل الاقتباسات',
            style: context.titleMedium?.copyWith(
              color: context.errorColor,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          ElevatedButton(
            onPressed: _loadQuotesData,
            child: Text('إعادة المحاولة', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      height: 180.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            color: context.textSecondaryColor,
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            'لا توجد اقتباسات متاحة',
            style: context.titleMedium?.copyWith(
              color: context.textSecondaryColor,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          ElevatedButton(
            onPressed: _loadQuotesData,
            child: Text('إعادة التحميل', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(quotes.length, (index) {
        final isActive = index == _currentPage;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: isActive ? 24.w : 6.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: isActive 
                ? context.primaryColor 
                : context.primaryColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3.r),
          ),
        );
      }),
    );
  }

  IconData _getQuoteIcon(QuoteType type) {
    switch (type) {
      case QuoteType.verse:
        return Icons.menu_book_rounded;
      case QuoteType.hadith:
        return Icons.auto_stories_rounded;
      case QuoteType.dua:
        return Icons.pan_tool_rounded;
    }
  }

  String _getQuoteTitle(QuoteType type) {
    switch (type) {
      case QuoteType.verse:
        return 'آية اليوم';
      case QuoteType.hadith:
        return 'حديث اليوم';
      case QuoteType.dua:
        return 'دعاء اليوم';
    }
  }

  void _copyQuote(BuildContext context, QuoteData quote) {
    final shareText = '${quote.content}\n\n${quote.source}\n\nمن تطبيق الأذكار';
    Clipboard.setData(ClipboardData(text: shareText));
    context.showSuccessSnackBar('تم نسخ النص بنجاح');
    HapticFeedback.mediumImpact();
  }

  void _shareQuote(BuildContext context, QuoteData quote) {
    HapticFeedback.lightImpact();
    final shareText = '${quote.content}\n\n${quote.source}\n\nمن تطبيق الأذكار';
    Share.share(shareText);
  }

  void _showQuoteDetails(BuildContext context, QuoteData quote) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => QuoteDetailsModal(quote: quote),
    );
  }
}

// باقي الكلاسات الموجودة
class QuoteData {
  final QuoteType type;
  final String content;
  final String source;
  final String? theme;
  final List<Color> gradient;

  const QuoteData({
    required this.type,
    required this.content,
    required this.source,
    this.theme,
    required this.gradient,
  });
}

enum QuoteType {
  verse,
  hadith,
  dua,
}

// نافذة تفاصيل الاقتباس محسنة للشاشات الصغيرة
class QuoteDetailsModal extends StatelessWidget {
  final QuoteData quote;

  const QuoteDetailsModal({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * (isSmallScreen ? 0.8 : 0.9),
        minHeight: screenHeight * (isSmallScreen ? 0.5 : 0.6),
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isSmallScreen ? 20.r : 24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16.w : 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getQuoteTitle(quote.type),
                    style: context.headlineSmall?.semiBold.copyWith(
                      fontSize: isSmallScreen ? 20.sp : 24.sp,
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 12.h : 16.h),
                  
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 16.w : 20.w),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: context.dividerColor.withValues(alpha: 0.5),
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      quote.content,
                      style: context.bodyLarge?.copyWith(
                        height: isSmallScreen ? 1.8 : 2.0,
                        fontSize: isSmallScreen ? 16.sp : 18.sp,
                        fontFamily: quote.type == QuoteType.verse 
                            ? ThemeConstants.fontFamilyQuran 
                            : ThemeConstants.fontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 12.h : 16.h),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12.w : 16.w,
                            vertical: isSmallScreen ? 6.h : 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          child: Text(
                            quote.source,
                            style: context.titleSmall?.copyWith(
                              color: context.primaryColor,
                              fontWeight: ThemeConstants.semiBold,
                              fontSize: isSmallScreen ? 12.sp : 14.sp,
                            ),
                          ),
                        ),
                      ),
                      
                      if (quote.theme != null) 
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10.w : 12.w,
                              vertical: isSmallScreen ? 3.h : 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(999.r),
                              border: Border.all(
                                color: context.dividerColor.withValues(alpha: 0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.label_outline,
                                  color: context.textSecondaryColor,
                                  size: isSmallScreen ? 12.sp : 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    quote.theme!,
                                    style: context.labelSmall?.copyWith(
                                      color: context.textSecondaryColor,
                                      fontWeight: ThemeConstants.medium,
                                      fontSize: isSmallScreen ? 11.sp : 12.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: isSmallScreen ? 20.h : 24.h),
                  
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: isSmallScreen ? 42.h : 48.h,
                          child: ElevatedButton.icon(
                            onPressed: () => _copyQuote(context),
                            icon: Icon(Icons.copy_rounded, size: isSmallScreen ? 16.sp : 18.sp),
                            label: Text('نسخ النص', style: TextStyle(fontSize: isSmallScreen ? 13.sp : 14.sp)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.surfaceColor,
                              foregroundColor: context.textPrimaryColor,
                              side: BorderSide(color: context.dividerColor),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 12.w),
                      
                      Expanded(
                        child: SizedBox(
                          height: isSmallScreen ? 42.h : 48.h,
                          child: ElevatedButton.icon(
                            onPressed: () => _shareQuote(context),
                            icon: Icon(Icons.share_rounded, size: isSmallScreen ? 16.sp : 18.sp),
                            label: Text('مشاركة', style: TextStyle(fontSize: isSmallScreen ? 13.sp : 14.sp)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getQuoteTitle(QuoteType type) {
    switch (type) {
      case QuoteType.verse:
        return 'آية من القرآن الكريم';
      case QuoteType.hadith:
        return 'حديث شريف';
      case QuoteType.dua:
        return 'دعاء مأثور';
    }
  }

  void _copyQuote(BuildContext context) {
    final fullText = '${quote.content}\n\n${quote.source}';
    Clipboard.setData(ClipboardData(text: fullText));
    context.showSuccessSnackBar('تم نسخ النص بنجاح');
    HapticFeedback.mediumImpact();
  }

  void _shareQuote(BuildContext context) {
    HapticFeedback.lightImpact();
    final shareText = '${quote.content}\n\n${quote.source}\n\nمن تطبيق الأذكار';
    Share.share(shareText);
  }
}