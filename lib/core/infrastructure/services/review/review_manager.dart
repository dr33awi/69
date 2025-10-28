// lib/core/infrastructure/services/review/review_manager.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'review_service.dart';
import 'review_dialog.dart';

/// مدير التقييم الشامل
/// 
/// يدير عملية عرض طلبات التقييم والتفاعل مع المستخدم
class ReviewManager {
  ReviewManager({required ReviewService reviewService})
      : _reviewService = reviewService;

  final ReviewService _reviewService;

  // ============== الوظائف العامة ==============

  /// التحقق من إمكانية عرض طلب التقييم وعرضه إذا كان مناسباً
  /// 
  /// هذه هي الطريقة الأساسية التي يجب استدعاؤها من التطبيق
  /// يُفضل استدعاؤها في:
  /// - بعد إكمال مهمة مهمة
  /// - بعد تفاعل إيجابي من المستخدم
  /// - عند بدء التطبيق (إذا استوفى الشروط)
  Future<void> checkAndRequestReview(BuildContext context) async {
    // التحقق من أن المستخدم مؤهل
    if (!_reviewService.shouldRequestReview()) {
      return;
    }

    // التحقق من توفر النافذة الأصلية
    final isAvailable = await _reviewService.isReviewAvailable();
    
    if (isAvailable) {
      // عرض نافذة التقييم الأصلية مباشرة
      await _reviewService.requestReview();
    } else {
      // عرض مربع الحوار المخصص
      await _showCustomReviewDialog(context);
    }
  }

  /// عرض مربع حوار التقييم المخصص
  Future<void> _showCustomReviewDialog(BuildContext context) async {
    final result = await ReviewDialog.show(context);

    if (result == null) return;

    switch (result) {
      case ReviewDialogResult.rate:
        await _handleRateAction();
        break;
        
      case ReviewDialogResult.feedback:
        await _handleFeedbackAction();
        break;
        
      case ReviewDialogResult.later:
        await _handleLaterAction();
        break;
    }
  }

  /// معالجة اختيار التقييم
  Future<void> _handleRateAction() async {
    await _reviewService.openStorePage();
  }

  /// معالجة اختيار إرسال ملاحظات
  Future<void> _handleFeedbackAction() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'dhakarani.app@gmail.com',
      queryParameters: {
        'subject': 'ملاحظات على تطبيق ذكرني',
        'body': 'أود مشاركة ملاحظاتي التالية:\n\n',
      },
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
      }
    } catch (e) {
    }
    
    // اعتبار هذا تفاعل إيجابي
    await _reviewService.incrementSignificantActions();
  }

  /// معالجة اختيار "لاحقاً"
  Future<void> _handleLaterAction() async {
    await _reviewService.markReviewDeclined();
  }

  // ============== أدوات مساعدة ==============

  /// طلب التقييم بشكل مباشر (للاستخدام من الإعدادات)
  /// يعرض مربع الحوار المخصص دائماً لضمان تجربة مستخدم متسقة
  Future<void> requestReviewDirect(BuildContext context) async {
    // عرض مربع الحوار المخصص مباشرة
    // هذا يضمن أن المستخدم يرى خيارات واضحة دائماً
    await _showCustomReviewDialog(context);
  }

  /// فتح صفحة التطبيق في المتجر
  Future<void> openStorePage() async {
    await _reviewService.openStorePage();
  }

  /// زيادة عداد مرات تشغيل التطبيق
  Future<void> incrementAppLaunches() async {
    await _reviewService.incrementAppLaunches();
  }

  /// زيادة عداد الإجراءات المهمة
  Future<void> incrementSignificantActions() async {
    await _reviewService.incrementSignificantActions();
  }

  /// الحصول على إحصائيات التقييم
  Map<String, dynamic> getReviewStats() {
    return _reviewService.getReviewStats();
  }

  /// طباعة إحصائيات التقييم
  void printReviewStats() {
    _reviewService.printReviewStats();
  }

  /// إعادة تعيين حالة التقييم (للتطوير فقط)
  Future<void> resetReviewState() async {
    await _reviewService.resetReviewState();
  }
}
