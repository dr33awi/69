// lib/features/quran/screens/quran_bookmarks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/themes/app_theme.dart';
import '../services/quran_service.dart';
import 'quran_reader_screen.dart';

class QuranBookmarksScreen extends StatefulWidget {
  const QuranBookmarksScreen({super.key});

  @override
  State<QuranBookmarksScreen> createState() => _QuranBookmarksScreenState();
}

class _QuranBookmarksScreenState extends State<QuranBookmarksScreen> {
  late final QuranService _quranService;
  List<BookmarkData> _bookmarks = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _quranService = getIt<QuranService>();
    _loadBookmarks();
  }
  
  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    
    try {
      final bookmarks = await _quranService.getBookmarks();
      
      if (mounted) {
        setState(() {
          _bookmarks = bookmarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل الإشارات المرجعية: $e');
      if (mounted) {
        setState(() {
          _bookmarks = [];
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.background(context),
      appBar: AppBar(
        title: const Text('الإشارات المرجعية'),
        backgroundColor: ThemeConstants.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_bookmarks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _showClearAllDialog,
              tooltip: 'حذف الكل',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _bookmarks.isEmpty
              ? _buildEmptyState(context)
              : _buildBookmarksList(context),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: ThemeConstants.primary,
            strokeWidth: 3.w,
          ),
          SizedBox(height: 16.h),
          Text(
            'جارٍ تحميل الإشارات المرجعية...',
            style: AppTextStyles.body2.copyWith(
              color: ThemeConstants.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140.w,
              height: 140.w,
              decoration: BoxDecoration(
                gradient: ThemeConstants.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: ThemeConstants.shadowLg,
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 70.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'لا توجد إشارات مرجعية',
              style: AppTextStyles.h4.copyWith(
                color: ThemeConstants.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'يمكنك إضافة إشارات مرجعية للآيات\nمن شاشة القراءة',
              style: AppTextStyles.body2.copyWith(
                color: ThemeConstants.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.menu_book),
              label: const Text('ابدأ القراءة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBookmarksList(BuildContext context) {
    return Column(
      children: [
        // إحصائيات
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ThemeConstants.primary.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: ThemeConstants.divider(context),
                width: 1.w,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.bookmarks,
                color: ThemeConstants.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'لديك ${_bookmarks.length} إشارة مرجعية',
                style: AppTextStyles.body2.copyWith(
                  color: ThemeConstants.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        // القائمة
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: _bookmarks.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final bookmark = _bookmarks[index];
              return _buildBookmarkCard(context, bookmark, index);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildBookmarkCard(BuildContext context, BookmarkData bookmark, int index) {
    return Dismissible(
      key: Key('${bookmark.surahNumber}-${bookmark.verseNumber}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.w),
        decoration: BoxDecoration(
          color: ThemeConstants.error,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: 28.sp,
        ),
      ),
      confirmDismiss: (direction) => _confirmDelete(bookmark),
      onDismissed: (direction) => _deleteBookmark(bookmark),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeConstants.card(context),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: ThemeConstants.shadowSm,
          border: Border.all(
            color: ThemeConstants.primary.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToVerse(bookmark),
            onLongPress: () => _showBookmarkOptions(context, bookmark),
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // أيقونة الإشارة المرجعية
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      gradient: ThemeConstants.primaryGradient,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.bookmark,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                  
                  SizedBox(width: 16.w),
                  
                  // معلومات الإشارة
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookmark.surahName,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ThemeConstants.textPrimary(context),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeConstants.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'الآية ${bookmark.verseNumber}',
                                style: AppTextStyles.caption.copyWith(
                                  color: ThemeConstants.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _formatDate(bookmark.addedAt),
                              style: AppTextStyles.caption.copyWith(
                                color: ThemeConstants.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                        if (bookmark.note != null && bookmark.note!.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: ThemeConstants.surface(context),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              bookmark.note!,
                              style: AppTextStyles.body2.copyWith(
                                color: ThemeConstants.textSecondary(context),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  // زر الخيارات
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: ThemeConstants.textSecondary(context),
                      size: 24.sp,
                    ),
                    onPressed: () => _showBookmarkOptions(context, bookmark),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      return 'منذ ${(difference.inDays / 7).floor()} أسابيع';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _navigateToVerse(BookmarkData bookmark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranReaderScreen(
          surahNumber: bookmark.surahNumber,
          initialAyah: bookmark.verseNumber,
        ),
      ),
    );
  }
  
  void _showBookmarkOptions(BuildContext context, BookmarkData bookmark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeConstants.card(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: ThemeConstants.divider(context),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.surahName,
                      style: AppTextStyles.h5.copyWith(
                        color: ThemeConstants.textPrimary(context),
                      ),
                    ),
                    Text(
                      'الآية ${bookmark.verseNumber}',
                      style: AppTextStyles.body2.copyWith(
                        color: ThemeConstants.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16.h),
              Divider(height: 1.h),
              
              _buildOptionTile(
                context,
                icon: Icons.open_in_new,
                title: 'فتح في القارئ',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToVerse(bookmark);
                },
              ),
              
              _buildOptionTile(
                context,
                icon: Icons.copy,
                title: 'نسخ معلومات الإشارة',
                onTap: () {
                  _copyBookmarkInfo(bookmark);
                  Navigator.pop(context);
                },
              ),
              
              _buildOptionTile(
                context,
                icon: Icons.share,
                title: 'مشاركة',
                onTap: () {
                  _shareBookmark(bookmark);
                  Navigator.pop(context);
                },
              ),
              
              Divider(height: 1.h),
              
              _buildOptionTile(
                context,
                icon: Icons.delete,
                title: 'حذف الإشارة المرجعية',
                color: ThemeConstants.error,
                onTap: () {
                  Navigator.pop(context);
                  _confirmAndDeleteBookmark(bookmark);
                },
              ),
              
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? ThemeConstants.primary;
    
    return ListTile(
      leading: Icon(
        icon,
        color: effectiveColor,
        size: 24.sp,
      ),
      title: Text(
        title,
        style: AppTextStyles.body1.copyWith(
          color: color ?? ThemeConstants.textPrimary(context),
        ),
      ),
      onTap: onTap,
    );
  }
  
  void _copyBookmarkInfo(BookmarkData bookmark) {
    final text = '${bookmark.surahName} - الآية ${bookmark.verseNumber}';
    Clipboard.setData(ClipboardData(text: text));
    _showSuccessSnackBar('تم نسخ المعلومات');
  }
  
  void _shareBookmark(BookmarkData bookmark) async {
    try {
      final verseText = _quranService.getVerseText(
        bookmark.surahNumber,
        bookmark.verseNumber,
      );
      
      final text = '$verseText\n\n'
          '(${bookmark.surahName} - الآية ${bookmark.verseNumber})';
      
      await Share.share(text);
    } catch (e) {
      debugPrint('خطأ في المشاركة: $e');
      _showErrorSnackBar('حدث خطأ أثناء المشاركة');
    }
  }
  
  Future<bool> _confirmDelete(BookmarkData bookmark) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإشارة المرجعية'),
        content: Text(
          'هل تريد حذف الإشارة المرجعية من ${bookmark.surahName}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: ThemeConstants.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  void _confirmAndDeleteBookmark(BookmarkData bookmark) async {
    final confirmed = await _confirmDelete(bookmark);
    if (confirmed) {
      _deleteBookmark(bookmark);
    }
  }
  
  Future<void> _deleteBookmark(BookmarkData bookmark) async {
    try {
      await _quranService.removeBookmark(
        bookmark.surahNumber,
        bookmark.verseNumber,
      );
      
      await _loadBookmarks();
      
      if (mounted) {
        _showSuccessSnackBar('تم حذف الإشارة المرجعية');
      }
    } catch (e) {
      debugPrint('خطأ في حذف الإشارة المرجعية: $e');
      if (mounted) {
        _showErrorSnackBar('حدث خطأ أثناء الحذف');
      }
    }
  }
  
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جميع الإشارات المرجعية'),
        content: const Text(
          'هل أنت متأكد من حذف جميع الإشارات المرجعية؟\nلا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllBookmarks();
            },
            style: TextButton.styleFrom(
              foregroundColor: ThemeConstants.error,
            ),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _clearAllBookmarks() async {
    try {
      for (final bookmark in _bookmarks) {
        await _quranService.removeBookmark(
          bookmark.surahNumber,
          bookmark.verseNumber,
        );
      }
      
      await _loadBookmarks();
      
      if (mounted) {
        _showSuccessSnackBar('تم حذف جميع الإشارات المرجعية');
      }
    } catch (e) {
      debugPrint('خطأ في حذف جميع الإشارات المرجعية: $e');
      if (mounted) {
        _showErrorSnackBar('حدث خطأ أثناء الحذف');
      }
    }
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Text(message),
          ],
        ),
        backgroundColor: ThemeConstants.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Text(message),
          ],
        ),
        backgroundColor: ThemeConstants.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }
}