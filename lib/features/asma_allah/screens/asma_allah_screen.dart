// lib/features/asma_allah/screens/asma_allah_screen.dart - محدث مع flutter_screenutil
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/asma_allah_model.dart';
import '../services/asma_allah_service.dart';
import '../widgets/asma_allah_widgets.dart';
import 'asma_detail_screen.dart';

class AsmaAllahScreen extends StatefulWidget {
  const AsmaAllahScreen({super.key});
  @override
  State<AsmaAllahScreen> createState() => _AsmaAllahScreenState();
}

class _AsmaAllahScreenState extends State<AsmaAllahScreen> {
  late AsmaAllahService _service;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  
  // إعدادات العرض
  bool _showDetailedView = false;

  @override
  void initState() {
    super.initState();
    _service = AsmaAllahService(storage: getIt<StorageService>());
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  List<AsmaAllahModel> _getFilteredList() {
    var list = _service.asmaAllahList;
    if (_searchQuery.isNotEmpty) {
      list = list.where((item) => 
        item.name.contains(_searchQuery) || 
        item.meaning.contains(_searchQuery) ||
        item.explanation.contains(_searchQuery) ||
        (item.reference?.contains(_searchQuery) ?? false)
      ).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _service,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // شريط التطبيق المحسن
              _buildEnhancedAppBar(),
              
              // المحتوى الرئيسي
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // الصف الأول - العنوان والأزرار
          Row(
            children: [
              // زر الرجوع
              AppBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              
              SizedBox(width: 12.w),
              
              // أيقونة مميزة
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ThemeConstants.tertiary, ThemeConstants.tertiaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConstants.tertiary.withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star_outline,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              
              SizedBox(width: 12.w),
              
              // معلومات العنوان
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أسماء الله الحسنى',
                      style: context.titleLarge?.copyWith(
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'تسعة وتسعون اسماً من أحصاها دخل الجنة',
                      style: context.bodySmall?.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // زر تبديل طريقة العرض
              _buildViewToggleButton(),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // شريط البحث المحسن
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: () {
            setState(() => _showDetailedView = !_showDetailedView);
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              _showDetailedView ? Icons.view_agenda_rounded : Icons.view_list_rounded,
              color: ThemeConstants.tertiary,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: context.bodyMedium,
        decoration: InputDecoration(
          hintText: 'ابحث في الأسماء أو المعاني أو الشرح والتفسير...',
          hintStyle: TextStyle(
            color: context.textSecondaryColor.withValues(alpha: 0.7),
            fontSize: 14.sp,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(12.w),
            child: Icon(
              Icons.search_rounded,
              color: context.textSecondaryColor,
              size: 24.sp,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    margin: EdgeInsetsDirectional.only(end: 8.w),
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: context.textSecondaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.clear_rounded,
                      color: context.textSecondaryColor,
                      size: 16.sp,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<AsmaAllahService>(
      builder: (_, service, __) {
        if (service.isLoading) {
          return _buildLoadingState();
        }
        
        final list = _getFilteredList();
        if (list.isEmpty) {
          return _buildEmptyState();
        }
        
        return _showDetailedView 
            ? _buildDetailedList(list)
            : _buildCompactList(list);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: ThemeConstants.tertiary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty_rounded, 
              color: ThemeConstants.tertiary, 
              size: 28.sp
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل أسماء الله الحسنى...',
            style: context.titleMedium?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'يرجى الانتظار قليلاً',
            style: context.bodySmall?.copyWith(
              color: context.textSecondaryColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
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
              Icons.search_off_rounded,
              size: 60.sp,
              color: context.textSecondaryColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد نتائج',
            style: context.titleLarge?.copyWith(
              color: context.textSecondaryColor,
              fontWeight: ThemeConstants.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'جرب البحث بكلمات أخرى أو امسح شريط البحث',
            style: context.bodyMedium?.copyWith(
              color: context.textSecondaryColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              HapticFeedback.lightImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.tertiary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('عرض جميع الأسماء'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactList(List<AsmaAllahModel> list) {
    return Column(
      children: [
        // عداد النتائج ونوع البحث
        if (_searchQuery.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 16.sp,
                  color: context.textSecondaryColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  'عدد النتائج: ${list.length}',
                  style: context.labelMedium?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeConstants.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'البحث في كامل المحتوى',
                    style: context.labelSmall?.copyWith(
                      color: ThemeConstants.tertiary,
                      fontWeight: ThemeConstants.medium,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // القائمة المضغوطة
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16.w),
            physics: const ClampingScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                child: CompactAsmaAllahCard(
                  item: item,
                  onTap: () => _openDetails(item),
                  showExplanationPreview: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedList(List<AsmaAllahModel> list) {
    return Column(
      children: [
        // عداد النتائج مع معلومات إضافية
        if (_searchQuery.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 8.h,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 16.sp,
                      color: context.textSecondaryColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'عدد النتائج: ${list.length}',
                      style: context.labelMedium?.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeConstants.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'العرض التفصيلي',
                        style: context.labelSmall?.copyWith(
                          color: ThemeConstants.primary,
                          fontWeight: ThemeConstants.medium,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        
        // القائمة التفصيلية
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16.w),
            physics: const BouncingScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return DetailedAsmaAllahCard(
                item: item,
                onTap: () => _openDetails(item),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDetails(AsmaAllahModel item) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => UnifiedAsmaAllahDetailsScreen(
          item: item,
          service: _service,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      ),
    );
  }
}