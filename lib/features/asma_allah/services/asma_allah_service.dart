// lib/features/asma_allah/services/asma_allah_service.dart 
import 'package:flutter/material.dart';
import 'package:athkar_app/core/infrastructure/services/storage/storage_service.dart';
import '../../../core/infrastructure/services/favorites/favorites_service.dart';
import '../../../core/infrastructure/services/favorites/models/favorite_models.dart';
import '../../../app/di/service_locator.dart';
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
  
  // النظام الموحد للمفضلة
  FavoritesService get _favoritesService => getIt<FavoritesService>();
  
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
  
  // ==================== إدارة المفضلة ====================

  /// إضافة اسم إلى المفضلة
  Future<bool> addToFavorites(AsmaAllahModel asmaAllah) async {
    try {
      final favoriteItem = FavoriteItem.fromAsmaAllah(
        nameId: asmaAllah.id.toString(),
        arabicName: asmaAllah.name,
        explanation: asmaAllah.explanation,
      );

      return await _favoritesService.addFavorite(favoriteItem);
    } catch (e) {
      return false;
    }
  }

  /// إزالة اسم من المفضلة
  Future<bool> removeFromFavorites(String nameId) async {
    try {
      return await _favoritesService.removeFavorite(nameId);
    } catch (e) {
      return false;
    }
  }

  /// تبديل حالة المفضلة
  Future<bool> toggleFavorite(AsmaAllahModel item) async {
    try {
      final favoriteItem = FavoriteItem.fromAsmaAllah(
        nameId: 'asma_allah_${item.id}',
        arabicName: item.name,
        explanation: item.explanation,
        transliteration: null,
      );

      return await _favoritesService.toggleFavorite(favoriteItem);
    } catch (e) {
      debugPrint('خطأ في تبديل المفضلة: $e');
      return false;
    }
  }

  /// التحقق من وجود اسم في المفضلة
  Future<bool> isFavorite(String nameId) async {
    return await _favoritesService.isFavorite(nameId);
  }

  /// الحصول على أسماء الله المفضلة
  Future<List<FavoriteItem>> getFavoriteNames() async {
    try {
      return await _favoritesService.getFavoritesByType(FavoriteContentType.asmaAllah);
    } catch (e) {
      return [];
    }
  }

  /// الحصول على عدد أسماء الله المفضلة
  Future<int> getFavoritesCount() async {
    try {
      return await _favoritesService.getCountByType(FavoriteContentType.asmaAllah);
    } catch (e) {
      return 0;
    }
  }

  /// الحصول على أسماء الله المفضلة كـ AsmaAllahModel
  Future<List<AsmaAllahModel>> getFavoriteAsmaAllahModels() async {
    try {
      final favoriteItems = await getFavoriteNames();
      final favoriteModels = <AsmaAllahModel>[];
      
      for (final item in favoriteItems) {
        final nameId = int.tryParse(item.id);
        if (nameId != null) {
          final model = getNameById(nameId);
          if (model != null) {
            favoriteModels.add(model);
          }
        }
      }
      
      return favoriteModels;
    } catch (e) {
      return [];
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