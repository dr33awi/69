// lib/features/dua/screens/dua_favorites_screen.dart

import 'package:athkar_app/core/infrastructure/services/share/share_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/dua_service.dart';
import '../models/dua_model.dart';
import '../widgets/dua_item_card.dart';
import 'dua_details_screen.dart';

class DuaFavoritesScreen extends StatefulWidget {
  const DuaFavoritesScreen({super.key});

  @override
  State<DuaFavoritesScreen> createState() => _DuaFavoritesScreenState();
}

class _DuaFavoritesScreenState extends State<DuaFavoritesScreen> {
  late final DuaService _service;
  
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
    _loadData();
  }

  @override
  void dispose() {
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
    
    final duasMap = _favoriteDuas.map((dua) => {
      'title': dua.title,
      'text': dua.arabicText,
      'source': '${dua.source} - ${dua.reference}',
    }).toList();
    
    await context.shareService.shareFavoriteDuas(duasMap);
  }

  Future<void> _shareDua(DuaItem dua) async {
    await context.shareDua(
      dua.title,
      dua.arabicText,
      transliteration: dua.transliteration,
      translation: dua.translation,
      virtue: dua.virtue,
      source: dua.source,
      reference: dua.reference,
    );
  }

void _copyDua(DuaItem dua) {
  context.copyDua(
    dua.title,
    dua.arabicText,
    transliteration: dua.transliteration,
    translation: dua.translation,
    virtue: dua.virtue,
    source: dua.source,
    reference: dua.reference,
  );
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
              Icons.bookmark_rounded,
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
            _buildActionButton(
              icon: Icons.sort_rounded,
              onTap: _showSortOptions,
            ),
            
            // زر المشاركة
            _buildActionButton(
              icon: Icons.share_rounded,
              onTap: _shareAllFavorites,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 6.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: context.dividerColor.withOpacity(0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: context.textPrimaryColor,
              size: 20.sp,
            ),
          ),
        ),
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
          final categoryColor = _getCategoryColor(dua.categoryId);
          
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: DuaItemCard(
              dua: dua,
              fontSize: _fontSize,
              categoryColor: categoryColor,
              onTap: () => _openDuaDetails(dua),
              onFavorite: () => _toggleFavorite(dua),
              onShare: () => _shareDua(dua),
              onCopy: () => _copyDua(dua),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
          Text(
            'ترتيب حسب',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: ThemeConstants.bold,
            ),
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
}