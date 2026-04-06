import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/shop_repository.dart';
import '../datasources/firestore_shop_datasource.dart';
import '../models/shop_model.dart';

/// Concrete implementation of [IShopRepository] using [IShopDatasource].
///
/// Handles all shop-related data operations and maps exceptions to failures.
class ShopRepository implements IShopRepository {
  /// Creates a new [ShopRepository].
  const ShopRepository({
    required IShopDatasource shopDatasource,
  }) : _shopDatasource = shopDatasource;

  final IShopDatasource _shopDatasource;

  @override
  Future<List<ShopEntity>> getNearbyShops({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    try {
      final models = await _shopDatasource.getNearbyShops(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
      return models.map((model) => model.toEntity()).toList();
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Stream<ShopEntity> watchShop(String shopId) {
    try {
      return _shopDatasource
          .watchShop(shopId)
          .map((model) => model.toEntity())
          .handleError((error) {
        if (error is ServerException) {
          throw ServerFailure(code: error.code, message: error.message);
        }
        throw ServerFailure(code: 'unknown', message: error.toString());
      });
    } catch (e) {
      if (e is ServerFailure) {
        return Stream.error(e);
      }
      return Stream.error(
        ServerFailure(code: 'unknown', message: e.toString()),
      );
    }
  }

  @override
  Future<void> createShop(ShopEntity shop) async {
    try {
      final model = ShopModel(
        id: shop.id,
        ownerId: shop.ownerId,
        name: shop.name,
        description: shop.description,
        category: _categoryToString(shop.category),
        latitude: shop.latitude,
        longitude: shop.longitude,
        address: shop.address,
        phone: shop.phone,
        isOpen: shop.isOpen,
        isApproved: shop.isApproved,
        rating: shop.rating,
        totalReviews: shop.totalReviews,
        createdAt: shop.createdAt,
        imageUrl: shop.imageUrl,
      );
      await _shopDatasource.createShop(model);
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<void> updateShop(String shopId, Map<String, dynamic> data) async {
    try {
      await _shopDatasource.updateShop(shopId, data);
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<List<ShopEntity>> getShopsByOwner(String ownerId) async {
    try {
      final models = await _shopDatasource.getShopsByOwner(ownerId);
      return models.map((model) => model.toEntity()).toList();
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  /// Converts [ShopCategory] enum to string for Firestore storage.
  String _categoryToString(ShopCategory category) {
    switch (category) {
      case ShopCategory.grocery:
        return 'grocery';
      case ShopCategory.pharmacy:
        return 'pharmacy';
      case ShopCategory.electronics:
        return 'electronics';
      case ShopCategory.food:
        return 'food';
      case ShopCategory.other:
        return 'other';
    }
  }
}
