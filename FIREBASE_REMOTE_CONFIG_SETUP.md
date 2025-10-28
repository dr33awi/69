# Firebase Remote Config - إعدادات Force Update

## القيم المطلوبة في Firebase Console

انتقل إلى: Firebase Console → Remote Config → Add parameter

### 1️⃣ force_update
- **Parameter key**: `force_update`
- **Data type**: Boolean
- **Default value**: `false`
- **الوصف**: لتفعيل أو تعطيل Force Update

#### القيم:
```
✅ true  - التطبيق يتطلب تحديث إجباري
❌ false - التطبيق يعمل بشكل طبيعي
```

---

### 2️⃣ app_version
- **Parameter key**: `app_version`
- **Data type**: String
- **Default value**: `1.0.0`
- **الوصف**: الإصدار المطلوب من التطبيق

#### مثال:
```
1.0.0  - الإصدار الأول
1.1.0  - تحديث ثانوي
2.0.0  - تحديث رئيسي
```

#### ملاحظة:
- يجب أن يكون أكبر من الإصدار الحالي في `pubspec.yaml`
- التنسيق: `major.minor.patch`

---

### 3️⃣ update_url_android
- **Parameter key**: `update_url_android`
- **Data type**: String
- **Default value**: رابط تطبيقك على Google Play
- **الوصف**: رابط التحديث للأندرويد

#### مثال:
```
https://play.google.com/store/apps/details?id=com.dhakarani1.app
```

#### كيفية الحصول على الرابط:
1. افتح تطبيقك في Google Play Store
2. اضغط على "مشاركة"
3. انسخ الرابط
4. الصقه هنا

---

### 4️⃣ update_features_list (اختياري)
- **Parameter key**: `update_features_list`
- **Data type**: JSON
- **Default value**: `[]`
- **الوصف**: قائمة بمميزات التحديث الجديد

#### مثال JSON:
```json
[
  "إصلاح مشكلة توقف التطبيق",
  "تحسين سرعة التحميل بنسبة 50%",
  "إضافة ميزة البحث المتقدم",
  "تحديث التصميم ليكون أكثر سلاسة",
  "دعم اللغة الإنجليزية"
]
```

---

## 📝 مثال كامل للتكوين

### السيناريو: إجبار المستخدمين على التحديث

```
force_update: true
app_version: "1.2.0"
update_url_android: "https://play.google.com/store/apps/details?id=com.dhakarani1.app"
update_features_list: [
  "إصلاح ثغرة أمنية مهمة",
  "تحسين الأداء والاستقرار",
  "إضافة ميزات جديدة مهمة"
]
```

---

## 🔧 خطوات الإعداد في Firebase Console

### 1. انتقل إلى Remote Config
```
Firebase Console → Project → Remote Config
```

### 2. أضف المعامل الأول
- اضغط "Add parameter"
- Parameter key: `force_update`
- Data type: Boolean
- Default value: `false`
- اضغط "Add parameter"

### 3. أضف باقي المعاملات
كرر الخطوة السابقة لكل معامل:
- `app_version` (String)
- `update_url_android` (String)
- `update_features_list` (JSON)

### 4. انشر التغييرات
- اضغط "Publish changes" في أعلى الصفحة
- أدخل وصف التغييرات (مثل: "Enable force update")
- اضغط "Publish"

---

## 🧪 اختبار التكوين

### اختبار 1: التأكد من القيم الافتراضية
```dart
// في Flutter، شغّل:
final config = FirebaseRemoteConfigService();
await config.initialize();

print('Force Update: ${config.isForceUpdateRequired}');
print('Required Version: ${config.requiredAppVersion}');
print('Update URL: ${config.updateUrl}');
print('Features: ${config.updateFeaturesList}');
```

يجب أن تظهر القيم الافتراضية.

### اختبار 2: تفعيل Force Update
1. في Firebase، غيّر `force_update` إلى `true`
2. غيّر `app_version` إلى إصدار أعلى (مثل `2.0.0`)
3. انشر التغييرات
4. في Flutter:
```dart
await config.refresh();
```
5. شغّل التطبيق - يجب أن يظهر الـ Dialog

