# 🏗️ تحسين بنية الكود والمعمارية

## 1. إدارة الحالة المحسنة (Enhanced State Management)

### المشكلة الحالية:
- اختلاط الـ Business Logic مع الـ UI
- صعوبة في اختبار الكود
- تكرار في الكود

### الحل المقترح - MVVM Pattern:

```dart
// 📁 lib/features/prayer_times/
// ├── models/           # نماذج البيانات
// ├── services/         # خدمات البيانات
// ├── viewmodels/       # منطق العرض
// ├── views/            # واجهات المستخدم
// └── widgets/          # مكونات قابلة للإعادة

// ViewModel مثال
class PrayerTimesViewModel extends ChangeNotifier {
  final PrayerTimesService _service;
  
  // State
  PrayerTimesState _state = PrayerTimesState.loading();
  PrayerTimesState get state => _state;
  
  PrayerTimesViewModel(this._service);
  
  // Actions
  Future<void> loadPrayerTimes() async {
    _updateState(PrayerTimesState.loading());
    
    try {
      final times = await _service.getPrayerTimes();
      _updateState(PrayerTimesState.loaded(times));
    } catch (e) {
      _updateState(PrayerTimesState.error(e.toString()));
    }
  }
  
  Future<void> refreshLocation() async {
    _updateState(state.copyWith(isRefreshing: true));
    
    try {
      await _service.updateLocation();
      await loadPrayerTimes();
    } catch (e) {
      _updateState(state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }
  
  void _updateState(PrayerTimesState newState) {
    _state = newState;
    notifyListeners();
  }
}

// State Class
class PrayerTimesState {
  final bool isLoading;
  final bool isRefreshing;
  final List<PrayerTime>? prayerTimes;
  final String? error;
  
  const PrayerTimesState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.prayerTimes,
    this.error,
  });
  
  factory PrayerTimesState.loading() =>
      const PrayerTimesState(isLoading: true);
      
  factory PrayerTimesState.loaded(List<PrayerTime> times) =>
      PrayerTimesState(prayerTimes: times);
      
  factory PrayerTimesState.error(String message) =>
      PrayerTimesState(error: message);
      
  PrayerTimesState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<PrayerTime>? prayerTimes,
    String? error,
  }) {
    return PrayerTimesState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      error: error ?? this.error,
    );
  }
}
```

## 2. Dependency Injection المحسن

### تحسين ServiceLocator:

```dart
// lib/app/di/injection_container.dart
class InjectionContainer {
  static final GetIt _getIt = GetIt.instance;
  static GetIt get instance => _getIt;
  
  static Future<void> init() async {
    // Core Services
    _getIt.registerLazySingleton<StorageService>(
      () => StorageServiceImpl(),
    );
    
    _getIt.registerLazySingleton<NetworkService>(
      () => NetworkServiceImpl(),
    );
    
    // Feature Services
    _getIt.registerLazySingleton<PrayerTimesService>(
      () => PrayerTimesServiceImpl(_getIt<StorageService>()),
    );
    
    // ViewModels
    _getIt.registerFactory<PrayerTimesViewModel>(
      () => PrayerTimesViewModel(_getIt<PrayerTimesService>()),
    );
  }
  
  // Helper methods
  static T get<T extends Object>() => _getIt.get<T>();
  
  static void registerSingleton<T extends Object>(T instance) =>
      _getIt.registerSingleton<T>(instance);
      
  static void registerFactory<T extends Object>(T Function() factory) =>
      _getIt.registerFactory<T>(factory);
}
```

## 3. Repository Pattern للبيانات

```dart
// lib/core/data/repositories/prayer_repository.dart
abstract class PrayerRepository {
  Future<List<PrayerTime>> getPrayerTimes(Location location);
  Future<void> cachePrayerTimes(List<PrayerTime> times);
  Stream<List<PrayerTime>> watchPrayerTimes();
}

class PrayerRepositoryImpl implements PrayerRepository {
  final PrayerApiDataSource _apiSource;
  final PrayerLocalDataSource _localSource;
  final NetworkInfo _networkInfo;
  
  PrayerRepositoryImpl({
    required PrayerApiDataSource apiSource,
    required PrayerLocalDataSource localSource,
    required NetworkInfo networkInfo,
  }) : _apiSource = apiSource,
       _localSource = localSource,
       _networkInfo = networkInfo;
  
  @override
  Future<List<PrayerTime>> getPrayerTimes(Location location) async {
    if (await _networkInfo.isConnected) {
      try {
        final remoteTimes = await _apiSource.getPrayerTimes(location);
        await _localSource.cachePrayerTimes(remoteTimes);
        return remoteTimes;
      } catch (e) {
        // Fallback to cached data
        return await _localSource.getCachedPrayerTimes();
      }
    } else {
      return await _localSource.getCachedPrayerTimes();
    }
  }
  
  @override
  Stream<List<PrayerTime>> watchPrayerTimes() {
    return _localSource.watchPrayerTimes();
  }
}
```

