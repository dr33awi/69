// lib/core/infrastructure/services/favorites/screens/unified_favorites_screen.dart
// الشاشة الموحدة لعرض جميع المفضلات مع تبويبات للأنواع المختلفة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import '../models/favorite_models.dart';
import '../extensions/favorites_extensions.dart';

/// الشاشة الموحدة للمفضلات
class UnifiedFavoritesScreen extends StatefulWidget {
  final FavoriteContentType? initialType;

  const UnifiedFavoritesScreen({
    super.key,
    this.initialType,
  });

  @override
  State<UnifiedFavoritesScreen> createState() => _UnifiedFavoritesScreenState();
}

class _UnifiedFavoritesScreenState extends State<UnifiedFavoritesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<FavoriteItem> _allFavorites = [];
  FavoritesStatistics? _statistics;
  bool _isLoading = true;
  String _searchQuery = '';
  
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    
    // إعداد التبويبات
    _tabController = TabController(
      length: FavoriteContentType.values.length,
      vsync: this,
    );
    
    // الانتقال للتبويب المحدد إذا تم توفيره
    if (widget.initialType != null) {
      final index = FavoriteContentType.values.indexOf(widget.initialType!);
      if (index != -1) {
        _tabController.index = index;
      }
    }
    
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// تحميل البيانات
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final favorites = await context.getAllFavorites();
      final statistics = await context.getFavoritesStatistics();
      
      setState(() {
        _allFavorites = favorites;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// الحصول على المفضلات المفلترة للتبويب الحالي
  List<FavoriteItem> _getFilteredFavorites() {
    final currentType = FavoriteContentType.values[_tabController.index];
    var favorites = _allFavorites.filterByType(currentType);
    
    // تطبيق البحث
    if (_searchQuery.isNotEmpty) {
      favorites = favorites.search(_searchQuery);
    }
    
    return favorites;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.backgroundColor,
      elevation: 0,
      title: _showSearch ? _buildSearchField() : const Text('المفضلة'),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: context.textPrimaryColor,
          size: 20.sp,
        ),
      ),
      actions: [
        // زر البحث
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(
            _showSearch ? Icons.close_rounded : Icons.search_rounded,
            color: context.textPrimaryColor,
            size: 22.sp,
          ),
        ),
        
        // قائمة الخيارات
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'sort',
              child: Row(
                children: [
                  Icon(Icons.sort_rounded, size: 20.sp),
                  SizedBox(width: 8.w),
                  const Text('ترتيب وفلترة'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'statistics',
              child: Row(
                children: [
                  Icon(Icons.analytics_rounded, size: 20.sp),
                  SizedBox(width: 8.w),
                  const Text('الإحصائيات'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download_rounded, size: 20.sp),
                  SizedBox(width: 8.w),
                  const Text('تصدير'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_rounded, size: 20.sp, color: Colors.red),
                  SizedBox(width: 8.w),
                  Text('مسح الكل', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: _statistics != null && _statistics!.hasFavorites
          ? TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: ThemeConstants.primary,
              unselectedLabelColor: context.textSecondaryColor,
              indicatorColor: ThemeConstants.primary,
              tabs: FavoriteContentType.values.map((type) {
                final count = _statistics!.getCountForType(type);
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type.icon, size: 16.sp),
                      SizedBox(width: 6.w),
                      Text(type.displayName),
                      if (count > 0) ...[
                        SizedBox(width: 4.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: ThemeConstants.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: ThemeConstants.primary,
                              fontWeight: ThemeConstants.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            )
          : null,
    );
  }

  /// بناء حقل البحث
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'البحث في المفضلات...',
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: context.textSecondaryColor,
          fontSize: 14.sp,
        ),
      ),
      style: TextStyle(
        color: context.textPrimaryColor,
        fontSize: 14.sp,
      ),
      autofocus: true,
    );
  }

  /// بناء حالة التحميل
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(ThemeConstants.primary),
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل المفضلات...',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء المحتوى الرئيسي
  Widget _buildMainContent() {
    if (_statistics == null || !_statistics!.hasFavorites) {
      return _buildEmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: FavoriteContentType.values.map((type) {
        return _buildTypeContent(type);
      }).toList(),
    );
  }

  /// بناء محتوى نوع معين
  Widget _buildTypeContent(FavoriteContentType type) {
    final favorites = _getFilteredFavorites();
    
    if (favorites.isEmpty) {
      return _buildEmptyTypeState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: ThemeConstants.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final item = favorites[index];
          return _buildFavoriteCard(item, index);
        },
      ),
    );
  }

  /// بناء كارت المفضلة
  Widget _buildFavoriteCard(FavoriteItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Card(
        color: context.cardColor,
        elevation: 2.r,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: InkWell(
          onTap: () => _openItem(item),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان والأيقونة
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: ThemeConstants.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        item.contentType.icon,
                        size: 16.sp,
                        color: ThemeConstants.primary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: ThemeConstants.bold,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // قائمة الخيارات
                    PopupMenuButton<String>(
                      onSelected: (action) => _handleItemAction(action, item),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 16.sp),
                              SizedBox(width: 8.w),
                              const Text('مشاركة'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 16.sp),
                              SizedBox(width: 8.w),
                              const Text('نسخ'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 16.sp, color: Colors.red),
                              SizedBox(width: 8.w),
                              Text('حذف من المفضلة', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 20.sp,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // المحتوى
                Text(
                  item.content.length > 100 
                      ? '${item.content.substring(0, 100)}...'
                      : item.content,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.textPrimaryColor,
                    height: 1.5,
                  ),
                ),
                
                // العنوان الفرعي
                if (item.subtitle != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                
                SizedBox(height: 12.h),
                
                // المعلومات الإضافية
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // تاريخ الإضافة
                    Text(
                      _formatDate(item.addedAt),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    
                    // المصدر
                    if (item.source != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: context.dividerColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          item.source!,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء حالة فارغة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: ThemeConstants.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bookmark_outline_rounded,
              size: 60.sp,
              color: ThemeConstants.primary.withOpacity(0.5),
            ),
          ),
          
          SizedBox(height: 20.h),
          
          Text(
            'لا توجد مفضلات',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontWeight: ThemeConstants.bold,
              fontSize: 20.sp,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            'ابدأ بإضافة العناصر التي تفضلها\nليسهل الوصول إليها لاحقاً',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 14.sp,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء حالة فارغة لنوع معين
  Widget _buildEmptyTypeState(FavoriteContentType type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type.icon,
            size: 60.sp,
            color: context.textSecondaryColor.withOpacity(0.5),
          ),
          
          SizedBox(height: 16.h),
          
          Text(
            'لا توجد ${type.displayName} مفضلة',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontWeight: ThemeConstants.bold,
              fontSize: 16.sp,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            'ابحث عن ${type.displayName} واضغط على أيقونة المفضلة لإضافتها هنا',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 12.sp,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== الأحداث والتفاعلات ====================

  /// تبديل البحث
  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// معالجة أحداث القائمة
  void _handleMenuAction(String action) {
    switch (action) {
      case 'sort':
        _showSortOptions();
        break;
      case 'statistics':
        _showStatistics();
        break;
      case 'export':
        _exportFavorites();
        break;
      case 'clear_all':
        context.clearAllFavoritesWithConfirmation();
        break;
    }
  }

  /// معالجة أحداث العناصر
  void _handleItemAction(String action, FavoriteItem item) {
    switch (action) {
      case 'share':
        _shareItem(item);
        break;
      case 'copy':
        _copyItem(item);
        break;
      case 'remove':
        _removeItem(item);
        break;
    }
  }

  /// فتح عنصر مفضلة
  void _openItem(FavoriteItem item) {
    HapticFeedback.lightImpact();
    context.favoritesService.markAsAccessed(item.id);
    // TODO: التنقل للشاشة المناسبة حسب نوع العنصر
  }

  /// مشاركة عنصر
  void _shareItem(FavoriteItem item) {
    final text = '''
${item.title}

${item.content}

${item.subtitle != null ? '\n${item.subtitle}' : ''}
${item.source != null ? '\nالمصدر: ${item.source}' : ''}
''';
    
    // TODO: استخدام خدمة المشاركة
  }

  /// نسخ عنصر
  void _copyItem(FavoriteItem item) {
    final text = '''
${item.title}

${item.content}

${item.subtitle != null ? '\n${item.subtitle}' : ''}
${item.source != null ? '\nالمصدر: ${item.source}' : ''}
''';
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم النسخ إلى الحافظة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// حذف عنصر
  Future<void> _removeItem(FavoriteItem item) async {
    final success = await context.removeFromFavorites(item.id);
    
    if (success) {
      setState(() {
        _allFavorites.removeWhere((f) => f.id == item.id);
      });
      await _loadData(); // إعادة تحميل للتأكد من التحديث
    }
  }

  /// عرض خيارات الترتيب
  void _showSortOptions() {
    // TODO: عرض حوار خيارات الترتيب
  }

  /// عرض الإحصائيات
  void _showStatistics() {
    // TODO: عرض حوار الإحصائيات
  }

  /// تصدير المفضلات
  void _exportFavorites() {
    // TODO: تنفيذ تصدير المفضلات
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'اليوم';
    } else if (difference == 1) {
      return 'أمس';
    } else if (difference < 7) {
      return 'منذ $difference أيام';
    } else if (difference < 30) {
      final weeks = (difference / 7).round();
      return 'منذ $weeks أسبوع';
    } else if (difference < 365) {
      final months = (difference / 30).round();
      return 'منذ $months شهر';
    } else {
      final years = (difference / 365).round();
      return 'منذ $years سنة';
    }
  }
}