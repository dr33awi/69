// lib/core/infrastructure/firebase/utils/firebase_verification.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// أداة التحقق من إعداد Firebase
class FirebaseVerification {
  
  /// التحقق من جميع خدمات Firebase
  static Future<Map<String, bool>> verifyAllServices() async {
    final results = <String, bool>{};
    
    debugPrint('🔍 ========== Firebase Verification Starting ==========');
    
    // 1. التحقق من Firebase Core
    results['Firebase Core'] = await _verifyFirebaseCore();
    
    // 2. التحقق من Analytics
    results['Analytics'] = await _verifyAnalytics();
    
    // 3. التحقق من Crashlytics
    results['Crashlytics'] = await _verifyCrashlytics();
    
    // 4. التحقق من Performance
    results['Performance'] = await _verifyPerformance();
    
    // 5. التحقق من In-App Messaging
    results['In-App Messaging'] = await _verifyInAppMessaging();
    
    // 6. التحقق من Cloud Messaging
    results['Cloud Messaging'] = await _verifyCloudMessaging();
    
    // 7. التحقق من Remote Config
    results['Remote Config'] = await _verifyRemoteConfig();
    
    // طباعة النتائج
    _printResults(results);
    
    return results;
  }
  
  /// التحقق من Firebase Core
  static Future<bool> _verifyFirebaseCore() async {
    try {
      debugPrint('\n📦 Checking Firebase Core...');
      
      // التحقق من التهيئة
      if (Firebase.apps.isEmpty) {
        debugPrint('  ❌ No Firebase apps initialized');
        return false;
      }
      
      final app = Firebase.app();
      debugPrint('  ✅ Firebase Core initialized');
      debugPrint('     - App Name: ${app.name}');
      debugPrint('     - Project ID: ${app.options.projectId}');
      debugPrint('     - API Key: ${app.options.apiKey.substring(0, 10)}...');
      
      return true;
      
    } catch (e) {
      debugPrint('  ❌ Firebase Core error: $e');
      return false;
    }
  }
  
