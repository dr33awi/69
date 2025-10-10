// lib/features/dua/data/dua_data.dart - محدث للبيانات الجديدة
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dua_model.dart';

/// بيانات الأدعية من ملف JSON المحدث
class DuaData {
  static Map<String, dynamic>? _cachedData;
  static DateTime? _cacheTimestamp;
  static const Duration _loadTimeout = Duration(seconds: 10);
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  /// تحميل البيانات من ملف JSON مع timeout وcache expiry
  static Future<Map<String, dynamic>> _loadData() async {
    // التحقق من صلاحية الكاش
    if (_cachedData != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < _cacheExpiry) {
        debugPrint('✅ استخدام البيانات من الكاش (عمر الكاش: ${cacheAge.inMinutes} دقيقة)');
        return _cachedData!;
      } else {
        debugPrint('⚠️ انتهت صلاحية الكاش، إعادة التحميل...');
      }
    }
    
    try {
      final String jsonString = await rootBundle
          .loadString('assets/data/duas_data.json')
          .timeout(
            _loadTimeout,
            onTimeout: () {
              throw TimeoutException('انتهت مهلة تحميل ملف الأدعية');
            },
          );
      
      final dynamic decoded = json.decode(jsonString);
      
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('صيغة ملف JSON غير صحيحة');
      }
      
      _cachedData = decoded;
      _cacheTimestamp = DateTime.now();
      
      // التحقق من البنية الأساسية
      _validateDataStructure(_cachedData!);
      
