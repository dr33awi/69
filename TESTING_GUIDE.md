# 🧪 دليل الاختبارات الشامل

## 1. Unit Tests للمنطق الأساسي

### اختبار خدمات الصلاة:

```dart
// test/features/prayer_times/services/prayer_times_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([StorageService, LocationService])
import 'prayer_times_service_test.mocks.dart';

void main() {
  group('PrayerTimesService Tests', () {
    late PrayerTimesService service;
    late MockStorageService mockStorage;
    late MockLocationService mockLocation;
    
    setUp(() {
      mockStorage = MockStorageService();
      mockLocation = MockLocationService();
      service = PrayerTimesServiceImpl(
        storage: mockStorage,
        locationService: mockLocation,
      );
    });
    
    group('getPrayerTimes', () {
      test('should return cached prayer times when available', () async {
        // Arrange
        final cachedTimes = [
          PrayerTime(name: 'الفجر', time: DateTime(2023, 1, 1, 5, 30)),
          PrayerTime(name: 'الظهر', time: DateTime(2023, 1, 1, 12, 15)),
        ];
        
        when(mockStorage.getCachedPrayerTimes(any))
            .thenAnswer((_) async => cachedTimes);
        
        // Act
        final result = await service.getPrayerTimes();
        
        // Assert
        expect(result, equals(cachedTimes));
        verify(mockStorage.getCachedPrayerTimes(any)).called(1);
      });
      
      test('should calculate new prayer times when no cache', () async {
        // Arrange
        final location = PrayerLocation(
          latitude: 24.7136, 
          longitude: 46.6753, 
          city: 'الرياض'
        );
        
        when(mockStorage.getCachedPrayerTimes(any))
            .thenAnswer((_) async => null);
        when(mockLocation.getCurrentLocation())
            .thenAnswer((_) async => location);
        
        // Act
        final result = await service.getPrayerTimes();
        
        // Assert
        expect(result, isNotEmpty);
        expect(result.length, equals(5)); // خمس صلوات
        
        // التحقق من ترتيب الصلوات
        expect(result[0].name, equals('الفجر'));
        expect(result[1].name, equals('الظهر'));
        expect(result[2].name, equals('العصر'));
        expect(result[3].name, equals('المغرب'));
        expect(result[4].name, equals('العشاء'));
        
        // التحقق من صحة الأوقات
        expect(result[0].time.hour, lessThan(result[1].time.hour));
        expect(result[1].time.hour, lessThan(result[2].time.hour));
      });
      
      test('should handle location error gracefully', () async {
        // Arrange
        when(mockStorage.getCachedPrayerTimes(any))
            .thenAnswer((_) async => null);
        when(mockLocation.getCurrentLocation())
            .thenThrow(const LocationError('GPS not available'));
        
        // Act & Assert
        expect(
          () async => await service.getPrayerTimes(),
          throwsA(isA<LocationError>()),
        );
      });
    });
    
    group('getNextPrayer', () {
      test('should return correct next prayer', () {
        // Arrange
        final now = DateTime(2023, 1, 1, 10, 0); // 10 صباحاً
        final prayers = [
          PrayerTime(name: 'الفجر', time: DateTime(2023, 1, 1, 5, 30)),
          PrayerTime(name: 'الظهر', time: DateTime(2023, 1, 1, 12, 15)),
          PrayerTime(name: 'العصر', time: DateTime(2023, 1, 1, 15, 45)),
        ];
        
        // Act
        final nextPrayer = service.getNextPrayer(prayers, currentTime: now);
        
        // Assert
        expect(nextPrayer?.name, equals('الظهر'));
      });
      
      test('should return null when no next prayer today', () {
        // Arrange
        final now = DateTime(2023, 1, 1, 23, 0); // 11 مساءً
        final prayers = [
          PrayerTime(name: 'الفجر', time: DateTime(2023, 1, 1, 5, 30)),
          PrayerTime(name: 'العشاء', time: DateTime(2023, 1, 1, 19, 30)),
        ];
        
        // Act
        final nextPrayer = service.getNextPrayer(prayers, currentTime: now);
        
        // Assert
        expect(nextPrayer, isNull);
      });
    });
  });
}
```

### اختبار نماذج البيانات:

