import 'package:equatable/equatable.dart';

import 'order_item_entity.dart';

/// Order lifecycle states.
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

/// Represents a customer order.
class OrderEntity extends Equatable {
  /// Creates an [OrderEntity].
  const OrderEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.shopId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    required this.status,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.createdAt,
    required this.updatedAt,
    this.customerNotes,
  });

  /// Order document ID.
  final String id;

  /// Ordering customer ID.
  final String customerId;

  /// Ordering customer display name.
  final String customerName;

  /// Shop ID that will fulfill this order.
  final String shopId;

  /// Ordered items.
  final List<OrderItemEntity> items;

  /// Subtotal before fees.
  final double subtotal;

  /// Delivery fee applied to the order.
  final double deliveryFee;

  /// Tax applied to the order.
  final double tax;

  /// Final order total.
  final double total;

  /// Current order status.
  final OrderStatus status;

  /// Delivery destination address.
  final String deliveryAddress;

  /// Delivery latitude.
  final double deliveryLatitude;

  /// Delivery longitude.
  final double deliveryLongitude;

  /// Optional delivery instructions.
  final String? customerNotes;

  /// Order creation time.
  final DateTime createdAt;

  /// Order last update time.
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        shopId,
        items,
        subtotal,
        deliveryFee,
        tax,
        total,
        status,
        deliveryAddress,
        deliveryLatitude,
        deliveryLongitude,
        customerNotes,
        createdAt,
        updatedAt,
      ];
}