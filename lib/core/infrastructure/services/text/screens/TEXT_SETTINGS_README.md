# شاشة إعدادات النص 📝

شاشة موحدة لإدارة وتخصيص جميع إعدادات النصوص في التطبيق، مع واجهة سهلة ومتناسقة مع تصميم التطبيق.

## المميزات الرئيسية ✨

### 1. **التبويبات لكل نوع محتوى**
   - تاب منفصل لكل نوع: الأذكار، الدعاء، أسماء الله الحسنى
   - إمكانية فتح الشاشة على تاب محدد
   - أيقونة ولون مميز لكل نوع

### 2. **الخط العام**
   - اختيار خط واحد لجميع الأنواع
   - قائمة بالخطوط المتاحة: Cairo, Amiri, Noto Naskh Arabic, Scheherazade New, Lateef
   - إمكانية العودة للخطوط الافتراضية

### 3. **القوالب الجاهزة**
   - 4 قوالب معدة مسبقاً:
     - **مدمج** (Compact): حجم 16، مناسب للشاشات الصغيرة
     - **مريح** (Comfortable): حجم 20، التوازن المثالي
     - **كبير** (Large): حجم 24، للقراءة السهلة
     - **إمكانية الوصول** (Accessibility): حجم 28، لذوي الاحتياجات الخاصة
   - تطبيق سريع بضغطة واحدة

### 4. **تخصيص حجم الخط**
   - مزلاج (Slider) لضبط حجم الخط من 12 إلى 36
   - 24 درجة دقيقة للتحكم الكامل
   - عرض القيمة الحالية بشكل واضح

### 5. **تخصيص التباعد**
   - **تباعد الأسطر**: من 1.0 إلى 3.0
   - **تباعد الأحرف**: من 0 إلى 2.0
   - مزلاج سلس لكل إعداد

### 6. **خيارات العرض**
   - إظهار/إخفاء التشكيل
   - إظهار/إخفاء الفضل (للأذكار والدعاء)
   - إظهار/إخفاء المصدر
   - إظهار/إخفاء العداد (للأذكار فقط)
   - تفعيل/تعطيل الاهتزاز

### 7. **معاينة فورية**
   - عرض نموذجي للنص مع الإعدادات الحالية
   - يتأثر بكل التغييرات فوراً
   - نصوص مختلفة حسب نوع المحتوى

### 8. **إعادة التعيين**
   - إعادة تعيين النوع الحالي فقط
   - إعادة تعيين جميع الأنواع مرة واحدة
   - حوار تأكيد لتجنب الحذف الخاطئ

## الاستخدام 🚀

### الطريقة الأولى: الفتح المباشر

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GlobalTextSettingsScreen(),
  ),
);
```

### الطريقة الثانية: فتح على تاب معين

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GlobalTextSettingsScreen(
      initialContentType: ContentType.athkar, // أو dua أو asmaAllah
    ),
  ),
);
```

### الطريقة الثالثة: استخدام Extension

```dart
// من أي BuildContext
await context.showGlobalTextSettings();

// أو مع تحديد التاب
await context.showGlobalTextSettings(
  initialContentType: ContentType.dua,
);
```

## أمثلة التكامل 🔗

### في AppBar

```dart
AppBar(
  title: Text('الأذكار'),
  actions: [
    IconButton(
      icon: Icon(Icons.text_fields_rounded),
      tooltip: 'إعدادات النص',
      onPressed: () => context.showGlobalTextSettings(
        initialContentType: ContentType.athkar,
      ),
    ),
  ],
)
```

### في القائمة الجانبية (Drawer)

```dart
ListTile(
  leading: Icon(Icons.text_fields_rounded),
  title: Text('إعدادات النص'),
  subtitle: Text('تخصيص مظهر النصوص'),
  onTap: () {
    Navigator.pop(context); // إغلاق الدرور
    context.showGlobalTextSettings();
  },
)
```

### في شاشة الإعدادات

```dart
ListTile(
  leading: Icon(Icons.text_fields_rounded),
  title: Text('إعدادات النص'),
  subtitle: Text('تخصيص حجم ونوع الخط'),
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () => context.showGlobalTextSettings(),
)
```

### في Bottom Sheet

```dart
showModalBottomSheet(
  context: context,
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: Icon(Icons.text_fields_rounded),
        title: Text('إعدادات النص'),
        onTap: () {
          Navigator.pop(context);
          context.showGlobalTextSettings();
        },
      ),
      // خيارات أخرى...
    ],
  ),
);
```

## البنية التقنية 🏗️

### الاعتماديات

```dart
import '../../../../../app/themes/app_theme.dart';
import '../../../../../app/themes/widgets/layout/app_bar.dart';
import '../../../../../app/di/service_locator.dart';
import '../models/text_settings_models.dart';
import '../service/text_settings_service.dart';
```

### الخدمات المستخدمة

- **TextSettingsService**: إدارة حفظ وتحميل الإعدادات
- **StorageService**: التخزين المحلي عبر SharedPreferences
- **GetIt**: Dependency Injection

### النماذج

- **TextSettings**: حجم الخط، نوع الخط، التباعد، إلخ
- **DisplaySettings**: خيارات الإظهار/الإخفاء
- **ContentType**: نوع المحتوى (athkar, dua, asmaAllah)
- **TextStylePreset**: القوالب الجاهزة

