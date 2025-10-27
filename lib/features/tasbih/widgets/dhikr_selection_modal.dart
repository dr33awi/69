// lib/features/tasbih/widgets/dhikr_selection_modal.dart
import 'package:athkar_app/features/tasbih/models/dhikr_model.dart';
import 'package:athkar_app/features/tasbih/services/tasbih_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../app/themes/app_theme.dart';

import 'custom_dhikr_dialogs.dart';

class DhikrSelectionModal extends StatefulWidget {
  final DhikrItem currentDhikr;
  final TasbihService service;
  final Function(DhikrItem) onDhikrSelected;

  const DhikrSelectionModal({
    super.key,
    required this.currentDhikr,
    required this.service,
    required this.onDhikrSelected,
  });

  @override
  State<DhikrSelectionModal> createState() => _DhikrSelectionModalState();
}

class _DhikrSelectionModalState extends State<DhikrSelectionModal> {
  late DhikrItem _selectedDhikr;

  @override
  void initState() {
    super.initState();
    _selectedDhikr = widget.currentDhikr;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(context),
          _buildHeader(context),
          Flexible(child: _buildDhikrCategoriesList(context)),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10.h),
      width: 36.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: context.dividerColor,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
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
            child: Icon(Icons.list_alt_rounded, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اختر الذكر', style: TextStyle(fontWeight: ThemeConstants.bold, fontSize: 16.sp)),
                Text('اختر الذكر الذي تريد تسبيحه', style: TextStyle(color: context.textSecondaryColor, fontSize: 12.sp)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: context.textSecondaryColor, size: 22.sp),
            padding: EdgeInsets.all(6.r),
            constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrCategoriesList(BuildContext context) {
    final allAdhkar = widget.service.getAllAdhkar();
    final Map<DhikrCategory, List<DhikrItem>> categorizedAdhkar = {};
    
    for (final dhikr in allAdhkar) {
      categorizedAdhkar.putIfAbsent(dhikr.category, () => []).add(dhikr);
    }

    return Consumer<TasbihService>(
      builder: (context, service, _) {
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.r),
          itemCount: categorizedAdhkar.keys.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildAddCustomButton(context);
            
            final categoryIndex = index - 1;
            final category = categorizedAdhkar.keys.elementAt(categoryIndex);
            final adhkar = categorizedAdhkar[category]!;
            
            return _buildCategorySection(context, category, adhkar);
          },
        );
      },
    );
  }

  Widget _buildAddCustomButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: () => CustomDhikrDialogs.showAddDialog(
            context,
            widget.service,
            (newDhikr) {
              setState(() => _selectedDhikr = newDhikr);
              Navigator.pop(context);
              widget.onDhikrSelected(newDhikr);
            },
          ),
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
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
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
                        blurRadius: 6.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add_circle_outline, color: Colors.white, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إضافة ذكر مخصص',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: ThemeConstants.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'أضف ذكرك الخاص وحدد عدد التسبيح',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    DhikrCategory category,
    List<DhikrItem> adhkar,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeConstants.primary.withOpacity(0.1),
                  ThemeConstants.primaryLight.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: ThemeConstants.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(category.icon, color: ThemeConstants.primary, size: 18.sp),
                SizedBox(width: 6.w),
                Text(
                  category.title,
                  style: TextStyle(
                    color: ThemeConstants.primary,
                    fontWeight: ThemeConstants.semiBold,
                    fontSize: 14.sp,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${adhkar.length}',
                    style: TextStyle(
                      color: ThemeConstants.primary,
                      fontWeight: ThemeConstants.bold,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          ...adhkar.map((dhikr) => _buildDhikrItem(context, dhikr)),
        ],
      ),
    );
  }

  Widget _buildDhikrItem(BuildContext context, DhikrItem dhikr) {
    final isSelected = _selectedDhikr.id == dhikr.id;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: () => widget.onDhikrSelected(dhikr),
          onLongPress: dhikr.isCustom ? () => _showCustomOptions(context, dhikr) : null,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: isSelected ? dhikr.primaryColor.withOpacity(0.1) : context.cardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isSelected 
                    ? dhikr.primaryColor.withOpacity(0.3)
                    : context.dividerColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: dhikr.gradient),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(dhikr.category.icon, color: Colors.white, size: 14.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dhikr.text,
                              style: TextStyle(
                                fontWeight: isSelected ? ThemeConstants.semiBold : ThemeConstants.regular,
                                color: isSelected ? dhikr.primaryColor : context.textPrimaryColor,
                                fontSize: 12.sp,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (dhikr.isCustom) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: ThemeConstants.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'مخصص',
                                style: TextStyle(
                                  color: ThemeConstants.accent,
                                  fontSize: 9.sp,
                                  fontWeight: ThemeConstants.semiBold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (dhikr.virtue != null) ...[
                        SizedBox(height: 6.h),
                        GestureDetector(
                          onTap: () => _showVirtueDialog(context, dhikr),
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? dhikr.primaryColor.withOpacity(0.1)
                                  : ThemeConstants.accent.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: isSelected 
                                    ? dhikr.primaryColor.withOpacity(0.2)
                                    : ThemeConstants.accent.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 11.sp,
                                  color: isSelected ? dhikr.primaryColor : ThemeConstants.accent,
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: Text(
                                    dhikr.virtue!,
                                    style: TextStyle(
                                      color: context.textSecondaryColor,
                                      fontSize: 10.sp,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.more_horiz,
                                  size: 14.sp,
                                  color: context.textSecondaryColor.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: dhikr.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${dhikr.recommendedCount}×',
                    style: TextStyle(
                      color: dhikr.primaryColor,
                      fontWeight: ThemeConstants.semiBold,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected 
                      ? dhikr.primaryColor
                      : context.textSecondaryColor.withOpacity(0.3),
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVirtueDialog(BuildContext context, DhikrItem dhikr) {
    if (dhikr.virtue == null) return;
    
    AppInfoDialog.show(
      context: context,
      title: 'فضيلة الذكر',
      content: dhikr.virtue!,
      icon: Icons.star_rounded,
      closeButtonText: 'حسناً',
    );
  }

  void _showCustomOptions(BuildContext context, DhikrItem dhikr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit, color: ThemeConstants.primary),
              title: Text(
                'تعديل الذكر',
                style: TextStyle(fontSize: 14.sp, fontWeight: ThemeConstants.medium),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                CustomDhikrDialogs.showEditDialog(
                  context,
                  dhikr,
                  widget.service,
                  (updatedDhikr) {
                    if (_selectedDhikr.id == dhikr.id) {
                      setState(() => _selectedDhikr = updatedDhikr);
                      widget.onDhikrSelected(updatedDhikr);
                    }
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: ThemeConstants.error),
              title: Text(
                'حذف الذكر',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: ThemeConstants.medium,
                  color: ThemeConstants.error,
                ),
              ),
              onTap: () {
                Navigator.pop(modalContext);
                CustomDhikrDialogs.showDeleteConfirmation(
                  context,
                  dhikr,
                  widget.service,
                  () {
                    if (_selectedDhikr.id == dhikr.id) {
                      final defaultDhikr = DefaultAdhkar.getAll().first;
                      setState(() => _selectedDhikr = defaultDhikr);
                      widget.onDhikrSelected(defaultDhikr);
                    }
                  },
                );
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}