  /// التحقق من Analytics
  static Future<bool> _verifyAnalytics() async {
    try {
      debugPrint('\n📊 Checking Firebase Analytics...');
      
      final analytics = FirebaseAnalytics.instance;
      
      // محاولة تسجيل حدث اختبار
      await analytics.logEvent(
        name: 'verification_test',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'test': true,
        },
      );
      
      debugPrint('  ✅ Firebase Analytics working');
      debugPrint('     - Test event logged successfully');
      
      return true;
      
    } catch (e) {
      debugPrint('  ❌ Firebase Analytics error: $e');
      return false;
    }
  }
  
  /// التحقق من Crashlytics
  static Future<bool> _verifyCrashlytics() async {
    try {
      debugPrint('\n🐛 Checking Firebase Crashlytics...');
      
      final crashlytics = FirebaseCrashlytics.instance;
      
      // تسجيل رسالة اختبار
      crashlytics.log('Verification test log');
      
      // تعيين مفتاح مخصص
      await crashlytics.setCustomKey('verification_test', true);
      
      // تسجيل خطأ غير قاتل للاختبار
      await crashlytics.recordError(
        Exception('Verification test exception'),
        StackTrace.current,
        reason: 'Testing Crashlytics setup',
        fatal: false,
      );
      
      debugPrint('  ✅ Firebase Crashlytics working');
      debugPrint('     - Collection enabled: ${!crashlytics.isCrashlyticsCollectionEnabled}');
      
      return true;
      
    } catch (e) {
      debugPrint('  ❌ Firebase Crashlytics error: $e');
      return false;
    }
  }
  
  /// التحقق من Performance
  static Future<bool> _verifyPerformance() async {
    try {
      debugPrint('\n⚡ Checking Firebase Performance...');
      
      final performance = FirebasePerformance.instance;
      
      // إنشاء trace اختبار
      final trace = performance.newTrace('verification_test_trace');
      await trace.start();
      
      // إضافة metrics
      trace.setMetric('test_metric', 100);
      trace.putAttribute('test_attribute', 'verification');
      
      await trace.stop();
      
      // اختبار HTTP metric
      final httpMetric = performance.newHttpMetric(
        'https://example.com/test',
        HttpMethod.Get,
      );
      await httpMetric.start();
      httpMetric.httpResponseCode = 200;
      httpMetric.responsePayloadSize = 1000;
      await httpMetric.stop();
      
      debugPrint('  ✅ Firebase Performance working');
      debugPrint('     - Test trace completed');
      debugPrint('     - Test HTTP metric recorded');
      
      return true;
      
    } catch (e) {
      debugPrint('  ❌ Firebase Performance error: $e');
      return false;
    }
  }
  
  /// التحقق من In-App Messaging
  static Future<bool> _verifyInAppMessaging() async {
    try {
      debugPrint('\n💬 Checking Firebase In-App Messaging...');
      
      final inAppMessaging = FirebaseInAppMessaging.instance;
      
      // تشغيل حدث اختبار
      await inAppMessaging.triggerEvent('verification_test_event');
      
      // التحقق من الإعدادات
      inAppMessaging.setMessagesSuppressed(false);
      
      debugPrint('  ✅ Firebase In-App Messaging working');
      debugPrint('     - Test event triggered');
      debugPrint('     - Messages not suppressed');
      
      return true;
      
    } catch (e) {
      debugPrint('  ❌ Firebase In-App Messaging error: $e');
      return false;
    }
  }
  
  /// التحقق من Cloud Messaging
  static Future<bool> _verifyCloudMessaging() async {
    try {
      debugPrint('\n☁️ Checking Firebase Cloud Messaging...');
      
      final messaging = FirebaseMessaging.instance;
      
      // طلب الأذونات
      final settings = await messaging.getNotificationSettings();
      debugPrint('     - Permission status: ${settings.authorizationStatus}');
      
      // الحصول على التوكن
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('  ✅ Firebase Cloud Messaging working');
        debugPrint('     - Token received: ${token.substring(0, 20)}...');
        
        // الاشتراك في موضوع اختبار
        await messaging.subscribeToTopic('verification_test');
        debugPrint('     - Subscribed to test topic');
        
        return true;
      } else {
        debugPrint('  ⚠️ Firebase Cloud Messaging: No token received');
        return false;
      }
      
    } catch (e) {
      debugPrint('  ❌ Firebase Cloud Messaging error: $e');
      return false;
    }
  }
  
  /// التحقق من Remote Config
  static Future<bool> _verifyRemoteConfig() async {
    try {
      debugPrint('\n⚙️ Checking Firebase Remote Config...');
      
      final remoteConfig = FirebaseRemoteConfig.instance;
      
      // تعيين الإعدادات
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      
      // تعيين القيم الافتراضية
      await remoteConfig.setDefaults({
        'verification_test': 'default_value',
      });
      
      // محاولة الجلب والتفعيل
      final result = await remoteConfig.fetchAndActivate();
      
      debugPrint('  ✅ Firebase Remote Config working');
      debugPrint('     - Fetch result: $result');
      debugPrint('     - Last fetch time: ${remoteConfig.lastFetchTime}');
      debugPrint('     - Last fetch status: ${remoteConfig.lastFetchStatus}');
      
      return true;
      
    } catch (e) {
      debugPrint('  ❌ Firebase Remote Config error: $e');
      return false;
    }
  }
  
  /// طباعة النتائج
  static void _printResults(Map<String, bool> results) {
    debugPrint('\n🎯 ========== Firebase Verification Results ==========');
    
    int passed = 0;
    int failed = 0;
    
    results.forEach((service, status) {
      final icon = status ? '✅' : '❌';
      debugPrint('  $icon $service: ${status ? 'PASSED' : 'FAILED'}');
      
      if (status) {
        passed++;
      } else {
        failed++;
      }
    });
    
    debugPrint('\n📈 Summary:');
    debugPrint('  - Total Services: ${results.length}');
    debugPrint('  - Passed: $passed');
    debugPrint('  - Failed: $failed');
    debugPrint('  - Success Rate: ${(passed / results.length * 100).toStringAsFixed(1)}%');
    
    if (failed == 0) {
      debugPrint('\n🎉 All Firebase services are working correctly!');
    } else {
      debugPrint('\n⚠️ Some services need attention. Check the logs above.');
    }
    
    debugPrint('====================================================\n');
  }
  
  /// إنشاء تقرير HTML
  static String generateHTMLReport(Map<String, bool> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('<html><head><title>Firebase Verification Report</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: Arial, sans-serif; padding: 20px; }');
    buffer.writeln('.passed { color: green; } .failed { color: red; }');
    buffer.writeln('table { border-collapse: collapse; width: 100%; }');
    buffer.writeln('td, th { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    buffer.writeln('</style></head><body>');
    
    buffer.writeln('<h1>Firebase Services Verification Report</h1>');
    buffer.writeln('<p>Generated: ${DateTime.now()}</p>');
    
    buffer.writeln('<table>');
    buffer.writeln('<tr><th>Service</th><th>Status</th></tr>');
    
    results.forEach((service, status) {
      final statusClass = status ? 'passed' : 'failed';
      final statusText = status ? 'PASSED ✅' : 'FAILED ❌';
      buffer.writeln('<tr><td>$service</td><td class="$statusClass">$statusText</td></tr>');
    });
    
    buffer.writeln('</table>');
    buffer.writeln('</body></html>');
    
    return buffer.toString();
  }
}

/// Widget للتحقق من Firebase بصرياً
class FirebaseVerificationWidget extends StatefulWidget {
  const FirebaseVerificationWidget({super.key});
  
  @override
  State<FirebaseVerificationWidget> createState() => _FirebaseVerificationWidgetState();
}

class _FirebaseVerificationWidgetState extends State<FirebaseVerificationWidget> {
  Map<String, bool>? _results;
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Verification'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results == null
              ? Center(
                  child: ElevatedButton(
                    onPressed: _runVerification,
                    child: const Text('Start Verification'),
                  ),
                )
              : ListView.builder(
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    final entry = _results!.entries.elementAt(index);
                    return ListTile(
                      leading: Icon(
                        entry.value ? Icons.check_circle : Icons.cancel,
                        color: entry.value ? Colors.green : Colors.red,
                      ),
                      title: Text(entry.key),
                      subtitle: Text(entry.value ? 'Working' : 'Failed'),
                    );
                  },
                ),
    );
  }
  
  Future<void> _runVerification() async {
    setState(() => _isLoading = true);
    
    final results = await FirebaseVerification.verifyAllServices();
    
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }
}