## خصائص الشاشة 📋

### المعاملات (Parameters)

| المعامل | النوع | مطلوب | الوصف |
|---------|-------|-------|-------|
| initialContentType | ContentType? | ❌ | التاب الافتراضي عند الفتح |

### الأساليب الخاصة (Private Methods)

| الأسلوب | الوصف |
|---------|-------|
| _loadSettings() | تحميل جميع الإعدادات من الخدمة |
| _updateSetting() | تحديث إعدادات نوع محدد |
| _updateDisplaySettings() | تحديث إعدادات العرض |
| _applyPreset() | تطبيق قالب جاهز |
| _resetSettings() | إعادة تعيين إعدادات نوع |
| _setGlobalFont() | تعيين خط عام |
| _showResetDialog() | عرض حوار إعادة التعيين |

## التخصيص 🎨

### الألوان المستخدمة

- **اللون الأساسي**: `ThemeConstants.info` (أزرق)
- **لون التحذير**: `ThemeConstants.warning` (برتقالي)
- **لون النجاح**: `ThemeConstants.success` (أخضر)

### الأيقونات

- **الشاشة**: `Icons.text_fields_rounded`
- **القوالب**: `Icons.style_rounded`
- **الحجم**: `Icons.format_size_rounded`
- **التباعد**: `Icons.space_bar_rounded`
- **العرض**: `Icons.visibility_rounded`
- **المعاينة**: `Icons.preview_rounded`
- **إعادة التعيين**: `Icons.refresh_rounded`

### الخطوط المتاحة

```dart
final List<String> _availableFonts = [
  'Cairo',              // خط عصري ومقروء
  'Amiri',              // خط تقليدي أنيق
  'Noto Naskh Arabic',  // خط نسخي واضح
  'Scheherazade New',   // خط شهرزاد المحدث
  'Lateef',             // خط لطيف بسيط
];
```

## الأداء والتحسين ⚡

### Caching

- تخزين مؤقت للإعدادات المحملة
- تحديث فوري في الذاكرة
- حفظ في الخلفية

### State Management

- استخدام StatefulWidget مع TabController
- ChangeNotifier في TextSettingsService
- إشعارات فورية عند التغيير

### التحميل

- شاشة تحميل أثناء جلب الإعدادات
- تحميل متوازي لجميع الأنواع
- معالجة أخطاء التحميل

## معالجة الأخطاء 🛡️

### سيناريوهات الأخطاء

1. **فشل التحميل**: عرض رسالة خطأ واستخدام القيم الافتراضية
2. **فشل الحفظ**: إعادة المحاولة وإشعار المستخدم
3. **خط غير صالح**: التحقق والعودة للخط الافتراضي

### التحقق من المدخلات

```dart
// تحديد نطاق حجم الخط
min: 12.0
max: 36.0
divisions: 24

// تحديد نطاق تباعد الأسطر
min: 1.0
max: 3.0
divisions: 20

// تحديد نطاق تباعد الأحرف
min: 0.0
max: 2.0
divisions: 20
```

## الرسائل التوضيحية 💬

### SnackBar للنجاح

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('تم تطبيق قالب "${preset.name}"'),
    backgroundColor: ThemeConstants.success,
    duration: Duration(seconds: 2),
  ),
);
```

### حوار التأكيد

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('إعادة تعيين الإعدادات'),
    content: Text('هل تريد إعادة تعيين إعدادات النوع الحالي أم جميع الأنواع؟'),
    // أزرار الإجراءات...
  ),
);
```

## الاعتبارات الخاصة 📌

### RTL Support

- جميع النصوص بالعربية
- `TextDirection.rtl` في المعاينة
- دعم كامل للتنسيق من اليمين لليسار

### Dark Mode

- دعم كامل للوضع الليلي
- ألوان تتكيف تلقائياً
- استخدام `context.isDarkMode`

### Responsive Design

- استخدام `flutter_screenutil`
- تكيف مع أحجام الشاشات المختلفة
- أبعاد ديناميكية (`.w`, `.h`, `.sp`, `.r`)

### Accessibility

- قالب مخصص لذوي الاحتياجات الخاصة
- Tooltips على الأزرار
- أحجام نصوص واضحة

## الملفات ذات الصلة 📁

```
lib/core/infrastructure/services/text/
├── screens/
│   ├── global_text_settings_screen.dart   # الشاشة الرئيسية
│   └── screens.dart                        # التصدير
├── models/
│   └── text_settings_models.dart           # النماذج
├── service/
│   └── text_settings_service.dart          # الخدمة
├── extensions/
│   └── text_settings_extensions.dart       # الامتدادات
└── examples/
    └── text_settings_usage_example.dart    # 10 أمثلة استخدام
```

## التوافق 🔄

- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## الخلاصة 📝

شاشة إعدادات النص توفر:
- ✅ واجهة موحدة لإدارة كل إعدادات النصوص
- ✅ تخصيص كامل لكل نوع محتوى
- ✅ قوالب جاهزة للاستخدام السريع
- ✅ معاينة فورية للتغييرات
- ✅ دعم الوضع الليلي والـ RTL
- ✅ تصميم متناسق مع التطبيق
- ✅ سهولة التكامل والاستخدام

للمزيد من الأمثلة، راجع ملف `text_settings_usage_example.dart` الذي يحتوي على 10 أمثلة متنوعة للاستخدام! 🚀
