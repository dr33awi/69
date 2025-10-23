// lib/core/infrastructure/services/favorites/screens/unified_favorites_screen.dart
// الشاشة الموحدة لعرض جميع المفضلات مع تبويبات للأنواع المختلفة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/themes/app_theme.dart';
import '../../../../../app/di/service_locator.dart';
import '../models/favorite_models.dart';
import '../extensions/favorites_extensions.dart';
import '../../share/share_service.dart';

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
  late ShareService _shareService;
  
  List<FavoriteItem> _allFavorites = [];
  FavoritesStatistics? _statistics;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    
    // إعداد الخدمات
    _shareService = getIt<ShareService>();
    
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

  /// الحصول على المفضلات المفلترة لنوع معين
  List<FavoriteItem> _getFilteredFavorites(FavoriteContentType type) {
    var favorites = _allFavorites.filterByType(type);
    

    
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
      title: const Text('المفضلة'),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: context.textPrimaryColor,
          size: 20.sp,
        ),
      ),
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
    final favorites = _getFilteredFavorites(type);
    
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

  /// بناء كارت المفضلة بنفس تصميم البطاقة الأصلية
  Widget _buildFavoriteCard(FavoriteItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: _buildOriginalStyleCard(item),
    );
  }

  /// بناء البطاقة بنفس الأسلوب الأصلي حسب نوع المحتوى
  Widget _buildOriginalStyleCard(FavoriteItem item) {
    switch (item.contentType) {
      case FavoriteContentType.dua:
        return _buildDuaStyleCard(item);
      case FavoriteContentType.athkar:
        return _buildAthkarStyleCard(item);
      case FavoriteContentType.asmaAllah:
        return _buildAsmaAllahStyleCard(item);
    }
  }

  /// بطاقة بأسلوب الدعاء الأصلي
  Widget _buildDuaStyleCard(FavoriteItem item) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ThemeConstants.primary.withOpacity(0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () => _openItem(item),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: ThemeConstants.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: ThemeConstants.primary,
                        size: 20.sp,
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
                          fontFamily: ThemeConstants.fontFamilyArabic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildFavoriteMenu(item),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // المحتوى العربي
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: ThemeConstants.primary.withOpacity(0.1),
                      width: 1.w,
                    ),
                  ),
                  child: Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: context.textPrimaryColor,
                      height: 1.8,
                      fontFamily: ThemeConstants.fontFamilyArabic,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                
                // الترجمة إذا كانت موجودة
                if (item.subtitle != null) ...[
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: context.textSecondaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: context.textSecondaryColor,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: 12.h),
                
                // معلومات إضافية
                _buildCardFooter(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بطاقة بأسلوب الأذكار الأصلي
  Widget _buildAthkarStyleCard(FavoriteItem item) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ThemeConstants.accent.withOpacity(0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () => _openItem(item),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: ThemeConstants.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: ThemeConstants.accent,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'ذكر من أذكار المسلم',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: ThemeConstants.medium,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                    _buildFavoriteMenu(item),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // نص الذكر
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: ThemeConstants.accent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: ThemeConstants.accent.withOpacity(0.15),
                      width: 1.w,
                    ),
                  ),
                  child: Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: context.textPrimaryColor,
                      height: 1.8,
                      fontFamily: ThemeConstants.fontFamilyArabic,
                      fontWeight: ThemeConstants.medium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // الفضل إذا كان موجود
                if (item.subtitle != null) ...[
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: ThemeConstants.tertiary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: ThemeConstants.tertiary.withOpacity(0.2),
                        width: 1.w,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: ThemeConstants.tertiary,
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'الفضل',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: ThemeConstants.bold,
                                color: ThemeConstants.tertiary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: context.textPrimaryColor,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 12.h),
                
                // معلومات إضافية
                _buildCardFooter(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بطاقة بأسلوب أسماء الله الأصلي
  Widget _buildAsmaAllahStyleCard(FavoriteItem item) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ThemeConstants.tertiary.withOpacity(0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () => _openItem(item),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رأس البطاقة
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ThemeConstants.tertiary, ThemeConstants.tertiaryLight],
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: ThemeConstants.bold,
                          color: ThemeConstants.tertiary,
                          fontFamily: ThemeConstants.fontFamilyArabic,
                        ),
                      ),
                    ),
                    _buildFavoriteMenu(item),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // الشرح
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: context.textSecondaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_rounded,
                            color: context.textSecondaryColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'الشرح والتفسير',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: ThemeConstants.bold,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        item.content.length > 200 
                            ? '${item.content.substring(0, 200)}...'
                            : item.content,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.textPrimaryColor,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                // معلومات إضافية
                _buildCardFooter(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// أيقونات خيارات المفضلة
  Widget _buildFavoriteMenu(FavoriteItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // أيقونة المشاركة
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: () => _handleItemAction('share', item),
            child: Container(
              padding: EdgeInsets.all(6.w),
              child: Icon(
                Icons.share_rounded,
                size: 18.sp,
                color: context.textSecondaryColor,
              ),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        
        // أيقونة النسخ
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: () => _handleItemAction('copy', item),
            child: Container(
              padding: EdgeInsets.all(6.w),
              child: Icon(
                Icons.copy_rounded,
                size: 18.sp,
                color: context.textSecondaryColor,
              ),
            ),
          ),
        ),
        SizedBox(width: 4.w),
        
        // أيقونة الحذف
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: () => _handleItemAction('remove', item),
            child: Container(
              padding: EdgeInsets.all(6.w),
              child: Icon(
                Icons.delete_rounded,
                size: 18.sp,
                color: const Color(0xFFB85450),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// تذييل البطاقة مع التاريخ والمصدر
  Widget _buildCardFooter(FavoriteItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // تاريخ الإضافة
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: context.dividerColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark_added_rounded,
                size: 12.sp,
                color: context.textSecondaryColor,
              ),
              SizedBox(width: 4.w),
              Text(
                _formatDate(item.addedAt),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        
        // المصدر إذا كان موجود
        if (item.source != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: ThemeConstants.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              item.source!,
              style: TextStyle(
                fontSize: 10.sp,
                color: ThemeConstants.primary,
                fontWeight: ThemeConstants.medium,
              ),
            ),
          ),
      ],
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
    
    // عرض تفاصيل العنصر في مربع حوار
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontFamily: ThemeConstants.fontFamilyArabic,
            fontSize: 16.sp,
            fontWeight: ThemeConstants.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // المحتوى الرئيسي
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: item.contentType == FavoriteContentType.dua
                      ? ThemeConstants.primary.withOpacity(0.05)
                      : item.contentType == FavoriteContentType.athkar
                          ? ThemeConstants.accent.withOpacity(0.05)
                          : ThemeConstants.tertiary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: item.contentType == FavoriteContentType.dua
                        ? ThemeConstants.primary.withOpacity(0.2)
                        : item.contentType == FavoriteContentType.athkar
                            ? ThemeConstants.accent.withOpacity(0.2)
                            : ThemeConstants.tertiary.withOpacity(0.2),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  item.content,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.6,
                    fontFamily: ThemeConstants.fontFamilyArabic,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              
              // الترجمة/الفضل (ليس لأسماء الله الحسنى)
              if (item.subtitle != null && item.contentType != FavoriteContentType.asmaAllah) ...[
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: context.textSecondaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.contentType == FavoriteContentType.dua
                            ? 'الترجمة'
                            : 'الفضل',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: ThemeConstants.bold,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // المصدر
              if (item.source != null) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.source_rounded,
                      size: 16.sp,
                      color: context.textSecondaryColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'المصدر: ',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: ThemeConstants.bold,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.source!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          // زر الإغلاق فقط
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// مشاركة عنصر
  void _shareItem(FavoriteItem item) async {
    HapticFeedback.lightImpact();
    
    try {
      switch (item.contentType) {
        case FavoriteContentType.dua:
          await _shareService.shareDua(
            item.title,
            item.content,
            translation: item.subtitle,
            virtue: item.metadata?['virtue'],
            source: item.source,
            reference: item.metadata?['reference'],
          );
          break;
          
        case FavoriteContentType.athkar:
          await _shareService.shareAthkar(
            item.content,
            fadl: item.metadata?['fadl'],
            source: item.source,
            categoryTitle: item.title,
          );
          break;
          
        case FavoriteContentType.asmaAllah:
          await _shareService.shareAsmaAllah(
            item.title,
            item.content,
          );
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في المشاركة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// نسخ عنصر
  void _copyItem(FavoriteItem item) async {
    HapticFeedback.lightImpact();
    
    try {
      switch (item.contentType) {
        case FavoriteContentType.dua:
          await _shareService.copyDua(
            item.title,
            item.content,
            translation: item.subtitle,
            virtue: item.metadata?['virtue'],
            source: item.source,
            reference: item.metadata?['reference'],
          );
          break;
          
        case FavoriteContentType.athkar:
          await _shareService.copyAthkar(
            item.content,
            fadl: item.metadata?['fadl'],
            source: item.source,
            categoryTitle: item.title,
          );
          break;
          
        case FavoriteContentType.asmaAllah:
          await _shareService.copyAsmaAllah(
            item.title,
            item.content,
          );
          break;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم النسخ إلى الحافظة'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF5D7052),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في النسخ: $e'),
          backgroundColor: const Color(0xFFB85450),
        ),
      );
    }
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