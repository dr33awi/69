// lib/core/infrastructure/firebase/promotional_banners/utils/banner_helpers.dart

import 'package:flutter/material.dart';
import '../models/promotional_banner_model.dart';
import '../services/banner_service.dart';
import '../widgets/banner_widget.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/banner_dialog.dart';

/// مساعدات لعرض البانرات
class BannerHelpers {
  
  /// عرض البانرات في شاشة معينة
  static Widget? showBannersForScreen({
    required BuildContext context,
    required String screenName,
    String? countryCode,
    int maxBanners = 3,
  }) {
    final bannerService = BannerService();
    
    if (!bannerService.isInitialized) {
      return null;
    }
    
    final banners = bannerService.getActiveBanners(
      screenName: screenName,
      countryCode: countryCode,
    );
    
    if (banners.isEmpty) {
      return null;
    }
    
    // عرض البانرات حسب النوع
    final cardBanners = banners
        .where((b) => b.type == BannerType.card || b.type == BannerType.inline)
        .take(maxBanners)
        .toList();
    
    final carouselBanners = banners
        .where((b) => b.type == BannerType.carousel)
        .take(maxBanners)
        .toList();
    
    // عرض Dialog للبانرات العاجلة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUrgentDialogs(context, banners, screenName);
    });
    
    // عرض الكاروسيل إذا وجد
    if (carouselBanners.isNotEmpty) {
      return BannerCarousel(
        banners: carouselBanners,
        screenName: screenName,
      );
    }
    
    // عرض البانرات العادية
    if (cardBanners.isEmpty) {
      return null;
    }
    
    return Column(
      children: cardBanners.map((banner) {
        return BannerWidget(
          banner: banner,
          screenName: screenName,
        );
      }).toList(),
    );
  }
  
  /// عرض Dialog للبانرات العاجلة
  static void _showUrgentDialogs(
    BuildContext context,
    List<PromotionalBanner> banners,
    String screenName,
  ) {
    final urgentDialogs = banners
        .where((b) => b.type == BannerType.dialog && b.priority == BannerPriority.urgent)
        .toList();
    
    if (urgentDialogs.isEmpty) return;
    
    // عرض أول بانر عاجل فقط
    BannerDialog.show(
      context: context,
      banner: urgentDialogs.first,
      screenName: screenName,
    );
  }
  
  /// عرض بانر واحد
  static Widget? showSingleBanner({
    required String screenName,
    String? countryCode,
    BannerPriority? minPriority,
  }) {
    final bannerService = BannerService();
    
    if (!bannerService.isInitialized) {
      return null;
    }
    
    var banners = bannerService.getActiveBanners(
      screenName: screenName,
      countryCode: countryCode,
    );
    
    if (minPriority != null) {
      banners = banners
          .where((b) => b.priority.index >= minPriority.index)
          .toList();
    }
    
    if (banners.isEmpty) {
      return null;
    }
    
    return BannerWidget(
      banner: banners.first,
      screenName: screenName,
    );
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
    );
    
    return banners.any((b) => b.priority == BannerPriority.urgent);
  }
}

/// Extension للاستخدام السريع
extension BannerContextExtension on BuildContext {
  /// عرض البانرات في الشاشة الحالية
  Widget? showBanners({
    required String screenName,
    int maxBanners = 3,
  }) {
    return BannerHelpers.showBannersForScreen(
      context: this,
      screenName: screenName,
      maxBanners: maxBanners,
    );
  }
  
  /// عرض بانر واحد فقط
  Widget? showSingleBanner({
    required String screenName,
    BannerPriority? minPriority,
  }) {
    return BannerHelpers.showSingleBanner(
      screenName: screenName,
      minPriority: minPriority,
    );
  }
}