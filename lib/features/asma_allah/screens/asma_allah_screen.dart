// lib/features/asma_allah/screens/asma_allah_screen.dart
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/app/themes/app_theme.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:athkar_app/core/infrastructure/services/text_settings/extensions/text_settings_extensions.dart';
import 'package:athkar_app/core/infrastructure/services/text_settings/models/text_settings_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
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
              _buildEnhancedAppBar(),
              
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
      padding: EdgeInsets.all(12.w),
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
              
              SizedBox(width: 8.w),
              
              Container(
                padding: EdgeInsets.all(9.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ThemeConstants.tertiary, ThemeConstants.tertiaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: context.isDarkMode ? 0.15 : 0.06,
                      ),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: context.isDarkMode ? 0.08 : 0.03,
                      ),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Icon(
                  FlutterIslamicIcons.solidAllah,
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
                      'أسماء الله الحسنى',
                      style: context.titleLarge?.copyWith(
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                        fontSize: 17.sp,
                      ),
                    ),
                    Text(
                      'تسعة وتسعون اسماً',
                      style: context.bodySmall?.copyWith(
                        color: context.textSecondaryColor,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: 2.w),
              
              // زر إعدادات النصوص
              _buildActionButton(
                icon: Icons.text_fields_rounded,
                color: ThemeConstants.info,
                tooltip: 'إعدادات النص',
                onTap: _openTextSettings,
              ),
              
              SizedBox(width: 2.w),
              
              // زر إعدادات النص تم نقله هنا
            ],
          ),
          
          SizedBox(height: 12.h),
          
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 2.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: context.dividerColor.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.15 : 0.06,
                  ),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.08 : 0.03,
                  ),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                  spreadRadius: -1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
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
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: context.dividerColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.15 : 0.06,
            ),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.08 : 0.03,
            ),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
            spreadRadius: -1,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: context.bodyMedium?.copyWith(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'ابحث في الأسماء أو المعاني أو الشرح...',
          hintStyle: TextStyle(
            color: context.textSecondaryColor.withValues(alpha: 0.7),
            fontSize: 14.sp,
          ),
          prefixIcon: Container(
            padding: EdgeInsets.all(10.w),
            child: Icon(
              Icons.search_rounded,
              color: context.textSecondaryColor,
              size: 20.sp,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    margin: EdgeInsetsDirectional.only(end: 6.w),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: context.textSecondaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.clear_rounded,
                      color: context.textSecondaryColor,
                      size: 14.sp,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
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
        
        return _buildCompactList(list);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: ThemeConstants.tertiary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty_rounded, 
              color: ThemeConstants.tertiary, 
              size: 24.sp
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'جاري تحميل أسماء الله الحسنى...',
            style: context.titleMedium?.copyWith(
              color: context.textSecondaryColor,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'يرجى الانتظار قليلاً',
            style: context.bodySmall?.copyWith(
              color: context.textSecondaryColor.withOpacity(0.7),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: context.textSecondaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 50.sp,
              color: context.textSecondaryColor.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'لا توجد نتائج',
            style: context.titleLarge?.copyWith(
              color: context.textSecondaryColor,
              fontWeight: ThemeConstants.bold,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'جرب البحث بكلمات أخرى أو امسح شريط البحث',
              style: context.bodyMedium?.copyWith(
                color: context.textSecondaryColor.withValues(alpha: 0.7),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              HapticFeedback.lightImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.tertiary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 10.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
            ),
            icon: Icon(Icons.refresh_rounded, size: 18.sp),
            label: Text('عرض جميع الأسماء', style: TextStyle(fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactList(List<AsmaAllahModel> list) {
    return Column(
      children: [
        if (_searchQuery.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 6.h,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
            decoration: BoxDecoration(
              color: ThemeConstants.tertiary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: ThemeConstants.tertiary.withValues(alpha: 0.15),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 14.sp,
                  color: ThemeConstants.tertiary,
                ),
                SizedBox(width: 6.w),
                Text(
                  'عدد النتائج: ${list.length}',
                  style: context.labelMedium?.copyWith(
                    color: ThemeConstants.tertiary,
                    fontSize: 13.sp,
                    fontWeight: ThemeConstants.medium,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeConstants.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'البحث في كامل المحتوى',
                    style: context.labelSmall?.copyWith(
                      color: ThemeConstants.tertiary,
                      fontWeight: ThemeConstants.medium,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            color: ThemeConstants.tertiary,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(12.w),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 6.h),
                  child: CompactAsmaAllahCard(
                    item: item,
                    onTap: () => _openDetails(item),
                  ),
                );
              },
            ),
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

  void _openTextSettings() {
    context.showGlobalTextSettings(
      initialContentType: ContentType.asmaAllah,
    );
  }
}