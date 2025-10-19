# إصلاح مشكلة ظهور كارد الأذونات في كل مرة

## المشكلة
عند فتح التطبيق، كان كارد طلب الأذونات يظهر في كل مرة حتى بعد منح الأذونات، مع ظهور خطأ null check عند محاولة طلب الإذن.

## الأعراض
1. كارد الأذونات يظهر في كل فتحة للتطبيق
2. الأذونات تظهر بحالة `unknown` بسبب throttling
3. خطأ `Null check operator used on a null value` عند الضغط على "تفعيل"

## السبب
1. **عدم حفظ حالة الأذونات**: لم يكن هناك آلية لحفظ أن الأذونات قد منحت مسبقاً
2. **تعامل خاطئ مع حالة unknown**: الكارد كان يظهر حتى للأذونات بحالة `unknown`
3. **معالجة خطأ ناقصة**: لم تكن هناك معالجة صحيحة للأخطاء والـ context في حالة null

## الحل المطبق

### 1. حفظ حالة الأذونات (`permission_manager.dart`)
```dart
// إضافة مفاتيح للتخزين
static const String _keyPermissionsGranted = 'permissions_all_granted';
static const String _keyLastPermissionCheck = 'last_permission_check_time';

// دالة لحفظ الحالة
Future<void> _savePermissionsState(bool allGranted) async {
  await _storage.setBool(_keyPermissionsGranted, allGranted);
  await _storage.setString(
    _keyLastPermissionCheck,
    DateTime.now().toIso8601String(),
  );
}

// دالة للتحقق من الحالة المحفوظة
bool _arePermissionsPreviouslyGranted() {
  final wasGranted = _storage.getBool(_keyPermissionsGranted) ?? false;
  if (wasGranted) {
    final lastCheckStr = _storage.getString(_keyLastPermissionCheck);
    if (lastCheckStr != null) {
      final lastCheck = DateTime.parse(lastCheckStr);
      final daysSinceCheck = DateTime.now().difference(lastCheck).inDays;
      // تعتبر الحالة صالحة لمدة 7 أيام
      return daysSinceCheck < 7;
    }
  }
  return false;
}
```

### 2. استخدام الحالة المحفوظة في الفحص الأولي
```dart
Future<PermissionCheckResult> performInitialCheck() async {
  // التحقق من الأذونات المحفوظة مسبقاً
  if (_arePermissionsPreviouslyGranted()) {
    _log('✅ Using cached permissions state (previously granted)');
    _hasCheckedThisSession = true;
    
    // إنشاء نتيجة نجاح افتراضية
    final successResult = PermissionCheckResult.success(
      granted: criticalPermissions,
      statuses: Map.fromEntries(
        criticalPermissions.map(
          (p) => MapEntry(p, AppPermissionStatus.granted),
        ),
      ),
    );
    
    _lastCheckResult = successResult;
    _lastEmittedResult = successResult;
    _stateController.add(successResult);
    
    return successResult;
  }
  
  // باقي الكود للفحص الفعلي...
}
```

### 3. تحسين فلترة الأذونات في PermissionMonitor
```dart
void _processCheckResult(PermissionCheckResult result) {
  // فلترة الأذونات المفقودة فعلياً (استبعاد unknown)
  final actuallyMissing = result.missingPermissions
      .where((p) => PermissionConstants.isCritical(p))
      .where((p) {
        final status = result.statuses[p];
        // فقط الأذونات المرفوضة فعلياً، ليس unknown
        return status != null && 
               status != AppPermissionStatus.granted &&
               status != AppPermissionStatus.unknown;
      })
      .toList();
  
  // عرض الإشعار فقط إذا كانت هناك أذونات مفقودة فعلياً
  if (actuallyMissing.isNotEmpty && 
      widget.showNotifications && 
      !_isShowingNotification) {
    // عرض الكارد
  } else if (actuallyMissing.isEmpty) {
    debugPrint('[PermissionMonitor] ✅ All critical permissions granted - not showing notification');
  }
}
```

### 4. معالجة أفضل للأخطاء في طلب الأذونات
```dart
Future<void> _handlePermissionRequest() async {
  if (_currentPermission == null || _isProcessing || !mounted) return;
  
  setState(() => _isProcessing = true);
  
  try {
    final granted = await _manager.requestPermissionWithExplanation(
      context,
      _currentPermission!,
      forceRequest: true,
    );
    
    if (!mounted) return;
    
    // معالجة النتيجة...
    
  } catch (e, stackTrace) {
    debugPrint('[PermissionMonitor] ❌ Error: $e');
    debugPrint('[PermissionMonitor] Stack trace: $stackTrace');
    
    if (mounted) {
      setState(() => _isProcessing = false);
      
      // عرض رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء طلب الإذن...'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

## الملفات المعدلة
1. `lib/core/infrastructure/services/permissions/permission_manager.dart`
   - إضافة حفظ وقراءة حالة الأذونات من SharedPreferences
   - تحسين منطق الفحص الأولي

2. `lib/core/infrastructure/services/permissions/widgets/permission_monitor.dart`
   - تحسين فلترة الأذونات لاستبعاد `unknown`
   - معالجة أفضل للأخطاء والـ context
   - إضافة فحوصات `mounted` في كل مكان مناسب

## النتيجة المتوقعة
1. ✅ الكارد لن يظهر إذا كانت الأذونات ممنوحة مسبقاً (خلال 7 أيام)
2. ✅ الكارد لن يظهر للأذونات بحالة `unknown`
3. ✅ معالجة صحيحة للأخطاء مع رسائل واضحة للمستخدم
4. ✅ تجربة أفضل بدون إزعاج غير ضروري

## ملاحظات
- مدة صلاحية الحالة المحفوظة: 7 أيام
- بعد 7 أيام، سيتم الفحص الفعلي مرة أخرى للتأكد
- الحالة المحفوظة تُحدث تلقائياً عند كل فحص ناجح

## اختبار الإصلاح
1. افتح التطبيق لأول مرة → يجب أن يظهر الكارد للأذونات المفقودة
2. امنح الأذونات المطلوبة
3. أغلق التطبيق وافتحه مرة أخرى → يجب ألا يظهر الكارد
4. كرر عدة مرات → يجب ألا يظهر الكارد

---
**تاريخ الإصلاح**: 18 أكتوبر 2025
**المطور**: GitHub Copilot
