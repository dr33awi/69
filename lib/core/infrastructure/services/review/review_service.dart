// lib/core/infrastructure/services/review/review_service.dart

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// خدمة التقييم الذكية داخل التطبيق
/// 
/// توفر هذه الخدمة نظام تقييم ذكي يحسّن من فرص التقييم الإيجابي
/// من خلال:
/// - عرض نافذة التقييم في الوقت المناسب
/// - تتبع تفاعل المستخدم مع التطبيق
/// - عدم إزعاج المستخدم بشكل متكرر
class ReviewService {
  ReviewService({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;
  final InAppReview _inAppReview = InAppReview.instance;

  // ============== مفاتيح التخزين ==============
  static const String _keyAppLaunches = 'review_app_launches';
  static const String _keyLastReviewRequest = 'review_last_request_date';
  static const String _keyReviewCompleted = 'review_completed';
  static const String _keyReviewDeclined = 'review_declined';
  static const String _keySignificantActions = 'review_significant_actions';

  // ============== إعدادات التقييم ==============
  /// عدد مرات فتح التطبيق قبل عرض طلب التقييم
  static const int _minLaunchesBeforeReview = 5;

  /// عدد الإجراءات المهمة قبل عرض طلب التقييم
  static const int _minSignificantActionsBeforeReview = 10;

  /// الحد الأدنى من الأيام بين طلبات التقييم
  static const int _minDaysBetweenRequests = 30;

  /// معرف التطبيق على Google Play (يجب تحديثه)
  static const String _androidPackageName = 'com.dhakarani1.app';

  /// معرف التطبيق على App Store (يجب تحديثه إذا كان iOS)
  static const String _iosAppId = 'YOUR_IOS_APP_ID';

  // ============== الوظائف الرئيسية ==============

  /// زيادة عداد مرات تشغيل التطبيق
  Future<void> incrementAppLaunches() async {
    final count = _prefs.getInt(_keyAppLaunches) ?? 0;
    await _prefs.setInt(_keyAppLaunches, count + 1);
  }

  /// زيادة عداد الإجراءات المهمة
  /// 
  /// الإجراءات المهمة مثل:
  /// - قراءة ذكر كامل
  /// - مشاركة محتوى
  /// - إكمال مهمة
  Future<void> incrementSignificantActions() async {
    final count = _prefs.getInt(_keySignificantActions) ?? 0;
    await _prefs.setInt(_keySignificantActions, count + 1);
  }

  /// التحقق من توفر نافذة التقييم
  Future<bool> isReviewAvailable() async {
    try {
      return await _inAppReview.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// التحقق من أن المستخدم يستحق عرض طلب التقييم
  bool shouldRequestReview() {
    // إذا كان المستخدم قد قيّم أو رفض
    if (_prefs.getBool(_keyReviewCompleted) == true ||
        _prefs.getBool(_keyReviewDeclined) == true) {
      return false;
    }

    // التحقق من عدد مرات التشغيل
    final launches = _prefs.getInt(_keyAppLaunches) ?? 0;
    if (launches < _minLaunchesBeforeReview) {
      return false;
    }

    // التحقق من عدد الإجراءات المهمة
    final actions = _prefs.getInt(_keySignificantActions) ?? 0;
    if (actions < _minSignificantActionsBeforeReview) {
      return false;
    }

    // التحقق من الوقت منذ آخر طلب
    final lastRequestStr = _prefs.getString(_keyLastReviewRequest);
    if (lastRequestStr != null) {
      final lastRequest = DateTime.parse(lastRequestStr);
      final daysSinceLastRequest = DateTime.now().difference(lastRequest).inDays;
      
      if (daysSinceLastRequest < _minDaysBetweenRequests) {
        return false;
      }
    }
    return true;
  }

  /// طلب التقييم من المستخدم (نافذة النظام الأصلية)
  /// 
  /// [forceRequest] إذا كان true، يتجاوز التحقق من الشروط (للاستخدام من الإعدادات)
  Future<void> requestReview({bool forceRequest = false}) async {
    try {
      if (!forceRequest && !shouldRequestReview()) {
        return;
      }

      final available = await isReviewAvailable();
      if (!available) {
        return;
      }
      await _inAppReview.requestReview();
      
      // حفظ تاريخ آخر طلب
      await _prefs.setString(
        _keyLastReviewRequest,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
    }
  }

  /// فتح صفحة التطبيق في المتجر مباشرة
  Future<void> openStorePage() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: _iosAppId,
      );
      
      // وضع علامة على أن المستخدم أكمل عملية التقييم
      await _markReviewCompleted();
    } catch (e) {
      // محاولة بديلة لفتح الرابط
      await _openStorePageFallback();
    }
  }

  /// محاولة بديلة لفتح صفحة المتجر
  Future<void> _openStorePageFallback() async {
    try {
      final Uri storeUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.gof.global&pcampaignid=merch_published_cluster_promotion_battlestar_featured_games',
      );
      
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
        await _markReviewCompleted();
      }
    } catch (e) {
    }
  }

  /// وضع علامة على أن المستخدم أكمل التقييم
  Future<void> _markReviewCompleted() async {
    await _prefs.setBool(_keyReviewCompleted, true);
  }

  /// وضع علامة على أن المستخدم رفض التقييم
  Future<void> markReviewDeclined() async {
    await _prefs.setBool(_keyReviewDeclined, true);
    await _prefs.setString(
      _keyLastReviewRequest,
      DateTime.now().toIso8601String(),
    );
  }

  /// إعادة تعيين حالة التقييم (للاختبار فقط)
  Future<void> resetReviewState() async {
    await _prefs.remove(_keyAppLaunches);
    await _prefs.remove(_keyLastReviewRequest);
    await _prefs.remove(_keyReviewCompleted);
    await _prefs.remove(_keyReviewDeclined);
    await _prefs.remove(_keySignificantActions);
  }

  // ============== معلومات للمطورين ==============

  /// الحصول على إحصائيات التقييم (للتطوير والتصحيح)
  Map<String, dynamic> getReviewStats() {
    return {
      'appLaunches': _prefs.getInt(_keyAppLaunches) ?? 0,
      'significantActions': _prefs.getInt(_keySignificantActions) ?? 0,
      'lastRequest': _prefs.getString(_keyLastReviewRequest),
      'reviewCompleted': _prefs.getBool(_keyReviewCompleted) ?? false,
      'reviewDeclined': _prefs.getBool(_keyReviewDeclined) ?? false,
      'shouldRequest': shouldRequestReview(),
    };
  }

  /// طباعة إحصائيات التقييم
  void printReviewStats() {
    final stats = getReviewStats();
    stats.forEach((key, value) {
    });
  }
}
