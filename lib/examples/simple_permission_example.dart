// lib/examples/simple_permission_example.dart
// مثال على كيفية استخدام نظام الأذونات المبسط الجديد

import 'package:flutter/material.dart';
import '../core/infrastructure/services/permissions/simple_permission_service.dart';
import '../core/infrastructure/services/permissions/simple_permission_extensions.dart';

/// مثال شامل لاستخدام نظام الأذونات البسيط
class SimplePermissionExample extends StatefulWidget {
  const SimplePermissionExample({super.key});

  @override
  State<SimplePermissionExample> createState() => _SimplePermissionExampleState();
}

class _SimplePermissionExampleState extends State<SimplePermissionExample> {
  final SimplePermissionService _permissionService = SimplePermissionService();
  PermissionResults? _lastResults;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال الأذونات البسيط'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات النظام الجديد
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'نظام الأذونات البسيط الجديد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '✅ يستخدم smart_permission للبساطة\n'
                      '✅ يدعم الإشعارات والموقع فقط\n'
                      '✅ واجهة مبسطة وسهلة الاستخدام\n'
                      '✅ حوارات تلقائية وذكية\n'
                      '✅ بدون تعقيدات أو أخطاء',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // أزرار العمليات
            const Text(
              'العمليات المتاحة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // فحص الأذونات
            ElevatedButton.icon(
              onPressed: _checkPermissions,
              icon: const Icon(Icons.search),
              label: const Text('فحص الأذونات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // طلب الأذونات منفردة
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _requestSinglePermission(PermissionType.notification),
                    icon: const Icon(Icons.notifications),
                    label: const Text('إشعارات'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _requestSinglePermission(PermissionType.location),
                    icon: const Icon(Icons.location_on),
                    label: const Text('موقع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // طلب جميع الأذونات
            ElevatedButton.icon(
              onPressed: () => _requestAllPermissions(),
              icon: const Icon(Icons.security),
              label: const Text('طلب جميع الأذونات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // طلب أذونات متعددة (طريقة المجموعة)
            ElevatedButton.icon(
              onPressed: () => _requestMultiplePermissions(),
              icon: const Icon(Icons.group_work),
              label: const Text('طلب أذونات مجمعة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // فتح الإعدادات
            ElevatedButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings),
              label: const Text('فتح إعدادات التطبيق'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // عرض النتائج
            if (_lastResults != null) ...[
              const Text(
                'آخر النتائج:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildResultsCard(_lastResults!),
            ],
          ],
        ),
      ),
    );
  }

  /// فحص الأذونات بدون طلب
  Future<void> _checkPermissions() async {
    try {
      final results = await _permissionService.checkAllPermissions();
      setState(() => _lastResults = results);
      
      if (mounted) {
        results.showResultInSnackBar(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في فحص الأذونات: $e')),
        );
      }
    }
  }

  /// طلب إذن محدد
  Future<void> _requestSinglePermission(PermissionType type) async {
    try {
      bool granted = false;
      
      switch (type) {
        case PermissionType.notification:
          granted = await _permissionService.requestNotificationPermission(context);
          break;
        case PermissionType.location:
          granted = await _permissionService.requestLocationPermission(context);
          break;
      }

      if (mounted) {
        if (granted) {
          context.showPermissionGrantedSnackBar(type.arabicName);
        } else {
          context.showPermissionDeniedSnackBar(type.arabicName);
        }
      }

      // تحديث النتائج
      await _checkPermissions();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في طلب ${type.arabicName}: $e')),
        );
      }
    }
  }

  /// طلب جميع الأذونات (بشكل فردي)
  Future<void> _requestAllPermissions() async {
    try {
      final results = await _permissionService.requestAllPermissions(context);
      setState(() => _lastResults = results);
      
      if (mounted) {
        results.showResultInSnackBar(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في طلب الأذونات: $e')),
        );
      }
    }
  }

  /// طلب أذونات متعددة (بطريقة مجمعة)
  Future<void> _requestMultiplePermissions() async {
    try {
      final results = await _permissionService.requestMultiplePermissions(context);
      setState(() => _lastResults = results);
      
      if (mounted) {
        results.showResultInSnackBar(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في طلب الأذونات المجمعة: $e')),
        );
      }
    }
  }

  /// فتح إعدادات التطبيق
  Future<void> _openSettings() async {
    try {
      final opened = await _permissionService.openAppSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(opened ? 'تم فتح الإعدادات' : 'فشل في فتح الإعدادات'),
            backgroundColor: opened ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في فتح الإعدادات: $e')),
        );
      }
    }
  }

  /// بناء بطاقة النتائج
  Widget _buildResultsCard(PermissionResults results) {
    final color = results.allGranted 
        ? Colors.green 
        : results.anyGranted 
            ? Colors.orange 
            : Colors.red;

    return Card(
      color: color.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  results.allGranted 
                      ? Icons.check_circle 
                      : results.anyGranted 
                          ? Icons.warning 
                          : Icons.error,
                  color: color.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  results.description,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildPermissionStatus(
                    'الإشعارات',
                    results.notification,
                    Icons.notifications,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPermissionStatus(
                    'الموقع',
                    results.location,
                    Icons.location_on,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            Text(
              'عدد الأذونات الممنوحة: ${results.grantedCount} من 2',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء حالة إذن واحد
  Widget _buildPermissionStatus(String name, bool granted, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: granted ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 4),
        Icon(
          granted ? Icons.check : Icons.close,
          size: 14,
          color: granted ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _permissionService.dispose();
    super.dispose();
  }
}

/// Widget wrapper يطبق الأذونات تلقائياً
class AutoPermissionWrapper extends StatelessWidget {
  final Widget child;
  final bool requestOnInit;

  const AutoPermissionWrapper({
    super.key,
    required this.child,
    this.requestOnInit = true,
  });

  @override
  Widget build(BuildContext context) {
    return SimplePermissionRequester(
      checkOnInit: true,
      requestOnInit: requestOnInit,
      showSnackBarResults: true,
      child: child,
    );
  }
}