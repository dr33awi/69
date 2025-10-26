// lib/core/infrastructure/services/favorites/widgets/favorites_filter_sheet.dart
// صفحة فلترة وترتيب المفضلات

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../app/themes/app_theme.dart';
import '../models/favorite_models.dart';

/// Bottom Sheet لإعدادات الفلترة والترتيب
class FavoritesFilterSheet extends StatefulWidget {
  final FavoritesSortOptions currentOptions;
  final Function(FavoritesSortOptions) onApply;

  const FavoritesFilterSheet({
    super.key,
    required this.currentOptions,
    required this.onApply,
  });

  @override
  State<FavoritesFilterSheet> createState() => _FavoritesFilterSheetState();
}

class _FavoritesFilterSheetState extends State<FavoritesFilterSheet> {
  late SortBy _selectedSortBy;
  late SortOrder _selectedSortOrder;
  FavoriteContentType? _selectedFilterType;

  @override
  void initState() {
    super.initState();
    _selectedSortBy = widget.currentOptions.sortBy;
    _selectedSortOrder = widget.currentOptions.sortOrder;
    _selectedFilterType = widget.currentOptions.filterByType;
  }

  void _applyFilters() {
    final newOptions = FavoritesSortOptions(
      sortBy: _selectedSortBy,
      sortOrder: _selectedSortOrder,
      filterByType: _selectedFilterType,
    );
    
    widget.onApply(newOptions);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedSortBy = SortBy.dateAdded;
      _selectedSortOrder = SortOrder.descending;
      _selectedFilterType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // المقبض مع تصميم أفضل
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 45.w,
              height: 5.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.dividerColor.withValues(alpha: 0.4),
                    context.dividerColor.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            
            // العنوان
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.dividerColor.withValues(alpha: 0.1),
                    width: 1.w,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ThemeConstants.info,
                          ThemeConstants.info.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeConstants.info.withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.tune_rounded,
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
                          'الترتيب والفلترة',
                          style: context.titleLarge?.copyWith(
                            fontWeight: ThemeConstants.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                        Text(
                          'خصص طريقة عرض المفضلات',
                          style: context.bodySmall?.copyWith(
                            color: context.textSecondaryColor,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: ThemeConstants.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _resetFilters,
                        borderRadius: BorderRadius.circular(10.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                color: ThemeConstants.error,
                                size: 18.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'إعادة',
                                style: TextStyle(
                                  color: ThemeConstants.error,
                                  fontSize: 13.sp,
                                  fontWeight: ThemeConstants.semiBold,
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
            
            // المحتوى
            SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الترتيب حسب
                  _buildSectionTitle('الترتيب حسب', Icons.sort_rounded),
                  SizedBox(height: 12.h),
                  _buildSortByOptions(),
                  
                  SizedBox(height: 24.h),
                  
                  // اتجاه الترتيب
                  _buildSectionTitle('اتجاه الترتيب', Icons.swap_vert_rounded),
                  SizedBox(height: 12.h),
                  _buildSortOrderOptions(),
                  
                  SizedBox(height: 24.h),
                  
                  // الفلترة حسب النوع
                  _buildSectionTitle('الفلترة حسب النوع', Icons.category_rounded),
                  SizedBox(height: 12.h),
                  _buildFilterTypeOptions(),
                  
                  SizedBox(height: 24.h),
                  
                  // زر التطبيق
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ThemeConstants.accent,
                            ThemeConstants.accentLight,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeConstants.accent.withValues(alpha: 0.4),
                            blurRadius: 12.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 22.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'تطبيق الإعدادات',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: ThemeConstants.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: ThemeConstants.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 16.sp,
            color: ThemeConstants.accent,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: context.titleMedium?.copyWith(
            fontWeight: ThemeConstants.bold,
            fontSize: 15.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildSortByOptions() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: SortBy.values.map((sortBy) {
        final isSelected = _selectedSortBy == sortBy;
        return _buildChip(
          label: sortBy.displayName,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedSortBy = sortBy;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortOrderOptions() {
    return Row(
      children: SortOrder.values.map((order) {
        final isSelected = _selectedSortOrder == order;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: order == SortOrder.ascending ? 4.w : 0,
              right: order == SortOrder.descending ? 4.w : 0,
            ),
            child: _buildChip(
              label: order.displayName,
              isSelected: isSelected,
              icon: order == SortOrder.ascending 
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedSortOrder = order;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterTypeOptions() {
    return Column(
      children: [
        // خيار "الكل"
        _buildChip(
          label: 'الكل',
          icon: Icons.all_inclusive_rounded,
          isSelected: _selectedFilterType == null,
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedFilterType = null;
            });
          },
          fullWidth: true,
        ),
        
        SizedBox(height: 8.h),
        
        // الأنواع المختلفة
        ...FavoriteContentType.values.map((type) {
          final isSelected = _selectedFilterType == type;
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _buildChip(
              label: type.displayName,
              icon: type.icon,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedFilterType = type;
                });
              },
              fullWidth: true,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    bool fullWidth = false,
  }) {
    final color = isSelected ? ThemeConstants.accent : context.textSecondaryColor;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      ThemeConstants.accent.withValues(alpha: 0.12),
                      ThemeConstants.accent.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : context.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected 
                  ? ThemeConstants.accent
                  : context.dividerColor.withValues(alpha: 0.25),
              width: isSelected ? 2.w : 1.w,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ThemeConstants.accent.withValues(alpha: 0.15),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 3.r,
                      offset: Offset(0, 1.h),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 10.w),
              ],
              Flexible(
                child: Text(
                  label,
                  style: context.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: isSelected 
                        ? ThemeConstants.bold 
                        : ThemeConstants.medium,
                    fontSize: 14.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: 10.w),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
