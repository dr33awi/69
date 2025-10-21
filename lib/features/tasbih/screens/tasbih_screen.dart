// lib/features/tasbih/screens/tasbih_screen.dart
import 'package:athkar_app/features/tasbih/widgets/dhikr_selection_modal.dart';
import 'package:athkar_app/features/tasbih/widgets/dhikr_selector_widget.dart';
import 'package:athkar_app/features/tasbih/widgets/tasbih_main_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../services/tasbih_service.dart';
import '../models/dhikr_model.dart';


class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  late TasbihService _service;
  DhikrItem _currentDhikr = DefaultAdhkar.getAll().first;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() {
    _service = TasbihService(storage: getIt<StorageService>());
    _service.startSession(_currentDhikr.text);
  }

  @override
  void dispose() {
    _service.endSession();
    super.dispose();
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
              _buildAppBar(context),
              
              DhikrSelectorWidget(
                currentDhikr: _currentDhikr,
                onTap: _showDhikrSelectionModal,
              ),
              
              Expanded(
                child: TasbihMainArea(
                  currentDhikr: _currentDhikr,
                  onIncrement: _handleIncrement,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
                colors: _currentDhikr.gradient,
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              FlutterIslamicIcons.solidTasbihHand,
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
                  'المسبحة الرقمية',
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    fontSize: 17.sp,
                  ),
                ),
                Text(
                  'اذكر الله كثيراً',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          
          Consumer<TasbihService>(
            builder: (context, service, _) {
              return Container(
                margin: EdgeInsets.only(left: 6.w),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                  child: InkWell(
                    onTap: _showResetDialog,
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: context.dividerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: ThemeConstants.error,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleIncrement() {
    _service.increment(dhikrType: _currentDhikr.text);
    HapticFeedback.lightImpact();
    
    if (_service.count % _currentDhikr.recommendedCount == 0) {
      HapticFeedback.mediumImpact();
      _showCompletionMessage();
    }
  }

  void _showCompletionMessage() {
    if (mounted) {
      context.showSuccessSnackBar(
        'تم إكمال جولة ${_currentDhikr.category.title} 🎉',
      );
    }
  }

  void _showResetDialog() {
    AppInfoDialog.showConfirmation(
      context: context,
      title: 'تصفير العداد',
      content: 'هل أنت متأكد من أنك تريد تصفير العداد؟ سيتم فقدان العد الحالي.',
      confirmText: 'تصفير',
      cancelText: 'إلغاء',
      icon: Icons.refresh_rounded,
      destructive: true,
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        _service.reset();
        HapticFeedback.mediumImpact();
        context.showSuccessSnackBar('تم تصفير العداد');
      }
    });
  }

  // ✅ الإصلاح: تصفير العداد عند تغيير الذكر
  void _changeDhikr(DhikrItem newDhikr) async {
    // حفظ الجلسة الحالية
    await _service.endSession();
    
    // تصفير العداد الحالي
    await _service.reset();
    
    // تحديث الذكر
    setState(() {
      _currentDhikr = newDhikr;
    });
    
    // بدء جلسة جديدة
    _service.startSession(newDhikr.text);
    HapticFeedback.mediumImpact();
    
    if (mounted) {
      context.showSuccessSnackBar('تم تغيير الذكر إلى: ${newDhikr.text}');
    }
  }

  void _showDhikrSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => ChangeNotifierProvider.value(
        value: _service,
        child: DhikrSelectionModal(
          currentDhikr: _currentDhikr,
          service: _service,
          onDhikrSelected: (dhikr) {
            _changeDhikr(dhikr);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}