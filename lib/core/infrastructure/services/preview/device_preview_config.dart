// lib/core/infrastructure/services/preview/device_preview_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import '../logger/app_logger.dart';

/// تكوين Device Preview للتطوير
class DevicePreviewConfig {
  /// إعداد Device Preview
  static DevicePreview? wrapApp(Widget app) {
    // تمكين Device Preview في وضع التطوير فقط
    if (!kDebugMode) return null;

    AppLogger.info('Device Preview enabled');
    
    return DevicePreview(
      enabled: true,
      devices: [
        // الهواتف الذكية
        Devices.ios.iPhone13,
        Devices.ios.iPhone13Mini,
        Devices.ios.iPhone13ProMax,
        Devices.ios.iPhoneSE,
        
        Devices.android.samsungGalaxyS20,
        Devices.android.samsungGalaxyNote20,
        Devices.android.samsungGalaxyA50,
        Devices.android.onePlus8Pro,
        
        // الأجهزة اللوحية
        Devices.ios.iPadPro11Inches,
        Devices.ios.iPadAir4,
        
        // أجهزة أخرى
        Devices.macOS.macBookPro,
        Devices.windows.laptop,
        Devices.linux.laptop,
      ],
      builder: (context) => app,
    );
  }

  /// تكوين مخصص للأجهزة العربية/الشرق الأوسط
  static List<DeviceInfo> getMiddleEastDevices() {
    return [
      // أجهزة شائعة في الشرق الأوسط
      Devices.android.samsungGalaxyS20,
      Devices.android.samsungGalaxyA50,
      Devices.ios.iPhone13,
      Devices.ios.iPhone13Mini,
      
      // أجهزة لوحية شائعة
      Devices.ios.iPadPro11Inches,
      Devices.ios.iPadAir4,
    ];
  }

  /// اختبار دعم RTL
  static Widget addRTLTesting(Widget child) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    );
  }
}

/// Extension لسهولة الاستخدام
extension DevicePreviewExtension on Widget {
  Widget withDevicePreview() {
    final preview = DevicePreviewConfig.wrapApp(this);
    return preview ?? this;
  }

  Widget withRTLTesting() {
    return DevicePreviewConfig.addRTLTesting(this);
  }
}