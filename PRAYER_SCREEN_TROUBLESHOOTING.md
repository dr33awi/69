# 🚨 حل مشاكل prayer_time_screen

## 📋 المشاكل المُحتملة والحلول

### 1️⃣ مشكلة تحميل البيانات
إذا كانت الشاشة فارغة أو تظهر رسالة خطأ:

```dart
// تأكد من أن الموقع مفعل
// تأكد من اتصال الإنترنت
// تحقق من إعدادات الأذونات
```

### 2️⃣ مشكلة التخطيط والعرض
إذا كانت العناصر متداخلة أو غير متناسقة:

```dart
// تحقق من flutter_screenutil
// تأكد من responsive values
// تحقق من SafeArea
```

### 3️⃣ مشكلة الألوان والثيم
إذا كانت الألوان غير صحيحة:

```dart
// تحقق من AppTheme
// تأكد من context.primaryColor
// تحقق من Dark/Light mode
```

## 🛠️ خطوات التشخيص

### الخطوة 1: فحص console للأخطاء
```bash
flutter run --debug
# ابحث عن رسائل خطأ في console
```

### الخطوة 2: اختبار شاشة التشخيص
```dart
// استخدم PrayerScreenDebugInfo لفحص القيم
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const PrayerScreenDebugInfo(),
));
```

### الخطوة 3: فحص البيانات
```dart
// تحقق من PrayerTimesService
final service = getIt<PrayerTimesService>();
print('Current Location: ${service.currentLocation}');
print('Prayer Times: ${service.prayerTimesStream}');
```

## 🔧 حلول سريعة

### إعادة تعيين الموقع:
```dart
await _prayerService.getCurrentLocation(forceUpdate: true);
```

### تحديث المواقيت:
```dart
await _prayerService.updatePrayerTimes();
```

### إعادة تشغيل التطبيق:
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 اختبار على أجهزة مختلفة

### الشاشات الصغيرة (< 700px):
- تحقق من `isSmallScreen` logic
- تأكد من تصغير العناصر

### الشاشات الكبيرة (> 900px):
- تحقق من tablet layout
- تأكد من استخدام المساحة بفعالية

### وضع الليل/النهار:
- تحقق من context.isDarkMode
- تأكد من ألوان الثيم

## 🎯 مؤشرات المشكلة

### إذا كانت الشاشة فارغة:
❌ مشكلة في تحميل البيانات
✅ تحقق من الأذونات والموقع

### إذا كانت العناصر متداخلة:
❌ مشكلة في flutter_screenutil
✅ تحقق من القيم المتجاوبة

### إذا كانت الألوان خاطئة:
❌ مشكلة في الثيم
✅ تحقق من AppTheme

### إذا كان التطبيق بطيء:
❌ مشكلة في الأداء
✅ تحقق من استخدام const widgets

## 📞 المساعدة
إذا استمرت المشكلة، قم بما يلي:

1. ✅ تشغيل شاشة التشخيص
2. ✅ فحص console للأخطاء
3. ✅ أخذ screenshot للمشكلة
4. ✅ ذكر نوع الجهاز والشاشة
5. ✅ ذكر خطوات إعادة إنتاج المشكلة

---
**تم إنشاء هذا التقرير**: ${DateTime.now().toString().split('.')[0]}
**الحالة**: جاهز للتشخيص ✅