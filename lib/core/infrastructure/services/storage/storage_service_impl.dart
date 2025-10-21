// lib/core/infrastructure/services/storage/storage_service_impl.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class StorageServiceImpl implements StorageService {
  final SharedPreferences _prefs;

  StorageServiceImpl(this._prefs);

  // ==================== String Operations ====================
  
  @override
  Future<bool> setString(String key, String value) async {
    try {
      final result = await _prefs.setString(key, value);
      _log('Set string', {'key': key});
      return result;
    } catch (e) {
      _logError('Failed to set string', e);
      return false;
    }
  }

  @override
  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e) {
      _logError('Failed to get string', e);
      return null;
    }
  }

  // ==================== Int Operations ====================
  
  @override
  Future<bool> setInt(String key, int value) async {
    try {
      final result = await _prefs.setInt(key, value);
      _log('Set int', {'key': key, 'value': value});
      return result;
    } catch (e) {
      _logError('Failed to set int', e);
      return false;
    }
  }

  @override
  int? getInt(String key) {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      _logError('Failed to get int', e);
      return null;
    }
  }

  // ==================== Double Operations ====================
  
  @override
  Future<bool> setDouble(String key, double value) async {
    try {
      final result = await _prefs.setDouble(key, value);
      _log('Set double', {'key': key, 'value': value});
      return result;
    } catch (e) {
      _logError('Failed to set double', e);
      return false;
    }
  }

  @override
  double? getDouble(String key) {
    try {
      return _prefs.getDouble(key);
    } catch (e) {
      _logError('Failed to get double', e);
      return null;
    }
  }

  // ==================== Bool Operations ====================
  
  @override
  Future<bool> setBool(String key, bool value) async {
    try {
      final result = await _prefs.setBool(key, value);
      _log('Set bool', {'key': key, 'value': value});
      return result;
    } catch (e) {
      _logError('Failed to set bool', e);
      return false;
    }
  }

  @override
  bool? getBool(String key) {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      _logError('Failed to get bool', e);
      return null;
    }
  }

  // ==================== List Operations ====================
  
  @override
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      final result = await _prefs.setStringList(key, value);
      _log('Set string list', {'key': key, 'count': value.length});
      return result;
    } catch (e) {
      _logError('Failed to set string list', e);
      return false;
    }
  }

  @override
  List<String>? getStringList(String key) {
    try {
      return _prefs.getStringList(key);
    } catch (e) {
      _logError('Failed to get string list', e);
      return null;
    }
  }

  // ==================== Generic List Operations ====================
  
  @override
  Future<bool> setList(String key, List<dynamic> value) async {
    try {
      // Convert list to JSON string for storage
      final jsonString = jsonEncode(value);
      final result = await _prefs.setString(key, jsonString);
      _log('Set list', {'key': key, 'count': value.length});
      return result;
    } catch (e) {
      _logError('Failed to set list', e);
      return false;
    }
  }

  @override
  List<dynamic>? getList(String key) {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return null;
      
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded;
      }
      return null;
    } catch (e) {
      _logError('Failed to get list', e);
      return null;
    }
  }

  // ==================== Map Operations ====================
  
  @override
  Future<bool> setMap(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      final result = await _prefs.setString(key, jsonString);
      _log('Set map', {'key': key});
      return result;
    } catch (e) {
      _logError('Failed to set map', e);
      return false;
    }
  }

  @override
  Map<String, dynamic>? getMap(String key) {
    try {
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return null;
      
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      _logError('Failed to get map', e);
      return null;
    }
  }

  // ==================== Utility Operations ====================
  
  @override
  Future<bool> remove(String key) async {
    try {
      final result = await _prefs.remove(key);
      _log('Removed key', {'key': key});
      return result;
    } catch (e) {
      _logError('Failed to remove key', e);
      return false;
    }
  }

  @override
  Future<bool> clear() async {
    try {
      final result = await _prefs.clear();
      _logWarning('Cleared all data');
      return result;
    } catch (e) {
      _logError('Failed to clear', e);
      return false;
    }
  }

  @override
  bool containsKey(String key) {
    try {
      return _prefs.containsKey(key);
    } catch (e) {
      _logError('Failed to check key', e);
      return false;
    }
  }

  @override
  Set<String> getKeys() {
    try {
      return _prefs.getKeys();
    } catch (e) {
      _logError('Failed to get keys', e);
      return {};
    }
  }

  // ==================== NEW: Prefix Operations ====================
  
  @override
  Future<ClearPrefixResult> clearPrefix(String prefix) async {
    try {
      if (prefix.isEmpty) {
        _logWarning('clearPrefix called with empty prefix');
        return const ClearPrefixResult(
          success: false,
          deletedCount: 0,
          errorMessage: 'البادئة لا يمكن أن تكون فارغة',
        );
      }

      // الحصول على جميع المفاتيح
      final allKeys = _prefs.getKeys();
      
      // تصفية المفاتيح التي تبدأ بالـ prefix
      final keysToDelete = allKeys.where((key) => key.startsWith(prefix)).toList();
      
      if (keysToDelete.isEmpty) {
        _log('No keys found with prefix', {'prefix': prefix});
        return ClearPrefixResult(
          success: true,
          deletedCount: 0,
          totalFound: 0,
          message: 'لم يتم العثور على مفاتيح للحذف',
        );
      }

      // حذف المفاتيح
      int deletedCount = 0;
      final List<String> failedKeys = [];

      for (final key in keysToDelete) {
        try {
          final removed = await _prefs.remove(key);
          if (removed) {
            deletedCount++;
          } else {
            failedKeys.add(key);
          }
        } catch (e) {
          _logError('Failed to remove key during clearPrefix', e);
          failedKeys.add(key);
        }
      }

      final isFullSuccess = failedKeys.isEmpty;
      
      if (isFullSuccess) {
        _log('Successfully cleared prefix', {
          'prefix': prefix,
          'deleted': deletedCount,
        });
      } else {
        _logWarning(
          'Partially cleared prefix: $prefix. '
          'Deleted: $deletedCount, Failed: ${failedKeys.length}'
        );
      }

      return ClearPrefixResult(
        success: isFullSuccess,
        deletedCount: deletedCount,
        totalFound: keysToDelete.length,
        failedKeys: failedKeys,
        message: isFullSuccess
            ? 'تم مسح $deletedCount مفتاح بنجاح'
            : 'تم مسح $deletedCount من ${keysToDelete.length} مفتاح',
      );
    } catch (e) {
      _logError('Failed to clear prefix', e);
      return ClearPrefixResult(
        success: false,
        deletedCount: 0,
        errorMessage: 'حدث خطأ: $e',
      );
    }
  }

  @override
  Future<Map<String, ClearPrefixResult>> clearMultiplePrefixes(
    List<String> prefixes,
  ) async {
    final results = <String, ClearPrefixResult>{};

    for (final prefix in prefixes) {
      results[prefix] = await clearPrefix(prefix);
    }

    final totalDeleted = results.values.fold<int>(
      0,
      (sum, result) => sum + result.deletedCount,
    );

    _log('Cleared multiple prefixes', {
      'prefixes': prefixes.length,
      'totalDeleted': totalDeleted,
    });

    return results;
  }

  @override
  int countKeysWithPrefix(String prefix) {
    try {
      if (prefix.isEmpty) {
        _logWarning('countKeysWithPrefix called with empty prefix');
        return 0;
      }
      
      final allKeys = _prefs.getKeys();
      final count = allKeys.where((key) => key.startsWith(prefix)).length;
      
      return count;
    } catch (e) {
      _logError('Failed to count keys with prefix', e);
      return 0;
    }
  }

  @override
  List<String> getKeysWithPrefix(String prefix) {
    try {
      if (prefix.isEmpty) {
        _logWarning('getKeysWithPrefix called with empty prefix');
        return [];
      }
      
      final allKeys = _prefs.getKeys();
      return allKeys.where((key) => key.startsWith(prefix)).toList();
    } catch (e) {
      _logError('Failed to get keys with prefix', e);
      return [];
    }
  }

  // ==================== Simple Logging Methods ====================

  void _log(String message, Map<String, dynamic>? data) {
    if (kDebugMode) {
    }
  }

  void _logWarning(String message) {
    if (kDebugMode) {
    }
  }

  void _logError(String message, dynamic error) {
    if (kDebugMode) {
    }
  }
}