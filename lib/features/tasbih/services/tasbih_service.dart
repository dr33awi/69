// lib/features/tasbih/services/tasbih_service.dart
import 'package:flutter/material.dart';
import '../../../app/themes/constants/app_constants.dart';
import '../../../core/infrastructure/services/storage/storage_service.dart';
import '../models/dhikr_model.dart';

/// خدمة إدارة المسبحة الرقمية
class TasbihService extends ChangeNotifier {
  final StorageService _storage;

  int _count = 0;
  int _todayCount = 0;
  int _totalCount = 0;
  DateTime _lastUsedDate = DateTime.now();
  
  // إحصائيات متقدمة
  Map<String, int> _dhikrStats = {};
  List<DailyRecord> _history = [];
  
  // الأذكار المخصصة
  List<DhikrItem> _customAdhkar = [];
  
  // للتتبع الجلسة
  DateTime? _sessionStartTime;
  String? _currentDhikrType;

  TasbihService({
    required StorageService storage, 
  }) : _storage = storage {
    _loadData();
  }

  // Getters
  int get count => _count;
  int get todayCount => _todayCount;
  int get totalCount => _totalCount;
  Map<String, int> get dhikrStats => Map.unmodifiable(_dhikrStats);
  List<DailyRecord> get history => List.unmodifiable(_history);
  List<DhikrItem> get customAdhkar => List.unmodifiable(_customAdhkar);
  
  // الحصول على جميع الأذكار (الافتراضية + المخصصة)
  List<DhikrItem> getAllAdhkar() {
    return [...DefaultAdhkar.getAll(), ..._customAdhkar];
  }

