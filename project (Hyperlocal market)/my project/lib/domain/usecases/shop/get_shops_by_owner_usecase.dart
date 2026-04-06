import '../../entities/shop_entity.dart';
import '../../repositories/shop_repository.dart';

/// Retrieves all shops owned by a specific user.
class GetShopsByOwnerUsecase {
  /// Creates a [GetShopsByOwnerUsecase].
  const GetShopsByOwnerUsecase({required IShopRepository shopRepository})
      : _shopRepository = shopRepository;

  final IShopRepository _shopRepository;

  /// Returns all shops for the owner.
  Future<List<ShopEntity>> call({required String ownerId}) async {
    return await _shopRepository.getShopsByOwner(ownerId);
  }
}