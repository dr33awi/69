# نظام إعدادات النصوص الموحد

## نظرة عامة

تم إنشاء نظام موحد لإدارة جميع إعدادات النصوص والخطوط في التطبيق، مما يوفر:

- **إدارة موحدة**: تحكم في جميع إعدادات النصوص من مكان واحد
- **دعم أنواع متعددة**: أذكار، دعاء، أسماء الله، قرآن، حديث
- **قوالب جاهزة**: إعدادات مسبقة للاستخدام السريع
- **واجهة موحدة**: شاشة إعدادات شاملة لجميع الأنواع
- **Extensions سهلة**: وصول مباشر من أي BuildContext

## الهيكل

```
lib/core/infrastructure/services/text/
├── models/
│   └── text_settings_models.dart          # نماذج البيانات
├── constants/
│   └── text_settings_constants.dart       # الثوابت والقيم الافتراضية
├── screens/
│   └── global_text_settings_screen.dart   # شاشة الإعدادات الموحدة
├── extensions/
│   └── text_settings_extensions.dart      # Extensions للوصول السهل
└── text_settings_service.dart            # الخدمة الأساسية
```

## أنواع المحتوى المدعومة

```dart
enum ContentType {
  athkar,      // الأذكار
  dua,         // الدعاء  
  asmaAllah,   // أسماء الله الحسنى
  quran,       // القرآن الكريم
  hadith       // الأحاديث
}
```

## الاستخدام الأساسي

### 1. الوصول للإعدادات

```dart
// الحصول على إعدادات النص لنوع معين
final settings = await context.getTextSettings(ContentType.athkar);

// الحصول على إعدادات العرض
final displaySettings = await context.getDisplaySettings(ContentType.athkar);

// إنشاء TextStyle مخصص
final textStyle = await context.getAthkarTextStyle(
  color: Colors.black,
  fontWeight: FontWeight.bold,
);
```

### 2. تحديث الإعدادات

```dart
// تحديث حجم الخط فقط
await context.updateContentFontSize(ContentType.athkar, 20.0);

// تحديث نوع الخط
await context.updateContentFontFamily(ContentType.dua, 'Amiri');

// حفظ إعدادات كاملة
final textSettings = TextSettings(
  fontSize: 18.0,
  fontFamily: 'Cairo',
  lineHeight: 1.8,
  letterSpacing: 0.3,
  contentType: ContentType.athkar,
);
await context.textSettingsService.saveTextSettings(textSettings);
```

### 3. تطبيق القوالب الجاهزة

```dart
// تطبيق قالب على نوع محتوى واحد
await context.applyPresetToContent(
  ContentType.athkar,
  TextStylePresets.comfortable,
);

// تطبيق قالب على جميع الأنواع
await context.applyPresetToAllContent(TextStylePresets.large);
```

### 4. استخدام AdaptiveText Widget

```dart
// عرض نص مع الإعدادات الموحدة
AdaptiveText(
  'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
  contentType: ContentType.athkar,
  color: Colors.black,
  textAlign: TextAlign.center,
  applyDisplaySettings: true,
)
```

## القوالب الجاهزة

```dart
class TextStylePresets {
  static const compact = TextStylePreset(
    name: 'مضغوط',
    fontSize: 16.0,
    lineHeight: 1.5,
    letterSpacing: 0.1,
  );
  
  static const comfortable = TextStylePreset(
    name: 'قراءة مريحة',
    fontSize: 20.0,
    lineHeight: 2.0,
    letterSpacing: 0.5,
  );
  
  static const large = TextStylePreset(
    name: 'كبير',
    fontSize: 24.0,
    lineHeight: 2.2,
    letterSpacing: 0.7,
  );
  
  static const accessibility = TextStylePreset(
    name: 'كبار السن',
    fontSize: 28.0,
    lineHeight: 2.5,
    letterSpacing: 1.0,
  );
}
```

## شاشة الإعدادات الموحدة

```dart
// فتح شاشة الإعدادات العامة
await context.showGlobalTextSettings();

// فتح شاشة الإعدادات لنوع محتوى معين
await context.showGlobalTextSettings(
  initialContentType: ContentType.athkar,
);
```

## مميزات الشاشة الموحدة

- **تبويبات لكل نوع محتوى**: سهولة التنقل بين الأنواع المختلفة
- **معاينة فورية**: رؤية التغييرات مباشرة
- **قوالب جاهزة**: تطبيق سريع للإعدادات المحددة مسبقاً
- **إعدادات متقدمة**: تحكم دقيق في كل خاصية
- **إعدادات العرض**: التحكم في عرض التشكيل والفضائل والمصادر
- **إجراءات شاملة**: إعادة تعيين، خط عام، قوالب عامة

## الترحيل من النظام القديم

النظام الجديد يدعم الترحيل التلقائي من الإعدادات القديمة:

```dart
// يتم استدعاؤها تلقائياً عند التهيئة
await _textService._migrateOldSettings();
```

## Extensions إضافية

### للنصوص العربية

```dart
// إزالة التشكيل
final textWithoutTashkeel = arabicText.removeTashkeel();

// تطبيق إعدادات العرض
final processedText = text.applyDisplaySettings(displaySettings);

// تنسيق للمشاركة
final formattedText = text.formatForSharing(
  source: 'صحيح البخاري',
  fadl: 'من قالها...',
  categoryTitle: 'أذكار الصباح',
);
```

### للمشاركة والنسخ

```dart
// نسخ مع التفاصيل الكاملة
await context.copyAthkar(
  text,
  fadl: fadl,
  source: source,
  categoryTitle: categoryTitle,
);

// مشاركة مع التفاصيل
await context.shareAthkar(
  text,
  fadl: fadl,
  source: source,
  categoryTitle: categoryTitle,
);
```

## الفوائد

### قبل التحديث
- كود مكرر في كل ميزة
- إعدادات منفصلة لكل نوع
- صعوبة في الصيانة
- عدم الاتساق بين الميزات

### بعد التحديث
- كود موحد ومنظم
- إعدادات مركزية
- سهولة الإضافة والتعديل
- واجهة متسقة عبر التطبيق
- دعم شامل للترحيل

## المثال الشامل

راجع الملف:
`lib/examples/unified_text_settings_example.dart`

هذا المثال يوضح جميع الاستخدامات المتاحة بالتفصيل.

## التطوير المستقبلي

- دعم المزيد من الخطوط العربية
- إعدادات متقدمة للألوان والظلال
- قوالب مخصصة من المستخدم
- مزامنة الإعدادات عبر الأجهزة
- دعم إعدادات خاصة بالمناسبات

---

**ملاحظة**: هذا النظام يحافظ على التوافق مع النظام القديم ويقوم بالترحيل التلقائي عند أول استخدام.