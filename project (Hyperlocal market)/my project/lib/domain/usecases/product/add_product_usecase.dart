import '../../entities/product_entity.dart';
import '../../repositories/product_repository.dart';

/// Usecase for adding a product to a shop.
class AddProductUsecase {
  /// Creates [AddProductUsecase].
  const AddProductUsecase({required IProductRepository productRepository})
      : _productRepository = productRepository;

  final IProductRepository _productRepository;

  /// Persists a new product under the provided shop.
  Future<void> call({
    required String shopId,
    required ProductEntity product,
  }) {
    return _productRepository.addProduct(shopId: shopId, product: product);
  }
}
