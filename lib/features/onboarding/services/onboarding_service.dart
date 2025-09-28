// lib/features/onboarding/services/onboarding_service.dart
import '../../../core/infrastructure/services/storage/storage_service.dart';

class OnboardingService {
  final StorageService _storage;
  
  OnboardingService(this._storage);
  
  /// فحص إذا كان المستخدم قد أكمل الـ onboarding
  bool get isOnboardingCompleted => 
      _storage.getBool('onboarding_completed') ?? false;
  
  /// فحص إذا كان المستخدم قد تخطى الـ onboarding
  bool get isOnboardingSkipped => 
      _storage.getBool('onboarding_skipped') ?? false;
  
  /// هل يحتاج المستخدم لمشاهدة الـ onboarding
  bool get shouldShowOnboarding => 
      !isOnboardingCompleted && !isOnboardingSkipped;
  
  /// تسجيل اكتمال الـ onboarding
  Future<void> markOnboardingCompleted() async {
    await _storage.setBool('onboarding_completed', true);
    await _storage.setString('onboarding_completed_at', DateTime.now().toIso8601String());
  }
  
  /// تسجيل تخطي الـ onboarding
  Future<void> markOnboardingSkipped() async {
    await _storage.setBool('onboarding_skipped', true);
    await _storage.setString('onboarding_skipped_at', DateTime.now().toIso8601String());
  }
  
  /// إعادة تعيين حالة الـ onboarding (للتطوير)
  Future<void> resetOnboarding() async {
    await _storage.remove('onboarding_completed');
    await _storage.remove('onboarding_skipped');
    await _storage.remove('onboarding_completed_at');
    await _storage.remove('onboarding_skipped_at');
  }
}