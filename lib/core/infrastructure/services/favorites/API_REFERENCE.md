# دليل API للمطورين - نظام المفضلة الموحد

## 📚 مقدمة

هذا الدليل الشامل لجميع APIs المتاحة في نظام المفضلة الموحد. يوضح الدليل كيفية استخدام كل دالة مع أمثلة عملية.

## 🏗️ الهيكل العام

### الكلاسات الرئيسية:
- `FavoritesService`: الخدمة الرئيسية
- `FavoriteItem`: نموذج البيانات الأساسي
- `FavoritesStatistics`: إحصائيات المفضلات
- `FavoritesSortOptions`: خيارات الترتيب
- `FavoriteContentType`: أنواع المحتوى المدعومة

## 🔧 FavoritesService API

### 🚀 التهيئة والإعداد

```dart
/// تهيئة الخدمة (يتم استدعاؤها مرة واحدة في main.dart)
Future<void> initialize()

/// مثال الاستخدام:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.initEssential();
  
  // تهيئة خدمة المفضلة
  await getIt<FavoritesService>().initialize();
  
  runApp(MyApp());
}
```

### ➕ إضافة وإزالة المفضلات

```dart
/// إضافة عنصر للمفضلة
/// يعيد true إذا تم الإضافة، false إذا كان موجود مسبقاً
Future<bool> addFavorite(FavoriteItem item)

/// إزالة عنصر من المفضلة
/// يعيد true إذا تم الحذف، false إذا لم يكن موجود
Future<bool> removeFavorite(String itemId)

/// تغيير حالة المفضلة (إضافة/إزالة)
/// يعيد true إذا تم الإضافة، false إذا تم الحذف
Future<bool> toggleFavorite(FavoriteItem item)

/// أمثلة الاستخدام:
final favoritesService = getIt<FavoritesService>();

// إضافة دعاء للمفضلة
final duaItem = FavoriteItem.fromDua(
  duaId: "dua_001",
  title: "دعاء الاستخارة",
  arabicText: "اللهم إني أستخيرك بعلمك...",
  translation: "O Allah, I seek Your guidance...",
);

bool added = await favoritesService.addFavorite(duaItem);
if (added) {
  print("تم إضافة الدعاء للمفضلة");
}

// تغيير حالة المفضلة
bool isNowFavorite = await favoritesService.toggleFavorite(duaItem);
print(isNowFavorite ? "مُضاف للمفضلة" : "محذوف من المفضلة");
```

### 🔍 البحث والاستعلام

```dart
/// التحقق من وجود عنصر في المفضلة
Future<bool> isFavorite(String itemId)

/// الحصول على جميع المفضلات
Future<List<FavoriteItem>> getAllFavorites()

/// الحصول على المفضلات بنوع محدد
Future<List<FavoriteItem>> getFavoritesByType(FavoriteContentType type)

/// البحث في المفضلات
Future<List<FavoriteItem>> searchFavorites(String query, {
  FavoriteContentType? type,
  int? limit,
})

/// أمثلة الاستخدام:

// التحقق من المفضلة
bool isFav = await favoritesService.isFavorite("dua_001");

// الحصول على جميع الأدعية المفضلة
List<FavoriteItem> favoriteDuas = await favoritesService
    .getFavoritesByType(FavoriteContentType.dua);

// البحث في المفضلات
List<FavoriteItem> searchResults = await favoritesService
    .searchFavorites("الاستخارة", limit: 10);

// البحث في نوع محدد
List<FavoriteItem> duaResults = await favoritesService.searchFavorites(
  "الاستخارة",
  type: FavoriteContentType.dua,
  limit: 5,
);
```

### 📊 الإحصائيات والمعلومات

```dart
/// الحصول على إحصائيات شاملة
Future<FavoritesStatistics> getStatistics()

/// الحصول على عدد المفضلات لنوع محدد
Future<int> getCountByType(FavoriteContentType type)

/// الحصول على إجمالي عدد المفضلات
Future<int> getTotalCount()

/// أمثلة الاستخدام:

final statistics = await favoritesService.getStatistics();

print("إجمالي المفضلات: ${statistics.totalCount}");
print("عدد الأدعية: ${statistics.countByType[FavoriteContentType.dua]}");
print("آخر تحديث: ${statistics.lastUpdated}");

// عدد محدد
int duaCount = await favoritesService.getCountByType(FavoriteContentType.dua);
print("عدد الأدعية المفضلة: $duaCount");
```

