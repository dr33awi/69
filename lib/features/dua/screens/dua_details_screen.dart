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
  
  late DuaItem _dua;
  double _fontSize = 18.0;
  bool _showTransliteration = true;
  bool _showTranslation = true;
  
  // للتنقل بين الأدعية
  List<DuaItem> _categoryDuas = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _service = context.duaService;
    _dua = widget.dua;
    
    _initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initialize() async {
    // تحديد كمقروء
    await _service.markAsRead(_dua.id);
    
    // حفظ آخر دعاء تم عرضه
    await _service.saveLastViewed(_dua.id, widget.category.id);
    
    // تحميل حجم الخط
    _fontSize = await _service.getSavedFontSize();
    
    // تحميل جميع أدعية الفئة للتنقل
    _categoryDuas = await _service.getDuasByCategory(widget.category.id);
    _currentIndex = _categoryDuas.indexWhere((d) => d.id == _dua.id);
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleFavorite() async {
    final isFavorite = await _service.toggleFavorite(_dua.id);
    
    setState(() {
      _dua = _dua.copyWith(isFavorite: isFavorite);
      
      // تحديث في القائمة أيضاً
      if (_currentIndex >= 0 && _currentIndex < _categoryDuas.length) {
        _categoryDuas[_currentIndex] = _dua;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite ? 'تمت الإضافة للمفضلة' : 'تمت الإزالة من المفضلة',
        ),
        backgroundColor: isFavorite ? ThemeConstants.success : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareDua() async {
    final text = '''
${_dua.arabicText}

${_dua.title}
${_dua.virtue != null ? '\nالفضل: ${_dua.virtue}' : ''}
المصدر: ${_dua.source} - ${_dua.reference}

تطبيق الأذكار والأدعية
''';
    
    await Share.share(text);
  }

  void _copyDua() {
    Clipboard.setData(ClipboardData(text: _dua.arabicText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الدعاء'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _previousDua() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _dua = _categoryDuas[_currentIndex];
      });
      
      // تحديد كمقروء
      _service.markAsRead(_dua.id);
      _service.saveLastViewed(_dua.id, widget.category.id);
    }
  }

  void _nextDua() {
    if (_currentIndex < _categoryDuas.length - 1) {
      setState(() {
        _currentIndex++;
        _dua = _categoryDuas[_currentIndex];
      });
      
      // تحديد كمقروء
      _service.markAsRead(_dua.id);
      _service.saveLastViewed(_dua.id, widget.category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duaType = DuaType.fromValue(_dua.type);
    final categoryColor = _getCategoryColor(widget.category.id);
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(categoryColor),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // معلومات الدعاء
                    _buildDuaInfo(duaType),
                    
                    SizedBox(height: 20.h),
                    
                    // نص الدعاء العربي
                    _buildArabicText(),
                    
                    // النطق اللاتيني
                    if (_dua.transliteration != null && _showTransliteration) ...[
                      SizedBox(height: 16.h),
                      _buildTransliteration(),
                    ],
                    
                    // الترجمة
                    if (_dua.translation != null && _showTranslation) ...[
                      SizedBox(height: 16.h),
                      _buildTranslation(),
                    ],
                    
                    // الفضل
                    if (_dua.virtue != null) ...[
                      SizedBox(height: 16.h),
                      _buildVirtue(),
                    ],
                    
                    // المصدر
                    SizedBox(height: 16.h),
                    _buildSource(),
                    
                    // التصنيفات
                    if (_dua.tags.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      _buildTags(),
                    ],
                    
                    SizedBox(height: 80.h), // مساحة للأزرار السفلية
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // الأزرار السفلية
      bottomNavigationBar: _buildBottomBar(categoryColor),
    );
  }

  Widget _buildAppBar(Color categoryColor) {
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
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dua.title,
                  style: TextStyle(
                    fontWeight: ThemeConstants.bold,
                    color: context.textPrimaryColor,
                    fontSize: 16.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.category.name} • ${_currentIndex + 1}/${_categoryDuas.length}',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          
          // زر المفضلة
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _dua.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
              color: _dua.isFavorite ? ThemeConstants.accent : context.textSecondaryColor,
              size: 24.sp,
            ),
          ),
          
          // زر الإعدادات
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: context.textSecondaryColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copyDua();
                  break;
                case 'share':
                  _shareDua();
                  break;
                case 'font':
                  _showFontSizeDialog();
                  break;
                case 'display':
                  _showDisplaySettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20.sp),
                    SizedBox(width: 8.w),
                    const Text('نسخ الدعاء'),
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
              PopupMenuItem(
                value: 'display',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 20.sp),
                    SizedBox(width: 8.w),
                    const Text('إعدادات العرض'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDuaInfo(DuaType duaType) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            duaType.color.withOpacity(0.1),
            duaType.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: duaType.color.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: duaType.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              duaType.icon,
              color: duaType.color,
              size: 24.sp,
            ),
          ),
          
          SizedBox(width: 12.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dua.title,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontWeight: ThemeConstants.bold,
                    fontSize: 16.sp,
                  ),
                ),
                
                SizedBox(height: 4.h),
                
                Text(
                  duaType.arabicName,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicText() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.black.withOpacity(0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: SelectableText(
        _dua.arabicText,
        style: TextStyle(
          fontSize: _fontSize.sp,
          fontFamily: ThemeConstants.fontFamilyArabic,
          height: 2.0,
          color: context.textPrimaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTransliteration() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ThemeConstants.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ThemeConstants.info.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'النطق اللاتيني',
            style: TextStyle(
              color: ThemeConstants.info,
              fontWeight: ThemeConstants.semiBold,
              fontSize: 14.sp,
            ),
          ),
          
          SizedBox(height: 10.h),
          
          SelectableText(
            _dua.transliteration!,
            style: TextStyle(
              fontSize: (_fontSize - 2).sp,
              color: context.textPrimaryColor,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildTranslation() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ThemeConstants.primaryLight.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ThemeConstants.primaryLight.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المعنى',
            style: TextStyle(
              color: ThemeConstants.primaryLight,
              fontWeight: ThemeConstants.semiBold,
              fontSize: 14.sp,
            ),
          ),
          
          SizedBox(height: 10.h),
          
          SelectableText(
            _dua.translation!,
            style: TextStyle(
              fontSize: (_fontSize - 2).sp,
              color: context.textPrimaryColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtue() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConstants.success.withOpacity(0.08),
            ThemeConstants.success.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ThemeConstants.success.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: ThemeConstants.success,
                size: 20.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'الفضل',
                style: TextStyle(
                  color: ThemeConstants.success,
                  fontWeight: ThemeConstants.semiBold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 10.h),
          
          Text(
            _dua.virtue!,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textPrimaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSource() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: context.dividerColor.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book,
            color: context.textSecondaryColor,
            size: 20.sp,
          ),
          
          SizedBox(width: 10.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المصدر',
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                ),
                Text(
                  '${_dua.source} - ${_dua.reference}',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontWeight: ThemeConstants.medium,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _dua.tags.map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 6.h,
          ),
          decoration: BoxDecoration(
            color: ThemeConstants.tertiary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: ThemeConstants.tertiary.withOpacity(0.3),
              width: 1.w,
            ),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 12.sp,
              color: ThemeConstants.tertiary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(Color categoryColor) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // السابق
          IconButton(
            onPressed: _currentIndex > 0 ? _previousDua : null,
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: _currentIndex > 0 
                  ? categoryColor 
                  : context.textSecondaryColor.withOpacity(0.3),
            ),
          ),
          
          // نسخ
          IconButton(
            onPressed: _copyDua,
            icon: Icon(
              Icons.copy_rounded,
              color: context.textSecondaryColor,
            ),
          ),
          
          // مشاركة
          Container(
            decoration: BoxDecoration(
              color: categoryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _shareDua,
              icon: const Icon(
                Icons.share_rounded,
                color: Colors.white,
              ),
            ),
          ),
          
          // المفضلة
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _dua.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
              color: _dua.isFavorite 
                  ? ThemeConstants.accent 
                  : context.textSecondaryColor,
            ),
          ),
          
          // التالي
          IconButton(
            onPressed: _currentIndex < _categoryDuas.length - 1 ? _nextDua : null,
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: _currentIndex < _categoryDuas.length - 1 
                  ? categoryColor 
                  : context.textSecondaryColor.withOpacity(0.3),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text('حجم الخط'),
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
    
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: size.sp,
          fontWeight: isSelected ? ThemeConstants.semiBold : null,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: ThemeConstants.tertiary,
            )
          : null,
      onTap: () async {
        setState(() => _fontSize = size);
        await _service.saveFontSize(size);
        Navigator.pop(context);
      },
    );
  }

  void _showDisplaySettings() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: ThemeConstants.tertiary,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'إعدادات العرض',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: ThemeConstants.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  SwitchListTile(
                    title: const Text('النطق اللاتيني'),
                    subtitle: const Text('عرض النطق بالأحرف اللاتينية'),
                    value: _showTransliteration,
                    onChanged: _dua.transliteration != null 
                        ? (value) {
                            setState(() {
                              _showTransliteration = value;
                            });
                            this.setState(() {});
                          }
                        : null,
                    activeColor: ThemeConstants.tertiary,
                  ),
                  
                  SwitchListTile(
                    title: const Text('المعنى'),
                    subtitle: const Text('عرض معنى الدعاء'),
                    value: _showTranslation,
                    onChanged: _dua.translation != null
                        ? (value) {
                            setState(() {
                              _showTranslation = value;
                            });
                            this.setState(() {});
                          }
                        : null,
                    activeColor: ThemeConstants.tertiary,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return ThemeConstants.primary;
      case 'sahihain':
        return ThemeConstants.accent;
      case 'sunan':
        return ThemeConstants.tertiary;
      case 'other_authentic':
        return ThemeConstants.primaryDark;
      default:
        return ThemeConstants.tertiary;
    }
  }
}