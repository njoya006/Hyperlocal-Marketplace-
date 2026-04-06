import '../../entities/product_entity.dart';
import '../../repositories/product_repository.dart';

/// Usecase for fetching all products of a shop.
class GetShopProductsUsecase {
  /// Creates a [GetShopProductsUsecase].
  const GetShopProductsUsecase({required IProductRepository productRepository})
      : _productRepository = productRepository;

  final IProductRepository _productRepository;

  /// Returns products for the provided shop id.
  Future<List<ProductEntity>> call({required String shopId}) async {
    return await _productRepository.getShopProducts(shopId: shopId);
  }
}
