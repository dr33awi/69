// lib/core/infrastructure/services/storage/storage_service.dart

abstract class StorageService {
  // ==================== String Operations ====================
  Future<bool> setString(String key, String value);
  String? getString(String key);
  
  // ==================== Int Operations ====================
  Future<bool> setInt(String key, int value);
  int? getInt(String key);
  
  // ==================== Double Operations ====================
  Future<bool> setDouble(String key, double value);
  double? getDouble(String key);
  
  // ==================== Bool Operations ====================
  Future<bool> setBool(String key, bool value);
  bool? getBool(String key);
  
  // ==================== List Operations ====================
  Future<bool> setStringList(String key, List<String> value);
  List<String>? getStringList(String key);
  
  // Generic List operations for complex data
  Future<bool> setList(String key, List<dynamic> value);
  List<dynamic>? getList(String key);
  
  // ==================== Map Operations ====================
  Future<bool> setMap(String key, Map<String, dynamic> value);
  Map<String, dynamic>? getMap(String key);
  
  // ==================== Utility Operations ====================
  
  /// Remove a specific key
  Future<bool> remove(String key);
  
  /// Clear all data
  Future<bool> clear();
  
  /// Check if key exists
  bool containsKey(String key);
  
  /// Get all keys
  Set<String> getKeys();
  

  Future<ClearPrefixResult> clearPrefix(String prefix);
  
  Future<Map<String, ClearPrefixResult>> clearMultiplePrefixes(
    List<String> prefixes,
  );
  
  /// عدّ المفاتيح التي تبدأ بنص معين (بدون حذف)
  int countKeysWithPrefix(String prefix);
  
  /// الحصول على قائمة المفاتيح التي تبدأ بنص معين
  List<String> getKeysWithPrefix(String prefix);
}

// ==================== Result Classes ====================

/// نتيجة عملية مسح المفاتيح بالبادئة
class ClearPrefixResult {
  /// هل نجحت العملية بالكامل
  final bool success;
  
  /// عدد المفاتيح المحذوفة
  final int deletedCount;
  
  /// إجمالي المفاتيح التي تم العثور عليها
  final int totalFound;
  
  /// المفاتيح التي فشل حذفها
  final List<String> failedKeys;
  
  /// رسالة النتيجة
  final String? message;
  
  /// رسالة الخطأ (إن وجد)
  final String? errorMessage;

  const ClearPrefixResult({
    required this.success,
    required this.deletedCount,
    this.totalFound = 0,
    this.failedKeys = const [],
    this.message,
    this.errorMessage,
  });

  /// هل تم حذف أي مفاتيح
  bool get hasDeletedKeys => deletedCount > 0;

  /// هل فشل حذف بعض المفاتيح
  bool get hasFailedKeys => failedKeys.isNotEmpty;

  /// نسبة النجاح
  double get successRate {
    if (totalFound == 0) return 0.0;
    return (deletedCount / totalFound) * 100;
  }

  @override
  String toString() {
    return 'ClearPrefixResult('
        'success: $success, '
        'deleted: $deletedCount/$totalFound, '
        'failed: ${failedKeys.length}'
        ')';
  }
}