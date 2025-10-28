# 🔄 دليل اختبار ميزة التحديث الإجباري (Force Update)

## ✅ التعديلات المُطبّقة

تم إصلاح المشكلة بإضافة `AppStatusMonitor` إلى التطبيق في `lib/main.dart`:

```dart
builder: (context, child) {
  return AppStatusMonitor(
    configManager: _configManager,
    child: PermissionCheckWidget(
      // ... باقي الكود
    ),
  );
}
```

---

## 📋 المتطلبات

### في Firebase Remote Config

يجب أن يكون لديك هذه المعاملات:

| المعامل (Key) | النوع | القيمة للاختبار |
|--------------|-------|-----------------|
| `force_update` | Boolean | `true` |
| `app_version` | String | `2.0.0` (أو أي نسخة أعلى من نسخة التطبيق الحالية) |
| `update_url_android` | String | رابط تطبيقك في Google Play |
| `update_features_list` | JSON | قائمة الميزات الجديدة |

---

## 🧪 خطوات الاختبار

### 1️⃣ **تحديث Firebase Remote Config**

#### في Firebase Console:
1. اذهب إلى **Remote Config**
2. أضف/حدّث المعاملات التالية:

```
force_update = true (Boolean)
app_version = 2.0.0 (String)
update_url_android = https://play.google.com/store/apps/details?id=com.dhakarani1.app
```

#### مثال على `update_features_list` (JSON String):
```json
["تحسينات كبيرة في الأداء", "إضافة ميزات جديدة", "إصلاح الأخطاء الحرجة", "تحسين واجهة المستخدم"]
```

3. اضغط **Publish changes** (نشر التغييرات)

---

### 2️⃣ **اختبار التطبيق**

#### الطريقة الأولى - اختبار مباشر:

```dart
// في main.dart أو أي مكان للاختبار
Future<void> testForceUpdate() async {
  final remoteConfig = getIt<FirebaseRemoteConfigService>();
  
  // فرض تحديث
  await remoteConfig.refresh();
  
  print('Force Update: ${remoteConfig.isForceUpdateRequired}');
  print('Required Version: ${remoteConfig.requiredAppVersion}');
}
```

#### الطريقة الثانية - إعادة تشغيل التطبيق:

1. أغلق التطبيق تماماً
2. انتظر 10-30 ثانية
3. افتح التطبيق مرة أخرى
4. يجب أن تظهر شاشة التحديث الإجباري

---

### 3️⃣ **التحقق من الـ Logs**

ابحث عن هذه الرسائل في الـ Console:

```
✅ Firebase Services initialized
✅ [2/2] Advanced Firebase services initialized
✅ Config Manager ready
🔥 Force Update Required: true
📱 Current Version: 1.0.0
📱 Required Version: 2.0.0
```

---

## 🔍 استكشاف الأخطاء

### المشكلة: الشاشة لا تظهر

#### السبب المحتمل 1: القيم لم تُحدّث
**الحل:**
```dart
// في Debug Mode، Remote Config يُحدّث فوراً
// في Release Mode، قد يستغرق دقائق حسب الإعدادات

// لفرض التحديث الفوري:
await _remoteConfig.setConfigSettings(RemoteConfigSettings(
  fetchTimeout: const Duration(seconds: 10),
  minimumFetchInterval: Duration.zero, // ✅ تحديث فوري
));
```

#### السبب المحتمل 2: النسخة المطلوبة أقل من أو تساوي الحالية
**الحل:**
تأكد من أن `app_version` في Firebase أكبر من نسخة التطبيق في `pubspec.yaml`:

```yaml
# pubspec.yaml
version: 1.0.0+1  # النسخة الحالية

# Firebase Remote Config
app_version: 2.0.0  # ✅ يجب أن تكون أكبر
```

#### السبب المحتمل 3: المستخدم أقرّ بالتحديث سابقاً
**الحل:**
```dart
// مسح التخزين المحلي للسماح بإعادة الظهور
final storage = getIt<StorageService>();
await storage.remove('update_acknowledged_version');
```

---

## 🎯 سيناريوهات الاختبار

