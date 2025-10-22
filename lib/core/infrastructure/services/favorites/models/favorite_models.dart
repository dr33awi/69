// lib/core/infrastructure/services/favorites/models/favorite_models.dart
// نماذج البيانات للنظام الموحد للمفضلة

import 'package:flutter/material.dart';

/// أنواع المحتوى المدعومة في نظام المفضلة
enum FavoriteContentType {
  /// الأدعية
  dua('dua', 'الأدعية', Icons.menu_book),
  
  /// الأذكار
  athkar('athkar', 'الأذكار', Icons.auto_stories_rounded),
  
  /// أسماء الله الحسنى
  asmaAllah('asma_allah', 'أسماء الله الحسنى', Icons.auto_awesome_rounded),
  
  /// الأذكار المخصصة للتسبيح
  tasbih('tasbih', 'التسبيح', Icons.casino_rounded);

  const FavoriteContentType(this.key, this.displayName, this.icon);

  final String key;
  final String displayName;
  final IconData icon;

  /// الحصول على النوع من المفتاح
  static FavoriteContentType fromKey(String key) {
    return FavoriteContentType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => FavoriteContentType.dua,
    );
  }
}

/// نموذج عنصر المفضلة الموحد
class FavoriteItem {
  final String id;
  final FavoriteContentType contentType;
  final String title;
  final String content;
  final String? subtitle;
  final String? source;
  final String? reference;
  final Map<String, dynamic>? metadata;
  final DateTime addedAt;
  final DateTime? lastAccessedAt;

  const FavoriteItem({
    required this.id,
    required this.contentType,
    required this.title,
    required this.content,
    this.subtitle,
    this.source,
    this.reference,
    this.metadata,
    required this.addedAt,
    this.lastAccessedAt,
  });

  /// إنشاء عنصر مفضلة من دعاء
  factory FavoriteItem.fromDua({
    required String duaId,
    required String title,
    required String arabicText,
    String? transliteration,
    String? translation,
    String? virtue,
    String? source,
    String? reference,
    String? categoryId,
  }) {
    return FavoriteItem(
      id: duaId,
      contentType: FavoriteContentType.dua,
      title: title,
      content: arabicText,
      subtitle: translation,
      source: source,
      reference: reference,
      metadata: {
        'transliteration': transliteration,
        'virtue': virtue,
        'categoryId': categoryId,
      },
      addedAt: DateTime.now(),
    );
  }

  /// إنشاء عنصر مفضلة من ذكر
  factory FavoriteItem.fromAthkar({
    required String athkarId,
    required String text,
    String? fadl,
    String? source,
    String? categoryId,
    int? count,
  }) {
    return FavoriteItem(
      id: athkarId,
      contentType: FavoriteContentType.athkar,
      title: _extractTitle(text),
      content: text,
      subtitle: fadl,
      source: source,
      metadata: {
        'categoryId': categoryId,
        'count': count,
      },
      addedAt: DateTime.now(),
    );
  }

  /// إنشاء عنصر مفضلة من اسم الله
  factory FavoriteItem.fromAsmaAllah({
    required String nameId,
    required String arabicName,
    required String meaning,
    required String explanation,
    String? transliteration,
  }) {
    return FavoriteItem(
      id: nameId,
      contentType: FavoriteContentType.asmaAllah,
      title: arabicName,
      content: explanation,
      subtitle: meaning,
      metadata: {
        'transliteration': transliteration,
      },
      addedAt: DateTime.now(),
    );
  }

  /// إنشاء عنصر مفضلة من ذكر التسبيح
  factory FavoriteItem.fromTasbih({
    required String dhikrId,
    required String text,
    String? virtue,
    int? recommendedCount,
    String? category,
  }) {
    return FavoriteItem(
      id: dhikrId,
      contentType: FavoriteContentType.tasbih,
      title: _extractTitle(text),
      content: text,
      subtitle: virtue,
      metadata: {
        'recommendedCount': recommendedCount,
        'category': category,
      },
      addedAt: DateTime.now(),
    );
  }

  /// استخراج عنوان مختصر من النص الطويل
  static String _extractTitle(String text) {
    if (text.length <= 30) return text;
    
    final words = text.split(' ');
    if (words.length <= 3) return text;
    
    return '${words.take(3).join(' ')}...';
  }

