// lib/features/asma_allah/services/asma_allah_service.dart 
import 'package:flutter/material.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import '../models/asma_allah_model.dart';
import '../data/asma_allah_data.dart';

/// خدمة إدارة أسماء الله الحسنى (مبسطة)
class AsmaAllahService extends ChangeNotifier {
  
  // قائمة الأسماء
  List<AsmaAllahModel> _asmaAllahList = [];
  List<AsmaAllahModel> get asmaAllahList => _asmaAllahList;
  
  // حالة التحميل
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  AsmaAllahService({
    required StorageService storage,
  }) {
    _init();
  }
  
  /// تهيئة الخدمة
  Future<void> _init() async {
    await loadAsmaAllah();
  }
  
  /// تحميل أسماء الله الحسنى
  Future<void> loadAsmaAllah() async {
    try {
      _setLoading(true);
      
      // تحميل البيانات من الملف المحلي
      _asmaAllahList = AsmaAllahData.getAllNames()
        .map((data) => AsmaAllahModel.fromJson(data))
        .toList();
    } catch (e) {
      debugPrint('Error loading Asma Allah: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// الحصول على اسم بواسطة المعرف
  AsmaAllahModel? getNameById(int id) {
    try {
      return _asmaAllahList.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
  
  /// تعيين حالة التحميل
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}
