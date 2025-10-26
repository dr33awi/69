// lib/core/infrastructure/services/favorites/screens/unified_favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import '../models/favorite_models.dart';
import '../extensions/favorites_extensions.dart';

/// الشاشة الموحدة للمفضلات بتصميم القوائم
class UnifiedFavoritesScreen extends StatefulWidget {
  final FavoriteContentType? initialType;

  const UnifiedFavoritesScreen({
    super.key,
    this.initialType,
  });

  @override
  State<UnifiedFavoritesScreen> createState() => _UnifiedFavoritesScreenState();
}

class _UnifiedFavoritesScreenState extends State<UnifiedFavoritesScreen> {
  List<FavoriteItem> _allFavorites = [];
  FavoritesStatistics? _statistics;
  bool _isLoading = true;
  FavoriteContentType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _loadData();
  }

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

  List<FavoriteItem> _getFilteredFavorites(FavoriteContentType? type) {
    if (type == null) return _allFavorites;
    return _allFavorites.filterByType(type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: ThemeConstants.primary,
                child: _isLoading
                    ? _buildLoading()
                    : _statistics == null || !_statistics!.hasFavorites
                        ? _buildEmptyState()
                        : _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 8.w),
          
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ThemeConstants.primary, ThemeConstants.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withOpacity(0.25),
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
          
          SizedBox(width: 8.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مفضلاتي',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 17.sp,
                  ),
                ),
                if (_statistics != null)
                  Text(
                    '${_statistics!.totalCount} عنصر محفوظ',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11.sp,
                    ),
                  ),
              ],
            ),
          ),
          
          // زر الفلترة
          if (_selectedType != null)
            Container(
              margin: EdgeInsets.only(left: 6.w),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedType = null);
                    HapticFeedback.lightImpact();
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: context.dividerColor.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 3.r,
                          offset: Offset(0, 1.5.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.clear_rounded,
                      color: ThemeConstants.error,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeConstants.primary.withOpacity(0.12),
                  ThemeConstants.primary.withOpacity(0.08),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withOpacity(0.15),
                  blurRadius: 20.r,
                  offset: Offset(0, 5.h),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: ThemeConstants.primary,
              strokeWidth: 3.5.w,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'جاري تحميل المفضلات...',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 17.sp,
              fontWeight: ThemeConstants.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'يرجى الانتظار قليلاً',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.textSecondaryColor.withOpacity(0.08),
                    context.textSecondaryColor.withOpacity(0.04),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                size: 70.sp,
                color: context.textSecondaryColor.withOpacity(0.4),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'لا توجد مفضلات',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontWeight: ThemeConstants.bold,
                fontSize: 22.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'ابدأ بحفظ الأذكار والأدعية المفضلة لديك\nللوصول السريع إليها في أي وقت',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 14.sp,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ThemeConstants.primary.withOpacity(0.1),
                    ThemeConstants.accent.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: ThemeConstants.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18.sp,
                    color: ThemeConstants.primary,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'اضغط على أيقونة القلب ♥ لإضافة مفضلة',
                    style: TextStyle(
                      color: ThemeConstants.primary,
                      fontSize: 13.sp,
                      fontWeight: ThemeConstants.medium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final favorites = _getFilteredFavorites(_selectedType);
    
    return Column(
      children: [
        // شريط الإحصائيات والفلترة
        if (_selectedType == null)
          _buildCategoryStats()
        else
          _buildFilterBar(),
        
        // القائمة
        Expanded(
          child: favorites.isEmpty
              ? _buildEmptyTypeState(_selectedType!)
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final item = favorites[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: _buildCompactFavoriteCard(item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryStats() {
    return Column(
      children: [
        // شريط الإحصائيات العام
        Container(
          margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ThemeConstants.primary.withOpacity(0.08),
                ThemeConstants.accent.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: ThemeConstants.primary.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ThemeConstants.primary, ThemeConstants.primary.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.primary.withOpacity(0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  size: 20.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي المفضلات',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 12.sp,
                        fontWeight: ThemeConstants.medium,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${_statistics!.totalCount} عنصر محفوظ',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 16.sp,
                        fontWeight: ThemeConstants.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: ThemeConstants.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: ThemeConstants.primary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 14.sp,
                      color: ThemeConstants.primary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${FavoriteContentType.values.where((t) => _statistics!.getCountForType(t) > 0).length}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: ThemeConstants.bold,
                        color: ThemeConstants.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // بطاقات الفئات المحسّنة
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.1,
            children: FavoriteContentType.values.map((type) {
              final count = _statistics!.getCountForType(type);
              return _buildEnhancedCategoryCard(type, count);
            }).toList(),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildEnhancedCategoryCard(FavoriteContentType type, int count) {
    final typeColor = _getTypeColor(type);
    final hasItems = count > 0;
    
    return GestureDetector(
      onTap: hasItems
          ? () {
              setState(() => _selectedType = type);
              HapticFeedback.lightImpact();
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: hasItems 
                ? typeColor.withOpacity(0.3)
                : context.dividerColor.withOpacity(0.2),
            width: hasItems ? 1.5 : 1,
          ),
          boxShadow: hasItems
              ? [
                  BoxShadow(
                    color: typeColor.withOpacity(0.12),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(hasItems ? 14.r : 12.r),
              decoration: BoxDecoration(
                gradient: hasItems
                    ? LinearGradient(
                        colors: [typeColor, typeColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasItems ? null : context.dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: hasItems
                    ? [
                        BoxShadow(
                          color: typeColor.withOpacity(0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                type.icon,
                size: hasItems ? 26.sp : 22.sp,
                color: hasItems ? Colors.white : context.textSecondaryColor.withOpacity(0.4),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              type.displayName,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: hasItems ? ThemeConstants.bold : ThemeConstants.medium,
                color: hasItems ? typeColor : context.textSecondaryColor.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                gradient: hasItems
                    ? LinearGradient(
                        colors: [
                          typeColor.withOpacity(0.15),
                          typeColor.withOpacity(0.1),
                        ],
                      )
                    : null,
                color: hasItems ? null : context.dividerColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: hasItems 
                      ? typeColor.withOpacity(0.3)
                      : context.dividerColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: ThemeConstants.bold,
                  color: hasItems ? typeColor : context.textSecondaryColor.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final count = _statistics!.getCountForType(_selectedType!);
    final typeColor = _getTypeColor(_selectedType!);
    
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeColor.withOpacity(0.08),
            typeColor.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: typeColor.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [typeColor, typeColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: typeColor.withOpacity(0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Icon(
              _selectedType!.icon,
              size: 20.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عرض: ${_selectedType!.displayName}',
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 14.sp,
                    fontWeight: ThemeConstants.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$count ${count == 1 ? "عنصر" : "عناصر"} محفوظة',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: typeColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: ThemeConstants.bold,
                color: typeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFavoriteCard(FavoriteItem item) {
    final itemColor = _getTypeColor(item.contentType);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: () => _openItem(item),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: itemColor.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: itemColor.withOpacity(0.08),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [itemColor, itemColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: itemColor.withOpacity(0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Icon(
                  _getTypeIcon(item.contentType),
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              
              SizedBox(width: 14.w),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: itemColor,
                              fontWeight: ThemeConstants.bold,
                              fontFamily: ThemeConstants.fontFamilyArabic,
                              fontSize: 16.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: itemColor.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.contentType.displayName,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: ThemeConstants.medium,
                              color: itemColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 6.h),
                    
                    Text(
                      item.content,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        height: 1.4,
                        fontSize: 13.sp,
                        fontFamily: ThemeConstants.fontFamilyArabic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (item.source != null) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: itemColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: itemColor.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.library_books_rounded,
                              size: 12.sp,
                              color: itemColor,
                            ),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: Text(
                                item.source!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: itemColor,
                                  fontWeight: ThemeConstants.medium,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(width: 8.w),
              
              PopupMenuButton<String>(
                onSelected: (value) => _handleItemAction(value, item),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: itemColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: itemColor,
                    size: 20.sp,
                  ),
                ),
                itemBuilder: (context) => [
                  _buildMenuItem(
                    icon: Icons.share_rounded,
                    title: 'مشاركة',
                    value: 'share',
                    color: ThemeConstants.info,
                  ),
                  _buildMenuItem(
                    icon: Icons.copy_rounded,
                    title: 'نسخ',
                    value: 'copy',
                    color: ThemeConstants.success,
                  ),
                  const PopupMenuDivider(),
                  _buildMenuItem(
                    icon: Icons.delete_outline_rounded,
                    title: 'حذف',
                    value: 'remove',
                    color: ThemeConstants.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTypeState(FavoriteContentType type) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(30.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getTypeColor(type).withOpacity(0.12),
                    _getTypeColor(type).withOpacity(0.06),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getTypeColor(type).withOpacity(0.15),
                    blurRadius: 20.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Icon(
                type.icon,
                size: 60.sp,
                color: _getTypeColor(type).withOpacity(0.6),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'لا توجد ${type.displayName} مفضلة',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontWeight: ThemeConstants.bold,
                fontSize: 20.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              _getEmptyMessage(type),
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 14.sp,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getTypeColor(type).withOpacity(0.12),
                    _getTypeColor(type).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _getTypeColor(type).withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 18.sp,
                    color: _getTypeColor(type),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'اضغط على ♥ لإضافة ${type.displayName}',
                    style: TextStyle(
                      color: _getTypeColor(type),
                      fontSize: 13.sp,
                      fontWeight: ThemeConstants.medium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // باقي الدوال المساعدة (نفس التي في الكود السابق)
  PopupMenuItem<String> _buildMenuItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              icon,
              size: 16.sp,
              color: color,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: ThemeConstants.medium,
            ),
          ),
        ],
      ),
    );
  }

  void _openItem(FavoriteItem item) {
    HapticFeedback.lightImpact();
    context.favoritesService.markAsAccessed(item.id);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItemDetailSheet(item),
    );
  }

  Widget _buildItemDetailSheet(FavoriteItem item) {
    final typeColor = _getTypeColor(item.contentType);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: context.dividerColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          // Header محسّن
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  typeColor.withOpacity(0.08),
                  typeColor.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [typeColor, typeColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withOpacity(0.3),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getTypeIcon(item.contentType),
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: ThemeConstants.bold,
                          fontFamily: ThemeConstants.fontFamilyArabic,
                          color: context.textPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: typeColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.contentType.displayName,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: typeColor,
                            fontWeight: ThemeConstants.medium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: context.dividerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20.sp,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // المحتوى
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // محتوى العنصر
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          typeColor.withOpacity(0.06),
                          typeColor.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(
                        color: typeColor.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      item.content,
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 2.0,
                        fontFamily: ThemeConstants.fontFamilyArabic,
                        color: context.textPrimaryColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  
                  // العنوان الفرعي
                  if (item.subtitle != null) ...[
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: typeColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.description_outlined,
                                  size: 16.sp,
                                  color: typeColor,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'الوصف',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: ThemeConstants.bold,
                                  color: typeColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            item.subtitle!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              height: 1.6,
                              fontFamily: ThemeConstants.fontFamilyArabic,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // المصدر
                  if (item.source != null) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            typeColor.withOpacity(0.08),
                            typeColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: typeColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [typeColor, typeColor.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.library_books_rounded,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المصدر',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  item.source!,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: ThemeConstants.bold,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 24.h),
                  
                  // أزرار الإجراءات
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButtonSheet(
                          icon: Icons.share_rounded,
                          label: 'مشاركة',
                          color: ThemeConstants.info,
                          onTap: () {
                            Navigator.pop(context);
                            _shareItem(item);
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildActionButtonSheet(
                          icon: Icons.copy_rounded,
                          label: 'نسخ',
                          color: ThemeConstants.success,
                          onTap: () {
                            Navigator.pop(context);
                            _copyItem(item);
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildActionButtonSheet(
                          icon: Icons.delete_outline_rounded,
                          label: 'حذف',
                          color: ThemeConstants.error,
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteConfirmation(item);
                          },
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

  Widget _buildActionButtonSheet({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.12),
                color.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: ThemeConstants.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleItemAction(String action, FavoriteItem item) {
    switch (action) {
      case 'share':
        _shareItem(item);
        break;
      case 'copy':
        _copyItem(item);
        break;
      case 'remove':
        _showDeleteConfirmation(item);
        break;
    }
  }

  void _showDeleteConfirmation(FavoriteItem item) {
    final typeColor = _getTypeColor(item.contentType);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeConstants.error.withOpacity(0.12),
                      ThemeConstants.error.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ThemeConstants.error, ThemeConstants.error.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeConstants.error.withOpacity(0.3),
                            blurRadius: 8.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تأكيد الحذف',
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: ThemeConstants.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'هذا الإجراء لا يمكن التراجع عنه',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // المحتوى
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            typeColor.withOpacity(0.08),
                            typeColor.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: typeColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [typeColor, typeColor.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              _getTypeIcon(item.contentType),
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: ThemeConstants.bold,
                                    color: typeColor,
                                    fontFamily: ThemeConstants.fontFamilyArabic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  item.contentType.displayName,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'هل أنت متأكد من حذف هذا العنصر من المفضلة؟',
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.6,
                        color: context.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // الأزرار
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: context.dividerColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'إلغاء',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: context.textSecondaryColor,
                                fontWeight: ThemeConstants.medium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _removeItem(item);
                          },
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [ThemeConstants.error, ThemeConstants.error.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeConstants.error.withOpacity(0.3),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 3.h),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_rounded, color: Colors.white, size: 18.sp),
                                SizedBox(width: 6.w),
                                Text(
                                  'حذف',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                    fontWeight: ThemeConstants.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // باقي دوال المشاركة والنسخ والحذف
  void _shareItem(FavoriteItem item) async {
    // نفس الكود السابق
  }

  void _copyItem(FavoriteItem item) async {
    // نفس الكود السابق
  }

  Future<void> _removeItem(FavoriteItem item) async {
    final success = await context.removeFromFavorites(item.id);
    
    if (success) {
      setState(() {
        _allFavorites.removeWhere((f) => f.id == item.id);
      });
      await _loadData();
      _showSuccessSnackBar('تم الحذف من المفضلة');
    } else {
      _showErrorSnackBar('حدث خطأ في الحذف');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18.sp),
            SizedBox(width: 10.w),
            Text(message, style: TextStyle(fontSize: 13.sp)),
          ],
        ),
        backgroundColor: ThemeConstants.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 18.sp),
            SizedBox(width: 10.w),
            Text(message, style: TextStyle(fontSize: 13.sp)),
          ],
        ),
        backgroundColor: ThemeConstants.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getTypeColor(FavoriteContentType type) {
    switch (type) {
      case FavoriteContentType.dua:
        return ThemeConstants.primary;
      case FavoriteContentType.athkar:
        return ThemeConstants.accent;
      case FavoriteContentType.asmaAllah:
        return ThemeConstants.tertiary;
    }
  }

  IconData _getTypeIcon(FavoriteContentType type) {
    switch (type) {
      case FavoriteContentType.dua:
        return Icons.menu_book_rounded;
      case FavoriteContentType.athkar:
        return Icons.auto_stories_rounded;
      case FavoriteContentType.asmaAllah:
        return Icons.auto_awesome_rounded;
    }
  }

  String _getEmptyMessage(FavoriteContentType type) {
    switch (type) {
      case FavoriteContentType.dua:
        return 'اضغط على أيقونة القلب في أي دعاء\nلإضافته إلى مفضلاتك';
      case FavoriteContentType.athkar:
        return 'احفظ الأذكار المفضلة لديك\nللوصول السريع إليها';
      case FavoriteContentType.asmaAllah:
        return 'احفظ أسماء الله الحسنى المفضلة\nللتأمل والذكر';
    }
  }
}

// زر الرجوع المخصص
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  
  const AppBackButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: context.dividerColor.withOpacity(0.3),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: context.textPrimaryColor,
            size: 18.sp,
          ),
        ),
      ),
    );
  }
}