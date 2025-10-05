// lib/features/quran/services/quran_service.dart
import 'package:quran/quran.dart' as Quran;
import '../../../core/infrastructure/services/storage/storage_service.dart';

class QuranService {
  final StorageService _storage;
  
  // مفاتيح التخزين
  static const String _keyLastSurah = 'last_surah';
  static const String _keyLastAyah = 'last_ayah';
  static const String _keyBookmarks = 'quran_bookmarks';
  static const String _keyFontSize = 'quran_font_size';
  static const String _keyReadingMode = 'quran_reading_mode';
  
  QuranService({required StorageService storage}) : _storage = storage;

  // ==================== القراءة والتنقل ====================
  
  /// الحصول على آخر موضع قراءة
  Future<QuranPosition> getLastReadingPosition() async {
    final surahNumber = await _storage.getInt(_keyLastSurah) ?? 1;
    final ayahNumber = await _storage.getInt(_keyLastAyah) ?? 1;
    
    return QuranPosition(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
  }
  
  /// حفظ موضع القراءة
  Future<void> saveReadingPosition(int surahNumber, int ayahNumber) async {
    await _storage.setInt(_keyLastSurah, surahNumber);
    await _storage.setInt(_keyLastAyah, ayahNumber);
  }
  
  /// الحصول على معلومات السورة
  SurahInfo getSurahInfo(int surahNumber) {
    return SurahInfo(
      number: surahNumber,
      name: Quran.getSurahName(surahNumber),
      nameArabic: Quran.getSurahNameArabic(surahNumber),
      totalVerses: Quran.getVerseCount(surahNumber),
      revelationType: Quran.getPlaceOfRevelation(surahNumber),
    );
  }
  
  /// الحصول على نص الآية
  String getVerseText(int surahNumber, int verseNumber) {
    return Quran.getVerse(surahNumber, verseNumber);
  }
  
  /// الحصول على نص السورة كاملة
  List<VerseData> getSurahVerses(int surahNumber) {
    final verseCount = Quran.getVerseCount(surahNumber);
    return List.generate(
      verseCount,
      (index) {
        final verseNumber = index + 1;
        return VerseData(
          surahNumber: surahNumber,
          verseNumber: verseNumber,
          text: getVerseText(surahNumber, verseNumber),
          juzNumber: Quran.getJuzNumber(surahNumber, verseNumber),
          pageNumber: Quran.getPageNumber(surahNumber, verseNumber),
        );
      },
    );
  }
  
  /// الحصول على قائمة جميع السور
  List<SurahInfo> getAllSurahs() {
    return List.generate(
      114,
      (index) => getSurahInfo(index + 1),
    );
  }
  
  /// البحث في القرآن
  List<SearchResult> searchInQuran(String query) {
    if (query.trim().isEmpty) return [];
    
    final results = <SearchResult>[];
    final searchQuery = query.trim();
    
    for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
      final verseCount = Quran.getVerseCount(surahNumber);
      
      for (int verseNumber = 1; verseNumber <= verseCount; verseNumber++) {
        final verseText = getVerseText(surahNumber, verseNumber);
        
        if (verseText.contains(searchQuery)) {
          results.add(SearchResult(
            surahNumber: surahNumber,
            surahName: Quran.getSurahNameArabic(surahNumber),
            verseNumber: verseNumber,
            verseText: verseText,
            highlightedText: _highlightSearchQuery(verseText, searchQuery),
          ));
        }
      }
    }
    
    return results;
  }
  
  String _highlightSearchQuery(String text, String query) {
    return text.replaceAll(query, '**$query**');
  }

  // ==================== الإشارات المرجعية ====================
  
  /// الحصول على الإشارات المرجعية
  Future<List<BookmarkData>> getBookmarks() async {
    final bookmarksJson = await _storage.getStringList(_keyBookmarks) ?? [];
    return bookmarksJson
        .map((json) => BookmarkData.fromJson(json))
        .toList();
  }
  
  /// إضافة إشارة مرجعية
  Future<void> addBookmark(BookmarkData bookmark) async {
    final bookmarks = await getBookmarks();
    
    // تحقق من عدم وجود نفس الإشارة
    final exists = bookmarks.any(
      (b) => b.surahNumber == bookmark.surahNumber && 
             b.verseNumber == bookmark.verseNumber,
    );
    
    if (!exists) {
      bookmarks.add(bookmark);
      await _saveBookmarks(bookmarks);
    }
  }
  
