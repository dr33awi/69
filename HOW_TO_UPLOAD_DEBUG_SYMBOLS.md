# 🔧 دليل رفع رموز تصحيح الأخطاء (Debug Symbols)

## ❓ ما هي Debug Symbols؟

رموز تصحيح الأخطاء هي ملفات تساعد في:
- 🐛 تتبع الأعطال (Crashes) بدقة
- 📊 تحليل أخطاء ANR (Application Not Responding)
- 🔍 معرفة السطر المحدد الذي حدث فيه الخطأ

---

## ✅ الحل التلقائي (مُفعّل بالفعل)

تم تفعيل إعدادات تلقائية لتوليد ورفع Debug Symbols:

### 1️⃣ في `android/app/build.gradle.kts`:
```kotlin
buildTypes {
    release {
        ndk {
            debugSymbolLevel = "FULL"  // ✅ مُفعّل
        }
    }
}
```

هذا الإعداد سيقوم بـ:
- ✅ إنشاء ملفات `.so` symbols تلقائياً
- ✅ تضمينها في AAB الذي ترفعه على Play Console

---

## 📦 كيفية البناء مع Debug Symbols

### الطريقة الصحيحة لبناء AAB:

```bash
flutter build appbundle --release
```

سيتم إنشاء الملف في:
```
build/app/outputs/bundle/release/app-release.aab
```

**هذا الملف يحتوي على:**
- ✅ التطبيق كامل
- ✅ Native Debug Symbols تلقائياً (بفضل `debugSymbolLevel = "FULL"`)

---

## 🚀 رفع AAB على Google Play Console

1. افتح [Google Play Console](https://play.google.com/console/)
2. اختر تطبيقك
3. اذهب إلى **الإصدارات** → **الإصدار الإنتاجي**
4. ارفع ملف `app-release.aab`
5. **✅ سيتم رفع Debug Symbols تلقائياً!**

---

## 🔍 التحقق من نجاح الرفع

بعد رفع AAB، ستجد في Play Console:
- **App Bundle Explorer** → **Downloads** → **Native debug symbols**
- إذا وجدت ملفات `.so.dbg` أو `.so.sym`، فالرفع نجح ✅

---

## 🔥 رفع Symbols إلى Firebase Crashlytics (اختياري)

إذا أردت رفع Symbols إلى Firebase أيضاً:

### الطريقة 1: تلقائياً أثناء البناء (مُوصى به)
```bash
flutter build appbundle --release
```

Firebase Gradle Plugin سيرفع الرموز تلقائياً إذا كان Crashlytics مُفعّلاً.

### الطريقة 2: يدوياً (إذا فشل التلقائي)
```bash
cd android
./gradlew :app:uploadCrashlyticsSymbolFileRelease
```

---

## ⚠️ مشاكل شائعة وحلولها

### ❌ "لم يتم رفع الرموز"
**الحل:**
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

### ❌ "الملف كبير جداً"
**الحل:** Debug Symbols لا تزيد حجم AAB للمستخدمين، فقط للتحليل.

### ❌ "لا أرى الرموز في Play Console"
**الحل:** انتظر 24 ساعة بعد رفع AAB، قد يستغرق المعالجة وقتاً.

---

## 📚 مصادر إضافية

- [Flutter - Obfuscating Dart code](https://flutter.dev/docs/deployment/obfuscate)
- [Android - Native crash support](https://developer.android.com/studio/build/shrink-code#native-crash-support)
- [Firebase Crashlytics - NDK crashes](https://firebase.google.com/docs/crashlytics/ndk-reports)

---

## ✅ الخلاصة

✔️ **تم تفعيل الإعدادات تلقائياً**  
✔️ **فقط قم ببناء AAB عادي: `flutter build appbundle --release`**  
✔️ **ارفع AAB على Play Console**  
✔️ **Debug Symbols ستُرفع تلقائياً!**  

**لا حاجة لخطوات إضافية! 🎉**
