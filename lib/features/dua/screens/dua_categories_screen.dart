// lib/features/dua/screens/dua_categories_screen.dart - محدث
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/dua_service.dart';
import '../models/dua_model.dart';
import '../data/dua_data.dart';
import 'dua_details_screen.dart';

class DuaCategoriesScreen extends StatefulWidget {
  const DuaCategoriesScreen({super.key});

  @override
  State<DuaCategoriesScreen> createState() => _DuaCategoriesScreenState();
}

class _DuaCategoriesScreenState extends State<DuaCategoriesScreen> {
  late final DuaService _duaService;
  
  List<DuaCategory> _categories = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _duaService = getService<DuaService>();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // تحميل الفئات والإحصائيات بشكل متوازي
      final results = await Future.wait([
        _duaService.getCategories(),
        DuaData.getDataStats(),
      ]);
      
      _categories = results[0] as List<DuaCategory>;
      _stats = results[1] as Map<String, dynamic>;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        context.showErrorSnackBar('حدث خطأ في تحميل البيانات');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildEnhancedAppBar(),
            if (!_isLoading) _buildStatsBar(),
            Expanded(
              child: _isLoading ? _buildLoading() : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
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
                colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
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
              Icons.pan_tool_rounded,
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
                  'الأدعية المأثورة',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 16.sp,
                  ),
                ),
                Text(
                  'من الكتاب والسنة الصحيحة',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ شريط الإحصائيات
  Widget _buildStatsBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConstants.primary.withOpacity(0.1),
            ThemeConstants.primaryLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ThemeConstants.primary.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.book_rounded,
            _stats['totalDuas']?.toString() ?? '0',
            'دعاء',
            ThemeConstants.primary,
          ),
          Container(
            width: 1.w,
            height: 25.h,
            color: context.dividerColor.withOpacity(0.3),
          ),
          _buildStatItem(
            Icons.menu_book_rounded,
            '24',
            'من القرآن',
            ThemeConstants.accent,
          ),
          Container(
            width: 1.w,
            height: 25.h,
            color: context.dividerColor.withOpacity(0.3),
          ),
          _buildStatItem(
            Icons.verified_rounded,
            '76',
            'من السنة',
            ThemeConstants.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              value,
              style: TextStyle(
                fontWeight: ThemeConstants.bold,
                color: color,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: context.textSecondaryColor,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: ThemeConstants.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: ThemeConstants.primary,
              strokeWidth: 2.5.w,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'جاري تحميل الأدعية...',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_categories.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: ThemeConstants.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(12.r),
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: _buildCategoryCard(category, index),
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
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: context.textSecondaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_outlined,
              size: 50.sp,
              color: context.textSecondaryColor.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'لا توجد فئات',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontWeight: ThemeConstants.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            icon: Icon(Icons.refresh_rounded, size: 18.sp),
            label: Text('إعادة المحاولة', style: TextStyle(fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }

  /// ✅ بطاقة الفئة المحسنة
  Widget _buildCategoryCard(DuaCategory category, int index) {
    final color = _getCategoryColor(category.id);
    final icon = _getCategoryIcon(category.id);
    final gradient = _getCategoryGradient(category.id);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () => _onCategoryPressed(category),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: 120.h,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Stack(
            children: [
              // ✅ خلفية زخرفية
              Positioned(
                left: -20.w,
                bottom: -20.h,
                child: Icon(
                  icon,
                  size: 100.sp,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              
              // ✅ المحتوى
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: ThemeConstants.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                category.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12.sp,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // ✅ شريط المعلومات السفلي
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.format_list_numbered_rounded,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${category.duaCount} دعاء',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: ThemeConstants.semiBold,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                        ],
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

  /// ✅ الحصول على لون الفئة
  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return const Color(0xFF2E7D32); // أخضر داكن
      case 'sahihain':
        return const Color(0xFF1565C0); // أزرق
      case 'sunan':
        return const Color(0xFF6A1B9A); // بنفسجي
      case 'other_authentic':
        return const Color(0xFFD84315); // برتقالي داكن
      default:
        return ThemeConstants.primary;
    }
  }

  /// ✅ الحصول على تدرج الفئة
  LinearGradient _getCategoryGradient(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return LinearGradient(
          colors: [const Color(0xFF2E7D32), const Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'sahihain':
        return LinearGradient(
          colors: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'sunan':
        return LinearGradient(
          colors: [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'other_authentic':
        return LinearGradient(
          colors: [const Color(0xFFD84315), const Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  /// ✅ الحصول على أيقونة الفئة
  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return Icons.menu_book_rounded;
      case 'sahihain':
        return Icons.verified_rounded;
      case 'sunan':
        return Icons.collections_bookmark_rounded;
      case 'other_authentic':
        return Icons.bookmark_rounded;
      default:
        return Icons.auto_awesome;
    }
  }

  void _onCategoryPressed(DuaCategory category) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DuaDetailsScreen(
          categoryId: category.id,
          categoryName: category.name,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}