import '../../entities/shop_entity.dart';
import '../../repositories/shop_repository.dart';

/// Use case for getting shops near the user's current location.
///
/// Retrieves all approved shops within a specified radius of coordinates.
/// Results are sorted by distance from the given point.
/// Call this usecase by invoking an instance:
/// `await getNearbyShopsUsecase(lat: latitude, lng: longitude, radiusKm: 5.0)`
class GetNearbyShopsUsecase {
  /// Creates a new [GetNearbyShopsUsecase].
  const GetNearbyShopsUsecase({
    required IShopRepository shopRepository,
  }) : _shopRepository = shopRepository;

  final IShopRepository _shopRepository;

  /// Get shops near the specified location.
  ///
  /// [lat] and [lng] are the center coordinates (typically user's current location)
  /// [radiusKm] is the search radius in kilometers
  /// Returns [List<ShopEntity>] sorted by distance (nearest first)
  /// Throws [ServerFailure] if query fails
  Future<List<ShopEntity>> call({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    return await _shopRepository.getNearbyShops(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
    );
  }
}
