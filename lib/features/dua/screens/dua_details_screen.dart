// lib/features/dua/screens/dua_details_screen.dart - محسّن
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
  double _fontSize = 16.0;
  final ScrollController _scrollController = ScrollController();
  String? _errorMessage;

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
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final results = await Future.wait([
        _duaService.getDuasByCategory(widget.categoryId),
        _duaService.getSavedFontSize(),
      ]);
      
      _duas = results[0] as List<Dua>;
      _fontSize = results[1] as double;
      
      setState(() => _isLoading = false);
      
      debugPrint('✅ تم تحميل ${_duas.length} دعاء من ${widget.categoryName}');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في تحميل الأدعية';
      });
      
      debugPrint('❌ خطأ في تحميل الأدعية: $e');
      
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
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }
    
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    if (_duas.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildContent();
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
              Icons.menu_book_rounded,
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
                  widget.categoryName,
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 16.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!_isLoading)
                  Text(
                    '${_duas.length} دعاء',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11.sp,
                    ),
                  ),
              ],
            ),
          ),
          
          _buildActionButton(
            icon: Icons.text_fields_rounded,
            onTap: _showFontSizeDialog,
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
      margin: EdgeInsets.only(left: 6.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: context.dividerColor.withValues(alpha: 0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 3.r,
                  offset: Offset(0, 1.5.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isSecondary ? context.textSecondaryColor : ThemeConstants.primary,
              size: 20.sp,
            ),
          ),
        ),
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
            'جاري تحميل ${widget.categoryName}...',
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 50.sp,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'حدث خطأ',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontWeight: ThemeConstants.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              style: TextStyle(
                color: context.textSecondaryColor.withValues(alpha: 0.7),
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: _loadDuas,
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
            'لا توجد أدعية',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontWeight: ThemeConstants.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'لا توجد أدعية في هذه الفئة حالياً',
            style: TextStyle(
              color: context.textSecondaryColor.withValues(alpha: 0.7),
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: _loadDuas,
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

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Row(
            children: [
              Icon(
                Icons.format_list_numbered_rounded,
                size: 14.sp,
                color: context.textSecondaryColor,
              ),
              SizedBox(width: 4.w),
              Text(
                'عدد الأدعية: ${_duas.length}',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 12.sp,
                ),
              ),
              
              const Spacer(),
              
              if (_duas.any((d) => d.readCount > 0)) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 14.sp,
                  color: ThemeConstants.accent,
                ),
                SizedBox(width: 4.w),
                Text(
                  'مقروءة: ${_duas.where((d) => d.readCount > 0).length}',
                  style: TextStyle(
                    color: ThemeConstants.accent,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(12.r),
            physics: const BouncingScrollPhysics(),
            itemCount: _duas.length,
            itemBuilder: (context, index) {
              final dua = _duas[index];
              
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                child: DuaCardWidget(
                  dua: dua,
                  index: index,
                  fontSize: _fontSize,
                  onTap: () => _onDuaTap(dua, index),
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

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        contentPadding: EdgeInsets.all(16.r),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: ThemeConstants.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.text_fields_rounded,
                color: ThemeConstants.primary,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 6.w),
            Text('حجم الخط', style: TextStyle(fontSize: 16.sp)),
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
      margin: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            setState(() => _fontSize = size);
            
            await _duaService.saveFontSize(size);
            
            if (mounted) {
              Navigator.pop(context);
            }
          },
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isSelected 
                  ? ThemeConstants.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
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
                  width: 18.r,
                  height: 18.r,
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
                          size: 12.sp,
                        )
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: size.sp,
                      fontWeight: isSelected ? ThemeConstants.semiBold : ThemeConstants.regular,
                      color: isSelected ? ThemeConstants.primary : context.textPrimaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: context.textSecondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    '${size.toInt()}',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontWeight: ThemeConstants.medium,
                      fontSize: 10.sp,
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

  Future<void> _onDuaTap(Dua dua, int index) async {
    HapticFeedback.lightImpact();
    
    try {
      await _duaService.markDuaAsRead(dua.id);
      
      if (mounted) {
        setState(() {
          _duas[index] = dua.copyWith(
            readCount: dua.readCount + 1,
            lastRead: DateTime.now(),
          );
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل قراءة الدعاء: $e');
      
      if (mounted) {
        context.showErrorSnackBar('فشل تسجيل قراءة الدعاء');
      }
    }
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