// lib/features/dua/screens/dua_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../services/dua_service.dart';
import '../models/dua_model.dart';

class DuaDetailsScreen extends StatefulWidget {
  final DuaItem dua;
  final DuaCategory category;
  
  const DuaDetailsScreen({
    super.key,
    required this.dua,
    required this.category,
  });

  @override
  State<DuaDetailsScreen> createState() => _DuaDetailsScreenState();
}

class _DuaDetailsScreenState extends State<DuaDetailsScreen> {
  late final DuaService _service;
  late PageController _pageController;
  
  late DuaItem _currentDua;
  List<DuaItem> _categoryDuas = [];
  int _currentIndex = 0;
  
  double _fontSize = 20.0;

  @override
  void initState() {
    super.initState();
    _service = context.duaService;
    _currentDua = widget.dua;
    _initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _categoryDuas = await _service.getDuasByCategory(widget.category.id);
    _currentIndex = _categoryDuas.indexWhere((d) => d.id == _currentDua.id);
    if (_currentIndex < 0) _currentIndex = 0;
    
    _pageController = PageController(initialPage: _currentIndex);
    _fontSize = await _service.getSavedFontSize();
    
    await _service.markAsRead(_currentDua.id);
    await _service.saveLastViewed(_currentDua.id, widget.category.id);
    
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite() async {
    final isFavorite = await _service.toggleFavorite(_currentDua.id);
    
    setState(() {
      _currentDua = _currentDua.copyWith(isFavorite: isFavorite);
      if (_currentIndex >= 0 && _currentIndex < _categoryDuas.length) {
        _categoryDuas[_currentIndex] = _currentDua;
      }
    });
    
    context.showSuccessSnackBar(
      isFavorite ? 'تمت الإضافة للمفضلة' : 'تمت الإزالة من المفضلة',
    );
  }

  void _copyDua() {
    final text = '''${_currentDua.arabicText}

${_currentDua.title}
${_currentDua.virtue != null ? '\nالفضل: ${_currentDua.virtue}' : ''}
المصدر: ${_currentDua.source} - ${_currentDua.reference}

من تطبيق أذكاري''';
    
    Clipboard.setData(ClipboardData(text: text));
    context.showSuccessSnackBar('تم نسخ الدعاء بنجاح');
    HapticFeedback.mediumImpact();
  }

  void _shareDua() {
    final text = '''${_currentDua.arabicText}

${_currentDua.title}
${_currentDua.virtue != null ? '\nالفضل: ${_currentDua.virtue}' : ''}
المصدر: ${_currentDua.source} - ${_currentDua.reference}

من تطبيق أذكاري''';
    
    Share.share(text, subject: 'دعاء - ${_currentDua.title}');
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.category.id);
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildEnhancedAppBar(categoryColor),
            
            Expanded(
              child: _categoryDuas.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categoryDuas.length,
                      onPageChanged: (index) async {
                        setState(() {
                          _currentIndex = index;
                          _currentDua = _categoryDuas[index];
                        });
                        
                        await _service.markAsRead(_currentDua.id);
                        await _service.saveLastViewed(_currentDua.id, widget.category.id);
                        HapticFeedback.selectionClick();
                      },
                      itemBuilder: (_, index) {
                        final dua = _categoryDuas[index];
                        return _buildContentPage(dua, categoryColor);
                      },
                    ),
            ),
            