### اختبار 3: تعطيل Force Update
1. في Firebase، غيّر `force_update` إلى `false`
2. انشر التغييرات
3. في Flutter:
```dart
await config.refresh();
```
4. شغّل التطبيق - لا يجب أن يظهر الـ Dialog

---

## 🎯 سيناريوهات الاستخدام

### سيناريو 1: تحديث عاجل لإصلاح خطأ خطير
```json
{
  "force_update": true,
  "app_version": "1.0.1",
  "update_url_android": "رابط التطبيق",
  "update_features_list": [
    "إصلاح عاجل لمشكلة توقف التطبيق",
    "تحسين الأمان"
  ]
}
```

### سيناريو 2: تحديث رئيسي مع ميزات جديدة
```json
{
  "force_update": true,
  "app_version": "2.0.0",
  "update_url_android": "رابط التطبيق",
  "update_features_list": [
    "واجهة جديدة كلياً",
    "إضافة 10 ميزات جديدة",
    "تحسين السرعة بنسبة 70%",
    "دعم الوضع الليلي",
    "مزامنة سحابية"
  ]
}
```

### سيناريو 3: تعطيل Force Update
```json
{
  "force_update": false,
  "app_version": "1.0.0",
  "update_url_android": "رابط التطبيق",
  "update_features_list": []
}
```

---

## ⚠️ تحذيرات مهمة

### 1. تأكد من رفع التحديث أولاً
- قبل تفعيل `force_update = true`
- ارفع النسخة الجديدة على Google Play
- انتظر حتى تتم الموافقة عليها
- ثم فعّل Force Update

### 2. رابط التحديث الصحيح
- تأكد أن `update_url_android` يفتح صفحة التطبيق الصحيحة
- اختبر الرابط في المتصفح أولاً

### 3. الإصدار الصحيح
- `app_version` يجب أن يطابق الإصدار في `pubspec.yaml`
- استخدم نفس التنسيق: `major.minor.patch`

### 4. لا تنس النشر
- بعد تغيير أي قيمة، يجب الضغط على "Publish changes"
- وإلا لن يراها المستخدمون

---

## 🔄 تحديث القيم بدون إصدار جديد

يمكنك تغيير القيم في أي وقت:

1. افتح Firebase Console → Remote Config
2. عدّل القيمة المطلوبة
3. اضغط "Publish changes"
4. سيحصل المستخدمون على القيم الجديدة خلال دقائق

**لا يحتاج** المستخدمون لإعادة تشغيل التطبيق!

---

## 📊 مراقبة الاستخدام

في Firebase Console → Remote Config → "Get started with Analytics":

- عدد المستخدمين الذين حصلوا على القيم
- آخر وقت fetch
- معدل نجاح التحديث

---

## 🆘 حل المشاكل الشائعة

### المشكلة: الـ Dialog لا يظهر
**الحلول:**
1. تأكد من `force_update = true` في Firebase
2. تأكد من `app_version` أكبر من الحالي
3. تأكد من نشر التغييرات في Firebase
4. جرب `await config.refresh()`

### المشكلة: الرابط لا يفتح
**الحلول:**
1. تأكد من صحة الرابط في `update_url_android`
2. تأكد من وجود `url_launcher` في dependencies
3. اختبر الرابط في المتصفح

### المشكلة: القيم القديمة تظهر
**الحلول:**
1. انتظر دقيقة بعد النشر
2. استخدم `await config.refresh()`
3. امسح cache التطبيق
4. أعد تشغيل التطبيق

---

## ✅ Checklist للإطلاق

- [ ] رفع التحديث الجديد على Google Play
- [ ] انتظار موافقة Google (24-48 ساعة)
- [ ] التأكد من ظهور التحديث في المتجر
- [ ] تحديث `app_version` في Firebase
- [ ] تحديث `update_url_android` إذا لزم
- [ ] إضافة `update_features_list` مفيدة
- [ ] تفعيل `force_update = true`
- [ ] نشر التغييرات في Firebase
- [ ] اختبار على جهاز حقيقي
- [ ] مراقبة التحليلات

---

**ملاحظة نهائية:** 
استخدم Force Update بحكمة! إنه أداة قوية لكنها قد تزعج المستخدمين إذا استُخدمت بكثرة.