## 4. Error Handling المحسن

```dart
// lib/core/error/app_error.dart
abstract class AppError {
  final String message;
  final String? code;
  
  const AppError(this.message, [this.code]);
}

class NetworkError extends AppError {
  const NetworkError([String? message]) 
      : super(message ?? 'خطأ في الشبكة', 'NETWORK_ERROR');
}

class CacheError extends AppError {
  const CacheError([String? message])
      : super(message ?? 'خطأ في التخزين المؤقت', 'CACHE_ERROR');
}

class LocationError extends AppError {
  const LocationError([String? message])
      : super(message ?? 'خطأ في تحديد الموقع', 'LOCATION_ERROR');
}

// Error Handler
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AppError) {
      return error.message;
    } else if (error is SocketException) {
      return 'لا يوجد اتصال بالإنترنت';
    } else if (error is TimeoutException) {
      return 'انتهت مهلة الاتصال';
    } else {
      return 'حدث خطأ غير متوقع';
    }
  }
  
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    // Log to analytics/crashlytics
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
}
```

## 5. Generic Widgets للإعادة الاستخدام

```dart
// lib/app/themes/widgets/common/async_widget.dart
class AsyncWidget<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) dataBuilder;
  final Widget? loadingWidget;
  final Widget Function(String error)? errorBuilder;
  
  const AsyncWidget({
    super.key,
    required this.future,
    required this.dataBuilder,
    this.loadingWidget,
    this.errorBuilder,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const AppLoading.circular();
        }
        
        if (snapshot.hasError) {
          final errorMessage = ErrorHandler.getErrorMessage(snapshot.error);
          return errorBuilder?.call(errorMessage) ?? 
                 AppErrorWidget(message: errorMessage);
        }
        
        if (snapshot.hasData) {
          return dataBuilder(snapshot.data as T);
        }
        
        return const AppEmptyState.noData();
      },
    );
  }
}

// الاستخدام
AsyncWidget<List<PrayerTime>>(
  future: prayerService.getPrayerTimes(),
  dataBuilder: (times) => PrayerTimesList(times: times),
  loadingWidget: const AppLoading.shimmer(),
  errorBuilder: (error) => AppErrorWidget(
    message: error,
    onRetry: () => setState(() {}),
  ),
)
```

## 6. Feature-Based Folder Structure

```
lib/
├── app/                    # تكوين التطبيق
│   ├── di/                # Dependency Injection
│   ├── routes/            # التوجيه
│   └── themes/            # الثيمات والألوان
│
├── core/                  # الوظائف الأساسية
│   ├── data/              # قواعد البيانات والـ APIs
│   ├── error/             # معالجة الأخطاء
│   ├── network/           # إدارة الشبكة
│   └── utils/             # الأدوات المساعدة
│
├── features/              # الميزات
│   ├── prayer_times/      
│   │   ├── data/         # DataSources & Repositories
│   │   ├── domain/       # Entities & Use Cases
│   │   └── presentation/ # ViewModels & UI
│   │
│   ├── athkar/
│   ├── qibla/
│   └── settings/
│
└── shared/               # المكونات المشتركة
    ├── widgets/          # Widgets قابلة للإعادة
    └── extensions/       # Extensions مساعدة
```

## 7. Use Cases Pattern

```dart
// lib/features/prayer_times/domain/use_cases/get_prayer_times.dart
class GetPrayerTimesUseCase {
  final PrayerRepository repository;
  
  GetPrayerTimesUseCase(this.repository);
  
  Future<Either<AppError, List<PrayerTime>>> call(Location location) async {
    try {
      final times = await repository.getPrayerTimes(location);
      return Right(times);
    } on AppError catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownError(e.toString()));
    }
  }
}

// في ViewModel
class PrayerTimesViewModel extends ChangeNotifier {
  final GetPrayerTimesUseCase _getPrayerTimes;
  
  Future<void> loadPrayerTimes() async {
    _updateState(PrayerTimesState.loading());
    
    final result = await _getPrayerTimes(currentLocation);
    
    result.fold(
      (error) => _updateState(PrayerTimesState.error(error.message)),
      (times) => _updateState(PrayerTimesState.loaded(times)),
    );
  }
}
```

## الخلاصة:

1. **فصل Business Logic عن UI**
2. **استخدام Repository Pattern للبيانات**
3. **تطبيق MVVM أو Clean Architecture**
4. **إنشاء Generic Widgets قابلة للإعادة**
5. **معالجة أخطاء شاملة ومنظمة**
6. **تنظيم المجلدات حسب الميزات**
7. **استخدام Use Cases للعمليات المعقدة**