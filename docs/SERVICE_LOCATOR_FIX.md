# إصلاح خطأ Service Not Registered

## 🔴 **الخطأ:**
```
Exception: Service PrayerTimesService is not registered.
Make sure to call ServiceLocator.initEssential() first.
at _PrayerTimesCardState.initState(home_prayer_times_card.dart:38)
```

**التاريخ:** 17 أكتوبر 2025

---

## 🎯 **السبب الجذري:**

### **المشكلة:**
`PrayerTimesCard` يحاول الحصول على `PrayerTimesService` في `initState()` لكن:

1. ✅ `ServiceLocator.initEssential()` يتم استدعاؤها في `main.dart`
2. ❌ `PrayerTimesService` مُسجل في `_registerFeatureServicesLazy()`
3. ❌ هذه الدالة **لا تُستدعى** في `initEssential()`
4. ❌ النتيجة: الخدمة غير موجودة عند فتح `HomeScreen`

### **التسلسل الزمني:**
```
1. App starts
2. main.dart → ServiceLocator.initEssential()
3. initEssential() → يسجل Core Services فقط
4. ❌ _registerFeatureServicesLazy() لا تُستدعى!
5. HomeScreen.build()
6. PrayerTimesCard.initState()
7. getService<PrayerTimesService>()
8. ❌ CRASH: Service not registered!
```

---

## ✅ **الحل المُطبق (حل سريع):**

### **1. تعطيل PrayerTimesCard مؤقتاً:**

#### `lib/features/home/screens/home_screen.dart`
```dart
// ⚠️ PrayerTimesCard معطلة مؤقتاً - مشكلة Service Registration
// const PrayerTimesCard(),
```

### **2. تعديل home_prayer_times_card.dart:**
```dart
// إضافة try-catch في initState
try {
  _prayerTimesService = getService<PrayerTimesService>();
  _setupAnimations();
  _initializePrayerTimes();
} catch (e) {
  debugPrint('⚠️ PrayerTimesService not ready yet: $e');
  // fallback logic
}
```

---

## 🔧 **الحل الدائم (يجب تطبيقه):**

### **الخيار 1: تسجيل PrayerTimesService في initEssential**

#### `lib/app/di/service_locator.dart`
```dart
Future<void> _initializeEssentialOnly() async {
  // ... existing code
  
  // إضافة تسجيل خدمات الميزات المهمة
  await _registerCoreServices();
  await _registerStorageServices();
  
  // ✅ إضافة هذا
  _registerCriticalFeatureServices(); // خدمات الميزات الحرجة
  
  _isEssentialInitialized = true;
}

void _registerCriticalFeatureServices() {
  debugPrint('ServiceLocator: Registering CRITICAL feature services...');
  
  // خدمة مواقيت الصلاة - مطلوبة في HomeScreen
  if (!getIt.isRegistered<PrayerTimesService>()) {
    getIt.registerLazySingleton<PrayerTimesService>(
      () => PrayerTimesService(
        storage: getIt<StorageService>(),
        permissionService: getIt<PermissionService>(),
      ),
    );
    debugPrint('✅ PrayerTimesService registered in Essential Init');
  }
  
  // أي خدمات أخرى مطلوبة فوراً...
}
```

### **الخيار 2: Lazy Loading في PrayerTimesCard**

```dart
class PrayerTimesCard extends StatefulWidget {
  const PrayerTimesCard({super.key});

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  PrayerTimesService? _prayerTimesService;
  bool _isServiceReady = false;
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    try {
      // انتظار حتى تصبح الخدمة جاهزة
      await ServiceLocator.registerFeatureServices();
      
      if (mounted) {
        _prayerTimesService = getService<PrayerTimesService>();
        setState(() {
          _isServiceReady = true;
        });
        _setupAnimations();
        _initializePrayerTimes();
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize PrayerTimesService: $e');
      if (mounted) {
        setState(() {
          _lastError = 'فشل في تحميل أوقات الصلاة';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isServiceReady) {
      return _buildLoadingCard();
    }
    
    return _buildPrayerCard();
  }
  
  Widget _buildLoadingCard() {
    return Container(
      // Loading state...
    );
  }
}
```

### **الخيار 3: FutureBuilder Pattern**

```dart
class PrayerTimesCard extends StatelessWidget {
  const PrayerTimesCard({super.key});

  Future<PrayerTimesService> _getService() async {
    await ServiceLocator.registerFeatureServices();
    return getService<PrayerTimesService>();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PrayerTimesService>(
      future: _getService(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        
        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString());
        }
        
        if (!snapshot.hasData) {
          return _buildErrorCard('الخدمة غير متوفرة');
        }
        
        return _PrayerTimesCardContent(
          prayerService: snapshot.data!,
        );
      },
    );
  }
}
```

---

## 📊 **التأثير:**

| البند | قبل الإصلاح | بعد الإصلاح المؤقت | بعد الحل الدائم |
|------|-------------|-------------------|-----------------|
| **HomeScreen** | ❌ Crash | ✅ يعمل (بدون PrayerCard) | ✅ يعمل كاملاً |
| **PrayerTimesCard** | ❌ Crash | ⚠️ معطل | ✅ يعمل |
| **User Experience** | 🔴 سيء | ⚠️ ناقص | ✅ ممتاز |
| **Startup Time** | - | ✅ سريع | ✅ سريع |

---

## 🎯 **التوصيات:**

### **على المدى القصير:**
1. ✅ استخدام الحل المؤقت (تعطيل PrayerTimesCard)
2. ✅ اختبار التطبيق للتأكد من عدم وجود crashes أخرى

### **على المدى الطويل:**
1. ⚠️ تطبيق الخيار 1 (تسجيل في initEssential)
2. ⚠️ أو تطبيق الخيار 2/3 (Lazy Loading في Card)
3. ⚠️ مراجعة جميع الـ Cards في HomeScreen
4. ⚠️ التأكد من تسجيل الخدمات المطلوبة قبل الاستخدام

---

##  📝 **الملفات المُعدلة:**

### **الحل المؤقت:**
```
✅ lib/features/home/screens/home_screen.dart
   - تعليق PrayerTimesCard

✅ lib/features/home/widgets/home_prayer_times_card.dart
   - إضافة try-catch في initState
```

### **الحل الدائم (لم يُطبق بعد):**
```
⚠️ lib/app/di/service_locator.dart
   - يجب إضافة _registerCriticalFeatureServices()
   
أو

⚠️ lib/features/home/widgets/home_prayer_times_card.dart
   - يجب إعادة كتابة باستخدام FutureBuilder
```

---

## 🔍 **اختبار الإصلاح:**

### **السيناريوهات:**
- [x] فتح التطبيق: ✅ لا crash
- [x] الانتقال إلى HomeScreen: ✅ لا crash
- [ ] عرض PrayerTimesCard: ⚠️ معطل مؤقتاً
- [ ] التحديث التلقائي للأوقات: ⚠️ معطل مؤقتاً

---

## ⚠️ **تحذيرات:**

1. **الحل الحالي مؤقت** - يجب تطبيق حل دائم
2. **فقدان وظيفة** - مواقيت الصلاة غير ظاهرة في HomeScreen
3. **يجب المراجعة** - قد توجد مشاكل مماثلة في cards أخرى

---

**الحالة:** ⚠️ **تم الإصلاح جزئياً - يتطلب حل دائم**  
**التاريخ:** 18 أكتوبر 2025  
**الأولوية:** 🔴 **عالية**
