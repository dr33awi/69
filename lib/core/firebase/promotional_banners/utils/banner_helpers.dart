// lib/core/infrastructure/firebase/promotional_banners/utils/banner_helpers.dart

import 'package:athkar_app/core/firebase/remote_config_service.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import 'package:flutter/material.dart';
import '../promotional_banner_manager.dart';
import '../widgets/promotional_banner_dialog.dart';
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
        debugPrint('⚠️ PromotionalBannerManager not registered');
        return;
      }

      final bannerManager = getIt<PromotionalBannerManager>();
      
      // ✅ انتظار التهيئة إذا لم تكن جاهزة
      if (!bannerManager.isInitialized) {
        debugPrint('⚠️ PromotionalBannerManager not initialized, waiting...');
        
        // الانتظار حتى 5 ثوانٍ للتهيئة
        int attempts = 0;
        while (!bannerManager.isInitialized && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
          
          if (bannerManager.isInitialized) {
            debugPrint('✅ BannerManager initialized after ${attempts * 500}ms');
            break;
          }
        }
        
        // إذا لم تتم التهيئة بعد، محاولة التهيئة يدوياً
        if (!bannerManager.isInitialized) {
          debugPrint('🔄 Attempting manual initialization...');
          try {
            final storage = getIt<StorageService>();
            final remoteConfig = getIt<FirebaseRemoteConfigService>();
            
            await bannerManager.initialize(
              remoteConfig: remoteConfig,
              storage: storage,
            );
            
            if (!bannerManager.isInitialized) {
              debugPrint('❌ Manual initialization failed');
              return;
            }
            
            debugPrint('✅ Manual initialization successful');
          } catch (e) {
            debugPrint('❌ Manual initialization error: $e');
            return;
          }
        }
      }

      // الحصول على البانرات التي يجب عرضها
      final bannersToShow = await bannerManager.getBannersToShow(screenName);
      
      if (bannersToShow.isEmpty) {
        debugPrint('ℹ️ No banners to show for screen: $screenName');
        return;
      }

      debugPrint('🎯 Showing ${bannersToShow.length} banner(s) for: $screenName');

      // عرض البانرات واحداً تلو الآخر
      for (final banner in bannersToShow) {
        if (!context.mounted) break;

        await PromotionalBannerDialog.show(
          context: context,
          banner: banner,
          onDismiss: () {
            // تسجيل العرض
            bannerManager.markBannerAsShown(banner.id);
            debugPrint('✅ Banner ${banner.id} dismissed');
          },
          onActionPressed: () {
            // تسجيل النقر
            bannerManager.trackBannerClick(banner.id);
            debugPrint('👆 Banner ${banner.id} action pressed');
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
      debugPrint('❌ Error showing banners: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// فرض عرض بانر معين (للاختبار)
  static Future<void> showBannerById({
    required BuildContext context,
    required String bannerId,
  }) async {
    try {
      if (!getIt.isRegistered<PromotionalBannerManager>()) {
        debugPrint('⚠️ PromotionalBannerManager not registered');
        return;
      }

      final bannerManager = getIt<PromotionalBannerManager>();
      
      final banner = bannerManager.allBanners
          .where((b) => b.id == bannerId)
          .firstOrNull;
      
      if (banner == null) {
        debugPrint('⚠️ Banner not found: $bannerId');
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
      debugPrint('❌ Error showing banner by ID: $e');
    }
  }

  /// فرض عرض جميع البانرات (للاختبار)
  static Future<void> showAllBanners({
    required BuildContext context,
    String screenName = 'all',
  }) async {
    try {
      if (!getIt.isRegistered<PromotionalBannerManager>()) {
        debugPrint('⚠️ PromotionalBannerManager not registered');
        return;
      }

      final bannerManager = getIt<PromotionalBannerManager>();
      
      // ✅ التحقق من التهيئة ومحاولة إعادة التهيئة إذا لزم الأمر
      if (!bannerManager.isInitialized) {
        debugPrint('⚠️ PromotionalBannerManager not initialized, attempting to initialize...');
        
        try {
          final storage = getIt<StorageService>();
          final remoteConfig = getIt<FirebaseRemoteConfigService>();
          
          await bannerManager.initialize(
            remoteConfig: remoteConfig,
            storage: storage,
          );
          
          if (!bannerManager.isInitialized) {
            debugPrint('❌ Initialization failed');
            throw Exception('Failed to initialize BannerManager');
          }
          
          debugPrint('✅ BannerManager initialized successfully');
        } catch (e) {
          debugPrint('❌ Initialization error: $e');
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
        debugPrint('⚠️ No active banners found');
        return;
      }

      debugPrint('🧪 Testing: Showing ${allBanners.length} banner(s)');

      for (final banner in allBanners) {
        if (!context.mounted) break;

        await PromotionalBannerDialog.show(
          context: context,
          banner: banner,
          onDismiss: () {
            debugPrint('🧪 Test banner ${banner.id} dismissed');
          },
          onActionPressed: () {
            debugPrint('🧪 Test banner ${banner.id} action pressed');
          },
        );

        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error showing all banners: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // إعادة رفع الخطأ للسماح بمعالجته في UI
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