// lib/features/tasbih/widgets/custom_dhikr_dialogs.dart
import 'package:athkar_app/features/tasbih/models/dhikr_model.dart';
import 'package:athkar_app/features/tasbih/services/tasbih_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_theme.dart';


class CustomDhikrDialogs {
  static void showAddDialog(
    BuildContext context,
    TasbihService service,
    Function(DhikrItem) onAdded,
  ) {
    final textController = TextEditingController();
    final virtueController = TextEditingController();
    final countController = TextEditingController(text: '33');
    DhikrCategory selectedCategory = DhikrCategory.custom;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: context.backgroundColor,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.add_circle_outline, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Text('إضافة ذكر مخصص', style: TextStyle(fontSize: 16.sp, fontWeight: ThemeConstants.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  context,
                  'نص الذكر',
                  textController,
                  'أدخل نص الذكر...',
                  maxLines: 2,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  context,
                  'الفضيلة (اختياري)',
                  virtueController,
                  'أدخل فضيلة الذكر...', 
                  maxLines: 3,
                ),
                SizedBox(height: 16.h),
                _buildCategoryDropdown(
                  context,
                  selectedCategory,
                  (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  context,
                  'عدد التسبيح',
                  countController,
                  '33',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('إلغاء', style: TextStyle(color: context.textSecondaryColor, fontSize: 13.sp)),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = textController.text.trim();
                
                if (text.isEmpty) {
                  if (context.mounted) {
                    context.showErrorSnackBar('الرجاء إدخال نص الذكر');
                  }
                  return;
                }
                
                if (text.length < 3) {
                  if (context.mounted) {
                    context.showErrorSnackBar('نص الذكر قصير جداً (3 أحرف على الأقل)');
                  }
                  return;
                }
                
                final count = int.tryParse(countController.text) ?? 33;
                
                if (count < 1 || count > 1000) {
                  if (context.mounted) {
                    context.showErrorSnackBar('عدد التسبيح يجب أن يكون بين 1 و 1000');
                  }
                  return;
                }
                
                try {
                  final newDhikr = DhikrItem(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    text: text,
                    virtue: virtueController.text.trim().isEmpty 
                        ? null 
                        : virtueController.text.trim(),
                    recommendedCount: count,
                    category: selectedCategory,
                    gradient: _getGradientForCategory(selectedCategory),
                    primaryColor: _getColorForCategory(selectedCategory),
                    isCustom: true,
                    createdAt: DateTime.now(),
                  );
                  
                  await service.addCustomDhikr(newDhikr);
                  
                  // ✅ إصلاح: التحقق من mounted قبل Navigation
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  
                  onAdded(newDhikr);
                  
                  if (context.mounted) {
                    context.showSuccessSnackBar('تم إضافة الذكر بنجاح');
                  }
                } catch (e) {
                  if (context.mounted) {
                    context.showErrorSnackBar('حدث خطأ أثناء إضافة الذكر');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('إضافة', style: TextStyle(fontSize: 13.sp)),
            ),
          ],
        ),
      ),
    );
  }

  static void showEditDialog(
    BuildContext context,
    DhikrItem dhikr,
    TasbihService service,
    Function(DhikrItem) onEdited,
  ) {
    final textController = TextEditingController(text: dhikr.text);
    final virtueController = TextEditingController(text: dhikr.virtue ?? '');
    final countController = TextEditingController(text: dhikr.recommendedCount.toString());
    DhikrCategory selectedCategory = dhikr.category;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: context.backgroundColor,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ThemeConstants.primary, ThemeConstants.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.edit, color: Colors.white, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Text('تعديل الذكر', style: TextStyle(fontSize: 16.sp, fontWeight: ThemeConstants.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(context, 'نص الذكر', textController, 'أدخل نص الذكر...', maxLines: 2),
                SizedBox(height: 16.h),
                _buildTextField(context, 'الفضيلة (اختياري)', virtueController, 'أدخل فضيلة الذكر...', maxLines: 3),
                SizedBox(height: 16.h),
                _buildCategoryDropdown(context, selectedCategory, (value) {
                  if (value != null) {
                    setDialogState(() => selectedCategory = value);
                  }
                }),
                SizedBox(height: 16.h),
                _buildTextField(context, 'عدد التسبيح', countController, '33', keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('إلغاء', style: TextStyle(color: context.textSecondaryColor, fontSize: 13.sp)),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = textController.text.trim();
                
                if (text.isEmpty) {
                  if (context.mounted) {
                    context.showErrorSnackBar('الرجاء إدخال نص الذكر');
                  }
                  return;
                }
                
                if (text.length < 3) {
                  if (context.mounted) {
                    context.showErrorSnackBar('نص الذكر قصير جداً (3 أحرف على الأقل)');
                  }
                  return;
                }
                
                final count = int.tryParse(countController.text) ?? 33;
                
                if (count < 1 || count > 1000) {
                  if (context.mounted) {
                    context.showErrorSnackBar('عدد التسبيح يجب أن يكون بين 1 و 1000');
                  }
                  return;
                }try {
                  final updatedDhikr = dhikr.copyWith(
                    text: text,
                    virtue: virtueController.text.trim().isEmpty ? null : virtueController.text.trim(),
                    recommendedCount: count,
                    category: selectedCategory,
                    gradient: _getGradientForCategory(selectedCategory),
                    primaryColor: _getColorForCategory(selectedCategory),
                  );
                  
                  await service.updateCustomDhikr(dhikr.id, updatedDhikr);
                  
                  // ✅ إصلاح: التحقق من mounted قبل Navigation
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  
                  onEdited(updatedDhikr);
                  
                  if (context.mounted) {
                    context.showSuccessSnackBar('تم تحديث الذكر بنجاح');
                  }
                } catch (e) {
                  if (context.mounted) {
                    context.showErrorSnackBar('حدث خطأ أثناء تحديث الذكر');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('حفظ', style: TextStyle(fontSize: 13.sp)),
            ),
          ],
        ),
      ),
    );
  }

