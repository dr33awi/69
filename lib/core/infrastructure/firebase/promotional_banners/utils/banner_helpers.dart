// lib/core/infrastructure/firebase/promotional_banners/utils/banner_helpers.dart

import 'package:flutter/material.dart';
import '../models/promotional_banner_model.dart';
import '../services/banner_service.dart';
import '../widgets/banner_dialog.dart';

/// مساعدات لعرض البانرات (Dialog فقط)
class BannerHelpers {
  
  /// عرض البانرات في شاشة معينة
  static void showBannersForScreen({
    required BuildContext context,
    required String screenName,
    String? countryCode,
  }) {
    final bannerService = BannerService();
    
    if (!bannerService.isInitialized) {
      return;
    }
    
    final banners = bannerService.getActiveBanners(
      screenName: screenName,
      countryCode: countryCode,
      type: BannerType.dialog, // ✅ فقط Dialog
    );
    
    if (banners.isEmpty) {
      return;
    }
    
    // عرض Dialog للبانرات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDialogs(context, banners, screenName);
    });
  }
  
  /// عرض Dialog للبانرات
  static void _showDialogs(
    BuildContext context,
    List<PromotionalBanner> banners,
    String screenName,
  ) {
    if (banners.isEmpty) return;
    
    // عرض أول بانر فقط (الأعلى أولوية)
    BannerDialog.show(
      context: context,
      banner: banners.first,
      screenName: screenName,
    );
  }
  
  /// عرض بانر واحد
  static void showSingleBanner({
    required BuildContext context,
    required String screenName,
    String? countryCode,
    BannerPriority? minPriority,
  }) {
    final bannerService = BannerService();
    
    if (!bannerService.isInitialized) {
      return;
    }
    
    var banners = bannerService.getActiveBanners(
      screenName: screenName,
      countryCode: countryCode,
      type: BannerType.dialog, // ✅ فقط Dialog
    );
    
    if (minPriority != null) {
      banners = banners
          .where((b) => b.priority.index >= minPriority.index)
          .toList();
    }
    
    if (banners.isEmpty) {
      return;
    }
    
    // عرض Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BannerDialog.show(
        context: context,
        banner: banners.first,
        screenName: screenName,
      );
    });
  }
  
  /// الحصول على عدد البانرات النشطة
  static int getActiveBannersCount({
    String? screenName,
    String? countryCode,
  }) {
    final bannerService = BannerService();
    
    if (!bannerService.isInitialized) {
      return 0;
    }
    
    return bannerService.getActiveBanners(
      screenName: screenName,
      countryCode: countryCode,
      type: BannerType.dialog, // ✅ فقط Dialog
    ).length;
  }
  
  /// هل توجد بانرات عاجلة؟
  static bool hasUrgentBanners({
    String? screenName,
    String? countryCode,
  }) {
    final bannerService = BannerService();
    
    if (!bannerService.isInitialized) {
      return false;
    }
    
    final banners = bannerService.getActiveBanners(
      screenName: screenName,
      countryCode: countryCode,
      type: BannerType.dialog, // ✅ فقط Dialog
    );
    
    return banners.any((b) => b.priority == BannerPriority.urgent);
  }
}

/// Extension للاستخدام السريع
extension BannerContextExtension on BuildContext {
  /// عرض البانرات في الشاشة الحالية
  void showBanners({
    required String screenName,
  }) {
    BannerHelpers.showBannersForScreen(
      context: this,
      screenName: screenName,
    );
  }
  
  /// عرض بانر واحد فقط
  void showSingleBanner({
    required String screenName,
    BannerPriority? minPriority,
  }) {
    BannerHelpers.showSingleBanner(
      context: this,
      screenName: screenName,
      minPriority: minPriority,
    );
  }
}