### 🗂️ الترتيب والفلترة

```dart
/// ترتيب المفضلات
Future<List<FavoriteItem>> getSortedFavorites({
  FavoritesSortOptions sortBy = FavoritesSortOptions.dateAdded,
  bool ascending = false,
  FavoriteContentType? type,
})

/// أمثلة الاستخدام:

// ترتيب حسب تاريخ الإضافة (الأحدث أولاً)
List<FavoriteItem> recentFavorites = await favoritesService.getSortedFavorites(
  sortBy: FavoritesSortOptions.dateAdded,
  ascending: false,
);

// ترتيب الأدعية أبجدياً
List<FavoriteItem> alphabeticalDuas = await favoritesService.getSortedFavorites(
  sortBy: FavoritesSortOptions.alphabetical,
  ascending: true,
  type: FavoriteContentType.dua,
);

// ترتيب حسب نوع المحتوى
List<FavoriteItem> byTypeFavorites = await favoritesService.getSortedFavorites(
  sortBy: FavoritesSortOptions.contentType,
);
```

### 🗑️ إدارة البيانات

```dart
/// حذف جميع المفضلات
Future<void> clearAllFavorites()

/// حذف جميع المفضلات لنوع محدد
Future<int> clearFavoritesByType(FavoriteContentType type)

/// تصدير المفضلات كـ JSON
Future<Map<String, dynamic>> exportFavorites()

/// استيراد المفضلات من JSON
Future<bool> importFavorites(Map<String, dynamic> data)

/// أمثلة الاستخدام:

// حذف جميع الأذكار المفضلة
int deletedCount = await favoritesService
    .clearFavoritesByType(FavoriteContentType.athkar);
print("تم حذف $deletedCount ذكر من المفضلة");

// تصدير البيانات
Map<String, dynamic> exportData = await favoritesService.exportFavorites();
String jsonString = jsonEncode(exportData);

// حفظ النسخة الاحتياطية
await File('favorites_backup.json').writeAsString(jsonString);

// استيراد البيانات
String backupData = await File('favorites_backup.json').readAsString();
Map<String, dynamic> importData = jsonDecode(backupData);
bool success = await favoritesService.importFavorites(importData);
```

## 📝 FavoriteItem API

### 🏗️ إنشاء FavoriteItem

```dart
/// للأدعية
FavoriteItem.fromDua({
  required String duaId,
  required String title,
  required String arabicText,
  String? transliteration,
  String? translation,
  String? virtue,
  String? source,
  String? reference,
  String? categoryId,
})

/// للأذكار
FavoriteItem.fromAthkar({
  required String athkarId,
  required String text,
  String? fadl,
  String? source,
  String? categoryId,
  int? count,
})

/// لأسماء الله
FavoriteItem.fromAsmaAllah({
  required String nameId,
  required String arabicName,
  required String transliteration,
  required String meaning,
  String? explanation,
  String? verse,
  String? hadith,
})

/// للتسبيح
FavoriteItem.fromTasbih({
  required String dhikrId,
  required String text,
  String? virtue,
  int? recommendedCount,
  String? category,
})

/// للقرآن الكريم
FavoriteItem.fromQuran({
  required String verseId,
  required String surahName,
  required int surahNumber,
  required int verseNumber,
  required String arabicText,
  String? translation,
  String? tafseer,
})

/// للأحاديث
FavoriteItem.fromHadith({
  required String hadithId,
  required String arabicText,
  String? translation,
  String? narrator,
  String? source,
  String? grade,
  String? explanation,
})
```

### 🔄 تحويل FavoriteItem

```dart
/// تحويل إلى Map
Map<String, dynamic> toMap()

/// إنشاء من Map
factory FavoriteItem.fromMap(Map<String, dynamic> map)

/// تحويل إلى JSON
String toJson()

/// إنشاء من JSON
factory FavoriteItem.fromJson(String source)

/// مثال الاستخدام:
final duaItem = FavoriteItem.fromDua(
  duaId: "dua_001", 
  title: "دعاء النوم",
  arabicText: "اللهم باسمك أموت وأحيا",
);

// تحويل إلى JSON للحفظ
String jsonData = duaItem.toJson();

// استرجاع من JSON
FavoriteItem restoredItem = FavoriteItem.fromJson(jsonData);
```

