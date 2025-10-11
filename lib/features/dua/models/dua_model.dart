// lib/features/dua/models/dua_model.dart

import 'package:flutter/material.dart';

/// نموذج فئة الأدعية
class DuaCategory {
  final String id;
  final String name;
  final String description;
  final int type;
  final String icon;
  final int duasCount;

  const DuaCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    this.duasCount = 0,
  });

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    return DuaCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: json['type'] as int? ?? 0,
      icon: json['icon'] as String? ?? 'book',
      duasCount: 0, // سيتم تحديثه لاحقاً
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type,
    'icon': icon,
  };

  DuaCategory copyWith({
    String? id,
    String? name,
    String? description,
    int? type,
    String? icon,
    int? duasCount,
  }) {
    return DuaCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      duasCount: duasCount ?? this.duasCount,
    );
  }
}

/// نموذج الدعاء
class DuaItem {
  final String id;
  final String title;
  final String arabicText;
  final String? transliteration;
  final String? translation;
  final String source;
  final String reference;
  final String categoryId;
  final String? virtue;
  final List<String> tags;
  final int type;
  final bool isFavorite;

  const DuaItem({
    required this.id,
    required this.title,
    required this.arabicText,
    this.transliteration,
    this.translation,
    required this.source,
    required this.reference,
    required this.categoryId,
    this.virtue,
    required this.tags,
    required this.type,
    this.isFavorite = false,
  });

  factory DuaItem.fromJson(Map<String, dynamic> json) {
    return DuaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      arabicText: json['arabicText'] as String,
      transliteration: json['transliteration'] as String?,
      translation: json['translation'] as String?,
      source: json['source'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      categoryId: json['categoryId'] as String,
      virtue: json['virtue'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      type: json['type'] as int? ?? 0,
      isFavorite: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'arabicText': arabicText,
    'transliteration': transliteration,
    'translation': translation,
    'source': source,
    'reference': reference,
    'categoryId': categoryId,
    'virtue': virtue,
    'tags': tags,
    'type': type,
  };

  DuaItem copyWith({
    String? id,
    String? title,
    String? arabicText,
    String? transliteration,
    String? translation,
    String? source,
    String? reference,
    String? categoryId,
    String? virtue,
    List<String>? tags,
    int? type,
    bool? isFavorite,
  }) {
    return DuaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      arabicText: arabicText ?? this.arabicText,
      transliteration: transliteration ?? this.transliteration,
      translation: translation ?? this.translation,
      source: source ?? this.source,
      reference: reference ?? this.reference,
      categoryId: categoryId ?? this.categoryId,
      virtue: virtue ?? this.virtue,
      tags: tags ?? this.tags,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// أنواع الأدعية
enum DuaType {
  general(0),
  morning(1),
  evening(2),
  prayer(3),
  food(4),
  travel(5),
  sleep(6),
  protection(7),
  forgiveness(8),
  thanks(9),
  guidance(10),
  healing(11),
  wealth(12),
  knowledge(13);

  final int value;
  const DuaType(this.value);

  static DuaType fromValue(int value) {
    return DuaType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DuaType.general,
    );
  }

  String get arabicName {
    switch (this) {
      case DuaType.general:
        return 'عام';
      case DuaType.morning:
        return 'الصباح';
      case DuaType.evening:
        return 'المساء';
      case DuaType.prayer:
        return 'الصلاة';
      case DuaType.food:
        return 'الطعام';
      case DuaType.travel:
        return 'السفر';
      case DuaType.sleep:
        return 'النوم';
      case DuaType.protection:
        return 'الحماية';
      case DuaType.forgiveness:
        return 'الاستغفار';
      case DuaType.thanks:
        return 'الشكر';
      case DuaType.guidance:
        return 'الهداية';
      case DuaType.healing:
        return 'الشفاء';
      case DuaType.wealth:
        return 'الرزق';
      case DuaType.knowledge:
        return 'العلم';
    }
  }

  IconData get icon {
    switch (this) {
      case DuaType.general:
        return Icons.menu_book;
      case DuaType.morning:
        return Icons.wb_sunny;
      case DuaType.evening:
        return Icons.nights_stay;
      case DuaType.prayer:
        return Icons.mosque;
      case DuaType.food:
        return Icons.restaurant;
      case DuaType.travel:
        return Icons.flight;
      case DuaType.sleep:
        return Icons.bedtime;
      case DuaType.protection:
        return Icons.shield;
      case DuaType.forgiveness:
        return Icons.favorite;
      case DuaType.thanks:
        return Icons.volunteer_activism;
      case DuaType.guidance:
        return Icons.explore;
      case DuaType.healing:
        return Icons.healing;
      case DuaType.wealth:
        return Icons.attach_money;
      case DuaType.knowledge:
        return Icons.school;
    }
  }

  Color get color {
    switch (this) {
      case DuaType.general:
        return const Color(0xFF5D7052);
      case DuaType.morning:
        return const Color(0xFFDAA520);
      case DuaType.evening:
        return const Color(0xFF445A3B);
      case DuaType.prayer:
        return const Color(0xFF8B6F47);
      case DuaType.food:
        return const Color(0xFFB8860B);
      case DuaType.travel:
        return const Color(0xFF6B8E9F);
      case DuaType.sleep:
        return const Color(0xFF6B5637);
      case DuaType.protection:
        return const Color(0xFF5D7052);
      case DuaType.forgiveness:
        return const Color(0xFFB85450);
      case DuaType.thanks:
        return const Color(0xFF8FA584);
      case DuaType.guidance:
        return const Color(0xFF7A8B6F);
      case DuaType.healing:
        return const Color(0xFFD4A574);
      case DuaType.wealth:
        return const Color(0xFF996515);
      case DuaType.knowledge:
        return const Color(0xFF6B8E9F);
    }
  }
}