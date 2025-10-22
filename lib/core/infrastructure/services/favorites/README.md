# 📖 نظام المفضلة الموحد - README

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)
![Version](https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge)

**نظام شامل ومتطور لإدارة المفضلات في تطبيقات Flutter الإسلامية**

[الميزات](#-الميزات-الرئيسية) • [التثبيت](#-التثبيت-والإعداد) • [الاستخدام](#-دليل الاستخدام السريع) • [التوثيق](#-التوثيق-الشامل) • [المساهمة](#-المساهمة)

</div>

---

## 🌟 نظرة عامة

نظام المفضلة الموحد هو حل متكامل لإدارة المحتوى المفضل في التطبيقات الإسلامية. تم تصميمه خصيصاً لتطبيق أذكار وأدعية ليدعم أنواع مختلفة من المحتوى الإسلامي مع واجهة مستخدم عربية بديهية وأداء محسن.

### 🎯 المشكلة التي يحلها

- **تشتت المفضلات**: كل خدمة تدير مفضلاتها منفصلة
- **تكرار الكود**: نفس الوظائف مكررة في أماكن مختلفة  
- **صعوبة البحث**: لا يوجد بحث موحد عبر جميع المفضلات
- **عدم التنسيق**: واجهات مختلفة لنفس الوظيفة
- **ضعف الأداء**: عدم وجود تخزين مؤقت ذكي

### ✨ الحل الموحد

نظام واحد يدير جميع أنواع المحتوى مع:
- **واجهة موحدة** لجميع أنواع المفضلات
- **بحث متقدم** مع ترتيب حسب الصلة
- **إحصائيات شاملة** وتحليلات مفيدة
- **أداء محسن** مع تخزين مؤقت ذكي
- **ترحيل تلقائي** من الأنظمة القديمة

## 🚀 الميزات الرئيسية

### 📱 دعم شامل للمحتوى الإسلامي
- **الأدعية** مع الترجمة والفضائل
- **الأذكار** مع العدد والمصدر
- **أسماء الله الحسنى** مع المعاني والشرح
- **التسبيح والذكر** مع العدد المستحب
- **آيات القرآن** مع التفسير
- **الأحاديث الشريفة** مع الراوي والدرجة

### 🔍 بحث ذكي ومتقدم
- **بحث نصي سريع** عبر جميع المفضلات
- **ترتيب حسب الصلة** مع خوارزمية ذكية
- **فلترة حسب النوع** لنتائج مخصصة
- **بحث في المحتوى والوصف** شامل ودقيق

### 📊 إحصائيات وتحليلات
- **عدد المفضلات** لكل نوع محتوى
- **أكثر الأنواع استخداماً** إحصائيات مفيدة
- **تاريخ آخر تحديث** وتتبع النشاط
- **تقارير استخدام** تفصيلية

### 🎨 واجهة مستخدم متميزة
- **تصميم Material Design** عصري ونظيف
- **دعم كامل للعربية** مع RTL
- **وضع ليلي** مريح للعين
- **رسوم متحركة سلسة** وتفاعل بديهي
- **تجربة مستخدم محسنة** على جميع الأجهزة

### ⚡ أداء محسن
- **تحميل مسبق ذكي** للبيانات المتكررة
- **تخزين مؤقت متقدم** لسرعة الوصول
- **تحديثات تفاعلية** بدون إعادة تحميل
- **استهلاك ذاكرة محسن** كفاءة عالية

## 🛠️ التثبيت والإعداد

### المتطلبات الأساسية

- **Flutter SDK**: 3.0.0 أو أحدث
- **Dart SDK**: 3.0.0 أو أحدث
- **Android**: API Level 21 (Android 5.0) أو أحدث
- **iOS**: iOS 12.0 أو أحدث

### Dependencies المطلوبة

أضف هذه المكتبات في `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  get_it: ^7.6.4           # Service Locator
  shared_preferences: ^2.2.2  # Local Storage
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2          # للاختبارات
  build_runner: ^2.4.6     # لإنشاء Mocks
```

### خطوات التثبيت

#### 1. نسخ الملفات

انسخ مجلد النظام كاملاً إلى مشروعك:

```
lib/core/infrastructure/services/favorites/
├── constants/
│   └── favorites_constants.dart
├── extensions/
│   └── favorites_extensions.dart
├── models/
│   └── favorite_models.dart
├── screens/
│   └── unified_favorites_screen.dart
├── widgets/
│   └── favorite_button.dart
├── favorites_service.dart
├── favorites_usage_examples.dart
├── API_REFERENCE.md
├── MIGRATION_GUIDE.md
├── TESTING_GUIDE.md
└── README.md
```

#### 2. تحديث Service Locator

في `lib/app/di/service_locator.dart`:

```dart
import 'package:athkar_app/core/infrastructure/services/favorites/favorites_service.dart';

class ServiceLocator {
  static final GetIt _instance = GetIt.instance;
  
  static Future<void> initEssential() async {
    // الخدمات الأساسية
    _instance.registerLazySingleton<StorageService>(() => StorageService());
    
    // خدمة المفضلة الجديدة
    _registerFavoritesService();
  }
  
  static void _registerFavoritesService() {
    _instance.registerLazySingleton<FavoritesService>(
      () => FavoritesService(),
    );
  }
}
```

#### 3. تهيئة النظام

في `lib/main.dart`:

```dart
import 'package:athkar_app/core/infrastructure/services/favorites/favorites_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Service Locator
  await ServiceLocator.initEssential();
  
  // تهيئة خدمة المفضلة
  await getIt<FavoritesService>().initialize();
  
  runApp(MyApp());
}
```

#### 4. إضافة الواجهات

أضف شاشة المفضلة في التنقل:

```dart
// في AppRouter أو ملف التنقل
case '/favorites':
  return MaterialPageRoute(
    builder: (_) => const UnifiedFavoritesScreen(),
    settings: settings,
  );
```

## 📚 دليل الاستخدام السريع

### إضافة عنصر للمفضلة

```dart
// إنشاء عنصر مفضلة
final favoriteItem = FavoriteItem.fromDua(
  duaId: "dua_001",
  title: "دعاء الاستخارة", 
  arabicText: "اللهم إني أستخيرك بعلمك...",
  translation: "O Allah, I seek Your guidance...",
);

// إضافة للمفضلة
final favoritesService = getIt<FavoritesService>();
bool added = await favoritesService.addFavorite(favoriteItem);

if (added) {
  print("تم إضافة الدعاء للمفضلة بنجاح");
}
```

### استخدام زر المفضلة

```dart
// في واجهة المستخدم
FavoriteButton(
  itemId: dua.id,
  favoriteItem: FavoriteItem.fromDua(
    duaId: dua.id,
    title: dua.title,
    arabicText: dua.text,
  ),
  onToggle: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث المفضلة')),
    );
  },
)
```

### البحث في المفضلات

```dart
// البحث العام
final results = await favoritesService.searchFavorites("الاستخارة");

// البحث في نوع محدد
final duaResults = await favoritesService.searchFavorites(
  "الاستخارة",
  type: FavoriteContentType.dua,
  limit: 10,
);
```

### عرض شاشة المفضلة

```dart
// فتح شاشة المفضلة مع تبويب محدد
context.showUnifiedFavoritesScreen(
  initialType: FavoriteContentType.dua,
);

// أو باستخدام Navigator مباشرة
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const UnifiedFavoritesScreen(),
  ),
);
```

### الحصول على الإحصائيات

```dart
// إحصائيات شاملة
final statistics = await favoritesService.getStatistics();
print("إجمالي المفضلات: ${statistics.totalCount}");

// إحصائيات نوع محدد
final duaCount = await favoritesService.getCountByType(FavoriteContentType.dua);
print("عدد الأدعية المفضلة: $duaCount");
```

## 📁 هيكل المشروع

```
lib/core/infrastructure/services/favorites/
├── 📁 constants/
│   └── 📄 favorites_constants.dart      # الثوابت والقيم المخزنة
├── 📁 extensions/
│   └── 📄 favorites_extensions.dart     # Extensions للسهولة
├── 📁 models/
│   └── 📄 favorite_models.dart          # نماذج البيانات
├── 📁 screens/
│   └── 📄 unified_favorites_screen.dart # الشاشة الموحدة
├── 📁 widgets/
│   └── 📄 favorite_button.dart          # زر المفضلة
├── 📄 favorites_service.dart            # الخدمة الرئيسية
├── 📄 favorites_usage_examples.dart     # أمثلة الاستخدام
├── 📄 API_REFERENCE.md                  # مرجع API
├── 📄 MIGRATION_GUIDE.md                # دليل الترقية
├── 📄 TESTING_GUIDE.md                  # دليل الاختبار
└── 📄 README.md                         # هذا الملف
```

## 🎨 أمثلة الواجهات

### زر المفضلة البسيط

```dart
class DuaCard extends StatelessWidget {
  final DuaItem dua;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(dua.title),
        subtitle: Text(dua.arabicText),
        trailing: FavoriteButton(
          itemId: dua.id,
          favoriteItem: FavoriteItem.fromDua(
            duaId: dua.id,
            title: dua.title,
            arabicText: dua.arabicText,
          ),
        ),
      ),
    );
  }
}
```

### عرض إحصائيات المفضلة

```dart
class FavoritesStatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FavoritesStatistics>(
      future: context.getFavoritesStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final stats = snapshot.data!;
        return Card(
          child: Column(
            children: [
              Text('إحصائيات المفضلة'),
              Text('المجموع: ${stats.totalCount}'),
              Text('الأدعية: ${stats.countByType[FavoriteContentType.dua] ?? 0}'),
            ],
          ),
        );
      },
    );
  }
}
```

## 🔧 التخصيص والتطوير

### إضافة نوع محتوى جديد

1. **أضف النوع الجديد للـ enum**:
```dart
enum FavoriteContentType {
  dua, athkar, asmaAllah, tasbih, quran, hadith,
  newType, // النوع الجديد
}
```

2. **أضف Factory Method**:
```dart
extension FavoriteItemExtension on FavoriteItem {
  factory FavoriteItem.fromNewType({
    required String newTypeId,
    required String title,
    // باقي المعاملات المطلوبة
  }) {
    return FavoriteItem(
      id: newTypeId,
      title: title,
      contentType: FavoriteContentType.newType,
      // باقي البيانات
    );
  }
}
```

3. **حدث الواجهة**:
```dart
// أضف تبويب جديد في UnifiedFavoritesScreen
Tab(text: 'النوع الجديد'),
```

### تخصيص شاشة المفضلة

```dart
class CustomFavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مفضلاتي المخصصة')),
      body: FutureBuilder<List<FavoriteItem>>(
        future: context.favoritesService.getAllFavorites(),
        builder: (context, snapshot) {
          // واجهة مخصصة للمفضلات
          return CustomFavoritesListView(
            favorites: snapshot.data ?? [],
          );
        },
      ),
    );
  }
}
```

## 📖 التوثيق الشامل

### 📚 المراجع المتاحة

- **[API Reference](API_REFERENCE.md)**: دليل شامل لجميع APIs المتاحة
- **[Migration Guide](MIGRATION_GUIDE.md)**: دليل الترقية من الأنظمة القديمة  
- **[Testing Guide](TESTING_GUIDE.md)**: دليل الاختبار والجودة
- **[Usage Examples](favorites_usage_examples.dart)**: أمثلة عملية شاملة

### 🎯 نصائح مهمة

#### الأداء
- استخدم `initialize()` مرة واحدة فقط في `main.dart`
- فعّل التخزين المؤقت للبيانات المتكررة
- استخدم `limit` في البحث للمجموعات الكبيرة

#### الأمان
- تحقق من صحة البيانات قبل الحفظ
- استخدم `FavoritesConstants.isValidId()` للتحقق
- لا تثق في البيانات من مصادر خارجية

#### تجربة المستخدم
- أضف رسائل تأكيد للعمليات المهمة
- استخدم مؤشرات التحميل للعمليات الطويلة
- وفر خيارات التراجع للعمليات الحساسة

## 🔄 الترقية والترحيل

### من النظم القديمة

النظام يدعم الترحيل التلقائي من:
- `DuaService.favoriteDuas`
- `AthkarService.favoriteAthkar` 
- `TasbihService.favoriteDhikr`

```dart
// الترحيل يحدث تلقائياً عند أول استخدام
await favoritesService.initialize(); 
```

### التحقق من نجاح الترحيل

```dart
final statistics = await favoritesService.getStatistics();
if (statistics.totalCount > 0) {
  print("تم الترحيل بنجاح: ${statistics.totalCount} عنصر");
}
```

## 🧪 الاختبار

### تشغيل الاختبارات

```bash
# جميع الاختبارات
flutter test

# اختبارات مع تقرير التغطية
flutter test --coverage

# اختبارات الأداء فقط
flutter test test/performance/
```

### اختبارات التكامل

```bash
# اختبارات التكامل
flutter drive --target=test_driver/app.dart
```

## 🐛 استكشاف الأخطاء

### مشاكل شائعة وحلولها

#### خطأ: "FavoritesService not registered"
```dart
// تأكد من التسجيل في ServiceLocator
getIt.registerLazySingleton<FavoritesService>(() => FavoritesService());
```

#### خطأ: "Invalid favorite item data"
```dart
// تحقق من صحة البيانات
if (FavoritesConstants.isValidId(itemId)) {
  // آمن للاستخدام
}
```

#### بطء في الأداء
```dart
// استخدم التحميل المسبق
await favoritesService.initialize(); // في بداية التطبيق

// حدد عدد النتائج
final results = await favoritesService.searchFavorites(query, limit: 50);
```

### تشخيص المشاكل

```dart
// تفعيل الـ Debug Mode
class FavoritesService extends ChangeNotifier {
  static bool debugMode = true; // للتطوير فقط
  
  void _debugLog(String message) {
    if (debugMode) print('[FavoritesService] $message');
  }
}
```

## 📈 خارطة الطريق

### الإصدار الحالي (v1.0.0)
- ✅ النظام الأساسي المكتمل
- ✅ دعم 6 أنواع من المحتوى
- ✅ البحث والفلترة المتقدمة
- ✅ الواجهة الموحدة
- ✅ الترحيل التلقائي

### الإصدارات القادمة

#### v1.1.0 - تحسينات الأداء
- [ ] تحسين خوارزمية البحث
- [ ] تخزين مؤقت أكثر ذكاءً
- [ ] تحسين استهلاك الذاكرة
- [ ] دعم البحث الصوتي

#### v1.2.0 - ميزات متقدمة
- [ ] مشاركة المفضلات بين الأجهزة
- [ ] تصنيفات مخصصة
- [ ] تذكيرات للمحتوى المفضل
- [ ] تصدير بصيغ متعددة

#### v1.3.0 - تحسينات الواجهة
- [ ] ثيمات متعددة
- [ ] رسوم متحركة متقدمة
- [ ] دعم الإيماءات المتقدمة
- [ ] وضع القراءة المحسن

## 🤝 المساهمة

نرحب بمساهماتكم! يرجى اتباع هذه الخطوات:

### 1. إعداد البيئة التطويرية

```bash
# استنساخ المشروع
git clone https://github.com/your-repo/athkar-app.git

# تثبيت المكتبات
flutter pub get

# تشغيل الاختبارات
flutter test
```

### 2. المساهمة في الكود

1. **Fork** المشروع
2. أنشئ **branch** جديد للميزة: `git checkout -b feature/new-feature`
3. **اكتب الكود** مع الاختبارات المناسبة
4. **اختبر التغييرات**: `flutter test`
5. **Commit** التغييرات: `git commit -am 'Add new feature'`
6. **Push** للـ branch: `git push origin feature/new-feature`
7. أنشئ **Pull Request**

### 3. معايير الكود

- استخدم **Dart formatting**: `dart format .`
- اتبع **Flutter best practices**
- أضف **documentation** للدوال العامة
- اكتب **اختبارات** للميزات الجديدة
- حافظ على **التغطية > 85%**

### 4. الإبلاغ عن المشاكل

استخدم [GitHub Issues](https://github.com/your-repo/athkar-app/issues) مع:
- **وصف واضح** للمشكلة
- **خطوات إعادة الإنتاج**
- **معلومات البيئة** (Flutter version, OS, etc.)
- **لقطات شاشة** إن أمكن

## 📄 الترخيص

هذا المشروع مرخص تحت [MIT License](LICENSE).

```
MIT License

Copyright (c) 2024 Athkar App Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 👥 الفريق

### المطورون الرئيسيون
- **[@mo99a](https://github.com/mo99a)** - المطور الأساسي
- **GitHub Copilot** - مساعد التطوير الذكي

### الشكر والتقدير
- **Flutter Team** - إطار العمل الرائع
- **Dart Team** - لغة البرمجة المتميزة
- **Open Source Community** - للمكتبات المفيدة

## 📞 التواصل والدعم

### الدعم التقني
- **GitHub Issues**: [إبلاغ عن مشاكل](https://github.com/your-repo/athkar-app/issues)
- **GitHub Discussions**: [مناقشات عامة](https://github.com/your-repo/athkar-app/discussions)
- **Email**: support@athkarapp.com

### المجتمع
- **Discord Server**: [انضم للمجتمع](https://discord.gg/athkarapp)
- **Telegram Group**: [@athkarapp](https://t.me/athkarapp)

### المتابعة
- **Website**: [athkarapp.com](https://athkarapp.com)
- **Twitter**: [@athkarapp](https://twitter.com/athkarapp)
- **YouTube**: [قناة البرمجة الإسلامية](https://youtube.com/athkarapp)

---

<div align="center">

**صُنع بـ ❤️ للمجتمع الإسلامي**

*"وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا"*

[⬆ العودة للأعلى](#-نظام-المفضلة-الموحد---readme)

</div>