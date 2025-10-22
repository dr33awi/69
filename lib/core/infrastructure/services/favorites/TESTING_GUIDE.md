# دليل الاختبار والجودة - نظام المفضلة الموحد

## 🧪 مقدمة الاختبار

هذا الدليل الشامل لاختبار نظام المفضلة الموحد والتأكد من جودته وموثوقيته. يتضمن الدليل اختبارات الوحدة، اختبارات التكامل، واختبارات الأداء.

## 📋 قائمة مراجعة الاختبار

### ✅ اختبارات أساسية
- [ ] إضافة وإزالة المفضلات
- [ ] التحقق من حالة المفضلة
- [ ] البحث والفلترة
- [ ] الترتيب والتصنيف
- [ ] الإحصائيات والتقارير

### ✅ اختبارات التكامل
- [ ] التفاعل مع StorageService
- [ ] التفاعل مع Service Locator
- [ ] تحديثات الواجهة
- [ ] إشعارات التغيير

### ✅ اختبارات الأداء
- [ ] سرعة التحميل
- [ ] استهلاك الذاكرة
- [ ] كفاءة البحث
- [ ] التخزين المؤقت

### ✅ اختبارات البيانات
- [ ] الترحيل التلقائي
- [ ] التصدير والاستيراد
- [ ] حماية البيانات
- [ ] التحقق من صحة البيانات

## 🔧 إعداد بيئة الاختبار

### 1. إضافة dependencies الاختبار

في `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  mocktail: ^0.3.0
  fake_async: ^1.3.1
  test: ^1.21.0
```

### 2. إنشاء مجلد الاختبارات

```
test/
├── unit/
│   ├── favorites_service_test.dart
│   ├── favorite_models_test.dart
│   └── favorites_extensions_test.dart
├── widget/
│   ├── favorite_button_test.dart
│   └── unified_favorites_screen_test.dart
├── integration/
│   ├── favorites_integration_test.dart
│   └── migration_test.dart
└── mocks/
    ├── mock_storage_service.dart
    └── test_data.dart
```

## 🧪 اختبارات الوحدة (Unit Tests)

### اختبار FavoritesService

