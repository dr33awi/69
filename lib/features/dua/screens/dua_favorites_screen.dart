// lib/features/dua/screens/dua_favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/dua_service.dart';
import '../models/dua_model.dart';
import 'dua_details_screen.dart';

class DuaFavoritesScreen extends StatefulWidget {
  const DuaFavoritesScreen({super.key});

  @override
  State<DuaFavoritesScreen> createState() => _DuaFavoritesScreenState();
}

class _DuaFavoritesScreenState extends State<DuaFavoritesScreen> 
    with TickerProviderStateMixin {
  late final DuaService _service;
  late final AnimationController _listAnimationController;
  late final AnimationController _emptyAnimationController;
  
  List<DuaItem> _favoriteDuas = [];
  List<DuaCategory> _categories = [];
  bool _isLoading = true;
  double _fontSize = 18.0;
  
  // للترتيب والفلترة
  String _sortBy = 'date'; // date, title, category
  String? _filterByCategoryId;

  @override
  void initState() {
    super.initState();
    _service = context.duaService;
    
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _emptyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _loadData();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _emptyAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final favorites = await _service.getFavoriteDuas();
      final categories = await _service.loadCategories();
      _fontSize = await _service.getSavedFontSize();
      
      if (mounted) {
        setState(() {
          _favoriteDuas = favorites;
          _categories = categories;
          _isLoading = false;
        });
        
        if (_favoriteDuas.isNotEmpty) {
          _listAnimationController.forward();
        } else {
          _emptyAnimationController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<DuaItem> get _filteredAndSortedDuas {
    List<DuaItem> duas = [..._favoriteDuas];
    
    // الفلترة حسب الفئة
    if (_filterByCategoryId != null) {
      duas = duas.where((d) => d.categoryId == _filterByCategoryId).toList();
    }
    
    // الترتيب
    switch (_sortBy) {
      case 'title':
        duas.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'category':
        duas.sort((a, b) => a.categoryId.compareTo(b.categoryId));
        break;
      case 'date':
      default:
        // الترتيب الافتراضي (حسب تاريخ الإضافة)
        break;
    }
    
    return duas;
  }

  Future<void> _toggleFavorite(DuaItem dua) async {
    final isFavorite = await _service.toggleFavorite(dua.id);
    
    if (!isFavorite) {
      setState(() {
        _favoriteDuas.removeWhere((d) => d.id == dua.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت الإزالة من المفضلة'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareAllFavorites() async {
    if (_favoriteDuas.isEmpty) return;
    
    final text = '''
أدعيتي المفضلة

${_favoriteDuas.map((dua) => '''
${dua.title}
${dua.arabicText}
${dua.source} - ${dua.reference}
━━━━━━━━━━━━━━━
''').join('\n')}

تطبيق الأذكار والأدعية
''';
    
    await Share.share(text);
  }

  void _openDuaDetails(DuaItem dua) {
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
    ).then((_) => _loadData());
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      builder: (context) => _buildSortSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            if (!_isLoading && _favoriteDuas.isNotEmpty)
              _buildFilterBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.all(14.r),
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
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 10.w),
          
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ThemeConstants.accent, ThemeConstants.accentLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.accent.withOpacity(0.3),
                  blurRadius: 6.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Icon(
              Icons.bookmark,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          
          SizedBox(width: 10.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الأدعية المفضلة',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 17.sp,
                  ),
                ),
                Text(
                  '${_favoriteDuas.length} دعاء محفوظ',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          
          if (_favoriteDuas.isNotEmpty) ...[
            // زر الترتيب
            IconButton(
              onPressed: _showSortOptions,
              icon: Icon(
                Icons.sort_rounded,
                color: context.textPrimaryColor,
                size: 24.sp,
              ),
            ),
            
            // زر المشاركة
            IconButton(
              onPressed: _shareAllFavorites,
              icon: Icon(
                Icons.share_rounded,
                color: context.textPrimaryColor,
                size: 22.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filteredCategories = _categories.where((cat) {
      return _favoriteDuas.any((dua) => dua.categoryId == cat.id);
    }).toList();
    
    if (filteredCategories.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 44.h,
      margin: EdgeInsets.only(top: 8.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          // خيار "الكل"
          _buildFilterChip(
            label: 'الكل',
            isSelected: _filterByCategoryId == null,
            onTap: () => setState(() => _filterByCategoryId = null),
            color: ThemeConstants.tertiary,
          ),
          
          SizedBox(width: 8.w),
          
          // فلاتر الفئات
          ...filteredCategories.map((cat) => Container(
            margin: EdgeInsets.only(left: 8.w),
            child: _buildFilterChip(
              label: cat.name,
              isSelected: _filterByCategoryId == cat.id,
              onTap: () => setState(() {
                _filterByCategoryId = _filterByCategoryId == cat.id 
                    ? null 
                    : cat.id;
              }),
              color: _getCategoryColor(cat.id),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 8.h,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? color.withOpacity(0.15)
                : context.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected 
                  ? color.withOpacity(0.5)
                  : context.dividerColor.withOpacity(0.3),
              width: 1.w,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : context.textPrimaryColor,
              fontSize: 13.sp,
              fontWeight: isSelected ? ThemeConstants.semiBold : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: AppLoading.page(
          message: 'جاري تحميل المفضلة...',
        ),
      );
    }

    if (_favoriteDuas.isEmpty) {
      return _buildEmptyState();
    }

    final duas = _filteredAndSortedDuas;
    
    if (duas.isEmpty) {
      return _buildNoResultsState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: ThemeConstants.accent,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: duas.length,
        itemBuilder: (context, index) {
          final dua = duas[index];
          final delay = index * 50;
          
          return AnimatedBuilder(
            animation: _listAnimationController,
            builder: (context, child) {
              final animation = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: _listAnimationController,
                  curve: Interval(
                    delay / 1000,
                    (delay + 500) / 1000,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              );
              
              return Transform.translate(
                offset: Offset(0, (1 - animation.value) * 30),
                child: Opacity(
                  opacity: animation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: _buildFavoriteDuaCard(dua),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteDuaCard(DuaItem dua) {
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
    
    final categoryColor = _getCategoryColor(category.id);
    
    return Dismissible(
      key: Key(dua.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: ThemeConstants.error,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: const Text('تأكيد الحذف'),
            content: const Text('هل تريد إزالة هذا الدعاء من المفضلة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'حذف',
                  style: TextStyle(color: ThemeConstants.error),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _toggleFavorite(dua),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () => _openDuaDetails(dua),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: categoryColor.withOpacity(0.2),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withOpacity(0.1),
                        categoryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15.r),
                      topRight: Radius.circular(15.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          _getCategoryIcon(category.icon),
                          color: categoryColor,
                          size: 16.sp,
                        ),
                      ),
                      
                      SizedBox(width: 10.w),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dua.title,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontWeight: ThemeConstants.bold,
                                fontSize: 14.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              category.name,
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      IconButton(
                        onPressed: () => _toggleFavorite(dua),
                        icon: Icon(
                          Icons.bookmark,
                          color: ThemeConstants.accent,
                          size: 20.sp,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                // محتوى البطاقة
                Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dua.arabicText,
                        style: TextStyle(
                          fontSize: _fontSize.sp,
                          fontFamily: ThemeConstants.fontFamilyArabic,
                          height: 1.8,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      
                      if (dua.virtue != null) ...[
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: ThemeConstants.success.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14.sp,
                                color: ThemeConstants.success,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  dua.virtue!,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: context.textSecondaryColor,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      SizedBox(height: 8.h),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 12.sp,
                            color: context.textSecondaryColor.withOpacity(0.7),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${dua.source} - ${dua.reference}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: context.textSecondaryColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _emptyAnimationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: ThemeConstants.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline,
                size: 60.sp,
                color: ThemeConstants.accent.withOpacity(0.5),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            Text(
              'لا توجد أدعية مفضلة',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontWeight: ThemeConstants.bold,
                fontSize: 20.sp,
              ),
            ),
            
            SizedBox(height: 8.h),
            
            Text(
              'اضغط على أيقونة المفضلة في أي دعاء\nليتم حفظه هنا',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 14.sp,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 24.h),
            
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.search),
              label: const Text('استكشف الأدعية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.accent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
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

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_off,
            size: 60.sp,
            color: context.textSecondaryColor.withOpacity(0.5),
          ),
          
          SizedBox(height: 16.h),
          
          Text(
            'لا توجد أدعية بهذا الفلتر',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 18.sp,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          TextButton(
            onPressed: () => setState(() => _filterByCategoryId = null),
            child: const Text('إظهار الكل'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSheet() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sort,
                color: ThemeConstants.tertiary,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'ترتيب حسب',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: ThemeConstants.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          _buildSortOption(
            title: 'تاريخ الإضافة',
            value: 'date',
            icon: Icons.schedule,
          ),
          
          _buildSortOption(
            title: 'العنوان',
            value: 'title',
            icon: Icons.sort_by_alpha,
          ),
          
          _buildSortOption(
            title: 'الفئة',
            value: 'category',
            icon: Icons.category,
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _sortBy == value;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? ThemeConstants.tertiary : context.textSecondaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? ThemeConstants.semiBold : null,
          color: isSelected ? ThemeConstants.tertiary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: ThemeConstants.tertiary,
              size: 20.sp,
            )
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
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