import 'package:equatable/equatable.dart';

/// Represents a product sold by a shop.
class ProductEntity extends Equatable {
  /// Creates a [ProductEntity].
  const ProductEntity({
    required this.id,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  /// Product document ID.
  final String id;

  /// Owning shop ID.
  final String shopId;

  /// Product display name.
  final String name;

  /// Product description text.
  final String description;

  /// Unit price for a single quantity.
  final double price;

  /// Available stock count.
  final int stockQuantity;

  /// Whether product is available for ordering.
  final bool isAvailable;

  /// Product image URL in Firebase Storage.
  final String? imageUrl;

  /// Product creation timestamp.
  final DateTime createdAt;

  /// Product last update timestamp.
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        shopId,
        name,
        price,
        stockQuantity,
        isAvailable,
        imageUrl,
        createdAt,
        updatedAt,
      ];
}
