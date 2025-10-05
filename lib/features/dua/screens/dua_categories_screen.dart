// lib/features/dua/screens/dua_categories_screen.dart - محسّن للشاشات الصغيرة
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/dua_service.dart';
import '../models/dua_model.dart';
import 'dua_details_screen.dart';

class DuaCategoriesScreen extends StatefulWidget {
  const DuaCategoriesScreen({super.key});

  @override
  State<DuaCategoriesScreen> createState() => _DuaCategoriesScreenState();
}

class _DuaCategoriesScreenState extends State<DuaCategoriesScreen> {
  late final DuaService _duaService;
  
  List<DuaCategory> _categories = [];
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
      
      _categories = await _duaService.getCategories();
      
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
                  color: ThemeConstants.primary.withValues(alpha: 0.25),
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
                  'من الكتاب والسنة',
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

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: ThemeConstants.primary.withValues(alpha: 0.1),
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
          SizedBox(height: 6.h),
          Text(
            'يرجى الانتظار قليلاً',
            style: TextStyle(
              color: context.textSecondaryColor.withOpacity(0.7),
              fontSize: 11.sp,
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

    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 14.sp,
                color: context.textSecondaryColor,
              ),
              SizedBox(width: 4.w),
              Text(
                'عدد الفئات: ${_categories.length}',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(12.r),
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                child: _buildCompactCategoryCard(category, index),
              );
            },
          ),
        ),
      ],
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
              color: context.textSecondaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_outlined,
              size: 50.sp,
              color: context.textSecondaryColor.withValues(alpha: 0.5),
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
          SizedBox(height: 6.h),
          Text(
            'لم يتم العثور على فئات الأدعية',
            style: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.7),
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
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

  Widget _buildCompactCategoryCard(DuaCategory category, int index) {
    final color = _getCategoryColor(category.type);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: () => _onCategoryPressed(category),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(category.type),
                  color: _shouldUseWhiteIcon(category.type) ? Colors.white : Colors.black87,
                  size: 18.sp,
                ),
              ),
              
              SizedBox(width: 10.w),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        color: color,
                        fontWeight: ThemeConstants.bold,
                        fontFamily: ThemeConstants.fontFamilyArabic,
                        fontSize: 14.sp,
                      ),
                    ),
                    
                    SizedBox(height: 3.h),
                    
                    Text(
                      category.description,
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        height: 1.3,
                        fontSize: 11.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 3.h),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered_rounded,
                          size: 11.sp,
                          color: ThemeConstants.accent,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          '${category.duaCount} دعاء',
                          style: TextStyle(
                            color: ThemeConstants.accent,
                            fontWeight: ThemeConstants.medium,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: EdgeInsets.all(5.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: color,
                  size: 16.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldUseWhiteIcon(DuaType type) {
    switch (type) {
      case DuaType.morning:
        return false;
      case DuaType.evening:
        return true;
      case DuaType.prayer:
        return true;
      case DuaType.sleep:
        return context.isDarkMode ? true : true;
      case DuaType.protection:
        return true;
      case DuaType.food:
        return true;
      case DuaType.travel:
        return true;
      default:
        return true;
    }
  }

  Color _getCategoryColor(DuaType type) {
    switch (type) {
      case DuaType.morning:
        return const Color(0xFFDAA520);
      case DuaType.evening:
        return const Color(0xFF8B6F47);
      case DuaType.prayer:
        return ThemeConstants.primary;
      case DuaType.sleep:
        return context.isDarkMode 
            ? const Color(0xFF708090)
            : const Color(0xFF2D352D);
      case DuaType.protection:
        return ThemeConstants.accent;
      case DuaType.food:
        return ThemeConstants.tertiary;
      case DuaType.travel:
        return const Color(0xFF7A8B6F);
      default:
        return ThemeConstants.primary;
    }
  }

  IconData _getCategoryIcon(DuaType type) {
    switch (type) {
      case DuaType.general:
        return Icons.auto_awesome;
      case DuaType.morning:
        return Icons.wb_sunny_rounded;
      case DuaType.evening:
        return Icons.nights_stay_rounded;
      case DuaType.prayer:
        return Icons.mosque_rounded;
      case DuaType.food:
        return Icons.restaurant_rounded;
      case DuaType.travel:
        return Icons.flight_takeoff_rounded;
      case DuaType.sleep:
        return Icons.bedtime_rounded;
      case DuaType.protection:
        return Icons.shield_rounded;
      case DuaType.forgiveness:
        return Icons.favorite_rounded;
      case DuaType.gratitude:
        return Icons.celebration_rounded;
      case DuaType.guidance:
        return Icons.explore_rounded;
      case DuaType.health:
        return Icons.healing_rounded;
      case DuaType.wealth:
        return Icons.attach_money_rounded;
      case DuaType.knowledge:
        return Icons.school_rounded;
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