// lib/features/quran/screens/quran_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../services/quran_service.dart';
import 'quran_reader_screen.dart';
import 'quran_search_screen.dart';
import 'quran_bookmarks_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> 
    with SingleTickerProviderStateMixin {
  late final QuranService _quranService;
  late final TabController _tabController;
  
  List<SurahInfo> _allSurahs = [];
  List<SurahInfo> _filteredSurahs = [];
  String _searchQuery = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _quranService = getIt<QuranService>();
    _tabController = TabController(length: 3, vsync: this);
    _loadSurahs();
  }
  
  Future<void> _loadSurahs() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    _allSurahs = _quranService.getAllSurahs();
    _filteredSurahs = _allSurahs;
    
    setState(() => _isLoading = false);
  }
  
  void _filterSurahs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSurahs = _allSurahs;
      } else {
        _filteredSurahs = _allSurahs.where((surah) {
          return surah.nameArabic.contains(query) ||
                 surah.name.toLowerCase().contains(query.toLowerCase()) ||
                 surah.number.toString().contains(query);
        }).toList();
      }
    });
  }
  
  List<SurahInfo> get _makkiSurahs => 
      _filteredSurahs.where((s) => s.revelationType == 'Makkah').toList();
      
  List<SurahInfo> get _madaniSurahs => 
      _filteredSurahs.where((s) => s.revelationType == 'Madinah').toList();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildQuickActions(context),
                _buildLastReadCard(context),
                _buildSearchBar(context),
                _buildTabBar(context),
              ],
            ),
          ),
          
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: ThemeConstants.primary,
                      strokeWidth: 3.w,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'جاري تحميل السور...',
                      style: AppTextStyles.body2.copyWith(
                        color: ThemeConstants.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildTabContent(),
        ],
      ),
    );
  }
  
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.h,
      floating: false,
      pinned: true,
      backgroundColor: ThemeConstants.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'القرآن الكريم',
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ThemeConstants.primary,
                ThemeConstants.primaryDark,
              ],
            ),
          ),
          child: Stack(
            children: [
              // نمط زخرفي في الخلفية
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    'assets/images/pattern.png',
                    repeat: ImageRepeat.repeat,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              
              // أيقونة في الوسط
              Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 80.sp,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.bookmark,
            color: Colors.white,
            size: 24.sp,
          ),
          onPressed: () => _navigateToBookmarks(context),
          tooltip: 'الإشارات المرجعية',
        ),
      ],
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              context,
              icon: Icons.search,
              title: 'بحث في القرآن',
              gradient: ThemeConstants.accentGradient,
              onTap: () => _navigateToSearch(context),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildQuickActionCard(
              context,
              icon: Icons.bookmarks,
              title: 'المحفوظات',
              gradient: ThemeConstants.tertiaryGradient,
              onTap: () => _navigateToBookmarks(context),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: ThemeConstants.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  title,
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLastReadCard(BuildContext context) {
    return FutureBuilder<QuranPosition>(
      future: _quranService.getLastReadingPosition(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final position = snapshot.data!;
        final surahInfo = _quranService.getSurahInfo(position.surahNumber);
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: ThemeConstants.primaryGradient,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: ThemeConstants.shadowMd,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openSurah(context, position.surahNumber, position.ayahNumber),
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    // أيقونة
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 32.sp,
                      ),
                    ),
                    
                    SizedBox(width: 16.w),
                    
                    // معلومات آخر قراءة
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'آخر قراءة',
                            style: AppTextStyles.label2.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            surahInfo.nameArabic,
                            style: AppTextStyles.h4.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'الآية ${position.ayahNumber}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '${surahInfo.totalVerses} آية',
                                style: AppTextStyles.body2.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // سهم
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: ThemeConstants.card(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: ThemeConstants.shadowSm,
      ),
      child: TextField(
        onChanged: _filterSurahs,
        style: AppTextStyles.body1.copyWith(
          color: ThemeConstants.textPrimary(context),
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن سورة برقمها أو اسمها...',
          hintStyle: AppTextStyles.body2.copyWith(
            color: ThemeConstants.textSecondary(context),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: ThemeConstants.primary,
            size: 24.sp,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 20.sp,
                    color: ThemeConstants.textSecondary(context),
                  ),
                  onPressed: () {
                    _filterSurahs('');
                    FocusScope.of(context).unfocus();
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
    );
  }
  
  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: ThemeConstants.surface(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: ThemeConstants.divider(context),
          width: 1.w,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: ThemeConstants.primaryGradient,
          borderRadius: BorderRadius.circular(12.r),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: ThemeConstants.textSecondary(context),
        labelStyle: AppTextStyles.label1.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: AppTextStyles.label1,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.view_list, size: 18.sp),
                SizedBox(width: 6.w),
                Text('الكل (${_filteredSurahs.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.nights_stay, size: 18.sp),
                SizedBox(width: 6.w),
                Text('مكية (${_makkiSurahs.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_city, size: 18.sp),
                SizedBox(width: 6.w),
                Text('مدنية (${_madaniSurahs.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildSurahsList(_filteredSurahs),
          _buildSurahsList(_makkiSurahs),
          _buildSurahsList(_madaniSurahs),
        ],
      ),
    );
  }
  
  Widget _buildSurahsList(List<SurahInfo> surahs) {
    if (surahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: ThemeConstants.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 50.sp,
                color: ThemeConstants.primary.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'لا توجد نتائج',
              style: AppTextStyles.h5.copyWith(
                color: ThemeConstants.textPrimary(context),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'جرب البحث بطريقة مختلفة',
              style: AppTextStyles.body2.copyWith(
                color: ThemeConstants.textSecondary(context),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: surahs.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return _buildSurahCard(context, surah);
      },
    );
  }
  
  Widget _buildSurahCard(BuildContext context, SurahInfo surah) {
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
          onTap: () => _openSurah(context, surah.number),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // رقم السورة مع تصميم مميز
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        gradient: ThemeConstants.primaryGradient,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeConstants.primary.withValues(alpha: 0.3),
                            blurRadius: 8.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      surah.number.toString(),
                      style: AppTextStyles.h5.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(width: 16.w),
                
                // معلومات السورة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.nameArabic,
                        style: AppTextStyles.h5.copyWith(
                          color: ThemeConstants.textPrimary(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        surah.name,
                        style: AppTextStyles.body2.copyWith(
                          color: ThemeConstants.textSecondary(context),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          _buildInfoChip(
                            context,
                            icon: surah.revelationType == 'Makkah'
                                ? Icons.nights_stay
                                : Icons.location_city,
                            label: surah.revelationTypeArabic,
                            color: surah.revelationType == 'Makkah'
                                ? ThemeConstants.accent
                                : ThemeConstants.info,
                          ),
                          SizedBox(width: 8.w),
                          _buildInfoChip(
                            context,
                            icon: Icons.format_list_numbered,
                            label: '${surah.totalVerses} آية',
                            color: ThemeConstants.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // أيقونة السهم
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: ThemeConstants.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: ThemeConstants.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  // ==================== Navigation ====================
  
  void _openSurah(BuildContext context, int surahNumber, [int? ayahNumber]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranReaderScreen(
          surahNumber: surahNumber,
          initialAyah: ayahNumber ?? 1,
        ),
      ),
    );
  }
  
  void _navigateToSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuranSearchScreen(),
      ),
    );
  }
  
  void _navigateToBookmarks(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuranBookmarksScreen(),
      ),
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}