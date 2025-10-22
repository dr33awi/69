// lib/core/infrastructure/services/favorites/examples/favorites_usage_examples.dart
// أمثلة شاملة لاستخدام نظام المفضلة الموحد

import 'package:flutter/material.dart';
import '../models/favorite_models.dart';
import '../extensions/favorites_extensions.dart';

/// مجموعة أمثلة لاستخدام نظام المفضلة الموحد
class FavoritesUsageExamples {
  // منع إنشاء كائن من هذا الكلاس
  FavoritesUsageExamples._();

  // ==================== أمثلة الأدعية ====================

  /// مثال: إضافة دعاء للمفضلة
  static Future<void> exampleAddDuaToFavorites(BuildContext context) async {
    // البيانات المطلوبة لإضافة دعاء
    const duaId = 'dua_morning_001';
    const title = 'دعاء الصباح';
    const arabicText = 'اللهم أعني على ذكرك وشكرك وحسن عبادتك';
    const translation = 'اللهم أعني على ذكرك وشكرك وحسن عبادتك';
    const virtue = 'من قالها كتب الله له بها حسنات وأجر عظيم';
    const source = 'صحيح البخاري';
    const reference = 'رقم الحديث: 1234';
    const categoryId = 'morning_duas';

    // إضافة الدعاء للمفضلة باستخدام Extension
    final success = await context.addDuaToFavorites(
      duaId: duaId,
      title: title,
      arabicText: arabicText,
      translation: translation,
      virtue: virtue,
      source: source,
      reference: reference,
      categoryId: categoryId,
    );

    if (success) {
      print('✅ تم إضافة الدعاء للمفضلة بنجاح');
    } else {
      print('❌ فشل في إضافة الدعاء للمفضلة');
    }
  }

  /// مثال: إزالة دعاء من المفضلة
  static Future<void> exampleRemoveDuaFromFavorites(BuildContext context) async {
    const duaId = 'dua_morning_001';
    
    final success = await context.removeDuaFromFavorites(duaId);
    
    if (success) {
      print('✅ تم حذف الدعاء من المفضلة');
    } else {
      print('❌ لم يتم العثور على الدعاء في المفضلة');
    }
  }

  // ==================== أمثلة الأذكار ====================

  /// مثال: إضافة ذكر للمفضلة
  static Future<void> exampleAddAthkarToFavorites(BuildContext context) async {
    const athkarId = 'athkar_evening_002';
    const text = 'سبحان الله وبحمده، سبحان الله العظيم';
    const fadl = 'من قالها مائة مرة غفرت ذنوبه وإن كانت مثل زبد البحر';
    const source = 'صحيح مسلم';
    const categoryId = 'evening_athkar';
    const count = 100;

    final success = await context.addAthkarToFavorites(
      athkarId: athkarId,
      text: text,
      fadl: fadl,
      source: source,
      categoryId: categoryId,
      count: count,
    );

    if (success) {
      print('✅ تم إضافة الذكر للمفضلة');
    }
  }

  // ==================== أمثلة أسماء الله الحسنى ====================

  /// مثال: إضافة اسم من أسماء الله للمفضلة
  static Future<void> exampleAddAsmaAllahToFavorites(BuildContext context) async {
    const nameId = 'asma_001_rahman';
    const arabicName = 'الرحمن';
    const meaning = 'الذي وسعت رحمته كل شيء';
    const explanation = 'اسم من أسماء الله الحسنى يدل على سعة رحمته سبحانه وتعالى';
    const transliteration = 'Ar-Rahman';

    final success = await context.addAsmaAllahToFavorites(
      nameId: nameId,
      arabicName: arabicName,
      meaning: meaning,
      explanation: explanation,
      transliteration: transliteration,
    );

    if (success) {
      print('✅ تم إضافة الاسم للمفضلة');
    }
  }

  // ==================== أمثلة التسبيح ====================

  /// مثال: إضافة ذكر التسبيح للمفضلة
  static Future<void> exampleAddTasbihToFavorites(BuildContext context) async {
    const dhikrId = 'tasbih_subhan_allah';
    const text = 'سبحان الله';
    const virtue = 'تسبيحة تنظف القلب وتزيد من الأجر';
    const recommendedCount = 33;
    const category = 'تسبيح';

    final success = await context.addTasbihToFavorites(
      dhikrId: dhikrId,
      text: text,
      virtue: virtue,
      recommendedCount: recommendedCount,
      category: category,
    );

    if (success) {
      print('✅ تم إضافة ذكر التسبيح للمفضلة');
    }
  }

  // ==================== أمثلة الاستعلامات ====================

