// lib/features/quran/services/quran_service.dart - الخدمة الكاملة
import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';

class QuranService {
  final StorageService _storage;
  
  // مفاتيح التخزين
  static const String _keyLastReadSurah = 'last_read_surah';
  static const String _keyLastReadAyah = 'last_read_ayah';
  static const String _keyFontSize = 'quran_font_size';
  static const String _keyTranslationLanguage = 'translation_language';

  QuranService({required StorageService storage}) : _storage = storage;

  // ==================== معلومات السور ====================

  /// الحصول على معلومات سورة
  SurahInfo getSurahInfo(int surahNumber) {
    if (surahNumber < 1 || surahNumber > 114) {
      throw ArgumentError('رقم السورة يجب أن يكون بين 1 و 114');
    }
    
    return SurahInfo(
      number: surahNumber,
      name: QuranLibrary.getSurahName(surahNumber),
      nameArabic: QuranLibrary.getSurahNameArabic(surahNumber),
      revelationType: QuranLibrary.getPlaceOfRevelation(surahNumber),
      totalAyahs: QuranLibrary.getVerseCount(surahNumber),
      basmalaPosition: QuranLibrary.getBasmala(surahNumber),
    );
  }

  /// الحصول على قائمة بجميع السور
  List<SurahInfo> getAllSurahs() {
    return List.generate(
      114,
      (index) => getSurahInfo(index + 1),
    );
  }

  /// البحث في أسماء السور
  List<SurahInfo> searchSurahs(String query) {
    if (query.isEmpty) return getAllSurahs();
    
    final lowerQuery = query.toLowerCase();
    return getAllSurahs().where((surah) {
      return surah.name.toLowerCase().contains(lowerQuery) ||
             surah.nameArabic.contains(query);
    }).toList();
  }

  // ==================== الآيات ====================

  /// الحصول على آية محددة
  String getVerse(int surahNumber, int verseNumber) {
    try {
      return QuranLibrary.getVerse(surahNumber, verseNumber);
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على الآية: $e');
      return '';
    }
  }

  /// الحصول على جميع آيات سورة
  List<VerseInfo> getVerses(int surahNumber) {
    final surahInfo = getSurahInfo(surahNumber);
    final verses = <VerseInfo>[];
    
    for (int i = 1; i <= surahInfo.totalAyahs; i++) {
      verses.add(VerseInfo(
        surahNumber: surahNumber,
        verseNumber: i,
        text: getVerse(surahNumber, i),
        juz: QuranLibrary.getJuzNumber(surahNumber, i),
        page: QuranLibrary.getPageNumber(surahNumber, i),
      ));
    }
    
    return verses;
  }

  /// الحصول على نطاق من الآيات
  List<VerseInfo> getVerseRange(
    int surahNumber,
    int startVerse,
    int endVerse,
  ) {
    final allVerses = getVerses(surahNumber);
    return allVerses
        .where((v) => v.verseNumber >= startVerse && v.verseNumber <= endVerse)
        .toList();
  }

  // ==================== الأجزاء والصفحات ====================

  /// الحصول على رقم الجزء للآية
  int getJuzNumber(int surahNumber, int verseNumber) {
    return QuranLibrary.getJuzNumber(surahNumber, verseNumber);
  }

  /// الحصول على رقم الصفحة للآية
  int getPageNumber(int surahNumber, int verseNumber) {
    return QuranLibrary.getPageNumber(surahNumber, verseNumber);
  }

  /// الحصول على جميع الآيات في جزء معين
  List<VerseInfo> getJuzVerses(int juzNumber) {
    if (juzNumber < 1 || juzNumber > 30) {
      throw ArgumentError('رقم الجزء يجب أن يكون بين 1 و 30');
    }
    
    final verses = <VerseInfo>[];
    
    for (int surah = 1; surah <= 114; surah++) {
      final surahVerses = getVerses(surah);
      verses.addAll(
        surahVerses.where((v) => v.juz == juzNumber),
      );
    }
    
    return verses;
  }

  // ==================== البحث ====================

