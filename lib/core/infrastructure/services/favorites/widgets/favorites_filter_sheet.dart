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
          top: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // المقبض
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // العنوان
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: ThemeConstants.info,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'الترتيب والفلترة',
                    style: context.titleLarge?.copyWith(
                      fontWeight: ThemeConstants.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: _resetFilters,
                    child: Text(
                      'إعادة تعيين',
                      style: TextStyle(
                        color: ThemeConstants.error,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1.h),
            
            // المحتوى
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الترتيب حسب
                  _buildSectionTitle('الترتيب حسب'),
                  SizedBox(height: 12.h),
                  _buildSortByOptions(),
                  
                  SizedBox(height: 24.h),
                  
                  // اتجاه الترتيب
                  _buildSectionTitle('اتجاه الترتيب'),
                  SizedBox(height: 12.h),
                  _buildSortOrderOptions(),
                  
                  SizedBox(height: 24.h),
                  
                  // الفلترة حسب النوع
                  _buildSectionTitle('الفلترة حسب النوع'),
                  SizedBox(height: 12.h),
                  _buildFilterTypeOptions(),
                  
                  SizedBox(height: 24.h),
                  
                  // زر التطبيق
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.accent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'تطبيق',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: ThemeConstants.semiBold,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: context.titleMedium?.copyWith(
        fontWeight: ThemeConstants.semiBold,
        fontSize: 15.sp,
      ),
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
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? ThemeConstants.accent.withValues(alpha: 0.1)
                : context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected 
                  ? ThemeConstants.accent
                  : context.dividerColor.withValues(alpha: 0.3),
              width: isSelected ? 2.w : 1.w,
            ),
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: color,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
              ],
              Text(
                label,
                style: context.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: isSelected 
                      ? ThemeConstants.semiBold 
                      : ThemeConstants.regular,
                  fontSize: 14.sp,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: 8.w),
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 18.sp,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
