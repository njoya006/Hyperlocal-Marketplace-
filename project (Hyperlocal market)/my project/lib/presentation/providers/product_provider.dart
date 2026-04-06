import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firestore_product_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/product/add_product_usecase.dart';
import '../../domain/usecases/product/get_shop_products_usecase.dart';

/// Provides Firestore for product data.
final productFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provides product datasource implementation.
final productDatasourceProvider = Provider<IProductDatasource>((ref) {
  final firestore = ref.watch(productFirestoreProvider);
  return FirestoreProductDatasource(firestore: firestore);
});

/// Provides product repository implementation.
final productRepositoryProvider = Provider<IProductRepository>((ref) {
  final datasource = ref.watch(productDatasourceProvider);
  return ProductRepository(productDatasource: datasource);
});

/// Provides get shop products usecase.
final getShopProductsUsecaseProvider = Provider<GetShopProductsUsecase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetShopProductsUsecase(productRepository: repository);
});

/// Provides add product usecase.
final addProductUsecaseProvider = Provider<AddProductUsecase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return AddProductUsecase(productRepository: repository);
});

/// Returns products for a given shop id.
final shopProductsProvider =
    FutureProvider.family<List<ProductEntity>, String>((ref, shopId) async {
  final usecase = ref.watch(getShopProductsUsecaseProvider);
  return await usecase(shopId: shopId);
});