## 🔄 Extensions API

### BuildContext Extensions

```dart
/// الحصول على خدمة المفضلة
FavoritesService get favoritesService

/// إضافة للمفضلة مع رسالة تأكيد
Future<void> addToFavorites(FavoriteItem item, {String? successMessage})

/// إضافة أنواع مختلفة للمفضلة
Future<void> addDuaToFavorites(String duaId, ...)
Future<void> addAthkarToFavorites(String athkarId, ...)
Future<void> addAsmaAllahToFavorites(String nameId, ...)
Future<void> addTasbihToFavorites(String dhikrId, ...)

/// الحصول على المفضلات مع معالجة الحالات
Future<List<FavoriteItem>> getFavoritesWithStates(...)

/// البحث مع نتائج مصفاة
Future<List<FavoriteItem>> searchFavoritesFiltered(...)

/// عرض شاشة المفضلة
void showUnifiedFavoritesScreen({FavoriteContentType? initialType})

/// الحصول على الإحصائيات
Future<FavoritesStatistics> getFavoritesStatistics()

/// أمثلة الاستخدام:

class _DuaScreenState extends State<DuaScreen> {
  
  void _addCurrentDuaToFavorites() async {
    final favoriteItem = FavoriteItem.fromDua(
      duaId: currentDua.id,
      title: currentDua.title,
      arabicText: currentDua.text,
    );
    
    // إضافة مع رسالة تأكيد
    await context.addToFavorites(
      favoriteItem, 
      successMessage: "تم إضافة الدعاء للمفضلة بنجاح",
    );
  }
  
  void _showFavorites() {
    // عرض المفضلات مع تركيز على الأدعية
    context.showUnifiedFavoritesScreen(
      initialType: FavoriteContentType.dua,
    );
  }
}
```

## 🎨 Widgets API

### FavoriteButton Widget

```dart
FavoriteButton({
  required String itemId,
  required FavoriteItem favoriteItem,
  VoidCallback? onToggle,
  Widget? favoriteIcon,
  Widget? notFavoriteIcon,
  Color? favoriteColor,
  Color? notFavoriteColor,
  double? size,
  String? tooltip,
})

/// مثال الاستخدام:
class DuaCard extends StatelessWidget {
  final DuaItem dua;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(dua.title),
        subtitle: Text(dua.arabicText),
        trailing: FavoriteButton(
          itemId: dua.id,
          favoriteItem: FavoriteItem.fromDua(
            duaId: dua.id,
            title: dua.title,
            arabicText: dua.arabicText,
          ),
          onToggle: () {
            // تنفيذ إضافي بعد التغيير
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم تحديث المفضلة')),
            );
          },
        ),
      ),
    );
  }
}
```

## 🎯 نصائح للاستخدام المتقدم

### 1. التحميل المُحسن

```dart
class FavoritesManager {
  static final Map<String, bool> _cache = {};
  
  /// تحميل مسبق لحالات المفضلة
  static Future<void> preloadFavoriteStates(List<String> itemIds) async {
    final service = getIt<FavoritesService>();
    for (String id in itemIds) {
      _cache[id] = await service.isFavorite(id);
    }
  }
  
  /// استخدام التخزين المؤقت
  static bool? getCachedFavoriteState(String itemId) {
    return _cache[itemId];
  }
}
```

### 2. إشعارات التغيير

```dart
class FavoritesListener extends StatefulWidget {
  final Widget child;
  
  @override
  _FavoritesListenerState createState() => _FavoritesListenerState();
}

class _FavoritesListenerState extends State<FavoritesListener> {
  late FavoritesService _service;
  
  @override
  void initState() {
    super.initState();
    _service = getIt<FavoritesService>();
    _service.addListener(_onFavoritesChanged);
  }
  
  void _onFavoritesChanged() {
    // تحديث الواجهة عند تغيير المفضلات
    setState(() {});
  }
  
  @override
  void dispose() {
    _service.removeListener(_onFavoritesChanged);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) => widget.child;
}
```

### 3. معالجة الأخطاء

