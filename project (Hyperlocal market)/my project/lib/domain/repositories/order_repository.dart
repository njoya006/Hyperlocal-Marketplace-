import '../entities/order_entity.dart';

/// Abstract interface for order repository operations.
abstract class IOrderRepository {
  /// Places a new order and returns the created order ID.
  Future<String> placeOrder({required OrderEntity order});

  /// Watches a single order for updates.
  Stream<OrderEntity> watchOrder(String orderId);

  /// Returns all orders for a customer.
  Future<List<OrderEntity>> getCustomerOrders(String customerId);

  /// Returns all orders for a shop.
  Stream<List<OrderEntity>> getShopOrders(String shopId);

  /// Updates the current status of an order.
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });
}