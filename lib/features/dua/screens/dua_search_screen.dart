// lib/features/dua/screens/dua_search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/dua_service.dart';
import '../models/dua_model.dart';
import '../widgets/dua_item_card.dart';
import 'dua_details_screen.dart';

class DuaSearchScreen extends StatefulWidget {
  const DuaSearchScreen({super.key});

  @override
  State<DuaSearchScreen> createState() => _DuaSearchScreenState();
}

class _DuaSearchScreenState extends State<DuaSearchScreen> {
  late final DuaService _service;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<DuaItem> _searchResults = [];
  List<String> _searchHistory = [];
  List<DuaCategory> _categories = [];
  bool _isSearching = false;
  bool _isLoading = false;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _service = context.duaService;
    _initialize();
    
    // التركيز على البحث تلقائياً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _fontSize = await _service.getSavedFontSize();
    _searchHistory = await _service.getSearchHistory();
    _categories = await _service.loadCategories();
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    final results = await _service.searchDuas(query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearSearchHistory() async {
    await _service.clearSearchHistory();
    setState(() {
      _searchHistory = [];
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم مسح سجل البحث'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openDuaDetails(DuaItem dua) {
    // الحصول على الفئة
    final category = _categories.firstWhere(
      (cat) => cat.id == dua.categoryId,
      orElse: () => DuaCategory(
        id: dua.categoryId,
        name: 'أدعية',
        description: '',
        type: 0,
        icon: 'book',
      ),
    );
    
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DuaDetailsScreen(
          dua: dua,
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              
              SizedBox(width: 12.w),
              
              Expanded(
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _searchFocus.hasFocus
                          ? ThemeConstants.tertiary.withOpacity(0.5)
                          : context.dividerColor.withOpacity(0.3),
                      width: 1.w,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _performSearch,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: context.textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث في الأدعية...',
                      hintStyle: TextStyle(
                        color: context.textSecondaryColor.withOpacity(0.7),
                        fontSize: 15.sp,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: context.textSecondaryColor,
                        size: 22.sp,
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
              ),
            ],
          ),
          
          // عدد النتائج
          if (_isSearching && !_isLoading)
            Container(
              margin: EdgeInsets.only(top: 12.h),
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: ThemeConstants.tertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 14.sp,
                    color: ThemeConstants.tertiary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'عدد النتائج: ${_searchResults.length}',
                    style: TextStyle(
                      color: ThemeConstants.tertiary,
                      fontSize: 12.sp,
                      fontWeight: ThemeConstants.medium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: ThemeConstants.tertiary,
              strokeWidth: 3.w,
            ),
            SizedBox(height: 12.h),
            Text(
              'جاري البحث...',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      if (_searchResults.isEmpty) {
        return _buildNoResults();
      }
      
      return _buildSearchResults();
    }

    return _buildSearchHistory();
  }

  Widget _buildSearchHistory() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // سجل البحث
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: context.textSecondaryColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'سجل البحث',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 16.sp,
                        fontWeight: ThemeConstants.semiBold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: Text(
                    'مسح الكل',
                    style: TextStyle(
                      color: ThemeConstants.error,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _searchHistory.map((query) {
                return ActionChip(
                  label: Text(query),
                  onPressed: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                  avatar: Icon(
                    Icons.history,
                    size: 16.sp,
                  ),
                  backgroundColor: context.cardColor,
                  side: BorderSide(
                    color: context.dividerColor.withOpacity(0.3),
                    width: 1.w,
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: 24.h),
          ],
          
          // اقتراحات البحث
          Row(
            children: [
              Icon(
                Icons.tips_and_updates,
                color: ThemeConstants.accent,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'اقتراحات البحث',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 16.sp,
                  fontWeight: ThemeConstants.semiBold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          _buildSearchSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      'رزق',
      'شفاء',
      'هداية',
      'مغفرة',
      'صباح',
      'مساء',
      'نوم',
      'سفر',
      'كرب',
      'استخارة',
    ];
    
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          onPressed: () {
            _searchController.text = suggestion;
            _performSearch(suggestion);
          },
          backgroundColor: ThemeConstants.tertiary.withOpacity(0.1),
          labelStyle: TextStyle(
            color: ThemeConstants.tertiary,
            fontSize: 13.sp,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    // تجميع النتائج حسب الفئة
    final Map<String, List<DuaItem>> groupedResults = {};
    
    for (final dua in _searchResults) {
      if (!groupedResults.containsKey(dua.categoryId)) {
        groupedResults[dua.categoryId] = [];
      }
      groupedResults[dua.categoryId]!.add(dua);
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: groupedResults.length,
      itemBuilder: (context, index) {
        final categoryId = groupedResults.keys.elementAt(index);
        final duas = groupedResults[categoryId]!;
        final category = _categories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => DuaCategory(
            id: categoryId,
            name: 'أدعية',
            description: '',
            type: 0,
            icon: 'book',
          ),
        );
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان الفئة
            Container(
              margin: EdgeInsets.only(bottom: 12.h, top: index > 0 ? 16.h : 0),
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: _getCategoryColor(categoryId).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: _getCategoryColor(categoryId).withOpacity(0.3),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getCategoryIcon(category.icon),
                    size: 16.sp,
                    color: _getCategoryColor(categoryId),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    category.name,
                    style: TextStyle(
                      color: _getCategoryColor(categoryId),
                      fontSize: 13.sp,
                      fontWeight: ThemeConstants.medium,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '(${duas.length})',
                    style: TextStyle(
                      color: _getCategoryColor(categoryId).withOpacity(0.7),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            
            // قائمة الأدعية
            ...duas.map((dua) => Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: _buildSearchResultCard(dua),
            )),
          ],
        );
      },
    );
  }

  Widget _buildSearchResultCard(DuaItem dua) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () => _openDuaDetails(dua),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: context.dividerColor.withOpacity(0.3),
              width: 1.w,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الدعاء
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dua.title,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontWeight: ThemeConstants.semiBold,
                        fontSize: 14.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  if (dua.isFavorite)
                    Icon(
                      Icons.bookmark,
                      size: 16.sp,
                      color: ThemeConstants.accent,
                    ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              // نص الدعاء (مختصر)
              Text(
                dua.arabicText,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: ThemeConstants.fontFamilyArabic,
                  color: context.textPrimaryColor.withOpacity(0.9),
                  height: 1.6,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 8.h),
              
              // التصنيفات والمصدر
              Row(
                children: [
                  // التصنيفات
                  if (dua.tags.isNotEmpty) ...[
                    ...dua.tags.take(2).map((tag) => Container(
                      margin: EdgeInsets.only(left: 4.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeConstants.tertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: ThemeConstants.tertiary,
                        ),
                      ),
                    )),
                    
                    const Spacer(),
                  ],
                  
                  // المصدر
                  Icon(
                    Icons.book_outlined,
                    size: 12.sp,
                    color: context.textSecondaryColor.withOpacity(0.7),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    dua.source,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.textSecondaryColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: context.textSecondaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 60.sp,
              color: context.textSecondaryColor.withOpacity(0.5),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontWeight: ThemeConstants.bold,
              fontSize: 20.sp,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            'جرب البحث بكلمات أخرى',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return ThemeConstants.primary;
      case 'sahihain':
        return ThemeConstants.accent;
      case 'sunan':
        return ThemeConstants.tertiary;
      case 'other_authentic':
        return ThemeConstants.primaryDark;
      default:
        return ThemeConstants.tertiary;
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'book_quran':
        return Icons.menu_book;
      case 'book_hadith':
        return Icons.book;
      case 'book_sunnah':
        return Icons.auto_stories;
      case 'verified':
        return Icons.verified;
      default:
        return Icons.pan_tool_rounded;
    }
  }
}