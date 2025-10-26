// lib/core/infrastructure/services/text/examples/text_settings_usage_example.dart
// أمثلة على استخدام شاشة إعدادات النص

import 'package:flutter/material.dart';
import '../screens/global_text_settings_screen.dart';
import '../models/text_settings_models.dart';

/// مثال 1: فتح شاشة إعدادات النص من أي مكان
class Example1_OpenTextSettings extends StatelessWidget {
  const Example1_OpenTextSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.text_fields_rounded),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GlobalTextSettingsScreen(),
          ),
        );
      },
      tooltip: 'إعدادات النص',
    );
  }
}

/// مثال 2: فتح الشاشة على تاب معين
class Example2_OpenSpecificTab extends StatelessWidget {
  const Example2_OpenSpecificTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // فتح الشاشة على تاب الأذكار
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GlobalTextSettingsScreen(
              initialContentType: ContentType.athkar,
            ),
          ),
        );
      },
      child: const Text('إعدادات نص الأذكار'),
    );
  }
}

/// مثال 3: استخدام Extension للفتح السريع
class Example3_UseExtension extends StatelessWidget {
  const Example3_UseExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        // استخدام Extension المعرفة في text_settings_extensions.dart
        // context.showGlobalTextSettings(); // سيعمل بعد تحديث Extension
        
        // أو الطريقة المباشرة:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GlobalTextSettingsScreen(),
          ),
        );
      },
    );
  }
}

/// مثال 4: فتح الشاشة من القائمة الجانبية
class Example4_OpenFromDrawer extends StatelessWidget {
  const Example4_OpenFromDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Text('القائمة'),
          ),
          
          ListTile(
            leading: const Icon(Icons.text_fields_rounded),
            title: const Text('إعدادات النص'),
            subtitle: const Text('تخصيص مظهر النصوص'),
            onTap: () {
              Navigator.of(context).pop(); // إغلاق الدرور
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GlobalTextSettingsScreen(),
                ),
              );
            },
          ),
          
          // يمكن إضافة أنواع محددة
          ListTile(
            leading: const Icon(Icons.auto_stories_rounded),
            title: const Text('إعدادات الأذكار'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GlobalTextSettingsScreen(
                    initialContentType: ContentType.athkar,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// مثال 5: إضافة زر في AppBar
class Example5_AppBarButton extends StatelessWidget {
  const Example5_AppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار'),
        actions: [
          // زر إعدادات النص
          IconButton(
            icon: const Icon(Icons.text_fields_rounded),
            tooltip: 'إعدادات النص',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GlobalTextSettingsScreen(
                    initialContentType: ContentType.athkar,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('محتوى الأذكار'),
      ),
    );
  }
}

/// مثال 6: فتح الشاشة من Bottom Sheet
class Example6_OpenFromBottomSheet extends StatelessWidget {
  const Example6_OpenFromBottomSheet({super.key});

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields_rounded),
                title: const Text('إعدادات النص'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GlobalTextSettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('مشاركة'),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () => _showOptions(context),
    );
  }
}

/// مثال 7: استخدام في شاشة تفاصيل الذكر
class Example7_InDetailScreen extends StatelessWidget {
  const Example7_InDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الذكر'),
      ),
      body: Column(
        children: [
          // محتوى الذكر
          const Expanded(
            child: Center(
              child: Text('نص الذكر...'),
            ),
          ),
          
          // شريط الأدوات
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // زر المفضلة
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
                
                // زر المشاركة
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {},
                ),
                
                // زر إعدادات النص
                IconButton(
                  icon: const Icon(Icons.text_fields_rounded),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GlobalTextSettingsScreen(
                          initialContentType: ContentType.athkar,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// مثال 8: استخدام مع Floating Action Button
class Example8_WithFAB extends StatelessWidget {
  const Example8_WithFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار'),
      ),
      body: const Center(
        child: Text('قائمة الأذكار'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const GlobalTextSettingsScreen(),
            ),
          );
        },
        icon: const Icon(Icons.text_fields_rounded),
        label: const Text('إعدادات النص'),
      ),
    );
  }
}

/// مثال 9: استخدام في شاشة الإعدادات الرئيسية
class Example9_InMainSettings extends StatelessWidget {
  const Example9_InMainSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        children: [
          // قسم المظهر
          const ListTile(
            title: Text(
              'المظهر',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('الوضع الليلي'),
            trailing: Switch(
              value: false,
              onChanged: (value) {},
            ),
          ),
          
          const Divider(),
          
          // قسم النصوص
          const ListTile(
            title: Text(
              'النصوص',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.text_fields_rounded),
            title: const Text('إعدادات النص'),
            subtitle: const Text('تخصيص حجم ونوع الخط'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GlobalTextSettingsScreen(),
                ),
              );
            },
          ),
          
          const Divider(),
          
          // أقسام أخرى...
        ],
      ),
    );
  }
}

/// مثال 10: صفحة تجريب كاملة
class Example10_FullDemo extends StatelessWidget {
  const Example10_FullDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تجريب إعدادات النص'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'اختر نوع المحتوى',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // زر لكل نوع محتوى
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GlobalTextSettingsScreen(
                      initialContentType: ContentType.athkar,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_stories_rounded),
              label: const Text('إعدادات الأذكار'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GlobalTextSettingsScreen(
                      initialContentType: ContentType.dua,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book),
              label: const Text('إعدادات الدعاء'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GlobalTextSettingsScreen(
                      initialContentType: ContentType.asmaAllah,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('إعدادات أسماء الله'),
            ),
            
            const SizedBox(height: 32),
            
            const Divider(),
            
            const SizedBox(height: 12),
            
            // زر لفتح الشاشة دون تحديد نوع معين
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GlobalTextSettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.text_fields_rounded),
              label: const Text('جميع الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }
}
