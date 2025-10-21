// lib/core/infrastructure/base/service_registration_helper.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// مساعد موحد لتسجيل الخدمات في ServiceLocator
///
/// يقلل التكرار ويوفر واجهة موحدة لتسجيل جميع أنواع الخدمات
class ServiceRegistrationHelper {
  final GetIt getIt;

  ServiceRegistrationHelper(this.getIt);

  /// تسجيل Singleton
  void registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    String? debugName,
  }) {
    if (getIt.isRegistered<T>(instanceName: instanceName)) {
      debugPrint('⚠️  [ServiceLocator] ${debugName ?? T} already registered');
      return;
    }

    getIt.registerSingleton<T>(instance, instanceName: instanceName);
    debugPrint('✅ [ServiceLocator] Registered Singleton: ${debugName ?? T}');
  }

  /// تسجيل LazySingleton
  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? instanceName,
    String? debugName,
    void Function(T)? dispose,
  }) {
    if (getIt.isRegistered<T>(instanceName: instanceName)) {
      debugPrint('⚠️  [ServiceLocator] ${debugName ?? T} already registered');
      return;
    }

    getIt.registerLazySingleton<T>(
      factory,
      instanceName: instanceName,
      dispose: dispose,
    );
    debugPrint('✅ [ServiceLocator] Registered LazySingleton: ${debugName ?? T}');
  }

  /// تسجيل Factory
  void registerFactory<T extends Object>(
    T Function() factory, {
    String? instanceName,
    String? debugName,
  }) {
    if (getIt.isRegistered<T>(instanceName: instanceName)) {
      debugPrint('⚠️  [ServiceLocator] ${debugName ?? T} already registered');
      return;
    }

    getIt.registerFactory<T>(factory, instanceName: instanceName);
    debugPrint('✅ [ServiceLocator] Registered Factory: ${debugName ?? T}');
  }

  /// تسجيل LazySingleton مع Dependencies
  void registerLazySingletonWithDeps<T extends Object>({
    required T Function() factory,
    required List<Type> dependencies,
    String? instanceName,
    String? debugName,
    void Function(T)? dispose,
  }) {
    // التحقق من التبعيات أولاً
    for (final dep in dependencies) {
      if (!getIt.isRegistered(instance: dep)) {
        debugPrint('❌ [ServiceLocator] Dependency $dep not found for ${debugName ?? T}');
        throw Exception('Dependency $dep not registered');
      }
    }

    registerLazySingleton<T>(
      factory,
      instanceName: instanceName,
      debugName: debugName,
      dispose: dispose,
    );
  }

  /// تسجيل مجموعة من الخدمات
  void registerGroup({
    required String groupName,
    required List<void Function()> registrations,
  }) {
    debugPrint('📦 [ServiceLocator] Registering group: $groupName');
    final stopwatch = Stopwatch()..start();

    for (final registration in registrations) {
      try {
        registration();
      } catch (e) {
        debugPrint('❌ [ServiceLocator] Error in $groupName: $e');
      }
    }

    stopwatch.stop();
    debugPrint('✅ [ServiceLocator] Group $groupName registered in ${stopwatch.elapsedMilliseconds}ms');
  }

  /// معلومات debug
  void printRegistrationStatus<T extends Object>() {
    final isRegistered = getIt.isRegistered<T>();
    final isReady = isRegistered ? getIt.isReadySync<T>() : false;

    debugPrint('📊 [ServiceLocator] Status for $T:');
    debugPrint('   - Registered: $isRegistered');
    debugPrint('   - Ready: $isReady');
  }
}

/// Extension لـ GetIt لتسهيل الاستخدام
extension GetItHelper on GetIt {
  /// تسجيل سريع لـ LazySingleton
  void lazyRegister<T extends Object>(
    T Function() factory, {
    String? name,
  }) {
    if (!isRegistered<T>(instanceName: name)) {
      registerLazySingleton<T>(factory, instanceName: name);
      debugPrint('✅ Registered: ${name ?? T}');
    }
  }

  /// تسجيل سريع لـ Singleton
  void singletonRegister<T extends Object>(
    T instance, {
    String? name,
  }) {
    if (!isRegistered<T>(instanceName: name)) {
      registerSingleton<T>(instance, instanceName: name);
      debugPrint('✅ Registered: ${name ?? T}');
    }
  }

  /// تسجيل سريع لـ Factory
  void factoryRegister<T extends Object>(
    T Function() factory, {
    String? name,
  }) {
    if (!isRegistered<T>(instanceName: name)) {
      registerFactory<T>(factory, instanceName: name);
      debugPrint('✅ Registered: ${name ?? T}');
    }
  }

  /// الحصول على خدمة بشكل آمن
  T? getSafe<T extends Object>() {
    try {
      return isRegistered<T>() ? get<T>() : null;
    } catch (e) {
      debugPrint('⚠️  Error getting service $T: $e');
      return null;
    }
  }

  /// التحقق من جاهزية الخدمة
  bool isServiceReady<T extends Object>() {
    return isRegistered<T>() && isReadySync<T>();
  }
}

/// Builder لتسجيل مجموعة من الخدمات المرتبطة
class ServiceGroupBuilder {
  final String groupName;
  final GetIt getIt;
  final List<void Function()> _registrations = [];

  ServiceGroupBuilder(this.groupName, this.getIt);

  /// إضافة LazySingleton
  ServiceGroupBuilder addLazy<T extends Object>(T Function() factory) {
    _registrations.add(() => getIt.lazyRegister<T>(factory));
    return this;
  }

  /// إضافة Singleton
  ServiceGroupBuilder addSingleton<T extends Object>(T instance) {
    _registrations.add(() => getIt.singletonRegister<T>(instance));
    return this;
  }

  /// إضافة Factory
  ServiceGroupBuilder addFactory<T extends Object>(T Function() factory) {
    _registrations.add(() => getIt.factoryRegister<T>(factory));
    return this;
  }

  /// تنفيذ التسجيل
  void register() {
    debugPrint('📦 Registering group: $groupName');
    final stopwatch = Stopwatch()..start();

    for (final registration in _registrations) {
      try {
        registration();
      } catch (e) {
        debugPrint('❌ Error in $groupName: $e');
      }
    }

    stopwatch.stop();
    debugPrint('✅ Group $groupName registered in ${stopwatch.elapsedMilliseconds}ms');
  }
}

/// دوال مساعدة عامة

/// إنشاء ServiceGroupBuilder
ServiceGroupBuilder createServiceGroup(String name, GetIt getIt) {
  return ServiceGroupBuilder(name, getIt);
}

/// تسجيل خدمات بشكل مجمع مع معالجة الأخطاء
Future<void> registerServicesAsync({
  required String groupName,
  required List<Future<void> Function()> asyncRegistrations,
}) async {
  debugPrint('📦 Registering async group: $groupName');
  final stopwatch = Stopwatch()..start();

  for (final registration in asyncRegistrations) {
    try {
      await registration();
    } catch (e, stack) {
      debugPrint('❌ Error in $groupName: $e');
      debugPrint('Stack: $stack');
    }
  }

  stopwatch.stop();
  debugPrint('✅ Async group $groupName registered in ${stopwatch.elapsedMilliseconds}ms');
}
