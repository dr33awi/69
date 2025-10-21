// lib/core/infrastructure/firebase/promotional_banners/utils/banner_helpers.dart
// ✅ الملف الكامل مع تتبع التحديثات

import 'package:athkar_app/core/firebase/remote_config_service.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../promotional_banner_manager.dart';
import '../widgets/promotional_banner_dialog.dart';
import '../models/promotional_banner_model.dart';
import '../../../../app/di/service_locator.dart';

/// مساعدات لعرض البانرات
class BannerHelpers {
  BannerHelpers._();

  /// عرض البانرات المتاحة لشاشة معينة
  static Future<void> showBannersForScreen({
    required BuildContext context,
    required String screenName,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    // انتظار قليل للسماح للشاشة بالبناء
    await Future.delayed(delay);

    if (!context.mounted) return;

    try {
      // التحقق من تسجيل الخدمة
      if (!getIt.isRegistered<PromotionalBannerManager>()) {
        return;
      }

      final bannerManager = getIt<PromotionalBannerManager>();
      
      // ✅ انتظار التهيئة إذا لم تكن جاهزة
      if (!bannerManager.isInitialized) {
        // الانتظار حتى 5 ثوانٍ للتهيئة
        int attempts = 0;
        while (!bannerManager.isInitialized && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
          
          if (bannerManager.isInitialized) {
            break;
          }
        }
        
        // إذا لم تتم التهيئة بعد، محاولة التهيئة يدوياً
        if (!bannerManager.isInitialized) {
          try {
            final storage = getIt<StorageService>();
            final remoteConfig = getIt<FirebaseRemoteConfigService>();
            
            await bannerManager.initialize(
              remoteConfig: remoteConfig,
              storage: storage,
            );
            
            if (!bannerManager.isInitialized) {
              return;
            }
          } catch (e) {
            return;
          }
        }
      }

      // الحصول على البانرات التي يجب عرضها
      final bannersToShow = await bannerManager.getBannersToShow(screenName);
      
      if (bannersToShow.isEmpty) {
        return;
      }
      // عرض البانرات واحداً تلو الآخر
      for (final banner in bannersToShow) {
        if (!context.mounted) break;

        await PromotionalBannerDialog.show(
          context: context,
          banner: banner,
          onDismiss: () async {
            // ✅ تسجيل الإغلاق
            await bannerManager.markBannerAsShown(banner.id);
            
            // ✅ إذا كان dismiss_forever، إخفاء نهائياً
            if (banner.dismissForever) {
              await bannerManager.dismissBannerForever(banner.id);
            }
          },
          onActionPressed: () async {
            // ✅ تسجيل النقر
            await bannerManager.trackBannerClick(banner.id);
            
            // ✅ إذا كان بانر تحديث، التحقق من النسخة وإخفاءه نهائياً
            if (banner.bannerType == BannerType.update) {
              await _handleUpdateBannerAction(banner);
            }
          },
        );

        // تسجيل العرض
        await bannerManager.markBannerAsShown(banner.id);

        // انتظار قليل بين البانرات
        if (bannersToShow.length > 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } catch (e, stackTrace) {
    }
  }

  /// ✅ معالجة نقر بانر التحديث
  static Future<void> _handleUpdateBannerAction(PromotionalBanner banner) async {
    try {
      final bannerManager = getIt<PromotionalBannerManager>();
      
      // حفظ معلومات أن المستخدم نقر على التحديث
      await bannerManager.markUpdateBannerAsActioned(banner.id);
      // بعد فترة، التحقق من النسخة وإخفاء البانر
      Future.delayed(const Duration(seconds: 30), () async {
        final shouldHide = await _shouldHideUpdateBanner(banner);
        if (shouldHide) {
          await bannerManager.dismissBannerForever(banner.id);
        }
      });
      
    } catch (e) {
    }
  }

  /// ✅ التحقق من أن المستخدم قام بالتحديث
  static Future<bool> _shouldHideUpdateBanner(PromotionalBanner banner) async {
    try {
      // إذا لم يكن هناك min_app_version، لا نخفي
      if (banner.minAppVersion == null || banner.minAppVersion!.isEmpty) {
        return false;
      }
      
      // الحصول على نسخة التطبيق الحالية
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      // مقارنة النسخ
      final isUpdated = _compareVersions(currentVersion, banner.minAppVersion!);
      
      return isUpdated;
      
    } catch (e) {
      return false;
    }
  }

  /// ✅ مقارنة نسخ التطبيق
  static bool _compareVersions(String current, String required) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final requiredParts = required.split('.').map(int.parse).toList();
      
      // التأكد من أن كلا الإصدارين لهما نفس عدد الأجزاء
      while (currentParts.length < requiredParts.length) {
        currentParts.add(0);
      }
      while (requiredParts.length < currentParts.length) {
        requiredParts.add(0);
      }
      
      // مقارنة كل جزء
      for (int i = 0; i < currentParts.length; i++) {
        if (currentParts[i] > requiredParts[i]) {
          return true; // النسخة الحالية أعلى
        } else if (currentParts[i] < requiredParts[i]) {
          return false; // النسخة الحالية أقل
        }
      }
      
      return true; // النسخ متساوية
      
    } catch (e) {
      return false;
    }
  }

  /// فرض عرض بانر معين (للاختبار)
  static Future<void> showBannerById({
    required BuildContext context,
    required String bannerId,
  }) async {
    try {
      if (!getIt.isRegistered<PromotionalBannerManager>()) {
        return;
      }

      final bannerManager = getIt<PromotionalBannerManager>();
      
      final banner = bannerManager.allBanners
          .where((b) => b.id == bannerId)
          .firstOrNull;
      
      if (banner == null) {
        return;
      }

      if (!context.mounted) return;

      await PromotionalBannerDialog.show(
        context: context,
        banner: banner,
        onDismiss: () {
          bannerManager.markBannerAsShown(banner.id);
        },
        onActionPressed: () {
          bannerManager.trackBannerClick(banner.id);
        },
      );
    } catch (e) {
    }
  }

  /// فرض عرض جميع البانرات (للاختبار)
  static Future<void> showAllBanners({
    required BuildContext context,
    String screenName = 'all',
  }) async {
    try {
      if (!getIt.isRegistered<PromotionalBannerManager>()) {
        return;
      }

      final bannerManager = getIt<PromotionalBannerManager>();
      
      // ✅ التحقق من التهيئة ومحاولة إعادة التهيئة إذا لزم الأمر
      if (!bannerManager.isInitialized) {
        try {
          final storage = getIt<StorageService>();
          final remoteConfig = getIt<FirebaseRemoteConfigService>();
          
          await bannerManager.initialize(
            remoteConfig: remoteConfig,
            storage: storage,
          );
          
          if (!bannerManager.isInitialized) {
            throw Exception('Failed to initialize BannerManager');
          }
        } catch (e) {
          throw Exception('Cannot initialize BannerManager: $e');
        }
      }
      
      // مسح بيانات العرض السابقة
      await bannerManager.clearAllBannerData();
      
      // إعادة تحميل البانرات
      await bannerManager.refresh();
      
      // عرض جميع البانرات
      final allBanners = bannerManager.allBanners
          .where((b) => b.isCurrentlyActive)
          .toList();

      if (allBanners.isEmpty) {
        return;
      }
      for (final banner in allBanners) {
        if (!context.mounted) break;

        await PromotionalBannerDialog.show(
          context: context,
          banner: banner,
          onDismiss: () {
          },
          onActionPressed: () {
          },
        );

        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e, stackTrace) {
      rethrow;
    }
  }
}

/// Extension على BuildContext لسهولة الاستخدام
extension BannerContext on BuildContext {
  /// عرض البانرات لهذه الشاشة
  Future<void> showBanners({
    required String screenName,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    return BannerHelpers.showBannersForScreen(
      context: this,
      screenName: screenName,
      delay: delay,
    );
  }

  /// عرض بانر معين
  Future<void> showBannerById(String bannerId) async {
    return BannerHelpers.showBannerById(
      context: this,
      bannerId: bannerId,
    );
  }

  /// عرض جميع البانرات (للاختبار)
  Future<void> showAllBannersTest() async {
    return BannerHelpers.showAllBanners(context: this);
  }
}