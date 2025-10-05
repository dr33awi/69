// lib/features/quran/screens/quran_surahs_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../services/quran_service.dart';
import 'quran_reader_screen.dart';

class QuranSurahsListScreen extends StatefulWidget {
  const QuranSurahsListScreen({super.key});

  @override
  State<QuranSurahsListScreen> createState() => _QuranSurahsListScreenState();
}

class _QuranSurahsListScreenState extends State<QuranSurahsListScreen> 
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
                _buildSearchBar(context),
                _buildLastReadCard(context),
                _buildTabBar(context),
              ],
            ),
          ),
          
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: ThemeConstants.primary,
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
          child: Center(
            child: Icon(
              Icons.menu_book_rounded,
              size: 80.sp,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ThemeConstants.card(context),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: ThemeConstants.shadowSm,
      ),
      child: TextField(
        onChanged: _filterSurahs,
        decoration: InputDecoration(
          hintText: 'ابحث عن سورة...',
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
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: ThemeConstants.shadowMd,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openSurah(context, position.surahNumber, position.ayahNumber),
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.bookmark,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    
                    SizedBox(width: 16.w),
                    
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
                          SizedBox(height: 4.h),
                          Text(
                            surahInfo.nameArabic,
                            style: AppTextStyles.h4.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'الآية ${position.ayahNumber}',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20.sp,
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
  
  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: ThemeConstants.surface(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: ThemeConstants.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: ThemeConstants.textSecondary(context),
        labelStyle: AppTextStyles.label1.copyWith(
          fontWeight: FontWeight.bold,
        ),
        tabs: [
          Tab(text: 'الكل (${_filteredSurahs.length})'),
          Tab(text: 'المكية (${_makkiSurahs.length})'),
          Tab(text: 'المدنية (${_madaniSurahs.length})'),
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
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: ThemeConstants.textSecondary(context).withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد نتائج',
              style: AppTextStyles.body1.copyWith(
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
                // رقم السورة
                Container(
                  width: 45.w,
                  height: 45.w,
                  decoration: BoxDecoration(
                    gradient: ThemeConstants.primaryGradient,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      surah.number.toString(),
                      style: AppTextStyles.h5.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: surah.revelationType == 'Makkah'
                                  ? ThemeConstants.accent.withValues(alpha: 0.1)
                                  : ThemeConstants.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              surah.revelationTypeArabic,
                              style: AppTextStyles.caption.copyWith(
                                color: surah.revelationType == 'Makkah'
                                    ? ThemeConstants.accent
                                    : ThemeConstants.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '${surah.totalVerses} آية',
                            style: AppTextStyles.body2.copyWith(
                              color: ThemeConstants.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // الأيقونة
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18.sp,
                  color: ThemeConstants.textSecondary(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
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
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}