      debugPrint('✅ تم تحميل بيانات الأدعية بنجاح');
      return _cachedData!;
    } on TimeoutException catch (e) {
      debugPrint('❌ خطأ timeout: $e');
      throw Exception('انتهت مهلة تحميل بيانات الأدعية');
    } on FormatException catch (e) {
      debugPrint('❌ خطأ في صيغة JSON: $e');
      throw Exception('خطأ في صيغة ملف الأدعية');
    } catch (e) {
      debugPrint('❌ فشل في تحميل بيانات الأدعية: $e');
      throw Exception('فشل في تحميل بيانات الأدعية: $e');
    }
  }

  /// التحقق من بنية البيانات
  static void _validateDataStructure(Map<String, dynamic> data) {
    if (!data.containsKey('categories')) {
      throw FormatException('لا يحتوي الملف على مفتاح "categories"');
    }
    
    if (!data.containsKey('duas')) {
      throw FormatException('لا يحتوي الملف على مفتاح "duas"');
    }
    
    if (data['categories'] is! List) {
      throw FormatException('مفتاح "categories" يجب أن يكون قائمة');
    }
    
    if (data['duas'] is! Map) {
      throw FormatException('مفتاح "duas" يجب أن يكون كائن');
    }
    
    final List categories = data['categories'];
    if (categories.isEmpty) {
      debugPrint('⚠️ تحذير: قائمة الفئات فارغة');
    }
  }

  /// الحصول على جميع فئات الأدعية
  static Future<List<DuaCategory>> getCategories() async {
    try {
      final data = await _loadData();
      final List categoriesData = data['categories'] ?? [];
      
      if (categoriesData.isEmpty) {
        debugPrint('⚠️ لا توجد فئات في ملف البيانات');
        return [];
      }
      
      final List<DuaCategory> categories = [];
      
      for (var categoryData in categoriesData) {
        try {
          if (categoryData is! Map<String, dynamic>) {
            debugPrint('⚠️ تخطي فئة بصيغة غير صحيحة');
            continue;
          }
          
          final categoryId = categoryData['id'];
          if (categoryId == null || categoryId.toString().isEmpty) {
            debugPrint('⚠️ تخطي فئة بدون معرف');
            continue;
          }
          
          final duasData = data['duas'][categoryId] ?? [];
          final typeIndex = categoryData['type'] ?? 0;
          
          // التحقق من صحة نوع الفئة
          DuaType type = DuaType.general;
          if (typeIndex >= 0 && typeIndex < DuaType.values.length) {
            type = DuaType.values[typeIndex];
          }
          
          categories.add(DuaCategory(
            id: categoryData['id']?.toString() ?? '',
            name: categoryData['name']?.toString() ?? 'بدون اسم',
            description: categoryData['description']?.toString() ?? '',
            type: type,
            duaCount: duasData is List ? duasData.length : 0,
            icon: categoryData['icon']?.toString(),
          ));
        } catch (e) {
          debugPrint('⚠️ خطأ في معالجة فئة: $e');
          continue;
        }
      }
      
      debugPrint('✅ تم تحميل ${categories.length} فئة');
      
      // ✅ إضافة إحصائيات كل فئة
      for (var category in categories) {
        final categoryDuas = data['duas'][category.id];
        if (categoryDuas is List) {
          debugPrint('📊 الفئة "${category.name}": ${categoryDuas.length} دعاء');
        }
      }
      
      return categories;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الفئات: $e');
      return [];
    }
  }

  /// الحصول على جميع الأدعية
  static Future<List<Dua>> getAllDuas() async {
    try {
      final data = await _loadData();
      final Map<String, dynamic> duasData = data['duas'] ?? {};
      
      if (duasData.isEmpty) {
        debugPrint('⚠️ لا توجد أدعية في ملف البيانات');
        return [];
      }
      
      final List<Dua> allDuas = [];
      final Map<String, int> categoryCount = {};
      
      for (var entry in duasData.entries) {
        final categoryDuas = entry.value;
        
        if (categoryDuas is! List) {
          debugPrint('⚠️ تخطي فئة بصيغة غير صحيحة: ${entry.key}');
          continue;
        }
        
        categoryCount[entry.key] = 0;
        
        for (var duaData in categoryDuas) {
          try {
            if (duaData is! Map<String, dynamic>) {
              debugPrint('⚠️ تخطي دعاء بصيغة غير صحيحة');
              continue;
            }
            
            // ✅ التأكد من أن categoryId موجود
            if (duaData['categoryId'] == null) {
              duaData['categoryId'] = entry.key;
            }
            
            allDuas.add(_parseDua(duaData));
            categoryCount[entry.key] = (categoryCount[entry.key] ?? 0) + 1;
          } catch (e) {
            debugPrint('⚠️ خطأ في معالجة دعاء: $e');
            continue;
          }
        }
      }
      
      debugPrint('✅ تم تحميل ${allDuas.length} دعاء إجمالاً');
      
      // ✅ عرض الإحصائيات
      categoryCount.forEach((category, count) {
        String categoryName;
        switch (category) {
          case 'quran':
            categoryName = 'القرآن الكريم';
            break;
          case 'sahihain':
            categoryName = 'الصحيحين';
            break;
          case 'sunan':
            categoryName = 'السنن';
            break;
          case 'other_authentic':
            categoryName = 'أحاديث صحيحة أخرى';
            break;
          default:
            categoryName = category;
        }
        debugPrint('📖 $categoryName: $count دعاء');
      });
      
      return allDuas;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على جميع الأدعية: $e');
      return [];
    }
  }

  /// الحصول على الأدعية حسب الفئة
  static Future<List<Dua>> getDuasByCategory(String categoryId) async {
    try {
      final data = await _loadData();
      final categoryDuas = data['duas'][categoryId];
      
      if (categoryDuas == null) {
        debugPrint('⚠️ لا توجد أدعية للفئة: $categoryId');
        return [];
      }
      
      if (categoryDuas is! List) {
        debugPrint('⚠️ صيغة أدعية الفئة غير صحيحة: $categoryId');
        return [];
      }
      
      final List<Dua> duas = [];
      
      for (var duaData in categoryDuas) {
        try {
          if (duaData is! Map<String, dynamic>) {
            debugPrint('⚠️ تخطي دعاء بصيغة غير صحيحة');
            continue;
          }
          
          // ✅ التأكد من أن categoryId موجود
          if (duaData['categoryId'] == null) {
            duaData['categoryId'] = categoryId;
          }
          
          duas.add(_parseDua(duaData));
        } catch (e) {
          debugPrint('⚠️ خطأ في معالجة دعاء: $e');
          continue;
        }
      }
      
      String categoryName;
      switch (categoryId) {
        case 'quran':
          categoryName = 'أدعية من القرآن الكريم';
          break;
        case 'sahihain':
          categoryName = 'أدعية من الصحيحين';
          break;
        case 'sunan':
          categoryName = 'أدعية من السنن';
          break;
        case 'other_authentic':
          categoryName = 'أدعية صحيحة أخرى';
          break;
        default:
          categoryName = categoryId;
      }
      
      debugPrint('✅ تم تحميل ${duas.length} دعاء من فئة: $categoryName');
      return duas;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على أدعية الفئة $categoryId: $e');
      return [];
    }
  }

  /// تحليل دعاء من Map
  static Dua _parseDua(Map<String, dynamic> duaData) {
    final id = duaData['id']?.toString();
    final title = duaData['title']?.toString();
    final arabicText = duaData['arabicText']?.toString();
    final categoryId = duaData['categoryId']?.toString();
    
    if (id == null || id.isEmpty) {
      throw FormatException('معرف الدعاء مفقود');
    }
    
    if (title == null || title.isEmpty) {
      throw FormatException('عنوان الدعاء مفقود');
    }
    
    if (arabicText == null || arabicText.isEmpty) {
      throw FormatException('نص الدعاء مفقود');
    }
    
    if (categoryId == null || categoryId.isEmpty) {
      throw FormatException('معرف الفئة مفقود');
    }
    
    final typeIndex = duaData['type'] ?? 0;
    DuaType type = DuaType.general;
    
    if (typeIndex >= 0 && typeIndex < DuaType.values.length) {
      type = DuaType.values[typeIndex];
    }
    
    return Dua(
      id: id,
      title: title,
      arabicText: arabicText,
      transliteration: duaData['transliteration']?.toString(),
      translation: duaData['translation']?.toString(),
      source: duaData['source']?.toString(),
      reference: duaData['reference']?.toString(),
      categoryId: categoryId,
      virtue: duaData['virtue']?.toString(), // ✅ إضافة الفضل
      tags: _parseTags(duaData['tags']),
      order: duaData['order'] as int?,
      type: type,
    );
  }

  /// تحليل قائمة الوسوم
  static List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    
    if (tags is List) {
      return tags
          .where((tag) => tag != null)
          .map((tag) => tag.toString())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }
    
    return [];
  }

  /// مسح الذاكرة المؤقتة (للاختبار أو إعادة التحميل)
  static void clearCache() {
    _cachedData = null;
    _cacheTimestamp = null;
    debugPrint('🗑️ تم مسح ذاكرة التخزين المؤقت');
  }
  
  /// الحصول على معلومات الكاش
  static Map<String, dynamic> getCacheInfo() {
    return {
      'isCached': _cachedData != null,
      'cacheTimestamp': _cacheTimestamp?.toIso8601String(),
      'cacheAge': _cacheTimestamp != null 
          ? DateTime.now().difference(_cacheTimestamp!).inMinutes 
          : null,
      'cacheExpiry': _cacheExpiry.inMinutes,
    };
  }
  
  /// ✅ الحصول على إحصائيات البيانات
  static Future<Map<String, dynamic>> getDataStats() async {
    try {
      final data = await _loadData();
      final Map<String, dynamic> duasData = data['duas'] ?? {};
      
      int totalDuas = 0;
      Map<String, int> categoryStats = {};
      
      for (var entry in duasData.entries) {
        if (entry.value is List) {
          final count = (entry.value as List).length;
          categoryStats[entry.key] = count;
          totalDuas += count;
        }
      }
      
      return {
        'totalDuas': totalDuas,
        'totalCategories': categoryStats.length,
        'categoryStats': categoryStats,
        'quranDuas': categoryStats['quran'] ?? 0,
        'sahihainDuas': categoryStats['sahihain'] ?? 0,
        'sunanDuas': categoryStats['sunan'] ?? 0,
        'otherDuas': categoryStats['other_authentic'] ?? 0,
      };
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الإحصائيات: $e');
      return {};
    }
  }
}

/// استثناء انتهاء المهلة
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}