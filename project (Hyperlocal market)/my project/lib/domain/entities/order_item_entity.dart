import 'package:equatable/equatable.dart';

/// Represents a single line item inside an order.
class OrderItemEntity extends Equatable {
  /// Creates an [OrderItemEntity].
  const OrderItemEntity({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.productImageUrl,
  });

  /// Ordered product ID.
  final String productId;

  /// Ordered product name.
  final String productName;

  /// Product unit price at the time of ordering.
  final double unitPrice;

  /// Quantity ordered.
  final int quantity;

  /// Optional product image.
  final String? productImageUrl;

  /// Total price for this line item.
  double get lineTotal => unitPrice * quantity;

  @override
  List<Object?> get props => [
        productId,
        productName,
        unitPrice,
        quantity,
        productImageUrl,
      ];
}