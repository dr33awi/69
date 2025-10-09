// lib/features/tasbih/services/tasbih_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/themes/constants/app_constants.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../models/dhikr_model.dart';

class TasbihService extends ChangeNotifier {
  final StorageService _storage;

  int _count = 0;
  int _todayCount = 0;
  int _totalCount = 0;
  DateTime _lastUsedDate = DateTime.now();
  
  Map<String, int> _dhikrStats = {};
  List<DailyRecord> _history = [];
  List<DhikrItem> _customAdhkar = [];
  
  DateTime? _sessionStartTime;
  String? _currentDhikrType;
  
  List<DhikrItem>? _cachedAllAdhkar;
  bool _adhkarCacheDirty = true;
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // ✅ إضافة: Timer للحفظ المُؤجل (debouncing)
  Timer? _saveTimer;

  TasbihService({required StorageService storage}) : _storage = storage {
    _loadData();
  }

  int get count => _count;
  int get todayCount => _todayCount;
  int get totalCount => _totalCount;
  Map<String, int> get dhikrStats => Map.unmodifiable(_dhikrStats);
  List<DailyRecord> get history => List.unmodifiable(_history);
  List<DhikrItem> get customAdhkar => List.unmodifiable(_customAdhkar);
  
  List<DhikrItem> getAllAdhkar() {
    if (_adhkarCacheDirty || _cachedAllAdhkar == null) {
      _cachedAllAdhkar = [...DefaultAdhkar.getAll(), ..._customAdhkar];
      _adhkarCacheDirty = false;
      debugPrint('[TasbihService] Adhkar cache updated - total: ${_cachedAllAdhkar!.length}');
    }
    return _cachedAllAdhkar!;
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadBasicData();
      notifyListeners();
      
      await Future.wait([
        _loadDhikrStats(),
        _loadHistory(),
        _loadCustomAdhkar(),
      ]);
      
    } catch (e) {
      debugPrint('[TasbihService] Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadBasicData() async {
    try {
      _count = _storage.getInt(AppConstants.tasbihCounterKey) ?? 0;
      _totalCount = _storage.getInt('${AppConstants.tasbihCounterKey}_total') ?? 0;
      
      final lastDateString = _storage.getString('${AppConstants.tasbihCounterKey}_last_date');
      if (lastDateString != null) {
        try {
          _lastUsedDate = DateTime.parse(lastDateString);
        } catch (e) {
          debugPrint('[TasbihService] Invalid date format: $lastDateString');
          _lastUsedDate = DateTime.now();
        }
      }
      
      final today = DateTime.now();
      if (!_isSameDay(_lastUsedDate, today)) {
        await _resetDailyCount();
        _lastUsedDate = today;
        await _storage.setString(
          '${AppConstants.tasbihCounterKey}_last_date',
          today.toIso8601String(),
        );
      } else {
        _todayCount = _storage.getInt('${AppConstants.tasbihCounterKey}_today') ?? 0;
      }
      
      debugPrint('[TasbihService] Basic data loaded - count: $_count, todayCount: $_todayCount');
    } catch (e) {
      debugPrint('[TasbihService] Error loading basic data: $e');
      _count = 0;
      _todayCount = 0;
      _totalCount = 0;
    }
  }

  Future<void> _loadDhikrStats() async {
    try {
      final statsData = _storage.getMap('${AppConstants.tasbihCounterKey}_stats');
      if (statsData != null) {
        _dhikrStats = {};
        statsData.forEach((key, value) {
          if (value is int) {
            _dhikrStats[key] = value;
          } else if (value is num) {
            _dhikrStats[key] = value.toInt();
          }
        });
        debugPrint('[TasbihService] Dhikr stats loaded - count: ${_dhikrStats.length}');
      }
    } catch (e) {
      debugPrint('[TasbihService] Error loading dhikr stats: $e');
      _dhikrStats = {};
    }
  }

  Future<void> _loadCustomAdhkar() async {
    try {
      final customAdhkarData = _storage.getMap('${AppConstants.tasbihCounterKey}_custom_adhkar');
      if (customAdhkarData != null) {
        _customAdhkar = [];
        
        final sortedKeys = customAdhkarData.keys
            .where((key) => int.tryParse(key) != null)
            .map((key) => int.parse(key))
            .toList()
          ..sort();
        
        debugPrint('[TasbihService] Loading ${sortedKeys.length} custom adhkar...');
        
        for (final key in sortedKeys) {
          final dhikrData = customAdhkarData[key.toString()];
          if (dhikrData is Map<String, dynamic>) {
            try {
              final dhikr = DhikrItem.fromMap(dhikrData);
              _customAdhkar.add(dhikr);
              debugPrint('[TasbihService] [$key] Loaded: ${dhikr.text}, count: ${dhikr.recommendedCount}');
            } catch (e) {
              debugPrint('[TasbihService] [$key] Invalid custom dhikr: $e');
              debugPrint('[TasbihService] [$key] Data: $dhikrData');
            }
          }
        }
        
        _adhkarCacheDirty = true;
        debugPrint('[TasbihService] Custom adhkar loaded successfully - total: ${_customAdhkar.length}');
      } else {
        debugPrint('[TasbihService] No custom adhkar found in storage');
      }
    } catch (e) {
      debugPrint('[TasbihService] Error loading custom adhkar: $e');
      _customAdhkar = [];
    }
  }

  Future<void> _saveCustomAdhkar() async {
    try {
      final customAdhkarData = <String, dynamic>{};
      
      debugPrint('[TasbihService] Saving ${_customAdhkar.length} custom adhkar...');
      
      for (int i = 0; i < _customAdhkar.length; i++) {
        final dhikrMap = _customAdhkar[i].toMap();
        customAdhkarData[i.toString()] = dhikrMap;
        
        debugPrint('[TasbihService] [$i] Saving: ${_customAdhkar[i].text}, count: ${_customAdhkar[i].recommendedCount}');
        debugPrint('[TasbihService] [$i] Map recommendedCount: ${dhikrMap['recommendedCount']} (${dhikrMap['recommendedCount'].runtimeType})');
      }
      
      await _storage.setMap('${AppConstants.tasbihCounterKey}_custom_adhkar', customAdhkarData);
      debugPrint('[TasbihService] Custom adhkar saved successfully');
      
      // التحقق من الحفظ
      final saved = _storage.getMap('${AppConstants.tasbihCounterKey}_custom_adhkar');
      if (saved != null) {
        debugPrint('[TasbihService] Verification - saved keys: ${saved.keys.toList()}');
        for (final key in saved.keys.take(3)) {
          final item = saved[key];
          if (item is Map) {
            debugPrint('[TasbihService] Verification [$key]: ${item['text']}, count: ${item['recommendedCount']}');
          }
        }
      }
    } catch (e) {
      debugPrint('[TasbihService] Error saving custom adhkar: $e');
      rethrow;
    }
  }

  Future<void> addCustomDhikr(DhikrItem dhikr) async {
    try {
      if (_customAdhkar.any((d) => d.id == dhikr.id)) {
        throw Exception('Dhikr with id ${dhikr.id} already exists');
      }
      
      debugPrint('[TasbihService] Adding custom dhikr:');
      debugPrint('  - Text: ${dhikr.text}');
      debugPrint('  - Count: ${dhikr.recommendedCount}');
      debugPrint('  - Category: ${dhikr.category.name}');
      debugPrint('  - ID: ${dhikr.id}');
      
      _customAdhkar.add(dhikr);
      _adhkarCacheDirty = true;
      
      await _saveCustomAdhkar();
      
      // التحقق من الإضافة
      final addedDhikr = _customAdhkar.firstWhere((d) => d.id == dhikr.id);
      debugPrint('[TasbihService] Verification after add:');
      debugPrint('  - Text: ${addedDhikr.text}');
      debugPrint('  - Count: ${addedDhikr.recommendedCount}');
      debugPrint('  - Match: ${addedDhikr.recommendedCount == dhikr.recommendedCount}');
      
      notifyListeners();
      
      debugPrint('[TasbihService] Custom dhikr added successfully');
    } catch (e) {
      debugPrint('[TasbihService] Error adding custom dhikr: $e');
      rethrow;
    }
  }

  Future<void> updateCustomDhikr(String id, DhikrItem updatedDhikr) async {
    try {
      final index = _customAdhkar.indexWhere((d) => d.id == id);
      if (index == -1) {
        throw Exception('Dhikr with id $id not found');
      }
      
      final oldDhikr = _customAdhkar[index];
      debugPrint('[TasbihService] Updating custom dhikr:');
      debugPrint('  - Old: ${oldDhikr.text}, count: ${oldDhikr.recommendedCount}');
      debugPrint('  - New: ${updatedDhikr.text}, count: ${updatedDhikr.recommendedCount}');
      
      _customAdhkar[index] = updatedDhikr;
      _adhkarCacheDirty = true;
      
      await _saveCustomAdhkar();
      
      // التحقق من التحديث
      final updated = _customAdhkar[index];
      debugPrint('[TasbihService] Verification after update:');
      debugPrint('  - Text: ${updated.text}');
      debugPrint('  - Count: ${updated.recommendedCount}');
      debugPrint('  - Match: ${updated.recommendedCount == updatedDhikr.recommendedCount}');
      
      notifyListeners();
      
      debugPrint('[TasbihService] Custom dhikr updated successfully');
    } catch (e) {
      debugPrint('[TasbihService] Error updating custom dhikr: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomDhikr(String id) async {
    try {
      final removedCount = _customAdhkar.length;
      final dhikrToDelete = _customAdhkar.firstWhere((d) => d.id == id);
      
      debugPrint('[TasbihService] Deleting custom dhikr: ${dhikrToDelete.text}');
      
      _customAdhkar.removeWhere((d) => d.id == id);
      
      // ✅ إصلاح: التحقق الصحيح من الحذف
      if (_customAdhkar.length == removedCount) {
        throw Exception('Dhikr with id $id not found');
      }
      
      _adhkarCacheDirty = true;
      
      await _saveCustomAdhkar();
      notifyListeners();
      
      debugPrint('[TasbihService] Custom dhikr deleted successfully');
    } catch (e) {
      debugPrint('[TasbihService] Error deleting custom dhikr: $e');
      rethrow;
    }
  }

  void startSession(String dhikrType) {
    _sessionStartTime = DateTime.now();
    _currentDhikrType = dhikrType;
    debugPrint('[TasbihService] Session started - dhikrType: $dhikrType');
  }

  Future<void> endSession() async {
    if (_sessionStartTime == null || _currentDhikrType == null) {
      return;
    }
    
    final sessionCount = _count;
    final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;
    
    debugPrint('[TasbihService] Session ended - dhikrType: $_currentDhikrType, count: $sessionCount, duration: ${duration}s');
    
    if (sessionCount > 0) {
      await _saveDailyRecord();
    }
    
    _sessionStartTime = null;
    _currentDhikrType = null;
  }

  // ✅ إصلاح: استخدام debouncing للحفظ
  Future<void> increment({String dhikrType = 'default'}) async {
    try {
      if (_sessionStartTime == null) {
        startSession(dhikrType);
      }
      
      _count++;
      _todayCount++;
      _totalCount++;
      
      _dhikrStats[dhikrType] = (_dhikrStats[dhikrType] ?? 0) + 1;
      
      notifyListeners();
      
      // ✅ حفظ مُؤجل بـ 500ms لتجنب الكتابة المتكررة
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 500), () {
        _saveCountData();
      });
      
      debugPrint('[TasbihService] Incremented - count: $_count, dhikrType: $dhikrType');
    } catch (e) {
      debugPrint('[TasbihService] Error incrementing: $e');
    }
  }

  Future<void> _saveCountData() async {
    try {
      await Future.wait([
        _storage.setInt(AppConstants.tasbihCounterKey, _count),
        _storage.setInt('${AppConstants.tasbihCounterKey}_today', _todayCount),
        _storage.setInt('${AppConstants.tasbihCounterKey}_total', _totalCount),
        _storage.setMap('${AppConstants.tasbihCounterKey}_stats', _dhikrStats),
      ]);
      debugPrint('[TasbihService] Count data saved successfully');
    } catch (e) {
      debugPrint('[TasbihService] Error saving count data: $e');
    }
  }

  Future<void> reset() async {
    try {
      // ✅ إلغاء أي حفظ مُؤجل
      _saveTimer?.cancel();
      
      await endSession();
      
      final previousCount = _count;
      _count = 0;
      notifyListeners();
      
      await _storage.setInt(AppConstants.tasbihCounterKey, _count);
      
      debugPrint('[TasbihService] Counter reset - previousCount: $previousCount');
    } catch (e) {
      debugPrint('[TasbihService] Error resetting: $e');
    }
  }

  Future<void> resetDaily() async {
    try {
      _saveTimer?.cancel();
      
      await _saveDailyRecord();
      await endSession();
      
      _todayCount = 0;
      notifyListeners();
      
      await _storage.setInt('${AppConstants.tasbihCounterKey}_today', _todayCount);
      
      debugPrint('[TasbihService] Daily count reset');
    } catch (e) {
      debugPrint('[TasbihService] Error resetting daily count: $e');
    }
  }

  Future<void> resetAll() async {
    try {
      _saveTimer?.cancel();
      
      await endSession();
      
      _count = 0;
      _todayCount = 0;
      _totalCount = 0;
      _dhikrStats.clear();
      _history.clear();
      
      notifyListeners();
      
      await Future.wait([
        _storage.remove(AppConstants.tasbihCounterKey),
        _storage.remove('${AppConstants.tasbihCounterKey}_today'),
        _storage.remove('${AppConstants.tasbihCounterKey}_total'),
        _storage.remove('${AppConstants.tasbihCounterKey}_stats'),
        _storage.remove('${AppConstants.tasbihCounterKey}_history'),
      ]);
      
      debugPrint('[TasbihService] All data reset');
    } catch (e) {
      debugPrint('[TasbihService] Error resetting all data: $e');
    }
  }

  Future<void> _resetDailyCount() async {
    if (_todayCount > 0) {
      await _saveDailyRecord();
    }
    _todayCount = 0;
  }

  Future<void> _saveDailyRecord() async {
    try {
      final record = DailyRecord(
        date: _lastUsedDate,
        count: _todayCount,
        dhikrBreakdown: Map<String, int>.from(_dhikrStats),
      );
      
      _history.insert(0, record);
      
      if (_history.length > 30) {
        _history = _history.take(30).toList();
      }
      
      await _saveHistory();
    } catch (e) {
      debugPrint('[TasbihService] Error saving daily record: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final historyMap = _storage.getMap('${AppConstants.tasbihCounterKey}_history');
      if (historyMap != null) {
        _history = [];
        
        final sortedKeys = historyMap.keys
            .where((key) => int.tryParse(key) != null)
            .map((key) => int.parse(key))
            .toList()
          ..sort();
        
        for (final key in sortedKeys) {
          final recordData = historyMap[key.toString()];
          if (recordData is Map<String, dynamic>) {
            try {
              _history.add(DailyRecord.fromMap(recordData));
            } catch (e) {
              debugPrint('[TasbihService] Invalid history record at index $key: $e');
            }
          }
        }
        
        debugPrint('[TasbihService] History loaded - count: ${_history.length}');
      }
    } catch (e) {
      debugPrint('[TasbihService] Error loading history: $e');
      _history = [];
    }
  }

  Future<void> _saveHistory() async {
    try {
      final historyData = <String, dynamic>{};
      for (int i = 0; i < _history.length; i++) {
        historyData[i.toString()] = _history[i].toMap();
      }
      await _storage.setMap('${AppConstants.tasbihCounterKey}_history', historyData);
      debugPrint('[TasbihService] History saved - count: ${_history.length}');
    } catch (e) {
      debugPrint('[TasbihService] Error saving history: $e');
      rethrow;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  int getWeeklyCount() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _history
        .where((record) => record.date.isAfter(weekAgo))
        .fold(0, (sum, record) => sum + record.count);
  }

  int getMonthlyCount() {
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return _history
        .where((record) => record.date.isAfter(monthAgo))
        .fold(0, (sum, record) => sum + record.count);
  }

  double getAverageDaily() {
    if (_history.isEmpty) return 0.0;
    
    final totalDays = _history.length;
    final totalCount = _history.fold(0, (sum, record) => sum + record.count);
    
    return totalCount / totalDays;
  }

  double getWeeklyAverage() {
    final weekRecords = getLastWeekRecords();
    if (weekRecords.isEmpty) return 0.0;
    
    final totalCount = weekRecords.fold(0, (sum, record) => sum + record.count);
    return totalCount / 7;
  }

  List<DailyRecord> getLastWeekRecords() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _history
        .where((record) => record.date.isAfter(weekAgo))
        .toList();
  }

  String getMostUsedDhikr() {
    if (_dhikrStats.isEmpty) return 'لا يوجد';
    
    String mostUsed = _dhikrStats.keys.first;
    int maxCount = _dhikrStats[mostUsed] ?? 0;
    
    for (final entry in _dhikrStats.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostUsed = entry.key;
      }
    }
    
    return mostUsed;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    endSession();
    super.dispose();
  }
}

class DailyRecord {
  final DateTime date;
  final int count;
  final Map<String, int> dhikrBreakdown;

  const DailyRecord({
    required this.date,
    required this.count,
    required this.dhikrBreakdown,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'count': count,
      'dhikrBreakdown': dhikrBreakdown,
    };
  }

  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      date: DateTime.parse(map['date']),
      count: map['count'] ?? 0,
      dhikrBreakdown: Map<String, int>.from(map['dhikrBreakdown'] ?? {}),
    );
  }
}