```dart
// test/features/asma_allah/models/asma_allah_model_test.dart
void main() {
  group('AsmaAllahModel Tests', () {
    test('should create model from JSON correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'name': 'الله',
        'meaning': 'الإله الواحد الأحد',
        'explanation': 'شرح مفصل للاسم...',
        'reference': 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      };
      
      // Act
      final model = AsmaAllahModel.fromJson(json);
      
      // Assert
      expect(model.id, equals(1));
      expect(model.name, equals('الله'));
      expect(model.meaning, equals('الإله الواحد الأحد'));
      expect(model.explanation, equals('شرح مفصل للاسم...'));
      expect(model.reference, equals('قُلْ هُوَ اللَّهُ أَحَدٌ'));
    });
    
    test('should handle missing optional fields', () {
      // Arrange
      final json = {
        'id': 2,
        'name': 'الرحمن',
        'meaning': 'الرحيم',
        'explanation': 'شرح...',
        // reference مفقود
      };
      
      // Act
      final model = AsmaAllahModel.fromJson(json);
      
      // Assert
      expect(model.reference, isNull);
      expect(model.name, equals('الرحمن'));
    });
    
    test('should convert to JSON correctly', () {
      // Arrange
      const model = AsmaAllahModel(
        id: 1,
        name: 'الله',
        meaning: 'الإله الواحد',
        explanation: 'شرح...',
        reference: 'آية كريمة',
      );
      
      // Act
      final json = model.toJson();
      
      // Assert
      expect(json['id'], equals(1));
      expect(json['name'], equals('الله'));
      expect(json['reference'], equals('آية كريمة'));
    });
    
    test('should compare models correctly', () {
      // Arrange
      const model1 = AsmaAllahModel(
        id: 1, name: 'الله', meaning: 'test', explanation: 'test'
      );
      const model2 = AsmaAllahModel(
        id: 1, name: 'الله', meaning: 'test', explanation: 'test'
      );
      const model3 = AsmaAllahModel(
        id: 2, name: 'الرحمن', meaning: 'test', explanation: 'test'
      );
      
      // Assert
      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
      expect(model1.hashCode, equals(model2.hashCode));
    });
  });
}
```

## 2. Widget Tests

### اختبار الواجهات:

```dart
// test/features/prayer_times/widgets/prayer_time_card_test.dart
void main() {
  group('PrayerTimeCard Widget Tests', () {
    testWidgets('should display prayer information correctly', (tester) async {
      // Arrange
      final prayer = PrayerTime(
        name: 'الفجر',
        time: DateTime(2023, 1, 1, 5, 30),
        isNext: true,
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerTimeCard(prayer: prayer),
          ),
        ),
      );
      
      // Assert
      expect(find.text('الفجر'), findsOneWidget);
      expect(find.text('05:30'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    });
    
    testWidgets('should handle tap correctly', (tester) async {
      // Arrange
      bool wasTapped = false;
      final prayer = PrayerTime(name: 'الظهر', time: DateTime.now());
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerTimeCard(
              prayer: prayer,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.byType(PrayerTimeCard));
      
      // Assert
      expect(wasTapped, isTrue);
    });
    
    testWidgets('should show next prayer indicator', (tester) async {
      // Arrange
      final prayer = PrayerTime(
        name: 'العصر',
        time: DateTime.now(),
        isNext: true,
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerTimeCard(prayer: prayer),
          ),
        ),
      );
      
      // Assert
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.text('الصلاة القادمة'), findsOneWidget);
    });
  });
}
```

### اختبار الصفحات:

```dart
// test/features/home/screens/home_screen_test.dart
void main() {
  group('HomeScreen Widget Tests', () {
    late MockPrayerTimesService mockPrayerService;
    
    setUp(() {
      mockPrayerService = MockPrayerTimesService();
      getIt.registerSingleton<PrayerTimesService>(mockPrayerService);
    });
    
    tearDown(() {
      getIt.reset();
    });
    
    testWidgets('should display loading state initially', (tester) async {
      // Arrange
      when(mockPrayerService.prayerTimesStream)
          .thenAnswer((_) => const Stream.empty());
      
      // Act
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen()),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('should display prayer times when loaded', (tester) async {
      // Arrange
      final prayers = [
        PrayerTime(name: 'الفجر', time: DateTime(2023, 1, 1, 5, 30)),
        PrayerTime(name: 'الظهر', time: DateTime(2023, 1, 1, 12, 15)),
      ];
      
      when(mockPrayerService.prayerTimesStream)
          .thenAnswer((_) => Stream.value(prayers));
      
      // Act
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen()),
      );
      await tester.pump(); // انتظار تحديث الـ stream
      
      // Assert
      expect(find.text('الفجر'), findsOneWidget);
      expect(find.text('الظهر'), findsOneWidget);
    });
    
    testWidgets('should handle refresh correctly', (tester) async {
      // Arrange
      when(mockPrayerService.refresh())
          .thenAnswer((_) async => {});
      when(mockPrayerService.prayerTimesStream)
          .thenAnswer((_) => Stream.value([]));
      
      // Act
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen()),
      );
      
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      
      // Assert
      verify(mockPrayerService.refresh()).called(1);
    });
  });
}
```

## 3. Integration Tests

### اختبار التدفق الكامل:

