# إصلاح مشكلة عدم طلب إذن الإشعارات

## المشكلة
عند الضغط على زر "تفعيل" في كارد الأذونات، لا يتم عرض نافذة طلب الإذن للمستخدم. بدلاً من ذلك، يتم إرجاع حالة `denied` مباشرة.

## السبب
على Android 13+، إذا تم رفض إذن الإشعارات مرتين، يصبح الإذن `permanentlyDenied` ولا يمكن طلبه مرة أخرى من خلال التطبيق. يجب على المستخدم تفعيله يدوياً من إعدادات النظام.

## من اللوجات
```
🔔 [NotificationHandler] Requesting notification permission...
🔔 [NotificationHandler] Permission status: PermissionStatus.denied
❌ [NotificationHandler] Permission denied on Android
```

المشكلة: لم يتم التحقق من الحالة قبل الطلب، ولم يتم توجيه المستخدم للإعدادات إذا كان الإذن مرفوض نهائياً.

## الحلول المطبقة

### 1. تحسين `NotificationHandler` للتحقق من الحالة قبل الطلب
```dart
@override
Future<AppPermissionStatus> request() async {
  // التحقق من الحالة الحالية أولاً
  final currentStatus = await nativePermission!.status;
  debugPrint('🔔 Current status before request: ${currentStatus.toString()}');
  
  // إذا كانت مرفوضة بشكل نهائي، نُرجع ذلك مباشرة
  if (currentStatus.isPermanentlyDenied) {
    debugPrint('⚠️ Permission is permanently denied, needs settings');
    return AppPermissionStatus.permanentlyDenied;
  }
  
  // إذا كانت مُمنوحة بالفعل
  if (currentStatus.isGranted) {
    debugPrint('✅ Permission already granted');
    return AppPermissionStatus.granted;
  }
  
  // الآن نطلب الإذن
  final status = await nativePermission!.request();
  
  // معالجة النتيجة...
}
```

### 2. توجيه مباشر للإعدادات في `PermissionMonitor`
```dart
Future<void> _handlePermissionRequest() async {
  // التحقق من الحالة الحالية أولاً
  final currentStatus = await _permissionService
      .checkPermissionStatus(_currentPermission!);
  
  // إذا كان مرفوض بشكل نهائي، نفتح حوار مباشر
  if (currentStatus == AppPermissionStatus.permanentlyDenied) {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفعيل الإذن من الإعدادات'),
        content: Text(
          'هذا الإذن مرفوض بشكل نهائي. '
          'يرجى تفعيله من إعدادات التطبيق.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('فتح الإعدادات'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldOpenSettings) {
      _permissionService.openAppSettings();
      _userWentToSettings = true;
    }
    return;
  }
  
  // محاولة طلب الإذن...
}
```

### 3. رسائل واضحة للمستخدم
```dart
// بعد فشل الطلب
if (status == AppPermissionStatus.permanentlyDenied) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('يرجى تفعيل الإذن من إعدادات النظام'),
      backgroundColor: Colors.orange,
      action: SnackBarAction(
        label: 'الإعدادات',
        onPressed: () => _permissionService.openAppSettings(),
      ),
      duration: const Duration(seconds: 5),
    ),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'لم يتم منح الإذن. '
        'يمكنك المحاولة مرة أخرى أو تفعيله من الإعدادات.'
      ),
    ),
  );
}
```

## سيناريوهات الاستخدام

### السيناريو 1: الإذن مرفوض عادي
1. المستخدم يضغط "تفعيل"
2. يظهر نافذة طلب الإذن من النظام
3. المستخدم يرفض
4. يُعرض رسالة "لم يتم منح الإذن..."

### السيناريو 2: الإذن مرفوض نهائياً
1. المستخدم يضغط "تفعيل"
2. يظهر حوار "تفعيل الإذن من الإعدادات"
3. المستخدم يختار "فتح الإعدادات"
4. يُفتح إعدادات التطبيق
5. المستخدم يفعّل الإذن
6. عند العودة، يتم فحص الإذن تلقائياً

### السيناريو 3: الإذن مُمنوح بالفعل
1. المستخدم يضغط "تفعيل"
2. يتم التحقق من أن الإذن ممنوح
3. يُعرض رسالة نجاح

## الملفات المعدلة
1. `lib/core/infrastructure/services/permissions/handlers/notification_handler.dart`
   - إضافة فحص الحالة قبل الطلب
   - معالجة أفضل لحالة `permanentlyDenied`

2. `lib/core/infrastructure/services/permissions/widgets/permission_monitor.dart`
   - توجيه مباشر للإعدادات إذا كان الإذن مرفوض نهائياً
   - رسائل واضحة للمستخدم حسب الحالة

## النتيجة المتوقعة
- ✅ إذا كان الإذن مرفوض عادي → تظهر نافذة طلب الإذن
- ✅ إذا كان الإذن مرفوض نهائياً → يُفتح حوار لتوجيه للإعدادات
- ✅ رسائل واضحة للمستخدم في كل الحالات
- ✅ تجربة مستخدم سلسة ومفهومة

## ملاحظات خاصة بـ Android
- **Android 13+**: إذن الإشعارات يتطلب runtime permission
- **إذن مرفوض مرتين**: يصبح `permanentlyDenied` تلقائياً
- **الحل**: يجب على المستخدم تفعيله من الإعدادات

## كيفية اختبار الإصلاح
1. **اختبار الرفض العادي**:
   - احذف التطبيق وأعد تثبيته
   - افتح التطبيق → يظهر كارد الأذونات
   - اضغط "تفعيل" → يجب أن تظهر نافذة طلب الإذن
   - ارفض الإذن
   - يجب أن يُعرض رسالة واضحة

2. **اختبار الرفض النهائي**:
   - ارفض الإذن مرتين
   - اضغط "تفعيل" مرة أخرى
   - يجب أن يظهر حوار "تفعيل الإذن من الإعدادات"
   - اضغط "فتح الإعدادات"
   - فعّل الإذن من الإعدادات
   - عد للتطبيق → يجب أن يختفي الكارد

3. **اختبار الإذن الممنوح**:
   - إذا كان الإذن ممنوح بالفعل
   - اضغط "تفعيل" → يجب أن يُعرض رسالة نجاح مباشرة

---
**تاريخ الإصلاح**: 18 أكتوبر 2025
**المطور**: GitHub Copilot