```dart
// test/unit/favorites_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/favorites_service.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/models/favorite_models.dart';

import '../mocks/mock_storage_service.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('FavoritesService', () {
    late FavoritesService favoritesService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      favoritesService = FavoritesService();
      // حقن المخزن المزيف
      // favoritesService.storageService = mockStorageService;
    });

    group('إضافة المفضلات', () {
      test('يجب إضافة عنصر جديد بنجاح', () async {
        // إعداد
        final testItem = FavoriteItem.fromDua(
          duaId: 'test_dua_001',
          title: 'دعاء الاختبار',
          arabicText: 'نص الدعاء للاختبار',
        );

        when(mockStorageService.getString(any)).thenReturn(null);
        when(mockStorageService.setString(any, any)).thenAnswer((_) async => true);

        // تنفيذ
        final result = await favoritesService.addFavorite(testItem);

        // تحقق
        expect(result, isTrue);
        verify(mockStorageService.setString(any, any)).called(1);
      });

      test('يجب رفض إضافة عنصر مكرر', () async {
        // إعداد
        final testItem = FavoriteItem.fromDua(
          duaId: 'existing_dua',
          title: 'دعاء موجود',
          arabicText: 'نص موجود',
        );

        // محاكاة وجود العنصر مسبقاً
        when(mockStorageService.getString(any))
            .thenReturn('{"existing_dua": {...}}');

        // تنفيذ
        final result = await favoritesService.addFavorite(testItem);

        // تحقق
        expect(result, isFalse);
      });

      test('يجب التحقق من الحد الأقصى للمفضلات', () async {
        // إعداد قائمة ممتلئة
        final favorites = List.generate(1000, (index) => 
          FavoriteItem.fromDua(
            duaId: 'dua_$index',
            title: 'دعاء $index',
            arabicText: 'نص $index',
          )
        );

        // محاكاة تجاوز الحد الأقصى
        when(mockStorageService.getString(any))
            .thenReturn(jsonEncode(favorites.map((f) => f.toMap()).toList()));

        final newItem = FavoriteItem.fromDua(
          duaId: 'dua_1001',
          title: 'دعاء جديد',
          arabicText: 'نص جديد',
        );

        // تنفيذ
        expect(
          () => favoritesService.addFavorite(newItem),
          throwsA(isA<FavoritesException>()),
        );
      });
    });

    group('البحث في المفضلات', () {
      test('يجب العثور على النتائج الصحيحة', () async {
        // إعداد
        final testItems = [
          FavoriteItem.fromDua(
            duaId: 'dua_001',
            title: 'دعاء الاستخارة',
            arabicText: 'اللهم إني أستخيرك بعلمك',
          ),
          FavoriteItem.fromDua(
            duaId: 'dua_002',
            title: 'دعاء السفر',
            arabicText: 'اللهم أنت الصاحب في السفر',
          ),
        ];

        when(mockStorageService.getString(any))
            .thenReturn(jsonEncode(testItems.map((f) => f.toMap()).toList()));

        await favoritesService.initialize();

        // تنفيذ
        final results = await favoritesService.searchFavorites('الاستخارة');

        // تحقق
        expect(results.length, equals(1));
        expect(results.first.title, contains('الاستخارة'));
      });

      test('يجب ترتيب النتائج حسب الصلة', () async {
        // إعداد
        final testItems = [
          FavoriteItem.fromDua(
            duaId: 'dua_001',
            title: 'دعاء النوم',
            arabicText: 'اللهم باسمك أموت وأحيا',
          ),
          FavoriteItem.fromDua(
            duaId: 'dua_002',
            title: 'دعاء الاستيقاظ من النوم',
            arabicText: 'الحمد لله الذي أحيانا بعد ما أماتنا',
          ),
        ];

        when(mockStorageService.getString(any))
            .thenReturn(jsonEncode(testItems.map((f) => f.toMap()).toList()));

        await favoritesService.initialize();

        // تنفيذ
        final results = await favoritesService.searchFavorites('النوم');

        // تحقق - يجب أن يكون "دعاء النوم" أولاً لأن "النوم" في العنوان
        expect(results.length, equals(2));
        expect(results.first.title, equals('دعاء النوم'));
      });
    });

    group('الإحصائيات', () {
      test('يجب حساب الإحصائيات الصحيحة', () async {
        // إعداد
        final testItems = [
          FavoriteItem.fromDua(duaId: 'dua_001', title: 'دعاء 1', arabicText: 'نص'),
          FavoriteItem.fromAthkar(athkarId: 'athkar_001', text: 'ذكر 1'),
          FavoriteItem.fromAsmaAllah(nameId: 'name_001', arabicName: 'الله', transliteration: 'Allah', meaning: 'God'),
        ];

        when(mockStorageService.getString(any))
            .thenReturn(jsonEncode(testItems.map((f) => f.toMap()).toList()));

        await favoritesService.initialize();

        // تنفيذ
        final stats = await favoritesService.getStatistics();

        // تحقق
        expect(stats.totalCount, equals(3));
        expect(stats.countByType[FavoriteContentType.dua], equals(1));
        expect(stats.countByType[FavoriteContentType.athkar], equals(1));
        expect(stats.countByType[FavoriteContentType.asmaAllah], equals(1));
      });
    });
  });
}
```

### اختبار النماذج

