# Force Update Dialog - دليل الاستخدام

## نظرة عامة
نظام Force Update Dialog يسمح لك بإجبار المستخدمين على تحديث التطبيق قبل الاستمرار في الاستخدام، مع التحكم الكامل من Firebase Remote Config.

## الملفات المنشأة
1. `force_update_dialog.dart` - الـ Dialog نفسه
2. `force_update_checker.dart` - نظام الفحص التلقائي

## إعدادات Firebase Remote Config

أضف هذه المفاتيح في Firebase Console:

### 1. force_update (Boolean)
- `true` - لتفعيل Force Update
- `false` - لتعطيل Force Update

### 2. app_version (String)
- مثال: `"1.2.0"`
- الإصدار المطلوب للتطبيق

### 3. update_url_android (String)
- مثال: `"https://play.google.com/store/apps/details?id=com.dhakarani1.app"`
- رابط تحديث التطبيق على Google Play Store

### 4. update_features_list (JSON)
قائمة بمميزات التحديث الجديد (اختياري):
```json
[
  "إصلاح مشكلة الإشعارات",
  "تحسين أداء التطبيق",
  "إضافة ميزات جديدة",
  "تحديث التصميم"
]
```

## طرق الاستخدام

### الطريقة 1: التحقق التلقائي (موصى بها)

في `main.dart`، أضف الـ widget حول التطبيق:

```dart
import 'core/firebase/widgets/force_update_checker.dart';

class AthkarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ForceUpdateChecker.widget(
        child: HomeScreen(),
      ),
    );
  }
}
```

### الطريقة 2: التحقق اليدوي

في أي شاشة أو عند أي حدث:

```dart
import 'core/firebase/widgets/force_update_checker.dart';

// في initState أو عند الحاجة
await ForceUpdateChecker.check(context);
```

### الطريقة 3: عرض الـ Dialog مباشرة

```dart
import 'core/firebase/widgets/force_update_dialog.dart';

await ForceUpdateDialog.show(
  context,
  currentVersion: '1.0.0',
  requiredVersion: '1.2.0',
);
```

## مثال كامل للاستخدام في main.dart

```dart
import 'package:flutter/material.dart';
import 'core/firebase/widgets/force_update_checker.dart';

class _AthkarAppState extends State<AthkarApp> {
  @override
  void initState() {
    super.initState();
    
    // التحقق من Force Update بعد بدء التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ForceUpdateChecker.check(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
```

## كيفية عمل النظام

1. **التحقق من Remote Config**: يفحص إذا كان `force_update = true`
2. **الحصول على الإصدار**: يقارن الإصدار الحالي مع `app_version`
3. **عرض Dialog**: إذا كان التحديث مطلوبًا
4. **فتح الرابط**: عند الضغط على "تحديث الآن"، يفتح `update_url_android`

## مقارنة الإصدارات

النظام يقارن الإصدارات بذكاء:

- `1.0.0` < `1.0.1` ✅ تحديث مطلوب
- `1.0.0` < `1.1.0` ✅ تحديث مطلوب
- `1.0.0` < `2.0.0` ✅ تحديث مطلوب
- `1.2.0` = `1.2.0` ❌ لا تحديث
- `1.3.0` > `1.2.0` ❌ لا تحديث

## مميزات الـ Dialog

✨ **تصميم جذاب**
- ألوان متناسقة مع Dark/Light Mode
- أيقونات واضحة
- تأثيرات بصرية جميلة

📱 **معلومات واضحة**
- عرض الإصدار الحالي
- عرض الإصدار المطلوب
- قائمة بمميزات التحديث

🔒 **لا يمكن إغلاقه**
- المستخدم يجب أن يحدّث التطبيق
- لا يمكن الضغط خارج الـ Dialog
- زر الرجوع معطّل

🌐 **رابط ديناميكي**
- يتم التحكم به من Remote Config
- يمكن تغييره في أي وقت
- يفتح في المتصفح الخارجي

## اختبار النظام

### 1. تفعيل Force Update في Firebase
```
force_update: true
app_version: "2.0.0"  (أكبر من إصدارك الحالي)
update_url_android: "رابط المتجر"
```

### 2. تشغيل التطبيق
سيظهر الـ Dialog تلقائياً

### 3. اختبار الرابط
اضغط "تحديث الآن" للتأكد من فتح الرابط الصحيح

## نصائح مهمة

⚠️ **استخدم بحذر**
- Force Update يمنع المستخدمين من استخدام التطبيق
- استخدمه فقط للتحديثات الحرجة

✅ **استخدم في هذه الحالات:**
- إصلاح ثغرات أمنية مهمة
- تغييرات في API تكسر التوافق
- تحديثات حرجة للأداء

❌ **لا تستخدمه لـ:**
- تحديثات صغيرة
- ميزات جديدة اختيارية
- تحسينات عادية

## تعطيل Force Update

في أي وقت، غيّر في Firebase:
```
force_update: false
```

سيعمل التطبيق بشكل طبيعي للجميع.

## الدعم

- يعمل على Android و iOS
- يدعم Dark Mode
- يدعم RTL (العربية)
- متجاوب مع جميع أحجام الشاشات

## التخصيص

يمكنك تخصيص:
- ألوان الـ Dialog
- نص العنوان والوصف
- تصميم قائمة المميزات
- أيقونة التحديث
- شكل الأزرار

جميع هذه التخصيصات متوفرة في ملف `force_update_dialog.dart`.