  /// مثال: الحصول على جميع المفضلات
  static Future<void> exampleGetAllFavorites(BuildContext context) async {
    final favorites = await context.getAllFavorites();
    
    print('📚 إجمالي المفضلات: ${favorites.length}');
    
    for (final favorite in favorites) {
      print('- ${favorite.contentType.displayName}: ${favorite.title}');
    }
  }

  /// مثال: الحصول على مفضلات نوع معين
  static Future<void> exampleGetFavoritesByType(BuildContext context) async {
    // الحصول على الأدعية المفضلة فقط
    final duaFavorites = await context.getFavoritesByType(FavoriteContentType.dua);
    
    print('🤲 عدد الأدعية المفضلة: ${duaFavorites.length}');
    
    for (final dua in duaFavorites) {
      print('- ${dua.title}');
    }
  }

  /// مثال: البحث في المفضلات
  static Future<void> exampleSearchFavorites(BuildContext context) async {
    const searchQuery = 'سبحان الله';
    final searchResults = await context.searchFavorites(searchQuery);
    
    print('🔍 نتائج البحث عن "$searchQuery": ${searchResults.length}');
    
    for (final result in searchResults) {
      print('- ${result.title} (${result.contentType.displayName})');
    }
  }

  /// مثال: الحصول على إحصائيات المفضلة
  static Future<void> exampleGetFavoritesStatistics(BuildContext context) async {
    final statistics = await context.getFavoritesStatistics();
    
    print('📊 إحصائيات المفضلة:');
    print('- العدد الإجمالي: ${statistics.totalCount}');
    print('- آخر إضافة: ${statistics.lastAddedAt}');
    print('- النوع الأكثر استخداماً: ${statistics.mostFavoriteType?.displayName}');
    
    print('\nتفصيل حسب النوع:');
    for (final entry in statistics.countByType.entries) {
      print('- ${entry.key.displayName}: ${entry.value}');
    }
  }

  // ==================== أمثلة الإدارة المتقدمة ====================

  /// مثال: التحقق من وجود عنصر في المفضلة
  static Future<void> exampleCheckIfFavorite(BuildContext context) async {
    const itemId = 'dua_morning_001';
    final isFavorite = await context.isFavorite(itemId);
    
    if (isFavorite) {
      print('✅ العنصر موجود في المفضلة');
    } else {
      print('❌ العنصر غير موجود في المفضلة');
    }
  }

  /// مثال: تبديل حالة المفضلة
  static Future<void> exampleToggleFavorite(BuildContext context) async {
    // إنشاء عنصر مفضلة للتبديل
    final favoriteItem = FavoriteItem.fromDua(
      duaId: 'dua_test_001',
      title: 'دعاء تجريبي',
      arabicText: 'اللهم اهدني فيمن هديت',
    );

    final isNowFavorite = await context.toggleFavorite(favoriteItem);
    
    if (isNowFavorite) {
      print('✅ تم إضافة العنصر للمفضلة');
    } else {
      print('❌ تم حذف العنصر من المفضلة');
    }
  }

  /// مثال: تحديث خيارات الترتيب
  static Future<void> exampleUpdateSortOptions(BuildContext context) async {
    // إعداد خيارات الترتيب الجديدة
    const newOptions = FavoritesSortOptions(
      sortBy: SortBy.title,
      sortOrder: SortOrder.ascending,
      filterByType: FavoriteContentType.dua,
    );

    await context.updateFavoritesSortOptions(newOptions);
    print('✅ تم تحديث خيارات الترتيب');
  }

  /// مثال: مسح مفضلات نوع معين
  static Future<void> exampleClearFavoritesByType(BuildContext context) async {
    // مسح جميع الأدعية المفضلة (مع تأكيد)
    await context.clearFavoritesByTypeWithConfirmation(FavoriteContentType.dua);
  }

  // ==================== أمثلة العمل مع القوائم ====================