```dart
// test/unit/favorite_models_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/models/favorite_models.dart';

void main() {
  group('FavoriteItem', () {
    test('يجب إنشاء دعاء صحيح', () {
      final item = FavoriteItem.fromDua(
        duaId: 'test_001',
        title: 'دعاء الاختبار',
        arabicText: 'نص عربي',
        translation: 'English text',
      );

      expect(item.id, equals('test_001'));
      expect(item.title, equals('دعاء الاختبار'));
      expect(item.contentType, equals(FavoriteContentType.dua));
      expect(item.metadata['translation'], equals('English text'));
    });

    test('يجب تحويل إلى JSON والعكس', () {
      final originalItem = FavoriteItem.fromDua(
        duaId: 'test_002',
        title: 'دعاء JSON',
        arabicText: 'نص للاختبار',
      );

      // تحويل إلى JSON
      final jsonString = originalItem.toJson();
      expect(jsonString, isA<String>());

      // استعادة من JSON
      final restoredItem = FavoriteItem.fromJson(jsonString);
      expect(restoredItem.id, equals(originalItem.id));
      expect(restoredItem.title, equals(originalItem.title));
      expect(restoredItem.contentType, equals(originalItem.contentType));
    });

    test('يجب التعامل مع البيانات المفقودة بأمان', () {
      final item = FavoriteItem.fromDua(
        duaId: 'minimal_test',
        title: 'حد أدنى',
        arabicText: 'نص',
        // بدون translation أو virtue
      );

      expect(item.metadata['translation'], isNull);
      expect(item.metadata['virtue'], isNull);
      
      // يجب أن يعمل التحويل بدون أخطاء
      final jsonString = item.toJson();
      final restored = FavoriteItem.fromJson(jsonString);
      expect(restored.id, equals('minimal_test'));
    });
  });

  group('FavoritesStatistics', () {
    test('يجب حساب الإحصائيات الصحيحة', () {
      final countByType = {
        FavoriteContentType.dua: 5,
        FavoriteContentType.athkar: 3,
        FavoriteContentType.asmaAllah: 2,
      };

      final stats = FavoritesStatistics(
        totalCount: 10,
        countByType: countByType,
        lastUpdated: DateTime.now(),
      );

      expect(stats.totalCount, equals(10));
      expect(stats.countByType.length, equals(3));
      expect(stats.mostPopularType, equals(FavoriteContentType.dua));
    });

    test('يجب التعامل مع القوائم الفارغة', () {
      final stats = FavoritesStatistics(
        totalCount: 0,
        countByType: {},
        lastUpdated: DateTime.now(),
      );

      expect(stats.totalCount, equals(0));
      expect(stats.mostPopularType, isNull);
    });
  });
}
```

## 🎨 اختبارات الواجهة (Widget Tests)

### اختبار FavoriteButton

```dart
// test/widget/favorite_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/widgets/favorite_button.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/models/favorite_models.dart';

class MockFavoritesService extends Mock implements FavoritesService {}

void main() {
  group('FavoriteButton Widget', () {
    late MockFavoritesService mockService;

    setUp(() {
      mockService = MockFavoritesService();
    });

    testWidgets('يجب عرض أيقونة صحيحة للمفضلة', (WidgetTester tester) async {
      // إعداد
      final testItem = FavoriteItem.fromDua(
        duaId: 'test_001',
        title: 'دعاء الاختبار',
        arabicText: 'نص',
      );

      when(mockService.isFavorite('test_001')).thenAnswer((_) async => true);

      // بناء الواجهة
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              itemId: 'test_001',
              favoriteItem: testItem,
            ),
          ),
        ),
      );

      // انتظار تحميل الحالة
      await tester.pumpAndSettle();

      // تحقق من وجود أيقونة المفضلة
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('يجب تغيير الحالة عند النقر', (WidgetTester tester) async {
      // إعداد
      final testItem = FavoriteItem.fromDua(
        duaId: 'test_002',
        title: 'دعاء التغيير',
        arabicText: 'نص',
      );

      when(mockService.isFavorite('test_002')).thenAnswer((_) async => false);
      when(mockService.toggleFavorite(testItem)).thenAnswer((_) async => true);

      // بناء الواجهة
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              itemId: 'test_002',
              favoriteItem: testItem,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // التحقق من الحالة الابتدائية
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // النقر على الزر
      await tester.tap(find.byType(FavoriteButton));
      await tester.pumpAndSettle();

      // التحقق من تغيير الحالة
      verify(mockService.toggleFavorite(testItem)).called(1);
    });

    testWidgets('يجب عرض tooltip صحيح', (WidgetTester tester) async {
      final testItem = FavoriteItem.fromDua(
        duaId: 'test_003',
        title: 'دعاء Tooltip',
        arabicText: 'نص',
      );

      when(mockService.isFavorite('test_003')).thenAnswer((_) async => false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              itemId: 'test_003',
              favoriteItem: testItem,
              tooltip: 'إضافة للمفضلة',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // البحث عن Tooltip
      final tooltipFinder = find.byTooltip('إضافة للمفضلة');
      expect(tooltipFinder, findsOneWidget);
    });
  });
}
```