  /// حذف إشارة مرجعية
  Future<void> removeBookmark(int surahNumber, int verseNumber) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere(
      (b) => b.surahNumber == surahNumber && b.verseNumber == verseNumber,
    );
    await _saveBookmarks(bookmarks);
  }
  
  /// فحص وجود إشارة مرجعية
  Future<bool> isBookmarked(int surahNumber, int verseNumber) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any(
      (b) => b.surahNumber == surahNumber && b.verseNumber == verseNumber,
    );
  }
  
  Future<void> _saveBookmarks(List<BookmarkData> bookmarks) async {
    final bookmarksJson = bookmarks.map((b) => b.toJson()).toList();
    await _storage.setStringList(_keyBookmarks, bookmarksJson);
  }

  // ==================== الإعدادات ====================
  
  /// الحصول على حجم الخط
  Future<double> getFontSize() async {
    return await _storage.getDouble(_keyFontSize) ?? 22.0;
  }
  
  /// تعيين حجم الخط
  Future<void> setFontSize(double size) async {
    await _storage.setDouble(_keyFontSize, size);
  }
  
  /// الحصول على وضع القراءة
  Future<ReadingMode> getReadingMode() async {
    final mode = await _storage.getString(_keyReadingMode) ?? 'continuous';
    return mode == 'continuous' ? ReadingMode.continuous : ReadingMode.paged;
  }
  
  /// تعيين وضع القراءة
  Future<void> setReadingMode(ReadingMode mode) async {
    await _storage.setString(
      _keyReadingMode,
      mode == ReadingMode.continuous ? 'continuous' : 'paged',
    );
  }
  
  // ==================== معلومات إضافية ====================
  
  /// الحصول على رقم الجزء
  int getJuzNumber(int surahNumber, int verseNumber) {
    return Quran.getJuzNumber(surahNumber, verseNumber);
  }
  
  /// الحصول على رقم الصفحة
  int getPageNumber(int surahNumber, int verseNumber) {
    return Quran.getPageNumber(surahNumber, verseNumber);
  }
  
  /// الحصول على معلومات الجزء
  JuzInfo getJuzInfo(int juzNumber) {
    return JuzInfo(
      number: juzNumber,
      // يمكن إضافة معلومات إضافية حسب الحاجة
    );
  }
  
  void dispose() {
    // تنظيف الموارد إذا لزم الأمر
  }
}

// ==================== Data Models ====================

class QuranPosition {
  final int surahNumber;
  final int ayahNumber;
  
  const QuranPosition({
    required this.surahNumber,
    required this.ayahNumber,
  });
}

class SurahInfo {
  final int number;
  final String name;
  final String nameArabic;
  final int totalVerses;
  final String revelationType;
  
  const SurahInfo({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.totalVerses,
    required this.revelationType,
  });
  
  String get revelationTypeArabic => 
      revelationType == 'Makkah' ? 'مكية' : 'مدنية';
}

class VerseData {
  final int surahNumber;
  final int verseNumber;
  final String text;
  final int juzNumber;
  final int pageNumber;
  
  const VerseData({
    required this.surahNumber,
    required this.verseNumber,
    required this.text,
    required this.juzNumber,
    required this.pageNumber,
  });
}

class SearchResult {
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final String verseText;
  final String highlightedText;
  
  const SearchResult({
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.verseText,
    required this.highlightedText,
  });
}

class BookmarkData {
  final int surahNumber;
  final int verseNumber;
  final String surahName;
  final DateTime addedAt;
  final String? note;
  
  const BookmarkData({
    required this.surahNumber,
    required this.verseNumber,
    required this.surahName,
    required this.addedAt,
    this.note,
  });
  
  String toJson() {
    return '$surahNumber|$verseNumber|$surahName|${addedAt.toIso8601String()}|${note ?? ""}';
  }
  
  factory BookmarkData.fromJson(String json) {
    final parts = json.split('|');
    return BookmarkData(
      surahNumber: int.parse(parts[0]),
      verseNumber: int.parse(parts[1]),
      surahName: parts[2],
      addedAt: DateTime.parse(parts[3]),
      note: parts.length > 4 && parts[4].isNotEmpty ? parts[4] : null,
    );
  }
}

class JuzInfo {
  final int number;
  
  const JuzInfo({required this.number});
}

enum ReadingMode {
  continuous,
  paged,
}