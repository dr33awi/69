# 🎯 نصائح تحسين الأداء للتطبيق

## 1. تحسين إدارة الحالة (State Management)

### المشكلة الحالية:
- استخدام مفرط لـ `setState()` 
- إعادة بناء الـ Widget كاملاً عند تغيير جزء صغير

### الحل المقترح:

```dart
// ❌ الطريقة الحالية - إعادة بناء كامل
setState(() {
  _isLoading = true;
  _errorMessage = null;
  _lastError = null;
});

// ✅ الطريقة المحسنة - تحسين محدود
class OptimizedPrayerScreen extends StatefulWidget {
  @override
  State<OptimizedPrayerScreen> createState() => _OptimizedPrayerScreenState();
}

class _OptimizedPrayerScreenState extends State<OptimizedPrayerScreen> {
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<String?> _errorMessage = ValueNotifier(null);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // فقط هذا الجزء سيعاد بناؤه
          ValueListenableBuilder<bool>(
            valueListenable: _isLoading,
            builder: (context, isLoading, child) {
              return isLoading 
                  ? CircularProgressIndicator()
                  : PrayerTimesContent();
            },
          ),
        ],
      ),
    );
  }
}
```

## 2. تحسين القوائم (ListView Optimization)

### استخدام ListView.builder بدلاً من Column مع كثرة العناصر:

```dart
// ❌ أداء ضعيف مع العناصر الكثيرة
Column(
  children: asmaAllahList.map((item) => AsmaCard(item)).toList(),
)

// ✅ أداء محسن
ListView.builder(
  itemCount: asmaAllahList.length,
  itemBuilder: (context, index) {
    return AsmaCard(asmaAllahList[index]);
  },
)
```

## 3. تحسين الصور والأنيميشن

### استخدام const constructors:

```dart
// ❌ بدون const
Icon(Icons.mosque, size: 24, color: Colors.green)

// ✅ مع const
const Icon(Icons.mosque, size: 24, color: Colors.green)
```

### تحسين الأنيميشن:

```dart
// ✅ أنيميشن محسن
class OptimizedAnimation extends StatefulWidget {
  @override
  State<OptimizedAnimation> createState() => _OptimizedAnimationState();
}

class _OptimizedAnimationState extends State<OptimizedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose(); // ⚠️ مهم جداً
    super.dispose();
  }
}
```

## 4. ذاكرة التخزين المؤقت (Caching)

### تحسين تخزين البيانات:

```dart
class OptimizedDataService {
  static final Map<String, dynamic> _cache = {};
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  static Future<List<AsmaAllahModel>> getAsmaAllah() async {
    final cacheKey = 'asma_allah_data';
    final cachedData = _cache[cacheKey];
    
    if (cachedData != null && 
        DateTime.now().difference(cachedData['timestamp']) < _cacheExpiry) {
      return cachedData['data'];
    }
    
    // تحميل البيانات الجديدة
    final freshData = await _loadFromAssets();
    _cache[cacheKey] = {
      'data': freshData,
      'timestamp': DateTime.now(),
    };
    
    return freshData;
  }
}
```

## 5. تحسين الشبكة والـ API

### استخدام Debouncing للبحث:

```dart
class SearchOptimization {
  Timer? _debounceTimer;
  
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

## 6. تحسين استخدام الذاكرة

### إدارة الـ Listeners بشكل صحيح:

```dart
class OptimizedService extends ChangeNotifier {
  StreamSubscription? _subscription;
  
  void startListening() {
    _subscription = someStream.listen((data) {
      // معالجة البيانات
      notifyListeners();
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel(); // ⚠️ مهم جداً
    super.dispose();
  }
}
```

## 7. تحسين البناء (Build Optimization)

### فصل الـ Widgets المعقدة:

```dart
// ❌ widget معقد في build method
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        Container(
          // 50 سطر من الكود المعقد
        ),
        // المزيد من الكود
      ],
    ),
  );
}

// ✅ تقسيم إلى widgets منفصلة
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _HeaderWidget(),
        _ContentWidget(),
        _FooterWidget(),
      ],
    ),
  );
}
```

## 8. تحسين التحميل (Loading Optimization)

### التحميل التدريجي:

```dart
class LazyLoadingList extends StatefulWidget {
  @override
  State<LazyLoadingList> createState() => _LazyLoadingListState();
}

class _LazyLoadingListState extends State<LazyLoadingList> {
  final ScrollController _scrollController = ScrollController();
  List<Item> _items = [];
  bool _isLoadingMore = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }
  
  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;
    
    setState(() => _isLoadingMore = true);
    
    final newItems = await ApiService.getMoreItems();
    setState(() {
      _items.addAll(newItems);
      _isLoadingMore = false;
    });
  }
}
```

## الخلاصة:

1. **استخدم ValueNotifier بدلاً من setState عند الإمكان**
2. **أضف const constructors في كل مكان ممكن**
3. **تأكد من dispose جميع الـ controllers والـ subscriptions**
4. **استخدم ListView.builder للقوائم الطويلة**
5. **طبق Debouncing للبحث والـ API calls**
6. **قسم الـ Widgets المعقدة إلى أجزاء صغيرة**
7. **استخدم الـ caching للبيانات المتكررة**