### اختبار UnifiedFavoritesScreen

```dart
// test/widget/unified_favorites_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/screens/unified_favorites_screen.dart';

void main() {
  group('UnifiedFavoritesScreen Widget', () {
    testWidgets('يجب عرض التبويبات الصحيحة', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UnifiedFavoritesScreen(),
        ),
      );

      // التحقق من وجود TabBar
      expect(find.byType(TabBar), findsOneWidget);
      
      // التحقق من وجود التبويبات
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('الأدعية'), findsOneWidget);
      expect(find.text('الأذكار'), findsOneWidget);
      expect(find.text('أسماء الله'), findsOneWidget);
      expect(find.text('التسبيح'), findsOneWidget);
    });

    testWidgets('يجب عرض حقل البحث', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UnifiedFavoritesScreen(),
        ),
      );

      // البحث عن حقل النص
      expect(find.byType(TextField), findsOneWidget);
      
      // التحقق من النص التوضيحي
      expect(find.text('البحث في المفضلات...'), findsOneWidget);
    });

    testWidgets('يجب التبديل بين التبويبات', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UnifiedFavoritesScreen(),
        ),
      );

      // النقر على تبويب "الأدعية"
      await tester.tap(find.text('الأدعية'));
      await tester.pumpAndSettle();

      // التحقق من تغيير المحتوى
      // (هنا نحتاج لمحاكاة البيانات للتحقق الدقيق)
    });
  });
}
```

## 🔗 اختبارات التكامل

### اختبار التكامل مع StorageService

```dart
// test/integration/favorites_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:athkar_app/main.dart' as app;
import 'package:athkar_app/app/di/service_locator.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/favorites_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Favorites Integration Tests', () {
    setUpAll(() async {
      await ServiceLocator.initEssential();
    });

    testWidgets('سيناريو كامل: إضافة وحذف وبحث', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final favoritesService = getIt<FavoritesService>();
      
      // 1. إضافة عنصر
      final testItem = FavoriteItem.fromDua(
        duaId: 'integration_test_001',
        title: 'دعاء اختبار التكامل',
        arabicText: 'نص الاختبار الكامل',
      );

      final added = await favoritesService.addFavorite(testItem);
      expect(added, isTrue);

      // 2. التحقق من الوجود
      final isFavorite = await favoritesService.isFavorite('integration_test_001');
      expect(isFavorite, isTrue);

      // 3. البحث
      final searchResults = await favoritesService.searchFavorites('اختبار التكامل');
      expect(searchResults.length, greaterThan(0));
      expect(searchResults.any((item) => item.id == 'integration_test_001'), isTrue);

      // 4. الحذف
      final removed = await favoritesService.removeFavorite('integration_test_001');
      expect(removed, isTrue);

      // 5. التحقق من الحذف
      final isStillFavorite = await favoritesService.isFavorite('integration_test_001');
      expect(isStillFavorite, isFalse);
    });

    testWidgets('اختبار الترحيل التلقائي', (WidgetTester tester) async {
      // إعداد بيانات قديمة في التخزين المحلي
      final storage = getIt<StorageService>();
      
      // محاكاة البيانات القديمة
      await storage.setStringList('dua_favorites', ['old_dua_001', 'old_dua_002']);
      
      // تهيئة الخدمة الجديدة
      final favoritesService = FavoritesService();
      await favoritesService.initialize();
      
      // التحقق من الترحيل
      final allFavorites = await favoritesService.getAllFavorites();
      final duaFavorites = allFavorites
          .where((f) => f.contentType == FavoriteContentType.dua)
          .toList();
      
      expect(duaFavorites.length, equals(2));
      expect(duaFavorites.any((f) => f.id == 'old_dua_001'), isTrue);
      expect(duaFavorites.any((f) => f.id == 'old_dua_002'), isTrue);
    });
  });
}
```

## 📊 اختبارات الأداء

### اختبار سرعة البحث

