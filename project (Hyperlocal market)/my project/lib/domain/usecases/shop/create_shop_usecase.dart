import '../../entities/shop_entity.dart';
import '../../repositories/shop_repository.dart';

/// Usecase for creating a new shop.
class CreateShopUsecase {
  /// Creates a new [CreateShopUsecase].
  const CreateShopUsecase({required IShopRepository shopRepository})
      : _shopRepository = shopRepository;

  final IShopRepository _shopRepository;

  /// Creates a shop document for a shop owner.
  Future<void> call({required ShopEntity shop}) async {
    await _shopRepository.createShop(shop);
  }
}