### سيناريو 1: التحديث الإجباري العادي
```
force_update = true
app_version = 2.0.0
النتيجة المتوقعة: تظهر شاشة ForceUpdateScreen
```

### سيناريو 2: وضع الصيانة له الأولوية
```
force_update = true
maintenance_mode = true
النتيجة المتوقعة: تظهر MaintenanceScreen (لها الأولوية)
```

### سيناريو 3: النسخة محدّثة
```
force_update = true
app_version = 1.0.0 (نفس نسخة التطبيق)
النتيجة المتوقعة: لا شيء يظهر (التطبيق محدّث)
```

### سيناريو 4: Force Update معطّل
```
force_update = false
app_version = 2.0.0
النتيجة المتوقعة: لا شيء يظهر (الميزة معطّلة)
```

---

## 🛠️ أدوات الاختبار السريع

### في Firebase Console:
1. استخدم **"In-app default values"** للاختبار السريع
2. استخدم **"Conditions"** لاستهداف مستخدمين محددين
3. استخدم **"Percentage rollout"** للنشر التدريجي

### في Android Studio / VS Code:
```dart
// إضافة زر اختبار مؤقت في الإعدادات
ElevatedButton(
  onPressed: () async {
    final config = getIt<RemoteConfigManager>();
    await config.refreshConfig();
    
    if (config.isForceUpdateRequired) {
      showDialog(
        context: context,
        builder: (context) => ForceUpdateScreen(),
      );
    }
  },
  child: Text('اختبار Force Update'),
)
```

---

## 📊 معلومات تقنية

### كيف يعمل النظام؟

```
┌─────────────────────────────────────────┐
│  1. App Start                           │
│     ↓                                   │
│  2. Firebase Remote Config Initialize   │
│     ↓                                   │
│  3. RemoteConfigManager Initialize      │
│     ↓                                   │
│  4. Check force_update = true?          │
│     ↓ (Yes)                            │
│  5. Compare Versions                    │
│     ↓ (Outdated)                       │
│  6. Check acknowledged?                 │
│     ↓ (No)                             │
│  7. AppStatusMonitor Shows Screen       │
│     ↓                                   │
│  8. ForceUpdateScreen Displayed         │
└─────────────────────────────────────────┘
```

### مقارنة النسخ (SemVer):
```dart
// 1.0.0 < 1.0.1 < 1.1.0 < 2.0.0

_compareVersions("1.0.0", "2.0.0") → -1 (يحتاج تحديث)
_compareVersions("2.0.0", "2.0.0") → 0  (محدّث)
_compareVersions("2.1.0", "2.0.0") → 1  (أحدث من المطلوب)
```

---

## ✅ Checklist للتأكد من عمل الميزة

- [ ] `AppStatusMonitor` مضاف في `main.dart`
- [ ] `force_update = true` في Firebase Remote Config
- [ ] `app_version` أكبر من نسخة التطبيق الحالية
- [ ] `update_url_android` يحتوي على رابط صحيح
- [ ] تم نشر التغييرات في Firebase Console
- [ ] تم إعادة تشغيل التطبيق للاختبار
- [ ] الـ Logs تظهر "Force Update Required: true"

---

## 📞 الدعم

إذا استمرت المشكلة:
1. تحقق من الـ Logs في Console
2. تأكد من أن Firebase مُهيأ بشكل صحيح
3. جرّب مسح الـ Cache: `flutter clean && flutter pub get`
4. تحقق من أن `google-services.json` محدّث

---

## 🎉 النتيجة المتوقعة

عند تفعيل الميزة بشكل صحيح، سيرى المستخدم:
- شاشة زرقاء جميلة مع أيقونة تحديث
- مقارنة بين النسخة الحالية والمطلوبة
- قائمة بميزات التحديث الجديد
- زر "تحديث التطبيق الآن" يفتح المتجر
- زر "إغلاق التطبيق" كخيار بديل
- لا يمكن الرجوع للخلف (PopScope: canPop: false)

---

**تم إنشاء هذا الدليل في:** 28 أكتوبر 2025
**آخر تحديث:** 28 أكتوبر 2025
