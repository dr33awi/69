// lib/features/dua/data/dua_data.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dua_model.dart';

/// بيانات الأدعية من ملف JSON
class DuaData {
  static Map<String, dynamic>? _cachedData;
  static const Duration _loadTimeout = Duration(seconds: 10);
  
  /// تحميل البيانات من ملف JSON مع timeout
  static Future<Map<String, dynamic>> _loadData() async {
    if (_cachedData != null) {
      return _cachedData!;
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
          final typeIndex = categoryData['type'];
          
          // التحقق من صحة نوع الفئة
          if (typeIndex == null || 
              typeIndex < 0 || 
              typeIndex >= DuaType.values.length) {
            debugPrint('⚠️ نوع فئة غير صحيح للفئة: $categoryId');
            continue;
          }
          
          categories.add(DuaCategory(
            id: categoryData['id']?.toString() ?? '',
            name: categoryData['name']?.toString() ?? 'بدون اسم',
            description: categoryData['description']?.toString() ?? '',
            type: DuaType.values[typeIndex],
            duaCount: duasData is List ? duasData.length : 0,
          ));
        } catch (e) {
          debugPrint('⚠️ خطأ في معالجة فئة: $e');
          continue;
        }
      }
      
      debugPrint('✅ تم تحميل ${categories.length} فئة');
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
      
      for (var entry in duasData.entries) {
        final categoryDuas = entry.value;
        
        if (categoryDuas is! List) {
          debugPrint('⚠️ تخطي فئة بصيغة غير صحيحة: ${entry.key}');
          continue;
        }
        
        for (var duaData in categoryDuas) {
          try {
            if (duaData is! Map<String, dynamic>) {
              debugPrint('⚠️ تخطي دعاء بصيغة غير صحيحة');
              continue;
            }
            
            allDuas.add(_parseDua(duaData));
          } catch (e) {
            debugPrint('⚠️ خطأ في معالجة دعاء: $e');
            continue;
          }
        }
      }
      
      debugPrint('✅ تم تحميل ${allDuas.length} دعاء');
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
          
          duas.add(_parseDua(duaData));
        } catch (e) {
          debugPrint('⚠️ خطأ في معالجة دعاء: $e');
          continue;
        }
      }
      
      debugPrint('✅ تم تحميل ${duas.length} دعاء من الفئة: $categoryId');
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
    
    final typeIndex = duaData['type'];
    final type = (typeIndex != null && 
                  typeIndex >= 0 && 
                  typeIndex < DuaType.values.length)
        ? DuaType.values[typeIndex]
        : DuaType.general;
    
    return Dua(
      id: id,
      title: title,
      arabicText: arabicText,
      transliteration: duaData['transliteration']?.toString(),
      translation: duaData['translation']?.toString(),
      source: duaData['source']?.toString(),
      reference: duaData['reference']?.toString(),
      categoryId: categoryId,
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
    debugPrint('🗑️ تم مسح ذاكرة التخزين المؤقت');
  }
}

/// استثناء انتهاء المهلة
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}