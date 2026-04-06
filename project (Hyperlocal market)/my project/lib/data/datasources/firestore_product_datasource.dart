import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/exceptions.dart';
import '../models/product_model.dart';

/// Abstract datasource interface for product data access.
abstract class IProductDatasource {
  /// Returns all products in a shop.
  Future<List<ProductModel>> getShopProducts({required String shopId});

  /// Adds a product document under a shop.
  Future<void> addProduct({
    required String shopId,
    required ProductModel product,
  });

  /// Updates fields for an existing product.
  Future<void> updateProduct({
    required String shopId,
    required String productId,
    required Map<String, dynamic> data,
  });

  /// Deletes an existing product.
  Future<void> deleteProduct({
    required String shopId,
    required String productId,
  });
}

/// Firestore implementation of [IProductDatasource].
class FirestoreProductDatasource implements IProductDatasource {
  /// Creates [FirestoreProductDatasource].
  const FirestoreProductDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _productsCollection({
    required String shopId,
  }) {
    return _firestore.collection('shops').doc(shopId).collection('products');
  }

  @override
  Future<List<ProductModel>> getShopProducts({required String shopId}) async {
    try {
      final snapshot = await _productsCollection(shopId: shopId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Failed to fetch products',
      );
    } catch (e) {
      throw ServerException(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<void> addProduct({
    required String shopId,
    required ProductModel product,
  }) async {
    try {
      await _productsCollection(shopId: shopId)
          .doc(product.id)
          .set(product.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Failed to add product',
      );
    } catch (e) {
      throw ServerException(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<void> updateProduct({
    required String shopId,
    required String productId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final updateData = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _productsCollection(shopId: shopId).doc(productId).update(updateData);
    } on FirebaseException catch (e) {
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Failed to update product',
      );
    } catch (e) {
      throw ServerException(code: 'unknown', message: e.toString());
    }
  }

  @override
  Future<void> deleteProduct({
    required String shopId,
    required String productId,
  }) async {
    try {
      await _productsCollection(shopId: shopId).doc(productId).delete();
    } on FirebaseException catch (e) {
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Failed to delete product',
      );
    } catch (e) {
      throw ServerException(code: 'unknown', message: e.toString());
    }
  }
}