  Future<void> _loadData() async {
    try {
      // تحميل العداد الأساسي
      _count = _storage.getInt(AppConstants.tasbihCounterKey) ?? 0;
      
      // تحميل العداد الإجمالي
      _totalCount = _storage.getInt('${AppConstants.tasbihCounterKey}_total') ?? 0;
      
      // تحميل تاريخ آخر استخدام
      final lastDateString = _storage.getString('${AppConstants.tasbihCounterKey}_last_date');
      if (lastDateString != null) {
        try {
          _lastUsedDate = DateTime.parse(lastDateString);
        } catch (e) {
          debugPrint('[TasbihService] Invalid date format, using current date - dateString: $lastDateString');
          _lastUsedDate = DateTime.now();
        }
      }
      
      // تحقق من تغيير اليوم
      final today = DateTime.now();
      if (!_isSameDay(_lastUsedDate, today)) {
        await _resetDailyCount();
        _lastUsedDate = today;
        await _storage.setString(
          '${AppConstants.tasbihCounterKey}_last_date',
          today.toIso8601String(),
        );
      } else {
        // تحميل عداد اليوم
        _todayCount = _storage.getInt('${AppConstants.tasbihCounterKey}_today') ?? 0;
      }
      
      // تحميل إحصائيات الأذكار
      await _loadDhikrStats();
      
      // تحميل التاريخ
      await _loadHistory();
      
      // تحميل الأذكار المخصصة
      await _loadCustomAdhkar();
      
      debugPrint('[TasbihService] Data loaded successfully - count: $_count, todayCount: $_todayCount, totalCount: $_totalCount, customAdhkar: ${_customAdhkar.length}');
      
      notifyListeners();
    } catch (e) {
      debugPrint('[TasbihService] Error loading data: $e');
      // في حالة الخطأ، نبدأ بقيم افتراضية
      _count = 0;
      _todayCount = 0;
      _totalCount = 0;
      _dhikrStats = {};
      _history = [];
      _customAdhkar = [];
      notifyListeners();
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
        
        for (final key in sortedKeys) {
          final dhikrData = customAdhkarData[key.toString()];
          if (dhikrData is Map<String, dynamic>) {
            try {
              _customAdhkar.add(DhikrItem.fromMap(dhikrData));
            } catch (e) {
              debugPrint('[TasbihService] Invalid custom dhikr format');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[TasbihService] Error loading custom adhkar: $e');
      _customAdhkar = [];
    }
  }

  Future<void> _saveCustomAdhkar() async {
    try {
      final customAdhkarData = <String, dynamic>{};
      for (int i = 0; i < _customAdhkar.length; i++) {
        customAdhkarData[i.toString()] = _customAdhkar[i].toMap();
      }
      await _storage.setMap('${AppConstants.tasbihCounterKey}_custom_adhkar', customAdhkarData);
    } catch (e) {
      debugPrint('[TasbihService] Error saving custom adhkar: $e');
    }
  }

  // إضافة ذكر مخصص
  Future<void> addCustomDhikr(DhikrItem dhikr) async {
    try {
      _customAdhkar.add(dhikr);
      await _saveCustomAdhkar();
      notifyListeners();
      debugPrint('[TasbihService] Custom dhikr added - text: ${dhikr.text}');
    } catch (e) {
      debugPrint('[TasbihService] Error adding custom dhikr: $e');
    }
  }

  // تعديل ذكر مخصص
  Future<void> updateCustomDhikr(String id, DhikrItem updatedDhikr) async {
    try {
      final index = _customAdhkar.indexWhere((d) => d.id == id);
      if (index != -1) {
        _customAdhkar[index] = updatedDhikr;
        await _saveCustomAdhkar();
        notifyListeners();
        debugPrint('[TasbihService] Custom dhikr updated - id: $id');
      }
    } catch (e) {
      debugPrint('[TasbihService] Error updating custom dhikr: $e');
    }
  }

  // حذف ذكر مخصص
  Future<void> deleteCustomDhikr(String id) async {
    try {
      _customAdhkar.removeWhere((d) => d.id == id);
      await _saveCustomAdhkar();
      notifyListeners();
      debugPrint('[TasbihService] Custom dhikr deleted - id: $id');
    } catch (e) {
      debugPrint('[TasbihService] Error deleting custom dhikr: $e');
    }
  }

  // بدء جلسة تسبيح جديدة
  void startSession(String dhikrType) {
    _sessionStartTime = DateTime.now();
    _currentDhikrType = dhikrType;
    
    debugPrint('[TasbihService] Session started - dhikrType: $dhikrType');
  }

  // إنهاء جلسة التسبيح
  Future<void> endSession() async {
    if (_sessionStartTime == null || _currentDhikrType == null) return;
    
    final sessionCount = _count;
    final duration = DateTime.now().difference(_sessionStartTime!).inSeconds;
    
    debugPrint('[TasbihService] Session ended - dhikrType: $_currentDhikrType, count: $sessionCount, duration: $duration');
    
    _sessionStartTime = null;
    _currentDhikrType = null;
  }

  Future<void> increment({String dhikrType = 'default'}) async {
    try {
      // بدء جلسة جديدة إذا لم تكن موجودة
      if (_sessionStartTime == null) {
        startSession(dhikrType);
      }
      
      _count++;
      _todayCount++;
      _totalCount++;
      
      // تحديث إحصائيات نوع الذكر
      _dhikrStats[dhikrType] = (_dhikrStats[dhikrType] ?? 0) + 1;
      
      notifyListeners();
      
      // حفظ البيانات
      await Future.wait([
        _storage.setInt(AppConstants.tasbihCounterKey, _count),
        _storage.setInt('${AppConstants.tasbihCounterKey}_today', _todayCount),
        _storage.setInt('${AppConstants.tasbihCounterKey}_total', _totalCount),
        _storage.setMap('${AppConstants.tasbihCounterKey}_stats', _dhikrStats),
      ]);
      
      debugPrint('[TasbihService] Incremented - count: $_count, dhikrType: $dhikrType, todayCount: $_todayCount');
    } catch (e) {
      debugPrint('[TasbihService] Error incrementing: $e');
    }
  }

  Future<void> reset() async {
    try {
      // إنهاء الجلسة الحالية قبل التصفير
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
      // حفظ سجل اليوم قبل التصفير
      await _saveDailyRecord();
      
      // إنهاء الجلسة الحالية
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
      // إنهاء الجلسة الحالية
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
      
      // الاحتفاظ بآخر 30 يوم فقط
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
        
        // ترتيب المفاتيح بترتيب عددي
        final sortedKeys = historyMap.keys
            .where((key) => int.tryParse(key) != null)
            .map((key) => int.parse(key))
            .toList()
          ..sort();
        
        // تحويل البيانات إلى قائمة السجلات
        for (final key in sortedKeys) {
          final recordData = historyMap[key.toString()];
          if (recordData is Map<String, dynamic>) {
            try {
              _history.add(DailyRecord.fromMap(recordData));
            } catch (e) {
              debugPrint('[TasbihService] Invalid history record format');
            }
          }
        }
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
    } catch (e) {
      debugPrint('[TasbihService] Error saving history: $e');
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // إحصائيات متقدمة
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
    // إنهاء الجلسة عند التخلص من الخدمة
    endSession();
    super.dispose();
  }
}

/// نموذج سجل يومي
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