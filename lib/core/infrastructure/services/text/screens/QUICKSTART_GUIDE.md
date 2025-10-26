# دليل البداية السريع - شاشة إعدادات النص ⚡

## التثبيت والإعداد 🔧

### 1. التأكد من الاعتماديات

تأكد من أن `pubspec.yaml` يحتوي على:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_screenutil: ^5.9.0
  get_it: ^7.6.0
  shared_preferences: ^2.2.2
```

### 2. تسجيل الخدمة

في ملف `service_locator.dart`:

```dart
import 'package:get_it/get_it.dart';
import '../services/text/service/text_settings_service.dart';
import '../services/storage/storage_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // تسجيل خدمة التخزين أولاً
  getIt.registerLazySingleton<StorageService>(
    () => StorageService(),
  );
  
  // تسجيل خدمة إعدادات النص
  getIt.registerLazySingleton<TextSettingsService>(
    () => TextSettingsService(
      storage: getIt<StorageService>(),
    ),
  );
}
```

### 3. تهيئة في main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Service Locator
  setupServiceLocator();
  
  // تهيئة ScreenUtil
  await ScreenUtil.ensureScreenSize();
  
  runApp(MyApp());
}
```

## الاستخدام الأساسي 🎯

### سيناريو 1: فتح الشاشة من زر

```dart
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الأذكار'),
        actions: [
          // زر إعدادات النص
          IconButton(
            icon: Icon(Icons.text_fields_rounded),
            onPressed: () {
              context.showGlobalTextSettings();
            },
          ),
        ],
      ),
      body: Center(
        child: Text('محتوى التطبيق'),
      ),
    );
  }
}
```

### سيناريو 2: فتح من قائمة الإعدادات

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الإعدادات')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.text_fields_rounded),
            title: Text('إعدادات النص'),
            subtitle: Text('تخصيص حجم ونوع الخط'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GlobalTextSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### سيناريو 3: فتح على تاب محدد

```dart
// في شاشة الأذكار
ElevatedButton(
  onPressed: () {
    context.showGlobalTextSettings(
      initialContentType: ContentType.athkar,
    );
  },
  child: Text('إعدادات نص الأذكار'),
)

// في شاشة الدعاء
ElevatedButton(
  onPressed: () {
    context.showGlobalTextSettings(
      initialContentType: ContentType.dua,
    );
  },
  child: Text('إعدادات نص الدعاء'),
)
```

## قراءة الإعدادات في التطبيق 📖

### طريقة 1: استخدام Extension

```dart
class AthkarCard extends StatelessWidget {
  final String text;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TextStyle>(
      future: context.getAthkarTextStyle(
        color: context.textPrimaryColor,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        return Text(
          text,
          style: snapshot.data,
        );
      },
    );
  }
}
```

### طريقة 2: استخدام الخدمة مباشرة

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late TextSettingsService _textService;
  TextSettings? _settings;
  
  @override
  void initState() {
    super.initState();
    _textService = getIt<TextSettingsService>();
    _loadSettings();
    
    // الاستماع للتغييرات
    _textService.addListener(_onSettingsChanged);
  }
  
  @override
  void dispose() {
    _textService.removeListener(_onSettingsChanged);
    super.dispose();
  }
  
  void _onSettingsChanged() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settings = await _textService.getTextSettings(ContentType.athkar);
    setState(() {
      _settings = settings;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return CircularProgressIndicator();
    }
    
    return Text(
      'نص الذكر',
      style: _settings!.toTextStyle(color: Colors.black),
    );
  }
}
```

### طريقة 3: استخدام Consumer

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: getIt<TextSettingsService>(),
      builder: (context, child) {
        return FutureBuilder<TextSettings>(
          future: context.getTextSettings(ContentType.athkar),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }
            
            return Text(
              'نص الذكر',
              style: snapshot.data!.toTextStyle(
                color: context.textPrimaryColor,
              ),
            );
          },
        );
      },
    );
  }
}
```

## أمثلة الاستخدام المتقدم 🚀

### إنشاء Widget مخصص للنص

```dart
class AdaptiveArabicText extends StatelessWidget {
  final String text;
  final ContentType contentType;
  final Color? color;
  final FontWeight? fontWeight;
  
  const AdaptiveArabicText({
    required this.text,
    required this.contentType,
    this.color,
    this.fontWeight,
    Key? key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TextSettings>(
      future: context.getTextSettings(contentType),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }
        
        final settings = snapshot.data!;
        
        return FutureBuilder<DisplaySettings>(
          future: context.getDisplaySettings(contentType),
          builder: (context, displaySnapshot) {
            if (!displaySnapshot.hasData) {
              return SizedBox.shrink();
            }
            
            final displaySettings = displaySnapshot.data!;
            String displayText = text;
            
            // إزالة التشكيل إذا كان معطلاً
            if (!displaySettings.showTashkeel) {
              displayText = text.replaceAll(
                RegExp(r'[\u0617-\u061A\u064B-\u0652]'),
                '',
              );
            }
            
            return Text(
              displayText,
              style: settings.toTextStyle(
                color: color ?? context.textPrimaryColor,
                fontWeight: fontWeight,
              ),
              textDirection: TextDirection.rtl,
            );
          },
        );
      },
    );
  }
}

// الاستخدام:
AdaptiveArabicText(
  text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  contentType: ContentType.athkar,
)
```

### تطبيق إعدادات على ListView

