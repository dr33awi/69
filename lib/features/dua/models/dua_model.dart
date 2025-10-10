// lib/features/dua/models/dua_model.dart - محدث
import 'package:equatable/equatable.dart';

/// نموذج بيانات الدعاء المحدث
class Dua extends Equatable {
  final String id;
  final String title;
  final String arabicText;
  final String? transliteration;
  final String? translation;
  final String? source;
  final String? reference;
  final String categoryId;
  final String? virtue; // ✅ حقل جديد للفضل
  final List<String> tags;
  final int? order;
  final bool isFavorite;
  final int readCount;
  final DateTime? lastRead;
  final DuaType type;

  const Dua({
    required this.id,
    required this.title,
    required this.arabicText,
    this.transliteration,
    this.translation,
    this.source,
    this.reference,
    required this.categoryId,
    this.virtue, // ✅ إضافة الفضل
    this.tags = const [],
    this.order,
    this.isFavorite = false,
    this.readCount = 0,
    this.lastRead,
    this.type = DuaType.general,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        arabicText,
        transliteration,
        translation,
        source,
        reference,
        categoryId,
        virtue,
        tags,
        order,
        isFavorite,
        readCount,
        lastRead,
        type,
      ];

  Dua copyWith({
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
    int? order,
    bool? isFavorite,
    int? readCount,
    DateTime? lastRead,
    DuaType? type,
  }) {
    return Dua(
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
      order: order ?? this.order,
      isFavorite: isFavorite ?? this.isFavorite,
      readCount: readCount ?? this.readCount,
      lastRead: lastRead ?? this.lastRead,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'order': order,
      'isFavorite': isFavorite ? 1 : 0,
      'readCount': readCount,
      'lastRead': lastRead?.millisecondsSinceEpoch,
      'type': type.index,
    };
  }

  factory Dua.fromMap(Map<String, dynamic> map) {
    return Dua(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      arabicText: map['arabicText'] ?? '',
      transliteration: map['transliteration'],
      translation: map['translation'],
      source: map['source'],
      reference: map['reference'],
      categoryId: map['categoryId'] ?? '',
      virtue: map['virtue'],
      tags: List<String>.from(map['tags'] ?? []),
      order: map['order'],
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      readCount: map['readCount'] ?? 0,
      lastRead: map['lastRead'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastRead'])
          : null,
      type: DuaType.values[map['type'] ?? 0],
    );
  }
}

/// أنواع الأدعية
enum DuaType {
  general, // عامة
  morning, // الصباح
  evening, // المساء
  prayer, // الصلاة
  food, // الطعام
  travel, // السفر
  sleep, // النوم
  protection, // الحماية
  forgiveness, // الاستغفار
  gratitude, // الشكر
  guidance, // الهداية
  health, // الصحة
  wealth, // الرزق
  knowledge, // العلم
}

extension DuaTypeExtension on DuaType {
  String get displayName {
    switch (this) {
      case DuaType.general:
        return 'أدعية عامة';
      case DuaType.morning:
        return 'أدعية الصباح';
      case DuaType.evening:
        return 'أدعية المساء';
      case DuaType.prayer:
        return 'أدعية الصلاة';
      case DuaType.food:
        return 'أدعية الطعام';
      case DuaType.travel:
        return 'أدعية السفر';
      case DuaType.sleep:
        return 'أدعية النوم';
      case DuaType.protection:
        return 'أدعية الحماية';
      case DuaType.forgiveness:
        return 'أدعية الاستغفار';
      case DuaType.gratitude:
        return 'أدعية الشكر';
      case DuaType.guidance:
        return 'أدعية الهداية';
      case DuaType.health:
        return 'أدعية الصحة';
      case DuaType.wealth:
        return 'أدعية الرزق';
      case DuaType.knowledge:
        return 'أدعية العلم';
    }
  }

  String get description {
    switch (this) {
      case DuaType.general:
        return 'أدعية متنوعة للحياة اليومية';
      case DuaType.morning:
        return 'أدعية للبدء بها في الصباح';
      case DuaType.evening:
        return 'أدعية للمساء والليل';
      case DuaType.prayer:
        return 'أدعية قبل وبعد الصلاة';
      case DuaType.food:
        return 'أدعية قبل وبعد تناول الطعام';
      case DuaType.travel:
        return 'أدعية للسفر والرحلات';
      case DuaType.sleep:
        return 'أدعية قبل النوم';
      case DuaType.protection:
        return 'أدعية للحماية من الشر';
      case DuaType.forgiveness:
        return 'أدعية طلب المغفرة والتوبة';
      case DuaType.gratitude:
        return 'أدعية الحمد والشكر';
      case DuaType.guidance:
        return 'أدعية طلب الهداية';
      case DuaType.health:
        return 'أدعية للصحة والعافية';
      case DuaType.wealth:
        return 'أدعية طلب الرزق الحلال';
      case DuaType.knowledge:
        return 'أدعية طلب العلم والحكمة';
    }
  }
  
  /// الحصول على معرف الفئة من النوع
  String get categoryId {
    return name; // يستخدم اسم enum كمعرف (general, morning, etc.)
  }
}

/// نموذج فئة الأدعية المحدث
class DuaCategory extends Equatable {
  final String id;
  final String name;
  final String description;
  final DuaType type;
  final int duaCount;
  final String? icon; // ✅ حقل جديد للأيقونة

  const DuaCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.duaCount = 0,
    this.icon,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        duaCount,
        icon,
      ];

  DuaCategory copyWith({
    String? id,
    String? name,
    String? description,
    DuaType? type,
    int? duaCount,
    String? icon,
  }) {
    return DuaCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      duaCount: duaCount ?? this.duaCount,
      icon: icon ?? this.icon,
    );
  }
}

/// إحصائيات الأدعية المحدثة
class DuaStats extends Equatable {
  final int totalDuas;
  final int favoriteDuas;
  final int readDuas;
  final int streakDays;
  final DateTime? lastReadDate;
  final Map<DuaType, int> duasByType;
  final Map<String, int>? duasByCategory; // ✅ إحصائيات حسب الفئة

  const DuaStats({
    this.totalDuas = 0,
    this.favoriteDuas = 0,
    this.readDuas = 0,
    this.streakDays = 0,
    this.lastReadDate,
    this.duasByType = const {},
    this.duasByCategory,
  });

  @override
  List<Object?> get props => [
        totalDuas,
        favoriteDuas,
        readDuas,
        streakDays,
        lastReadDate,
        duasByType,
        duasByCategory,
      ];

  DuaStats copyWith({
    int? totalDuas,
    int? favoriteDuas,
    int? readDuas,
    int? streakDays,
    DateTime? lastReadDate,
    Map<DuaType, int>? duasByType,
    Map<String, int>? duasByCategory,
  }) {
    return DuaStats(
      totalDuas: totalDuas ?? this.totalDuas,
      favoriteDuas: favoriteDuas ?? this.favoriteDuas,
      readDuas: readDuas ?? this.readDuas,
      streakDays: streakDays ?? this.streakDays,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      duasByType: duasByType ?? this.duasByType,
      duasByCategory: duasByCategory ?? this.duasByCategory,
    );
  }
}