            _buildBottomNavigationBar(categoryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedAppBar(Color categoryColor) {
    return Container(
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          AppBackButton(onPressed: () => Navigator.of(context).pop()),
          SizedBox(width: 8.w),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [categoryColor, categoryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.3),
                  blurRadius: 6.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: Text(
              '${_currentIndex + 1}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: ThemeConstants.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          
          SizedBox(width: 8.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentDua.title,
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: categoryColor,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.category.name}',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          
          _buildActionButton(
            icon: _currentDua.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
            onTap: _toggleFavorite,
            color: _currentDua.isFavorite ? ThemeConstants.accent : null,
          ),
          
          PopupMenuButton<String>(
            icon: _buildActionIcon(Icons.more_vert),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            onSelected: (value) {
              switch (value) {
                case 'copy': _copyDua(); break;
                case 'share': _shareDua(); break;
                case 'font': _showFontSizeDialog(); break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20.sp),
                    SizedBox(width: 8.w),
                    const Text('نسخ'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20.sp),
                    SizedBox(width: 8.w),
                    const Text('مشاركة'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'font',
                child: Row(
                  children: [
                    Icon(Icons.text_fields, size: 20.sp),
                    SizedBox(width: 8.w),
                    const Text('حجم الخط'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
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
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: context.dividerColor.withOpacity(0.3),
                width: 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color ?? context.textPrimaryColor,
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: context.textSecondaryColor,
        size: 20.sp,
      ),
    );
  }

  Widget _buildContentPage(DuaItem dua, Color categoryColor) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // النص العربي - بارز وواضح
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withOpacity(0.08),
                  categoryColor.withOpacity(0.03),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: categoryColor.withOpacity(0.2),
                width: 1.5.w,
              ),
            ),
            child: Text(
              dua.arabicText,
              style: TextStyle(
                fontSize: _fontSize.sp,
                fontFamily: ThemeConstants.fontFamilyArabic,
                height: 2.2,
                color: context.textPrimaryColor,
                fontWeight: ThemeConstants.medium,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // النطق اللاتيني
          if (dua.transliteration != null) ...[
            _buildSectionTitle(
              'النطق اللاتيني',
              Icons.translate_rounded,
              ThemeConstants.info,
            ),
            SizedBox(height: 12.h),
            Text(
              dua.transliteration!,
              style: TextStyle(
                fontSize: (_fontSize - 3).sp,
                color: context.textPrimaryColor.withOpacity(0.9),
                height: 2.0,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 24.h),
          ],
          
          // الترجمة/المعنى
          if (dua.translation != null) ...[
            _buildSectionTitle(
              'المعنى',
              Icons.description_outlined,
              ThemeConstants.primaryLight,
            ),
            SizedBox(height: 12.h),
            Text(
              dua.translation!,
              style: TextStyle(
                fontSize: (_fontSize - 3).sp,
                color: context.textPrimaryColor,
                height: 2.0,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 24.h),
          ],
          
          // الفضل
          if (dua.virtue != null) ...[
            _buildSectionTitle(
              'الفضيلة',
              Icons.star_rounded,
              ThemeConstants.success,
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ThemeConstants.success.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: ThemeConstants.success.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
              child: Text(
                dua.virtue!,
                style: TextStyle(
                  fontSize: (_fontSize - 4).sp,
                  color: context.textPrimaryColor,
                  height: 1.9,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            SizedBox(height: 24.h),
          ],
          
          // المصدر
          _buildSectionTitle(
            'المصدر',
            Icons.menu_book_rounded,
            context.textSecondaryColor,
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: context.dividerColor.withOpacity(0.3),
                width: 1.w,
              ),
            ),
            child: Text(
              '${dua.source} - ${dua.reference}',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontWeight: ThemeConstants.medium,
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
          ),
          

          
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: ThemeConstants.bold,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Container(
            height: 1.5.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(Color categoryColor) {
    final canPrev = _currentIndex > 0;
    final canNext = _currentIndex < _categoryDuas.length - 1;
    
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          top: BorderSide(
            color: context.dividerColor.withOpacity(0.2),
            width: 1.h,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canPrev ? () => _pageController.previousPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
              ) : null,
              label: Text('السابق', style: TextStyle(fontSize: 12.sp)),
              icon: Icon(Icons.chevron_left_rounded, size: 20.sp),
              style: ElevatedButton.styleFrom(
                backgroundColor: canPrev ? categoryColor : context.surfaceColor.withOpacity(0.5),
                foregroundColor: canPrev ? Colors.white : context.textSecondaryColor.withOpacity(0.5),
                elevation: canPrev ? 2 : 0,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                shadowColor: canPrev ? categoryColor.withOpacity(0.3) : null,
              ),
            ),
          ),
          
          SizedBox(width: 10.w),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(color: categoryColor.withOpacity(0.3), width: 1.w),
            ),
            child: Text(
              '${_currentIndex + 1} / ${_categoryDuas.length}',
              style: TextStyle(
                color: categoryColor,
                fontWeight: ThemeConstants.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
          
          SizedBox(width: 10.w),
          
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canNext ? () => _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
              ) : null,
              icon: Icon(Icons.chevron_right_rounded, size: 20.sp),
              label: Text('التالي', style: TextStyle(fontSize: 12.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: canNext ? context.surfaceColor : context.surfaceColor.withOpacity(0.5),
                foregroundColor: canNext ? context.textPrimaryColor : context.textSecondaryColor.withOpacity(0.5),
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('حجم الخط'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFontSizeOption('صغير', 16.0),
            _buildFontSizeOption('متوسط', 20.0),
            _buildFontSizeOption('كبير', 24.0),
            _buildFontSizeOption('كبير جداً', 28.0),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(String label, double size) {
    final isSelected = _fontSize == size;
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: size.sp, fontWeight: isSelected ? ThemeConstants.semiBold : null)),
      trailing: isSelected ? Icon(Icons.check_circle, color: ThemeConstants.tertiary) : null,
      onTap: () async {
        setState(() => _fontSize = size);
        await _service.saveFontSize(size);
        Navigator.pop(context);
      },
    );
  }


  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'quran': return ThemeConstants.primary;
      case 'sahihain': return ThemeConstants.accent;
      case 'sunan': return ThemeConstants.tertiary;
      case 'other_authentic': return ThemeConstants.primaryDark;
      default: return ThemeConstants.tertiary;
    }
  }
}