// lib/features/dua/screens/dua_list_screen.dart

import 'package:athkar_app/core/infrastructure/services/share/share_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
import '../../../core/infrastructure/services/text/extensions/text_settings_extensions.dart';
import '../../../core/infrastructure/services/text/models/text_settings_models.dart';
import '../services/dua_service.dart';
import '../models/dua_model.dart';
import '../widgets/dua_item_card.dart';
import 'dua_details_screen.dart';
import 'dua_search_screen.dart';

class DuaListScreen extends StatefulWidget {
  final DuaCategory category;
  
  const DuaListScreen({
    super.key,
    required this.category,
  });

  @override
  State<DuaListScreen> createState() => _DuaListScreenState();
}

class _DuaListScreenState extends State<DuaListScreen> {
  late final DuaService _service;
  
  List<DuaItem> _duas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = context.duaService;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final duas = await _service.getDuasByCategory(widget.category.id);
      
      if (mounted) {
        setState(() {
          _duas = duas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في تحميل الأدعية';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(DuaItem dua) async {
    final isFavorite = await _service.toggleFavorite(dua.id);
    
    setState(() {
      final index = _duas.indexWhere((d) => d.id == dua.id);
      if (index != -1) {
        _duas[index] = _duas[index].copyWith(isFavorite: isFavorite);
      }
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite ? 'تمت الإضافة للمفضلة' : 'تمت الإزالة من المفضلة',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: isFavorite ? ThemeConstants.success : null,
        ),
      );
    }
  }

  Future<void> _shareDua(DuaItem dua) async {
    final text = '''
${dua.arabicText}

${dua.title}
${dua.virtue != null ? '\nالفضيلة: ${dua.virtue}' : ''}
المصدر: ${dua.source} - ${dua.reference}

تطبيق الأذكار والأدعية
''';
    
    await Share.share(text);
  }

  void _copyDua(DuaItem dua) {
    context.copyDua(
      dua.title,
      dua.arabicText,
      transliteration: dua.transliteration,
      translation: dua.translation,
      virtue: dua.virtue,
      source: dua.source,
      reference: dua.reference,
    );
  }

  void _openDuaDetails(DuaItem dua) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DuaDetailsScreen(
          dua: dua,
          category: widget.category,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DuaSearchScreen(),
      ),
    );
  }

  void _openTextSettings() {
    HapticFeedback.lightImpact();
    context.showGlobalTextSettings(
      initialContentType: ContentType.dua,
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

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'book_quran':
        return Icons.menu_book;
      case 'book_hadith':
        return Icons.book;
      case 'book_sunnah':
        return Icons.auto_stories;
      case 'verified':
        return Icons.verified;
      default:
        return Icons.pan_tool_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.category.id);
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(categoryColor),
            Expanded(
              child: _buildContent(categoryColor),
            ),
          ],
        ),
      ),
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
      child: Column(
        children: [
          Row(
            children: [
              // زر الرجوع
              AppBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
              
              SizedBox(width: 10.w),
              
              // أيقونة الفئة
              Container(
                padding: EdgeInsets.all(7.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor,
                      categoryColor.withOpacity(0.8),
                    ],
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
                child: Icon(
                  _getCategoryIcon(widget.category.icon),
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              
              SizedBox(width: 10.w),
              
              // معلومات الفئة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.name,
                      style: TextStyle(
                        fontWeight: ThemeConstants.bold,
                        color: context.textPrimaryColor,
                        fontSize: 17.sp,
                      ),
                    ),
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
              
              // زر إعدادات النصوص
              _buildActionButton(
                icon: Icons.text_fields_rounded,
                onTap: _openTextSettings,
                color: ThemeConstants.info,
                tooltip: 'إعدادات النص',
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // شريط البحث
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        margin: EdgeInsets.only(left: 6.w),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: color != null 
                    ? color.withOpacity(0.1)
                    : context.cardColor,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: color != null 
                      ? color.withOpacity(0.3)
                      : context.dividerColor.withOpacity(0.3),
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _openSearch,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 12.h,
        ),
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
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: context.textSecondaryColor,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'ابحث في الأدعية...',
              style: TextStyle(
                color: context.textSecondaryColor.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color categoryColor) {
    if (_isLoading) {
      return Center(
        child: AppLoading.page(
          message: 'جاري تحميل الأدعية...',
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: AppEmptyState.error(
          message: _error!,
          onRetry: _loadData,
        ),
      );
    }

    if (_duas.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.search_off,
          message: 'لا توجد أدعية\nلا توجد أدعية في هذه الفئة',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: categoryColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _duas.length,
        itemBuilder: (context, index) {
          final dua = _duas[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: DuaItemCard(
              dua: dua,
              categoryColor: categoryColor,
              onTap: () => _openDuaDetails(dua),
              onFavorite: () => _toggleFavorite(dua),
              onShare: () => _shareDua(dua),
              onCopy: () => _copyDua(dua),
            ),
          );
        },
      ),
    );
  }
}