  /// تحويل إلى Map للتخزين
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentType': contentType.key,
      'title': title,
      'content': content,
      'subtitle': subtitle,
      'source': source,
      'reference': reference,
      'metadata': metadata,
      'addedAt': addedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
    };
  }

  /// إنشاء من Map
  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] ?? '',
      contentType: FavoriteContentType.fromKey(json['contentType'] ?? 'dua'),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      subtitle: json['subtitle'],
      source: json['source'],
      reference: json['reference'],
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      addedAt: DateTime.tryParse(json['addedAt'] ?? '') ?? DateTime.now(),
      lastAccessedAt: json['lastAccessedAt'] != null 
          ? DateTime.tryParse(json['lastAccessedAt']) 
          : null,
    );
  }

  /// إنشاء نسخة محدثة
  FavoriteItem copyWith({
    String? id,
    FavoriteContentType? contentType,
    String? title,
    String? content,
    String? subtitle,
    String? source,
    String? reference,
    Map<String, dynamic>? metadata,
    DateTime? addedAt,
    DateTime? lastAccessedAt,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      contentType: contentType ?? this.contentType,
      title: title ?? this.title,
      content: content ?? this.content,
      subtitle: subtitle ?? this.subtitle,
      source: source ?? this.source,
      reference: reference ?? this.reference,
      metadata: metadata ?? this.metadata,
      addedAt: addedAt ?? this.addedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  /// تحديث وقت آخر دخول
  FavoriteItem markAsAccessed() {
    return copyWith(lastAccessedAt: DateTime.now());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contentType == other.contentType;

  @override
  int get hashCode => id.hashCode ^ contentType.hashCode;

  @override
  String toString() {
    return 'FavoriteItem{id: $id, type: ${contentType.key}, title: $title}';
  }
}

/// إعدادات ترتيب وفلترة المفضلة
class FavoritesSortOptions {
  final SortBy sortBy;
  final SortOrder sortOrder;
  final FavoriteContentType? filterByType;

  const FavoritesSortOptions({
    this.sortBy = SortBy.dateAdded,
    this.sortOrder = SortOrder.descending,
    this.filterByType,
  });

  FavoritesSortOptions copyWith({
    SortBy? sortBy,
    SortOrder? sortOrder,
    FavoriteContentType? filterByType,
  }) {
    return FavoritesSortOptions(
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      filterByType: filterByType ?? this.filterByType,
    );
  }

  /// مسح الفلتر
  FavoritesSortOptions clearFilter() {
    return copyWith(filterByType: null);
  }

  Map<String, dynamic> toJson() {
    return {
      'sortBy': sortBy.name,
      'sortOrder': sortOrder.name,
      'filterByType': filterByType?.key,
    };
  }

  factory FavoritesSortOptions.fromJson(Map<String, dynamic> json) {
    return FavoritesSortOptions(
      sortBy: SortBy.values.firstWhere(
        (s) => s.name == json['sortBy'],
        orElse: () => SortBy.dateAdded,
      ),
      sortOrder: SortOrder.values.firstWhere(
        (s) => s.name == json['sortOrder'],
        orElse: () => SortOrder.descending,
      ),
      filterByType: json['filterByType'] != null 
          ? FavoriteContentType.fromKey(json['filterByType'])
          : null,
    );
  }
}

/// خيارات الترتيب
enum SortBy {
  dateAdded('تاريخ الإضافة'),
  lastAccessed('آخر دخول'),
  title('العنوان'),
  contentType('النوع');

  const SortBy(this.displayName);
  final String displayName;
}

/// اتجاه الترتيب
enum SortOrder {
  ascending('تصاعدي'),
  descending('تنازلي');

  const SortOrder(this.displayName);
  final String displayName;
}

/// إحصائيات المفضلة
class FavoritesStatistics {
  final int totalCount;
  final Map<FavoriteContentType, int> countByType;
  final DateTime? lastAddedAt;
  final DateTime? lastAccessedAt;
  final FavoriteContentType? mostFavoriteType;

  const FavoritesStatistics({
    required this.totalCount,
    required this.countByType,
    this.lastAddedAt,
    this.lastAccessedAt,
    this.mostFavoriteType,
  });

  /// إحصائيات فارغة
  const FavoritesStatistics.empty()
      : totalCount = 0,
        countByType = const {},
        lastAddedAt = null,
        lastAccessedAt = null,
        mostFavoriteType = null;

  /// الحصول على عدد نوع معين
  int getCountForType(FavoriteContentType type) {
    return countByType[type] ?? 0;
  }

  /// التحقق من وجود مفضلات
  bool get hasFavorites => totalCount > 0;

  /// أكثر الأنواع استخداماً
  List<MapEntry<FavoriteContentType, int>> get topTypes {
    final entries = countByType.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}