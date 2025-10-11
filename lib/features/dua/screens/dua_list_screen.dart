// lib/features/dua/screens/dua_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/themes/app_theme.dart';
import '../../../app/di/service_locator.dart';
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
  double _fontSize = 18.0;

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
      _fontSize = await _service.getSavedFontSize();
      
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

  Future<void> _shareDua(DuaItem dua) async {
    final text = '''
${dua.arabicText}

${dua.title}
${dua.virtue != null ? '\nالفضل: ${dua.virtue}' : ''}
المصدر: ${dua.source} - ${dua.reference}

تطبيق الأذكار والأدعية
''';
    
    await Share.share(text);
  }

  void _copyDua(DuaItem dua) {
    Clipboard.setData(ClipboardData(text: dua.arabicText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الدعاء'),
        duration: Duration(seconds: 2),
      ),
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

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.category.id);
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _buildContent(categoryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
          
          // زر البحث
          Container(
            margin: EdgeInsets.only(left: 6.w),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
              child: InkWell(
                onTap: _openSearch,
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.all(7.r),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: context.dividerColor.withOpacity(0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: context.textPrimaryColor,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
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

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _duas.length,
      itemBuilder: (context, index) {
        final dua = _duas[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: DuaItemCard(
            dua: dua,
            fontSize: _fontSize,
            categoryColor: categoryColor,
            onTap: () => _openDuaDetails(dua),
            onFavorite: () => _toggleFavorite(dua),
            onShare: () => _shareDua(dua),
            onCopy: () => _copyDua(dua),
          ),
        );
      },
    );
  }
}