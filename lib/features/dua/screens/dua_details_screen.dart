// lib/features/dua/screens/dua_details_screen.dart - محدث
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/dua_service.dart';
import '../models/dua_model.dart';
import '../widgets/dua_card_widget.dart';



class DuaDetailsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const DuaDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<DuaDetailsScreen> createState() => _DuaDetailsScreenState();
}

class _DuaDetailsScreenState extends State<DuaDetailsScreen> {
  late final DuaService _duaService;
  
  List<Dua> _duas = [];
  bool _isLoading = true;
  double _fontSize = 18.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _duaService = getService<DuaService>();
    _loadDuas();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDuas() async {
    try {
      setState(() => _isLoading = true);
      
      _duas = await _duaService.getDuasByCategory(widget.categoryId);
      _fontSize = await _duaService.getSavedFontSize();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        context.showErrorSnackBar('حدث خطأ في تحميل الأدعية');
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
              Icons.menu_book_rounded,
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
                  widget.categoryName,
                  style: context.titleLarge?.copyWith(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  '${_duas.length} دعاء',
                  style: context.bodySmall?.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          
          _buildActionButton(
            icon: Icons.text_fields_rounded,
            onTap: _showFontSizeDialog,
          ),
          
          _buildActionButton(
            icon: Icons.refresh_rounded,
            onTap: _loadDuas,
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 8.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
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
            child: Icon(
              icon,
              color: isSecondary ? context.textSecondaryColor : ThemeConstants.primary,
              size: 24.sp,
            ),
          ),
        ),
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
            'جاري تحميل ${widget.categoryName}...',
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
    if (_duas.isEmpty) {
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
                Icons.format_list_numbered_rounded,
                size: 16.sp,
                color: context.textSecondaryColor,
              ),
              SizedBox(width: 4.w),
              Text(
                'عدد الأدعية: ${_duas.length}',
                style: context.labelMedium?.copyWith(
                  color: context.textSecondaryColor,
                  fontSize: 14.sp,
                ),
              ),
              
              const Spacer(),
              
              if (_duas.any((d) => d.readCount > 0)) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 16.sp,
                  color: ThemeConstants.accent,
                ),
                SizedBox(width: 4.w),
                Text(
                  'مقروءة: ${_duas.where((d) => d.readCount > 0).length}',
                  style: context.labelMedium?.copyWith(
                    color: ThemeConstants.accent,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(16.w),
            physics: const BouncingScrollPhysics(),
            itemCount: _duas.length,
            itemBuilder: (context, index) {
              final dua = _duas[index];
              
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                child: DuaCardWidget(
                  dua: dua,
                  index: index,
                  fontSize: _fontSize,
                  onTap: () => _onDuaTap(dua),
                  onShare: () => _shareDua(dua),
                  onCopy: () => _copyDua(dua),
                ),
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
            'لا توجد أدعية',
            style: context.titleLarge?.copyWith(
              color: context.textSecondaryColor,
              fontWeight: ThemeConstants.bold,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'لا توجد أدعية في هذه الفئة حالياً',
            style: context.bodyMedium?.copyWith(
              color: context.textSecondaryColor.withValues(alpha: 0.7),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadDuas,
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

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: ThemeConstants.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.text_fields_rounded,
                color: ThemeConstants.primary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 8.w),
            const Text('حجم الخط'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFontSizeOption('صغير', 16.0),
            _buildFontSizeOption('متوسط', 18.0),
            _buildFontSizeOption('كبير', 22.0),
            _buildFontSizeOption('كبير جداً', 26.0),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(String label, double size) {
    final isSelected = _fontSize == size;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            setState(() => _fontSize = size);
            
            await _duaService.saveFontSize(size);
            
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isSelected 
                  ? ThemeConstants.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected 
                    ? ThemeConstants.primary.withValues(alpha: 0.3)
                    : context.dividerColor.withValues(alpha: 0.2),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: isSelected ? ThemeConstants.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? ThemeConstants.primary : context.textSecondaryColor,
                      width: 1.w,
                    ),
                  ),
                  child: isSelected 
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14.sp,
                        )
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    style: context.bodyLarge?.copyWith(
                      fontSize: size.sp,
                      fontWeight: isSelected ? ThemeConstants.semiBold : ThemeConstants.regular,
                      color: isSelected ? ThemeConstants.primary : context.textPrimaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: context.textSecondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    '${size.toInt()}',
                    style: context.labelSmall?.copyWith(
                      color: context.textSecondaryColor,
                      fontWeight: ThemeConstants.medium,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onDuaTap(Dua dua) {
    HapticFeedback.lightImpact();
    _duaService.markDuaAsRead(dua.id);
    
    setState(() {
      final index = _duas.indexWhere((d) => d.id == dua.id);
      if (index != -1) {
        _duas[index] = dua.copyWith(
          readCount: dua.readCount + 1,
          lastRead: DateTime.now(),
        );
      }
    });
  }

  void _shareDua(Dua dua) {
    HapticFeedback.lightImpact();
    
    final text = '''${dua.title}

${dua.arabicText}

${dua.source != null ? 'المصدر: ${dua.source}' : ''}
${dua.reference != null ? 'المرجع: ${dua.reference}' : ''}

من تطبيق أذكاري - الأدعية المأثورة''';
    
    Clipboard.setData(ClipboardData(text: text));
    context.showSuccessSnackBar('تم نسخ الدعاء للمشاركة');
  }

  void _copyDua(Dua dua) {
    HapticFeedback.lightImpact();
    
    Clipboard.setData(ClipboardData(text: dua.arabicText));
    context.showSuccessSnackBar('تم نسخ الدعاء');
  }
}