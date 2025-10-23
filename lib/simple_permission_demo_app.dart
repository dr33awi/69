// lib/simple_permission_demo_app.dart
// تطبيق تجريبي للنظام البسيط

import 'package:flutter/material.dart';
import 'core/infrastructure/services/permissions/simple_permission_initializer.dart';
import 'examples/simple_permission_example.dart';

/// تطبيق تجريبي بسيط لاختبار نظام الأذونات الجديد
class SimplePermissionDemoApp extends StatelessWidget {
  const SimplePermissionDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Permission Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Cairo',
        useMaterial3: true,
      ),
      home: const SimplePermissionExample(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// main للتجربة السريعة
Future<void> mainSimplePermissionDemo() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة النظام البسيط
  await SimplePermissionInitializer.initialize();
  
  runApp(const SimplePermissionDemoApp());
}

/* 
استخدم هذا الملف لاختبار النظام الجديد:

1. استبدل محتوى main.dart مؤقتاً بـ:
   ```dart
   import 'simple_permission_demo_app.dart';
   void main() => mainSimplePermissionDemo();
   ```

2. أو أنشئ ملف منفصل للاختبار:
   ```dart
   // test_simple_permissions.dart
   import 'simple_permission_demo_app.dart';
   void main() => mainSimplePermissionDemo();
   ```

3. شغل التطبيق واختبر جميع الوظائف
*/