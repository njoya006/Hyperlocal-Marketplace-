import '../entities/product_entity.dart';

/// Abstract interface for product repository operations.
abstract class IProductRepository {
  /// Gets all products for a shop.
  Future<List<ProductEntity>> getShopProducts({required String shopId});

  /// Adds a new product to a shop.
  Future<void> addProduct({
    required String shopId,
    required ProductEntity product,
  });

  /// Updates an existing product.
  Future<void> updateProduct({
    required String shopId,
    required String productId,
    required Map<String, dynamic> data,
  });

  /// Deletes a product from a shop.
  Future<void> deleteProduct({
    required String shopId,
    required String productId,
  });
}
