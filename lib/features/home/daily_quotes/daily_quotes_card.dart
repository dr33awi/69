// lib/features/home/widgets/daily_quotes_card.dart
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
        // عنوان القسم
        _buildSectionHeader(context),
        
        SizedBox(height: 10.h),
        
        // بطاقة الاقتباسات
        SizedBox(
          height: 220.h,
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
              return _buildQuoteCard(context, quotes[index]);
            },
          ),
        ),
        
        SizedBox(height: 10.h),
        
        // مؤشر الصفحات
        _buildPageIndicator(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withOpacity(0.05),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30.r,
            height: 30.r,
            decoration: BoxDecoration(
              gradient: ThemeConstants.primaryGradient,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          
          SizedBox(width: 8.w),
          
          Expanded(
            child: Text(
              'الاقتباس اليومي',
              style: context.titleMedium?.copyWith(
                fontWeight: ThemeConstants.bold,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, QuoteData quote) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: quote.gradient.map((c) => c.withOpacity(0.9)).toList(),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showQuoteDetails(context, quote),
            borderRadius: BorderRadius.circular(16.r),
            child: Stack(
              children: [
                _buildSimpleQuoteBackground(),
                
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: _buildQuoteContent(context, quote),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteContent(BuildContext context, QuoteData quote) {
    return Column(
      children: [
        // رأس البطاقة
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                _getQuoteIcon(quote.type),
                color: Colors.white,
                size: 16.sp,
              ),
            ),
            
            SizedBox(width: 8.w),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getQuoteTitle(quote.type),
                    style: context.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: ThemeConstants.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                  if (quote.theme != null) ...[
                    SizedBox(height: 2.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        quote.theme!,
                        style: context.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: ThemeConstants.medium,
                          fontSize: 9.sp,
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
                    color: Colors.white.withOpacity(0.8),
                    size: 16.sp,
                  ),
                  padding: EdgeInsets.all(4.r),
                  constraints: BoxConstraints(
                    minWidth: 28.r,
                    minHeight: 28.r,
                  ),
                ),
                IconButton(
                  onPressed: () => _shareQuote(context, quote),
                  icon: Icon(
                    Icons.share_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 16.sp,
                  ),
                  padding: EdgeInsets.all(4.r),
                  constraints: BoxConstraints(
                    minWidth: 28.r,
                    minHeight: 28.r,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const Spacer(),
        
        // النص الرئيسي
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.r),
          constraints: BoxConstraints(
            maxHeight: 100.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.w,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    Icons.format_quote,
                    color: Colors.white.withOpacity(0.6),
                    size: 14.sp,
                  ),
                ),
                
                SizedBox(height: 4.h),
                
                Text(
                  quote.content,
                  textAlign: TextAlign.center,
                  style: context.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: _getQuoteFontSize(quote.content.length),
                    height: 1.5,
                    fontWeight: ThemeConstants.medium,
                    fontFamily: quote.type == QuoteType.verse 
                        ? ThemeConstants.fontFamilyQuran 
                        : ThemeConstants.fontFamily,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 4.h),
                
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Transform.rotate(
                    angle: math.pi,
                    child: Icon(
                      Icons.format_quote,
                      color: Colors.white.withOpacity(0.6),
                      size: 14.sp,
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
              horizontal: 10.w,
              vertical: 4.h,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              quote.source,
              style: context.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: ThemeConstants.semiBold,
                fontSize: 10.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  double _getQuoteFontSize(int textLength) {
    if (textLength > 150) {
      return 11.sp;
    } else if (textLength > 100) {
      return 12.sp;
    } else {
      return 13.sp;
    }
  }

  Widget _buildSimpleQuoteBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -40.h,
            left: -40.w,
            child: Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
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
      height: 140.h,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
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
          SizedBox(height: 10.h),
          Text(
            'جاري تحميل الاقتباسات...',
            style: context.labelMedium?.copyWith(
              color: context.textSecondaryColor,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      height: 140.h,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: context.errorColor,
            size: 26.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            'خطأ في تحميل الاقتباسات',
            style: context.titleMedium?.copyWith(
              color: context.errorColor,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          ElevatedButton(
            onPressed: _loadQuotesData,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            ),
            child: Text(
              'إعادة المحاولة',
              style: TextStyle(fontSize: 11.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      height: 140.h,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            color: context.textSecondaryColor,
            size: 26.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            'لا توجد اقتباسات متاحة',
            style: context.titleMedium?.copyWith(
              color: context.textSecondaryColor,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 8.h),
          ElevatedButton(
            onPressed: _loadQuotesData,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            ),
            child: Text(
              'إعادة التحميل',
              style: TextStyle(fontSize: 11.sp),
            ),
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
          width: isActive ? 18.w : 5.r,
          height: 5.h,
          decoration: BoxDecoration(
            color: isActive 
                ? context.primaryColor 
                : context.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2.5.r),
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

// Data Models
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

// Quote Details Modal
class QuoteDetailsModal extends StatelessWidget {
  final QuoteData quote;

  const QuoteDetailsModal({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        minHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getQuoteTitle(quote.type),
                    style: context.headlineSmall?.semiBold.copyWith(
                      fontSize: 18.sp,
                    ),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Quote content
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.dividerColor.withOpacity(0.5),
                        width: 1.w,
                      ),
                    ),
                    child: Text(
                      quote.content,
                      style: context.bodyLarge?.copyWith(
                        height: 1.7,
                        fontSize: 14.sp,
                        fontFamily: quote.type == QuoteType.verse 
                            ? ThemeConstants.fontFamilyQuran 
                            : ThemeConstants.fontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Source and theme
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999.r),
                          ),
                          child: Text(
                            quote.source,
                            style: context.titleSmall?.copyWith(
                              color: context.primaryColor,
                              fontWeight: ThemeConstants.semiBold,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ),
                      
                      if (quote.theme != null) ...[
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(999.r),
                              border: Border.all(
                                color: context.dividerColor.withOpacity(0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.label_outline,
                                  color: context.textSecondaryColor,
                                  size: 11.sp,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    quote.theme!,
                                    style: context.labelSmall?.copyWith(
                                      color: context.textSecondaryColor,
                                      fontWeight: ThemeConstants.medium,
                                      fontSize: 10.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  SizedBox(height: 18.h),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40.h,
                          child: ElevatedButton.icon(
                            onPressed: () => _copyQuote(context),
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 16.sp,
                            ),
                            label: Text(
                              'نسخ النص',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.surfaceColor,
                              foregroundColor: context.textPrimaryColor,
                              side: BorderSide(color: context.dividerColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 8.w),
                      
                      Expanded(
                        child: SizedBox(
                          height: 40.h,
                          child: ElevatedButton.icon(
                            onPressed: () => _shareQuote(context),
                            icon: Icon(
                              Icons.share_rounded,
                              size: 16.sp,
                            ),
                            label: Text(
                              'مشاركة',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
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