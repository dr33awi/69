// lib/features/athkar/models/athkar_model.dart
import 'package:flutter/material.dart';
import '../utils/category_utils.dart';

/// نموذج الذكر الفردي
class AthkarItem {
  final int id;
  final String text;
  final int count;
  final String? fadl;
  final String? source;

  const AthkarItem({
    required this.id,
    required this.text,
    required this.count,
    this.fadl,
    this.source,
  });

  factory AthkarItem.fromJson(Map<String, dynamic> json) {
    return AthkarItem(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      count: json['count'] ?? 1,
      fadl: json['fadl'],
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'count': count,
      if (fadl != null) 'fadl': fadl,
      if (source != null) 'source': source,
    };
  }
}

/// فئة الأذكار
class AthkarCategory {
  final String id;
  final String title;
  final String? description;
  final IconData icon;
  final Color color;
  final TimeOfDay? notifyTime;
  final List<AthkarItem> athkar;

  const AthkarCategory({
    required this.id,
    required this.title,
    this.description,
    required this.icon,
    required this.color,
    this.notifyTime,
    required this.athkar,
  });

  factory AthkarCategory.fromJson(Map<String, dynamic> json) {
    // استخراج قائمة الأذكار
    final List<dynamic> items = json['athkar'] ?? [];
    
    // استخراج معرف الفئة
    final categoryId = json['id'] ?? '';
    
    // استخراج الوقت إذا وجد
    TimeOfDay? notifyTime;
    if (json['notify_time'] != null) {
      notifyTime = _timeOfDayFromString(json['notify_time']);
    }
    
    return AthkarCategory(
      id: categoryId,
      title: json['title'] ?? '',
      description: json['description'],
      icon: CategoryUtils.getCategoryIcon(categoryId),
      color: CategoryUtils.getCategoryThemeColor(categoryId),
      notifyTime: notifyTime,
      athkar: items.map((e) => AthkarItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (notifyTime != null) 'notify_time': '${notifyTime!.hour.toString().padLeft(2, '0')}:${notifyTime!.minute.toString().padLeft(2, '0')}',
      'athkar': athkar.map((e) => e.toJson()).toList(),
    };
  }

  static TimeOfDay? _timeOfDayFromString(String? time) {
    if (time == null || time.isEmpty) return null;
    
    try {
      final parts = time.split(':');
      if (parts.length != 2) return null;
      
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      
      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return null;
    }
  }
}

/// كلاس لتحليل البيانات من JSON
class AthkarData {
  final String version;
  final String source;
  final String lastUpdated;
  final List<AthkarCategory> categories;

  const AthkarData({
    required this.version,
    required this.source,
    required this.lastUpdated,
    required this.categories,
  });

  factory AthkarData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> categoriesJson = json['categories'] ?? [];
    
    return AthkarData(
      version: json['version'] ?? '1.0.0',
      source: json['source'] ?? '',
      lastUpdated: json['last_updated'] ?? '',
      categories: categoriesJson
          .map((e) => AthkarCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'source': source,
      'last_updated': lastUpdated,
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }
}