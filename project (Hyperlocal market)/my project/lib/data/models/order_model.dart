import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_item_entity.dart';

/// Firestore model for order serialization.
class OrderModel {
  /// Creates an [OrderModel].
  const OrderModel({
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

  /// Ordering customer name.
  final String customerName;

  /// Shop ID that will fulfill the order.
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

  /// Creates an [OrderModel] from Firestore.
  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final itemsData = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => OrderItemEntity(
              productId: item['productId'] as String,
              productName: item['productName'] as String,
              unitPrice: (item['unitPrice'] as num).toDouble(),
              quantity: (item['quantity'] as num).toInt(),
              productImageUrl: item['productImageUrl'] as String?,
            ))
        .toList();

    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] as String,
      customerName: data['customerName'] as String? ?? '',
      shopId: data['shopId'] as String,
      items: itemsData,
      subtotal: (data['subtotal'] as num).toDouble(),
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num).toDouble(),
      status: _statusFromString(data['status'] as String? ?? 'pending'),
      deliveryAddress: data['deliveryAddress'] as String? ?? '',
      deliveryLatitude: (data['deliveryLatitude'] as num?)?.toDouble() ?? 0.0,
      deliveryLongitude: (data['deliveryLongitude'] as num?)?.toDouble() ?? 0.0,
      customerNotes: data['customerNotes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts the model to Firestore data.
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      if (customerName.isNotEmpty) 'customerName': customerName,
      'shopId': shopId,
      'items': items
          .map(
            (item) => {
              'productId': item.productId,
              'productName': item.productName,
              'unitPrice': item.unitPrice,
              'quantity': item.quantity,
              if (item.productImageUrl != null) 'productImageUrl': item.productImageUrl,
            },
          )
          .toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'total': total,
      'status': status.name,
      'deliveryAddress': deliveryAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      if (customerNotes != null) 'customerNotes': customerNotes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Builds a model from an entity.
  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      customerId: entity.customerId,
      customerName: entity.customerName,
      shopId: entity.shopId,
      items: entity.items,
      subtotal: entity.subtotal,
      deliveryFee: entity.deliveryFee,
      tax: entity.tax,
      total: entity.total,
      status: entity.status,
      deliveryAddress: entity.deliveryAddress,
      deliveryLatitude: entity.deliveryLatitude,
      deliveryLongitude: entity.deliveryLongitude,
      customerNotes: entity.customerNotes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts to an entity.
  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      customerId: customerId,
      customerName: customerName,
      shopId: shopId,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      tax: tax,
      total: total,
      status: status,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      customerNotes: customerNotes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static OrderStatus _statusFromString(String value) {
    switch (value) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'outForDelivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}