```dart
class AthkarListView extends StatelessWidget {
  final List<String> athkar;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TextSettings>(
      future: context.getTextSettings(ContentType.athkar),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        
        final textSettings = snapshot.data!;
        
        return ListView.builder(
          itemCount: athkar.length,
          itemBuilder: (context, index) {
            return Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  athkar[index],
                  style: textSettings.toTextStyle(
                    color: context.textPrimaryColor,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
```

## التكامل مع الميزات الأخرى 🔗

### مع المفضلة

```dart
class FavoriteAthkarCard extends StatelessWidget {
  final FavoriteItem item;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: AdaptiveArabicText(
          text: item.title,
          contentType: item.contentType,
        ),
        subtitle: AdaptiveArabicText(
          text: item.content,
          contentType: item.contentType,
          color: context.textSecondaryColor,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر إعدادات النص
            IconButton(
              icon: Icon(Icons.text_fields_rounded),
              onPressed: () {
                context.showGlobalTextSettings(
                  initialContentType: item.contentType,
                );
              },
            ),
            // زر الحذف
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // حذف من المفضلة
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### مع البحث

```dart
class SearchResultCard extends StatelessWidget {
  final String query;
  final String content;
  final ContentType contentType;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // المحتوى مع الإعدادات المخصصة
          AdaptiveArabicText(
            text: _highlightQuery(content, query),
            contentType: contentType,
          ),
          
          // أزرار الإجراءات
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: Icon(Icons.text_fields_rounded),
                label: Text('تخصيص النص'),
                onPressed: () {
                  context.showGlobalTextSettings(
                    initialContentType: contentType,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _highlightQuery(String text, String query) {
    // تطبيق التمييز على نتائج البحث
    return text;
  }
}
```

## نصائح للأداء 💡

### 1. استخدام Cache

```dart
class CachedTextSettingsWidget extends StatefulWidget {
  @override
  _CachedTextSettingsWidgetState createState() => 
      _CachedTextSettingsWidgetState();
}

class _CachedTextSettingsWidgetState extends State<CachedTextSettingsWidget> {
  TextSettings? _cachedSettings;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settings = await context.getTextSettings(ContentType.athkar);
    if (mounted) {
      setState(() => _cachedSettings = settings);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_cachedSettings == null) {
      return CircularProgressIndicator();
    }
    
    return Text(
      'نص الذكر',
      style: _cachedSettings!.toTextStyle(color: Colors.black),
    );
  }
}
```

### 2. استخدام Singleton للخدمة

```dart
// الخدمة مسجلة كـ Singleton في GetIt
// لا حاجة لإنشاء نسخ متعددة
final textService = getIt<TextSettingsService>();

// الاستخدام في أي مكان
await textService.getTextSettings(ContentType.athkar);
```

### 3. الاستماع للتغييرات

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // الاستماع للتغييرات
    getIt<TextSettingsService>().addListener(_onUpdate);
  }
  
  @override
  void dispose() {
    getIt<TextSettingsService>().removeListener(_onUpdate);
    super.dispose();
  }
  
  void _onUpdate() {
    setState(() {
      // إعادة البناء عند تغيير الإعدادات
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## الأسئلة الشائعة ❓

### س: كيف أغير حجم الخط برمجياً؟

```dart
final textService = getIt<TextSettingsService>();
await textService.updateFontSize(ContentType.athkar, 24.0);
```

### س: كيف أطبق قالب جاهز على نوع معين؟

```dart
final textService = getIt<TextSettingsService>();
await textService.applyPreset(
  ContentType.athkar,
  TextStylePresets.large,
);
```

### س: كيف أطبق قالب على جميع الأنواع؟

```dart
final textService = getIt<TextSettingsService>();
await textService.applyPresetToAll(TextStylePresets.comfortable);
```

### س: كيف أعيد تعيين الإعدادات؟

```dart
// إعادة تعيين نوع واحد
await textService.resetToDefault(ContentType.athkar);

// إعادة تعيين الكل
await textService.resetAllToDefault();
```

### س: كيف أحفظ الإعدادات يدوياً؟

```dart
final settings = TextSettings(
  fontSize: 20.0,
  fontFamily: 'Cairo',
  lineHeight: 2.0,
  letterSpacing: 0.5,
  showTashkeel: true,
  showFadl: true,
  showSource: true,
  showCounter: true,
  enableVibration: true,
  contentType: ContentType.athkar,
);

await textService.saveTextSettings(settings);
```

## الخطوات التالية 🎯

1. ✅ تثبيت الاعتماديات
2. ✅ تسجيل الخدمات
3. ✅ إضافة زر للوصول للشاشة
4. ✅ استخدام الإعدادات في واجهتك
5. 🔄 اختبار على أجهزة مختلفة
6. 🔄 جمع ملاحظات المستخدمين
7. 🔄 ضبط القيم الافتراضية حسب الحاجة

## مصادر إضافية 📚

- [TEXT_SETTINGS_README.md](./TEXT_SETTINGS_README.md) - التوثيق الكامل
- [text_settings_usage_example.dart](../examples/text_settings_usage_example.dart) - 10 أمثلة عملية
- [text_settings_models.dart](../models/text_settings_models.dart) - تعريفات النماذج
- [text_settings_service.dart](../service/text_settings_service.dart) - وثائق الخدمة

---

الآن أنت جاهز لاستخدام شاشة إعدادات النص! 🎉

للمساعدة أو الاستفسارات، راجع الملفات أعلاه أو افتح issue في المشروع.
