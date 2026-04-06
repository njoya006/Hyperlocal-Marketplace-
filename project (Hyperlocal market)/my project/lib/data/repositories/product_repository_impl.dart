import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/firestore_product_datasource.dart';
import '../models/product_model.dart';

/// Concrete implementation of [IProductRepository].
class ProductRepository implements IProductRepository {
  /// Creates a [ProductRepository].
  const ProductRepository({required IProductDatasource productDatasource})
      : _productDatasource = productDatasource;

  final IProductDatasource _productDatasource;

  @override
  Future<List<ProductEntity>> getShopProducts({required String shopId}) async {
    try {
      final models = await _productDatasource.getShopProducts(shopId: shopId);
      return models.map((model) => model.toEntity()).toList();
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<void> addProduct({
    required String shopId,
    required ProductEntity product,
  }) async {
    try {
      await _productDatasource.addProduct(
        shopId: shopId,
        product: ProductModel.fromEntity(product),
      );
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<void> updateProduct({
    required String shopId,
    required String productId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _productDatasource.updateProduct(
        shopId: shopId,
        productId: productId,
        data: data,
      );
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<void> deleteProduct({
    required String shopId,
    required String productId,
  }) async {
    try {
      await _productDatasource.deleteProduct(shopId: shopId, productId: productId);
    } on ServerException catch (e) {
      throw ServerFailure(code: e.code, message: e.message);
    } catch (e) {
      throw ServerFailure(code: 'unknown', message: e.toString());
    }
  }
}