```dart
class FavoritesErrorHandler {
  static Future<T?> handleOperation<T>(Future<T> operation) async {
    try {
      return await operation;
    } catch (e) {
      if (e is FavoritesException) {
        // معالجة أخطاء المفضلة المحددة
        debugPrint('خطأ في المفضلة: ${e.message}');
      } else {
        // معالجة الأخطاء العامة
        debugPrint('خطأ غير متوقع: $e');
      }
      return null;
    }
  }
}

// الاستخدام
Future<void> addToFavoritesWithErrorHandling(FavoriteItem item) async {
  final result = await FavoritesErrorHandler.handleOperation(
    getIt<FavoritesService>().addFavorite(item),
  );
  
  if (result != null && result) {
    // نجحت العملية
    showSuccessMessage();
  } else {
    // فشلت العملية
    showErrorMessage();
  }
}
```

## 🔍 استكشاف الأخطاء

### أخطاء شائعة وحلولها:

1. **خطأ: Service not registered**
   ```dart
   // التأكد من تسجيل الخدمة
   getIt.registerLazySingleton<FavoritesService>(() => FavoritesService());
   ```

2. **خطأ: Invalid favorite item**
   ```dart
   // التأكد من صحة البيانات
   if (FavoritesConstants.isValidId(itemId) && 
       FavoritesConstants.isValidContentType(contentType)) {
     // آمن للاستخدام
   }
   ```

3. **بطء في الأداء**
   ```dart
   // استخدام التحميل المسبق
   await favoritesService.initialize(); // في بداية التطبيق
   
   // استخدام التخزين المؤقت
   final favorites = await favoritesService.getAllFavorites();
   // احفظ النتائج للاستخدام المتكرر
   ```

## 📱 أمثلة تطبيقية كاملة

### مثال 1: شاشة الأدعية مع المفضلة

```dart
class DuasListScreen extends StatefulWidget {
  @override
  _DuasListScreenState createState() => _DuasListScreenState();
}

class _DuasListScreenState extends State<DuasListScreen> {
  late FavoritesService _favoritesService;
  List<DuaItem> _duas = [];
  Set<String> _favoriteIds = {};
  
  @override
  void initState() {
    super.initState();
    _favoritesService = getIt<FavoritesService>();
    _loadDuas();
    _loadFavorites();
  }
  
  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService
        .getFavoritesByType(FavoriteContentType.dua);
    setState(() {
      _favoriteIds = favorites.map((f) => f.id).toSet();
    });
  }
  
  Future<void> _toggleFavorite(DuaItem dua) async {
    final favoriteItem = FavoriteItem.fromDua(
      duaId: dua.id,
      title: dua.title,
      arabicText: dua.arabicText,
    );
    
    await _favoritesService.toggleFavorite(favoriteItem);
    await _loadFavorites(); // إعادة تحميل
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الأدعية'),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () => context.showUnifiedFavoritesScreen(
              initialType: FavoriteContentType.dua,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _duas.length,
        itemBuilder: (context, index) {
          final dua = _duas[index];
          final isFavorite = _favoriteIds.contains(dua.id);
          
          return ListTile(
            title: Text(dua.title),
            subtitle: Text(dua.arabicText),
            trailing: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: () => _toggleFavorite(dua),
            ),
          );
        },
      ),
    );
  }
}
```

### مثال 2: إحصائيات المفضلة

```dart
class FavoritesStatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FavoritesStatistics>(
      future: context.getFavoritesStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        final stats = snapshot.data!;
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إحصائيات المفضلة',
                  style: Theme.of(context).textTheme.headline6,
                ),
                SizedBox(height: 12),
                _StatRow('إجمالي المفضلات', '${stats.totalCount}'),
                _StatRow('الأدعية', '${stats.countByType[FavoriteContentType.dua] ?? 0}'),
                _StatRow('الأذكار', '${stats.countByType[FavoriteContentType.athkar] ?? 0}'),
                _StatRow('أسماء الله', '${stats.countByType[FavoriteContentType.asmaAllah] ?? 0}'),
                _StatRow('التسبيح', '${stats.countByType[FavoriteContentType.tasbih] ?? 0}'),
                SizedBox(height: 8),
                Text(
                  'آخر تحديث: ${_formatDate(stats.lastUpdated)}',
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _StatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

هذا الدليل يغطي جميع APIs المتاحة في نظام المفضلة الموحد. استخدم هذه المراجع لتطوير ميزات متقدمة وتحسين تجربة المستخدم في تطبيقك.