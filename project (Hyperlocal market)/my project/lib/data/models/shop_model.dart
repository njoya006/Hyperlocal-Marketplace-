import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/shop_entity.dart';

/// Shop model for Firestore serialization.
///
/// Handles conversion between Firestore documents and domain entities.
/// All fields are final for immutability.
class ShopModel {
  const ShopModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
    required this.isOpen,
    required this.isApproved,
    required this.rating,
    required this.totalReviews,
    required this.createdAt,
    this.imageUrl,
  });

  /// Unique identifier for the shop.
  final String id;

  /// Owner's user ID.
  final String ownerId;

  /// Shop name.
  final String name;

  /// Shop description.
  final String description;

  /// Shop category (stored as string in Firestore).
  final String category;

  /// GPS latitude.
  final double latitude;

  /// GPS longitude.
  final double longitude;

  /// Physical address.
  final String address;

  /// Contact phone number.
  final String phone;

  /// Whether shop is open.
  final bool isOpen;

  /// Whether shop is approved by admin.
  final bool isApproved;

  /// Average rating.
  final double rating;

  /// Total number of reviews.
  final int totalReviews;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Optional shop image URL.
  final String? imageUrl;

  /// Creates [ShopModel] from a Firestore document snapshot.
  factory ShopModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Extract latitude and longitude - prefer separate fields, fall back to Location geopoint
    double latitude = 0.0;
    double longitude = 0.0;
    
    if (data['latitude'] != null && data['longitude'] != null) {
      // Priority: use separate numeric fields (more reliable for queries)
      latitude = (data['latitude'] as num).toDouble();
      longitude = (data['longitude'] as num).toDouble();
    } else if (data['Location'] != null) {
      // Fallback: extract from Location GeoPoint
      final geoPoint = data['Location'] as GeoPoint;
      latitude = geoPoint.latitude;
      longitude = geoPoint.longitude;
    }
    
    return ShopModel(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      latitude: latitude,
      longitude: longitude,
      address: data['address'] as String,
      phone: data['phone'] as String,
      isOpen: data['isOpen'] as bool? ?? false,
      isApproved: data['isApproved'] as bool? ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  /// Converts [ShopModel] to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'Location': GeoPoint(latitude, longitude),
      'address': address,
      'phone': phone,
      'isOpen': isOpen,
      'isApproved': isApproved,
      'rating': rating,
      'totalReviews': totalReviews,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  /// Converts [ShopModel] to domain [ShopEntity].
  ShopEntity toEntity() {
    return ShopEntity(
      id: id,
      ownerId: ownerId,
      name: name,
      description: description,
      category: _categoryFromString(category),
      latitude: latitude,
      longitude: longitude,
      address: address,
      phone: phone,
      isOpen: isOpen,
      isApproved: isApproved,
      rating: rating,
      totalReviews: totalReviews,
      createdAt: createdAt,
      imageUrl: imageUrl,
    );
  }

  /// Converts category string from Firestore to [ShopCategory] enum.
  static ShopCategory _categoryFromString(String cat) {
    switch (cat) {
      case 'grocery':
        return ShopCategory.grocery;
      case 'pharmacy':
        return ShopCategory.pharmacy;
      case 'electronics':
        return ShopCategory.electronics;
      case 'food':
        return ShopCategory.food;
      default:
        return ShopCategory.other;
    }
  }
}