  /// مثال: فلترة وترتيب قائمة المفضلات
  static void exampleListOperations() {
    // قائمة تجريبية من المفضلات
    final favoritesList = <FavoriteItem>[
      FavoriteItem.fromDua(
        duaId: 'dua_001',
        title: 'دعاء الاستخارة',
        arabicText: 'اللهم إني أستخيرك بعلمك',
      ),
      FavoriteItem.fromAthkar(
        athkarId: 'athkar_001',
        text: 'سبحان الله وبحمده',
      ),
      FavoriteItem.fromAsmaAllah(
        nameId: 'asma_001',
        arabicName: 'الرحمن',
        meaning: 'الرحيم',
        explanation: 'اسم من أسماء الله الحسنى',
      ),
    ];

    print('📋 أمثلة العمليات على القوائم:');
    
    // فلترة حسب النوع
    final duaOnly = favoritesList.filterByType(FavoriteContentType.dua);
    print('- الأدعية فقط: ${duaOnly.length}');
    
    // البحث في القائمة
    final searchResults = favoritesList.search('سبحان');
    print('- نتائج البحث عن "سبحان": ${searchResults.length}');
    
    // ترتيب حسب العنوان
    final sortedByTitle = favoritesList.sortByTitle();
    print('- مرتبة حسب العنوان: ${sortedByTitle.first.title}');
    
    // تجميع حسب النوع
    final groupedByType = favoritesList.groupByType();
    print('- عدد الأنواع: ${groupedByType.keys.length}');
    
    // إحصائيات سريعة
    final quickStats = favoritesList.getQuickStats();
    print('- إحصائيات سريعة: $quickStats');
  }

  // ==================== أمثلة شاملة ====================

  /// مثال شامل: دورة حياة كاملة للمفضلة
  static Future<void> exampleCompleteFavoritesLifecycle(BuildContext context) async {
    print('🔄 بدء دورة حياة كاملة للمفضلة...');
    
    // 1. إضافة عدة عناصر للمفضلة
    await exampleAddDuaToFavorites(context);
    await exampleAddAthkarToFavorites(context);
    await exampleAddAsmaAllahToFavorites(context);
    
    // 2. عرض الإحصائيات
    await exampleGetFavoritesStatistics(context);
    
    // 3. البحث في المفضلات
    await exampleSearchFavorites(context);
    
    // 4. فلترة حسب النوع
    await exampleGetFavoritesByType(context);
    
    // 5. تحديث الترتيب
    await exampleUpdateSortOptions(context);
    
    // 6. إزالة عنصر واحد
    await exampleRemoveDuaFromFavorites(context);
    
    // 7. الإحصائيات النهائية
    await exampleGetFavoritesStatistics(context);
    
    print('✅ اكتملت دورة الحياة بنجاح!');
  }

  // ==================== أمثلة تطوير مخصصة ====================

  /// مثال: إنشاء FavoriteItem مخصص
  static FavoriteItem createCustomFavoriteItem() {
    return FavoriteItem(
      id: 'custom_001',
      contentType: FavoriteContentType.dua,
      title: 'عنصر مخصص',
      content: 'محتوى مخصص للتجربة',
      subtitle: 'عنوان فرعي اختياري',
      source: 'مصدر مخصص',
      reference: 'مرجع مخصص',
      metadata: {
        'customField1': 'قيمة مخصصة 1',
        'customField2': 42,
        'isCustomCreated': true,
      },
      addedAt: DateTime.now(),
    );
  }

  /// مثال: معالجة الأخطاء
  static Future<void> exampleErrorHandling(BuildContext context) async {
    try {
      // محاولة إضافة عنصر بمعرف فارغ (سيفشل)
      final invalidItem = FavoriteItem(
        id: '', // معرف فارغ
        contentType: FavoriteContentType.dua,
        title: '',
        content: '',
        addedAt: DateTime.now(),
      );

      await context.addToFavorites(invalidItem);
    } catch (e) {
      print('❌ تم التعامل مع الخطأ بنجاح: $e');
    }
  }

  /// مثال: إدارة الذاكرة والأداء
  static Future<void> examplePerformanceConsiderations(BuildContext context) async {
    // الحصول على الخدمة مباشرة لعمليات متعددة
    final favoritesService = context.favoritesService;
    
    // تهيئة الخدمة إذا لم تكن مهيئة
    await favoritesService.initialize();
    
    // عمليات متعددة دون إعادة تحميل
    await favoritesService.addFavorite(createCustomFavoriteItem());
    final count = await favoritesService.getTotalCount();
    final statistics = await favoritesService.getStatistics();
    
    print('📊 العمليات المحسنة - العدد: $count');
    print('📊 الإحصائيات: ${statistics.totalCount}');
  }
}

/// مثال عملي: Widget يستخدم النظام الموحد
class FavoriteButton extends StatefulWidget {
  final String itemId;
  final FavoriteItem favoriteItem;

  const FavoriteButton({
    super.key,
    required this.itemId,
    required this.favoriteItem,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await context.isFavorite(widget.itemId);
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newStatus = await context.toggleFavorite(widget.favoriteItem);
      setState(() {
        _isFavorite = newStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث المفضلة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isLoading ? null : _toggleFavorite,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isFavorite ? Icons.bookmark : Icons.bookmark_outline,
              color: _isFavorite ? Colors.amber : Colors.grey,
            ),
      tooltip: _isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
    );
  }
}