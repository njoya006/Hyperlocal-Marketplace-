import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product_entity.dart';

/// Firestore model for product serialization.
class ProductModel {
  /// Creates a [ProductModel].
  const ProductModel({
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

  /// Creates [ProductModel] from Firestore snapshot.
  factory ProductModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ProductModel(
      id: doc.id,
      shopId: data['shopId'] as String,
      name: data['name'] as String,
      description: data['description'] as String? ?? '',
      price: (data['price'] as num).toDouble(),
      stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 0,
      isAvailable: data['isAvailable'] as bool? ?? true,
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts model to Firestore map.
  Map<String, dynamic> toFirestore() {
    return {
      'shopId': shopId,
      'name': name,
      'description': description,
      'price': price,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Builds [ProductModel] from [ProductEntity].
  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      shopId: entity.shopId,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      stockQuantity: entity.stockQuantity,
      isAvailable: entity.isAvailable,
      imageUrl: entity.imageUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Converts [ProductModel] to [ProductEntity].
  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      shopId: shopId,
      name: name,
      description: description,
      price: price,
      stockQuantity: stockQuantity,
      isAvailable: isAvailable,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