```dart
// test/performance/search_performance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:athkar_app/core/infrastructure/services/favorites/favorites_service.dart';

void main() {
  group('Performance Tests', () {
    test('يجب أن يكون البحث سريعاً مع 1000 عنصر', () async {
      final service = FavoritesService();
      
      // إنشاء 1000 عنصر تجريبي
      final testItems = List.generate(1000, (index) => 
        FavoriteItem.fromDua(
          duaId: 'perf_test_$index',
          title: 'دعاء الأداء $index',
          arabicText: 'نص تجريبي للأداء رقم $index',
        )
      );

      // إضافة العناصر
      for (final item in testItems) {
        await service.addFavorite(item);
      }

      // قياس وقت البحث
      final stopwatch = Stopwatch()..start();
      final results = await service.searchFavorites('الأداء');
      stopwatch.stop();

      // يجب أن يكون البحث أسرع من 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(results.length, equals(1000));
    });

    test('يجب أن يكون الترتيب فعال مع عدد كبير', () async {
      final service = FavoritesService();
      
      // إنشاء 500 عنصر عشوائي
      final testItems = List.generate(500, (index) => 
        FavoriteItem.fromDua(
          duaId: 'sort_test_$index',
          title: 'دعاء ${DateTime.now().millisecondsSinceEpoch % 100}',
          arabicText: 'نص عشوائي',
        )
      );

      for (final item in testItems) {
        await service.addFavorite(item);
      }

      // قياس وقت الترتيب
      final stopwatch = Stopwatch()..start();
      final sortedResults = await service.getSortedFavorites(
        sortBy: FavoritesSortOptions.alphabetical,
      );
      stopwatch.stop();

      // يجب أن يكون الترتيب أسرع من 50ms
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(sortedResults.length, equals(500));
    });
  });
}
```

## 🛡️ اختبارات الأمان والبيانات

### اختبار حماية البيانات

```dart
// test/security/data_protection_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Data Protection Tests', () {
    test('يجب رفض البيانات غير الصالحة', () {
      expect(
        () => FavoriteItem.fromDua(
          duaId: '', // معرف فارغ
          title: 'دعاء',
          arabicText: 'نص',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('يجب تنظيف النصوص من المحارف الخطرة', () {
      final item = FavoriteItem.fromDua(
        duaId: 'safe_test',
        title: '<script>alert("xss")</script>دعاء آمن',
        arabicText: 'نص آمن',
      );

      // يجب إزالة العلامات الخطرة
      expect(item.title, equals('دعاء آمن'));
    });

    test('يجب التحقق من حدود الحجم', () {
      final longText = 'أ' * 10000; // نص طويل جداً

      expect(
        () => FavoriteItem.fromDua(
          duaId: 'size_test',
          title: longText,
          arabicText: 'نص',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

## 📋 سيناريوهات الاختبار الشاملة

### سيناريو 1: رحلة المستخدم الكاملة

```dart
// test/scenarios/complete_user_journey_test.dart
void main() {
  testWidgets('رحلة المستخدم الكاملة للمفضلة', (WidgetTester tester) async {
    // 1. فتح التطبيق
    app.main();
    await tester.pumpAndSettle();

    // 2. الانتقال لشاشة الأدعية
    await tester.tap(find.text('الأدعية'));
    await tester.pumpAndSettle();

    // 3. اختيار دعاء وإضافته للمفضلة
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();

    // 4. التحقق من تغيير الأيقونة
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    // 5. فتح شاشة المفضلة
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    // 6. التحقق من وجود العنصر المضاف
    expect(find.byType(ListTile), findsAtLeastNWidgets(1));

    // 7. البحث في المفضلة
    await tester.enterText(find.byType(TextField), 'دعاء');
    await tester.pumpAndSettle();

    // 8. التحقق من نتائج البحث
    expect(find.byType(ListTile), findsAtLeastNWidgets(1));

    // 9. حذف من المفضلة
    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();

    // 10. تأكيد الحذف
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();

    // 11. التحقق من الحذف
    expect(find.text('لا توجد مفضلات'), findsOneWidget);
  });
}
```

### سيناريو 2: اختبار حالات الخطأ

```dart
void main() {
  group('Error Handling Scenarios', () {
    testWidgets('التعامل مع انقطاع الاتصال', (WidgetTester tester) async {
      // محاكاة انقطاع الاتصال
      // واختبار استمرار عمل المفضلة المحلية
    });

    testWidgets('التعامل مع امتلاء التخزين', (WidgetTester tester) async {
      // محاكاة امتلاء مساحة التخزين
      // واختبار عرض رسالة خطأ مناسبة
    });

    testWidgets('التعامل مع بيانات معطوبة', (WidgetTester tester) async {
      // محاكاة بيانات مخزنة معطوبة
      // واختبار إعادة تعيين النظام
    });
  });
}
```

## 🔧 أدوات المساعدة في الاختبار

### Mock Data Generator

```dart
// test/helpers/test_data_generator.dart
class TestDataGenerator {
  static List<FavoriteItem> generateDuas(int count) {
    return List.generate(count, (index) => 
      FavoriteItem.fromDua(
        duaId: 'test_dua_$index',
        title: 'دعاء اختبار $index',
        arabicText: 'اللهم اختبار $index',
        translation: 'Test dua $index',
      )
    );
  }