  /// البحث في القرآن الكريم
  List<SearchResult> searchInQuran(String query) {
    if (query.isEmpty || query.length < 3) return [];
    
    final results = <SearchResult>[];
    
    for (int surah = 1; surah <= 114; surah++) {
      final verses = getVerses(surah);
      
      for (final verse in verses) {
        if (verse.text.contains(query)) {
          results.add(SearchResult(
            surahNumber: surah,
            surahName: getSurahInfo(surah).nameArabic,
            verseNumber: verse.verseNumber,
            verseText: verse.text,
            highlightedText: _highlightText(verse.text, query),
          ));
        }
      }
    }
    
    return results;
  }

  String _highlightText(String text, String query) {
    return text.replaceAll(query, '【$query】');
  }

  // ==================== القراءة الأخيرة ====================

  /// حفظ موضع القراءة الأخير
  Future<void> saveLastReadPosition(int surahNumber, int verseNumber) async {
    try {
      await _storage.setInt(_keyLastReadSurah, surahNumber);
      await _storage.setInt(_keyLastReadAyah, verseNumber);
      debugPrint('✅ تم حفظ موضع القراءة: سورة $surahNumber، آية $verseNumber');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ موضع القراءة: $e');
    }
  }

  /// الحصول على موضع القراءة الأخير
  Future<ReadingPosition?> getLastReadPosition() async {
    try {
      final surahNumber = await _storage.getInt(_keyLastReadSurah);
      final verseNumber = await _storage.getInt(_keyLastReadAyah);
      
      if (surahNumber != null && verseNumber != null) {
        return ReadingPosition(
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          surahName: getSurahInfo(surahNumber).nameArabic,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على موضع القراءة: $e');
      return null;
    }
  }

  /// مسح موضع القراءة الأخير
  Future<void> clearLastReadPosition() async {
    try {
      await _storage.remove(_keyLastReadSurah);
      await _storage.remove(_keyLastReadAyah);
    } catch (e) {
      debugPrint('❌ خطأ في مسح موضع القراءة: $e');
    }
  }

  // ==================== الإعدادات ====================

  /// حفظ حجم الخط
  Future<void> setFontSize(double size) async {
    try {
      await _storage.setDouble(_keyFontSize, size);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ حجم الخط: $e');
    }
  }

  /// الحصول على حجم الخط
  Future<double> getFontSize() async {
    try {
      return await _storage.getDouble(_keyFontSize) ?? 22.0;
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على حجم الخط: $e');
      return 22.0;
    }
  }

  /// حفظ لغة الترجمة
  Future<void> setTranslationLanguage(String language) async {
    try {
      await _storage.setString(_keyTranslationLanguage, language);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ لغة الترجمة: $e');
    }
  }

  /// الحصول على لغة الترجمة
  Future<String> getTranslationLanguage() async {
    try {
      return await _storage.getString(_keyTranslationLanguage) ?? 'ar';
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على لغة الترجمة: $e');
      return 'ar';
    }
  }

  // ==================== التنظيف ====================

  void dispose() {
    debugPrint('🗑️ QuranService disposed');
  }
}

// ==================== نماذج البيانات ====================

class SurahInfo {
  final int number;
  final String name;
  final String nameArabic;
  final String revelationType;
  final int totalAyahs;
  final int basmalaPosition;

  SurahInfo({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.revelationType,
    required this.totalAyahs,
    required this.basmalaPosition,
  });

  bool get isMakki => revelationType == 'Makkah';
  bool get isMadani => revelationType == 'Madinah';
}

class VerseInfo {
  final int surahNumber;
  final int verseNumber;
  final String text;
  final int juz;
  final int page;

  VerseInfo({
    required this.surahNumber,
    required this.verseNumber,
    required this.text,
    required this.juz,
    required this.page,
  });
}

class ReadingPosition {
  final int surahNumber;
  final int verseNumber;
  final String surahName;

  ReadingPosition({
    required this.surahNumber,
    required this.verseNumber,
    required this.surahName,
  });
}

class SearchResult {
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final String verseText;
  final String highlightedText;

  SearchResult({
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.verseText,
    required this.highlightedText,
  });
}