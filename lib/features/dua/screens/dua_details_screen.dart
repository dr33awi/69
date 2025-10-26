// lib/features/dua/screens/dua_details_screen.dart

import 'package:athkar_app/core/infrastructure/services/share/share_extensions.dart';
import 'package:athkar_app/core/infrastructure/services/text_settings/extensions/text_settings_extensions.dart';
import 'package:athkar_app/core/infrastructure/services/text_settings/models/text_settings_models.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/models/favorite_models.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/extensions/favorites_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  
  // إعدادات النص الموحدة
  TextSettings? _textSettings;
  DisplaySettings? _displaySettings;

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
    
    // تحميل الإعدادات الموحدة للدعاء
    await _loadTextSettings();
    
    await _service.markAsRead(_currentDua.id);
    await _service.saveLastViewed(_currentDua.id, widget.category.id);
    
    if (mounted) setState(() {});
  }

  Future<void> _loadTextSettings() async {
    _textSettings = await context.getTextSettings(ContentType.dua);
    _displaySettings = await context.getDisplaySettings(ContentType.dua);
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
    context.copyDua(
      _currentDua.title,
      _currentDua.arabicText,
      transliteration: _currentDua.transliteration,
      translation: _currentDua.translation,
      virtue: _currentDua.virtue,
      source: _currentDua.source,
      reference: _currentDua.reference,
    );
  }

  void _shareDua() {
    context.shareDua(
      _currentDua.title,
      _currentDua.arabicText,
      transliteration: _currentDua.transliteration,
      translation: _currentDua.translation,
      virtue: _currentDua.virtue,
      source: _currentDua.source,
      reference: _currentDua.reference,
    );
    
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
      padding: EdgeInsets.all(14.r),
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
      child: Row(
        children: [
          AppBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: 10.w),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [categoryColor, categoryColor.withOpacity(0.8)],
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
            child: Text(
              '${_currentIndex + 1}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: ThemeConstants.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          
          SizedBox(width: 10.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentDua.title,
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.category.name,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
          
          // زر إعدادات النصوص
          _buildActionButton(
            icon: Icons.text_fields_rounded,
            color: ThemeConstants.info,
            onTap: () async {
              HapticFeedback.lightImpact();
              await context.showGlobalTextSettings(
                initialContentType: ContentType.dua,
              );
              await _loadTextSettings();
              setState(() {});
            },
          ),
          
          // زر النسخ
          _buildActionButton(
            icon: Icons.copy_rounded,
            color: context.textSecondaryColor,
            onTap: _copyDua,
          ),
          
          // زر المفضلة
          _buildActionButton(
            icon: _currentDua.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
            color: context.textSecondaryColor,
            onTap: _toggleFavorite,
          ),
          
          // زر المشاركة
          _buildActionButton(
            icon: Icons.share_rounded,
            color: context.textSecondaryColor,
            onTap: _shareDua,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 2.w),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
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

  Widget _buildContentPage(DuaItem dua, Color categoryColor) {
    final showTashkeel = _displaySettings?.showTashkeel ?? true;
    final textStyle = _textSettings?.toTextStyle() ?? TextStyle(
      fontSize: 20.sp,
      fontFamily: ThemeConstants.fontFamilyArabic,
      height: 2.2,
    );
    
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
            child: AdaptiveText(
              showTashkeel ? dua.arabicText : dua.arabicText.removeTashkeel(),
              contentType: ContentType.dua,
              color: context.textPrimaryColor,
              fontWeight: ThemeConstants.medium,
              textAlign: TextAlign.center,
              applyDisplaySettings: false, // نطبق الإعدادات يدوياً
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // النطق اللاتيني
          if ((_displaySettings?.showTransliteration ?? false) && dua.transliteration != null) ...[
            _buildSectionTitle(
              'النطق اللاتيني',
              Icons.translate_rounded,
              ThemeConstants.info,
            ),
            SizedBox(height: 12.h),
            Text(
              dua.transliteration!,
              style: TextStyle(
                fontSize: ((_textSettings?.fontSize ?? 20) - 3).sp,
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
          if ((_displaySettings?.showTranslation ?? false) && dua.translation != null) ...[
            _buildSectionTitle(
              'المعنى',
              Icons.description_outlined,
              ThemeConstants.primaryLight,
            ),
            SizedBox(height: 12.h),
            Text(
              dua.translation!,
              style: TextStyle(
                fontSize: ((_textSettings?.fontSize ?? 20) - 3).sp,
                color: context.textPrimaryColor,
                height: 2.0,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 24.h),
          ],
          
          // الفضيلة
          if ((_displaySettings?.showFadl ?? true) && dua.virtue != null) ...[
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
                  fontSize: ((_textSettings?.fontSize ?? 20) - 4).sp,
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
          if (_displaySettings?.showSource ?? true) ...[
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
          ],
          
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
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
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
            ),
          ),
        ],
      ),
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