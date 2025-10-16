// lib/core/infrastructure/firebase/promotional_banners/services/banner_analytics_service.dart

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../analytics/analytics_service.dart';
import '../models/promotional_banner_model.dart';

/// خدمة تحليلات البانرات
class BannerAnalyticsService {
  final GetIt _getIt = GetIt.instance;
  AnalyticsService? _analytics;

  BannerAnalyticsService() {
    _tryGetAnalytics();
  }

  void _tryGetAnalytics() {
    try {
      if (_getIt.isRegistered<AnalyticsService>()) {
        _analytics = _getIt<AnalyticsService>();
      }
    } catch (e) {
      debugPrint('⚠️ Analytics not available for banners');
    }
  }

  /// تتبع عرض البانر
  Future<void> trackBannerImpression(PromotionalBanner banner, String screenName) async {
    await _analytics?.logEvent('promotional_banner_shown', {
      'banner_id': banner.id,
      'banner_title': banner.title,
      'banner_priority': banner.priority.name,
      'banner_type': banner.type.name,
      'screen_name': screenName,
      'remaining_days': banner.remainingTime?.inDays ?? 0,
    });
  }

  /// تتبع نقر البانر
  Future<void> trackBannerClick(PromotionalBanner banner, String screenName) async {
    await _analytics?.logEvent('promotional_banner_clicked', {
      'banner_id': banner.id,
      'banner_title': banner.title,
      'action_url': banner.actionUrl,
      'screen_name': screenName,
    });
  }

  /// تتبع إغلاق البانر
  Future<void> trackBannerDismiss(PromotionalBanner banner, String screenName) async {
    await _analytics?.logEvent('promotional_banner_dismissed', {
      'banner_id': banner.id,
      'banner_title': banner.title,
      'screen_name': screenName,
    });
  }

  /// تتبع خطأ في البانر
  Future<void> trackBannerError(String bannerId, String error) async {
    await _analytics?.logEvent('promotional_banner_error', {
      'banner_id': bannerId,
      'error': error,
    });
  }
}