  static void showDeleteConfirmation(
    BuildContext context,
    DhikrItem dhikr,
    TasbihService service,
    Function() onDeleted,
  ) {
    AppInfoDialog.showConfirmation(
      context: context,
      title: 'حذف الذكر',
      content: 'هل أنت متأكد من حذف هذا الذكر؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'حذف',
      cancelText: 'إلغاء',
      icon: Icons.delete,
      destructive: true,
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          await service.deleteCustomDhikr(dhikr.id);
          onDeleted();
          
          // ✅ إصلاح: التحقق من mounted قبل استخدام context
          if (context.mounted) {
            context.showSuccessSnackBar('تم حذف الذكر بنجاح');
          }
        } catch (e) {
          if (context.mounted) {
            context.showErrorSnackBar('حدث خطأ أثناء حذف الذكر');
          }
        }
      }
    });
  }

  static Widget _buildTextField(
    BuildContext context,
    String label,
    TextEditingController controller,
    String hint, {
    int? maxLines,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: ThemeConstants.semiBold,
            color: context.textSecondaryColor,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          maxLines: maxLines ?? 1,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13.sp,
              color: context.textSecondaryColor.withOpacity(0.5),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            contentPadding: EdgeInsets.all(12.r),
          ),
          style: TextStyle(fontSize: 13.sp),
        ),
      ],
    );
  }

  static Widget _buildCategoryDropdown(
    BuildContext context,
    DhikrCategory selectedCategory,
    Function(DhikrCategory?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التصنيف',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: ThemeConstants.semiBold,
            color: context.textSecondaryColor,
          ),
        ),
        SizedBox(height: 6.h),
        DropdownButtonFormField<DhikrCategory>(
          value: selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          ),
          items: DhikrCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Icon(category.icon, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(category.title, style: TextStyle(fontSize: 12.sp)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static List<Color> _getGradientForCategory(DhikrCategory category) {
    switch (category) {
      case DhikrCategory.tasbih:
        return [ThemeConstants.primary, ThemeConstants.primaryLight];
      case DhikrCategory.tahmid:
        return [ThemeConstants.accent, ThemeConstants.accentLight];
      case DhikrCategory.takbir:
        return [ThemeConstants.tertiary, ThemeConstants.tertiaryLight];
      case DhikrCategory.tahlil:
        return [ThemeConstants.success, ThemeConstants.success.lighten(0.2)];
      case DhikrCategory.istighfar:
        return [ThemeConstants.primaryDark, ThemeConstants.primary];
      case DhikrCategory.salawat:
        return [ThemeConstants.accentDark, ThemeConstants.accent];
      case DhikrCategory.custom:
        return [ThemeConstants.primary, ThemeConstants.primaryLight];
    }
  }

  static Color _getColorForCategory(DhikrCategory category) {
    switch (category) {
      case DhikrCategory.tasbih:
        return ThemeConstants.primary;
      case DhikrCategory.tahmid:
        return ThemeConstants.accent;
      case DhikrCategory.takbir:
        return ThemeConstants.tertiary;
      case DhikrCategory.tahlil:
        return ThemeConstants.success;
      case DhikrCategory.istighfar:
        return ThemeConstants.primaryDark;
      case DhikrCategory.salawat:
        return ThemeConstants.accentDark;
      case DhikrCategory.custom:
        return ThemeConstants.primary;
    }
  }
}