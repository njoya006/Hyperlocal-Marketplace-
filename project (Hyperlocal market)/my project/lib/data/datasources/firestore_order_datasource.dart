import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/exceptions.dart';
import '../models/order_model.dart';
import '../../domain/entities/order_entity.dart';

/// Abstract interface for order data access operations.
abstract class IOrderDatasource {
  /// Places a new order and returns the created order ID.
  Future<String> placeOrder({required OrderModel order});

  /// Watches a single order for updates.
  Stream<OrderModel> watchOrder(String orderId);

  /// Returns all orders for a customer.
  Future<List<OrderModel>> getCustomerOrders(String customerId);

  /// Returns all orders for a shop.
  Stream<List<OrderModel>> getShopOrders(String shopId);

  /// Updates the status of an order.
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });
}

/// Firestore implementation of [IOrderDatasource].
class FirestoreOrderDatasource implements IOrderDatasource {
  /// Creates a [FirestoreOrderDatasource].
  const FirestoreOrderDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  @override
  Future<String> placeOrder({required OrderModel order}) async {
    try {
      final document = order.id.isEmpty
          ? _ordersCollection.doc()
          : _ordersCollection.doc(order.id);
      await document.set(order.toFirestore());
      return document.id;
    } on FirebaseException catch (e) {
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Failed to place order',
      );
    } catch (e) {
      throw ServerException(code: 'unknown', message: e.toString());
    }
  }

  @override
  Stream<OrderModel> watchOrder(String orderId) {
    try {
      return _ordersCollection.doc(orderId).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          throw const ServerException(
            code: 'not-found',
            message: 'Order not found',
          );
        }
        return OrderModel.fromFirestore(snapshot);
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      return Stream.error(
        ServerException(code: 'unknown', message: e.toString()),
      );
    }
  }

  @override
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    try {
      final snapshot = await _ordersCollection
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Failed to fetch customer orders',
      );
    } catch (e) {
      throw ServerException(code: 'unknown', message: e.toString());
    }
  }

  @override
  Stream<List<OrderModel>> getShopOrders(String shopId) {
    try {
      return _ordersCollection
          .where('shopId', isEqualTo: shopId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => OrderModel.fromFirestore(doc))
                .toList(),
          );
    } on FirebaseException catch (e) {
      return Stream.error(
        ServerException(
          code: e.code,
          message: e.message ?? 'Failed to watch shop orders',
        ),
      );
    } catch (e) {
      return Stream.error(
        ServerException(code: 'unknown', message: e.toString()),
      );
    }
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Failed to update order status',
      );
    } catch (e) {
      throw ServerException(code: 'unknown', message: e.toString());
    }
  }
}