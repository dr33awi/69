// lib/features/dua/screens/dua_categories_screen.dart - محدث
// ============================================================================
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
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 12.w),
          
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primary.withValues(alpha: 0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              Icons.pan_tool_rounded,
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
                  'الأدعية المأثورة',
                  style: context.titleLarge?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  'أدعية من الكتاب والسنة',
                  style: context.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
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
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: ThemeConstants.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: ThemeConstants.primary,
              strokeWidth: 3.w,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل الأدعية...',
            style: context.titleMedium?.copyWith(
              color: context.textSecondaryColor,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'يرجى الانتظار قليلاً',
            style: context.bodySmall?.copyWith(
              color: context.textSecondaryColor.withOpacity(0.7),
              fontSize: 12.sp,
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
          margin: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 8.h,
          ),
          child: Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 16.sp,
                color: context.textSecondaryColor,
              ),
              SizedBox(width: 4.w),
              Text(
                'عدد الفئات: ${_categories.length}',
                style: context.labelMedium?.copyWith(
                  color: context.textSecondaryColor,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16.w),
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
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: context.textSecondaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_outlined,
              size: 60.sp,
              color: context.textSecondaryColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد فئات',
            style: context.titleLarge?.copyWith(
              color: context.textSecondaryColor,
              fontWeight: ThemeConstants.bold,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'لم يتم العثور على فئات الأدعية',
            style: context.bodyMedium?.copyWith(
              color: context.textSecondaryColor.withValues(alpha: 0.7),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCategoryCard(DuaCategory category, int index) {
    final color = _getCategoryColor(category.type);
    
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () => _onCategoryPressed(category),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(category.type),
                  color: _shouldUseWhiteIcon(category.type) ? Colors.white : Colors.black87,
                  size: 20.sp,
                ),
              ),
              
              SizedBox(width: 12.w),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: context.titleMedium?.copyWith(
                        color: color,
                        fontWeight: ThemeConstants.bold,
                        fontFamily: ThemeConstants.fontFamilyArabic,
                        fontSize: 16.sp,
                      ),
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    Text(
                      category.description,
                      style: context.bodySmall?.copyWith(
                        color: context.textSecondaryColor,
                        height: 1.3,
                        fontSize: 12.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered_rounded,
                          size: 12.sp,
                          color: ThemeConstants.accent,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${category.duaCount} دعاء',
                          style: context.labelSmall?.copyWith(
                            color: ThemeConstants.accent,
                            fontWeight: ThemeConstants.medium,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: color,
                  size: 18.sp,
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