  static List<FavoriteItem> generateMixedContent(int count) {
    final types = FavoriteContentType.values;
    return List.generate(count, (index) {
      final type = types[index % types.length];
      switch (type) {
        case FavoriteContentType.dua:
          return FavoriteItem.fromDua(
            duaId: 'mixed_dua_$index',
            title: 'دعاء مختلط $index',
            arabicText: 'نص $index',
          );
        case FavoriteContentType.athkar:
          return FavoriteItem.fromAthkar(
            athkarId: 'mixed_athkar_$index',
            text: 'ذكر مختلط $index',
          );
        // ... باقي الأنواع
        default:
          return generateDuas(1).first;
      }
    });
  }
}
```

### Test Utilities

```dart
// test/helpers/test_utilities.dart
class TestUtilities {
  static Future<void> waitForFavoriteUpdate() async {
    await Future.delayed(Duration(milliseconds: 100));
  }

  static void expectFavoriteInList(List<FavoriteItem> favorites, String itemId) {
    expect(
      favorites.any((item) => item.id == itemId),
      isTrue,
      reason: 'المفضلة $itemId غير موجودة في القائمة',
    );
  }

  static void expectFavoriteNotInList(List<FavoriteItem> favorites, String itemId) {
    expect(
      favorites.any((item) => item.id == itemId),
      isFalse,
      reason: 'المفضلة $itemId ما زالت موجودة في القائمة',
    );
  }
}
```

## 📊 تقرير تغطية الكود

### تشغيل اختبارات التغطية

```bash
# تشغيل جميع الاختبارات مع تقرير التغطية
flutter test --coverage

# إنشاء تقرير HTML
genhtml coverage/lcov.info -o coverage/html

# عرض التقرير
# افتح coverage/html/index.html في المتصفح
```

### أهداف التغطية

- **اختبارات الوحدة**: 90%+ تغطية
- **اختبارات الواجهة**: 80%+ تغطية  
- **اختبارات التكامل**: 70%+ تغطية
- **التغطية الإجمالية**: 85%+ تغطية

## ✅ قائمة مراجعة ما قبل الإنتاج

### الاختبارات الوظيفية
- [ ] جميع اختبارات الوحدة تمر بنجاح
- [ ] جميع اختبارات الواجهة تمر بنجاح
- [ ] جميع اختبارات التكامل تمر بنجاح
- [ ] اختبارات الأداء ضمن الحدود المقبولة

### الاختبارات غير الوظيفية
- [ ] اختبار الأمان وحماية البيانات
- [ ] اختبار الوصولية (Accessibility)
- [ ] اختبار على أجهزة مختلفة
- [ ] اختبار مع أحجام شاشة مختلفة

### اختبارات تجربة المستخدم
- [ ] سهولة الاستخدام
- [ ] وضوح الرسائل والتنبيهات
- [ ] سرعة الاستجابة
- [ ] تصميم متسق

### الاختبارات التقنية
- [ ] إدارة الذاكرة
- [ ] أداء البطارية
- [ ] التعامل مع حالات الشبكة المختلفة
- [ ] استقرار التطبيق

هذا الدليل يضمن جودة عالية ونظام مفضلة موثوق وآمن لتطبيقك.