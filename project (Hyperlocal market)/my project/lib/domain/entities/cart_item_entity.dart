import 'package:equatable/equatable.dart';

import 'product_entity.dart';

/// Represents a product inside the shopping cart.
class CartItemEntity extends Equatable {
  /// Creates a [CartItemEntity].
  const CartItemEntity({
    required this.product,
    required this.quantity,
  });

  /// Product added to cart.
  final ProductEntity product;

  /// Quantity selected for this product.
  final int quantity;

  /// Total price for this cart line.
  double get lineTotal => product.price * quantity;

  /// Creates a copy with updated values.
  CartItemEntity copyWith({
    ProductEntity? product,
    int? quantity,
  }) {
    return CartItemEntity(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}