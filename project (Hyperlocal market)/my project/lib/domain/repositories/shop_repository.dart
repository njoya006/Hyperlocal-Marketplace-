import '../entities/shop_entity.dart';

/// Abstract interface for shop repository operations.
///
/// Defines the contract for all shop-related data operations.
/// Repositories bridge the domain and data layers.
abstract class IShopRepository {
  /// Get shops near the specified location.
  ///
  /// [lat] and [lng] are the center coordinates
  /// [radiusKm] is the search radius in kilometers
  /// Returns a list of [ShopEntity] sorted by distance from the given coordinates.
  Future<List<ShopEntity>> getNearbyShops({
    required double lat,
    required double lng,
    required double radiusKm,
  });

  /// Watch a single shop for real-time updates.
  ///
  /// [shopId] is the shop's unique identifier
  /// Returns a stream that emits shop updates.
  Stream<ShopEntity> watchShop(String shopId);

  /// Create a new shop.
  ///
  /// [shop] is the shop entity to create
  /// Raises exception if creation fails.
  Future<void> createShop(ShopEntity shop);

  /// Update an existing shop.
  ///
  /// [shopId] is the shop's unique identifier
  /// [data] is a map of fields to update
  /// Raises exception if update fails or permission denied.
  Future<void> updateShop(String shopId, Map<String, dynamic> data);

  /// Get all shops owned by a specific user.
  ///
  /// [ownerId] is the owner's user ID
  /// Returns a list of all shops owned by this user.
  Future<List<ShopEntity>> getShopsByOwner(String ownerId);
}
