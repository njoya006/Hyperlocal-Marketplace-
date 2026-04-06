import '../../entities/shop_entity.dart';
import '../../repositories/shop_repository.dart';

/// Use case for watching a specific shop for real-time updates.
///
/// Provides a stream of shop data that updates whenever the shop document changes.
/// Useful for displaying live shop details, status, or waiting for shop approval.
/// Call this usecase by invoking an instance:
/// `watchShopUsecase(shopId: 'shop123')`
class WatchShopUsecase {
  /// Creates a new [WatchShopUsecase].
  const WatchShopUsecase({
    required IShopRepository shopRepository,
  }) : _shopRepository = shopRepository;

  final IShopRepository _shopRepository;

  /// Watch a shop for real-time updates.
  ///
  /// [shopId] is the unique identifier of the shop to watch
  /// Returns a [Stream<ShopEntity>] that emits updates when shop data changes
  /// The stream will emit an error if the shop is not found or query fails
  Stream<ShopEntity> call(String shopId) {
    return _shopRepository.watchShop(shopId);
  }
}