```dart
// integration_test/app_test.dart
void main() {
  group('App Integration Tests', () {
    testWidgets('complete prayer times flow', (tester) async {
      // بدء التطبيق
      app.main();
      await tester.pumpAndSettle();
      
      // التحقق من وجود الشاشة الرئيسية
      expect(find.byType(HomeScreen), findsOneWidget);
      
      // الانتقال لصفحة مواقيت الصلاة
      await tester.tap(find.text('مواقيت الصلاة'));
      await tester.pumpAndSettle();
      
      // التحقق من عرض المواقيت
      expect(find.byType(PrayerTimesScreen), findsOneWidget);
      expect(find.text('الفجر'), findsOneWidget);
      
      // اختبار التحديث
      await tester.drag(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
      
      // التحقق من تحديث البيانات
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
    
    testWidgets('asma allah navigation and search', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // الانتقال لصفحة أسماء الله الحسنى
      await tester.tap(find.text('أسماء الله الحسنى'));
      await tester.pumpAndSettle();
      
      // التحقق من عرض القائمة
      expect(find.byType(AsmaAllahScreen), findsOneWidget);
      expect(find.text('الله'), findsOneWidget);
      
      // اختبار البحث
      await tester.enterText(find.byType(TextField), 'الرحمن');
      await tester.pumpAndSettle();
      
      // التحقق من نتائج البحث
      expect(find.text('الرحمن'), findsWidgets);
      expect(find.text('الله'), findsNothing);
      
      // اختبار فتح التفاصيل
      await tester.tap(find.text('الرحمن').first);
      await tester.pumpAndSettle();
      
      expect(find.byType(AsmaDetailScreen), findsOneWidget);
    });
  });
}
```

## 4. Golden Tests للـ UI

### اختبار الشكل البصري:

```dart
// test/golden/prayer_times_golden_test.dart
void main() {
  group('Prayer Times Golden Tests', () {
    testWidgets('prayer time card light theme', (tester) async {
      final prayer = PrayerTime(
        name: 'الفجر',
        time: DateTime(2023, 1, 1, 5, 30),
        isNext: true,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(prayer: prayer),
          ),
        ),
      );
      
      await expectLater(
        find.byType(PrayerTimeCard),
        matchesGoldenFile('prayer_time_card_light.png'),
      );
    });
    
    testWidgets('prayer time card dark theme', (tester) async {
      final prayer = PrayerTime(
        name: 'الفجر',
        time: DateTime(2023, 1, 1, 5, 30),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PrayerTimeCard(prayer: prayer),
          ),
        ),
      );
      
      await expectLater(
        find.byType(PrayerTimeCard),
        matchesGoldenFile('prayer_time_card_dark.png'),
      );
    });
  });
}
```

## 5. Performance Tests

### اختبار الأداء:

```dart
// test/performance/large_list_test.dart
void main() {
  group('Performance Tests', () {
    testWidgets('large asma allah list performance', (tester) async {
      // إنشاء قائمة كبيرة
      final largeList = List.generate(1000, (index) => 
        AsmaAllahModel(
          id: index,
          name: 'اسم $index',
          meaning: 'معنى $index',
          explanation: 'شرح طويل للاسم رقم $index...',
        ),
      );
      
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: largeList.length,
              itemBuilder: (context, index) => 
                  AsmaAllahCard(item: largeList[index]),
            ),
          ),
        ),
      );
      
      stopwatch.stop();
      
      // التحقق من أن الرندرنغ تم في وقت معقول
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      
      // اختبار التمرير
      await tester.fling(
        find.byType(ListView),
        const Offset(0, -500),
        1000,
      );
      await tester.pumpAndSettle();
      
      // التحقق من عدم وجود إطارات مفقودة
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
```

## 6. Test Configuration

### إعداد الاختبارات:

```dart
// test/helpers/test_helper.dart
class TestHelper {
  static void setupMockServices() {
    // إعداد GetIt للاختبارات
    getIt.reset();
    
    getIt.registerSingleton<StorageService>(MockStorageService());
    getIt.registerSingleton<LocationService>(MockLocationService());
    getIt.registerSingleton<PrayerTimesService>(MockPrayerTimesService());
  }
  
  static Future<void> pumpAppWithMocks(
    WidgetTester tester,
    Widget widget,
  ) async {
    setupMockServices();
    
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [const Locale('ar')],
        home: widget,
      ),
    );
  }
  
  static PrayerTime createMockPrayer({
    required String name,
    DateTime? time,
    bool isNext = false,
  }) {
    return PrayerTime(
      name: name,
      time: time ?? DateTime.now(),
      isNext: isNext,
    );
  }
}

// test/test_main.dart - نقطة دخول للاختبارات
void main() {
  setUpAll(() {
    // إعداد عام لجميع الاختبارات
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // تعطيل الشبكة للاختبارات
    HttpOverrides.global = MockHttpOverrides();
  });
  
  tearDownAll(() {
    // تنظيف عام بعد الاختبارات
    getIt.reset();
  });
}
```

## الخلاصة:

1. **Unit Tests للمنطق الأساسي والخدمات**
2. **Widget Tests للواجهات والمكونات**
3. **Integration Tests للتدفقات الكاملة**
4. **Golden Tests للتحقق من الشكل البصري**
5. **Performance Tests لضمان الأداء**
6. **إعداد شامل للـ Mocks والـ Test Helpers**
7. **تغطية شاملة لجميع الحالات**