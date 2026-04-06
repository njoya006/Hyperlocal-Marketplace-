import 'dart:math';

import 'package:equatable/equatable.dart';

/// Shop category enumeration.
enum ShopCategory { grocery, pharmacy, electronics, food, other }

/// Represents a shop entity in the domain layer.
///
/// Pure Dart class with no external dependencies.
/// Contains all shop information and utility methods.
class ShopEntity extends Equatable {
  const ShopEntity({
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

  /// Unique identifier for the shop (Firestore document ID).
  final String id;

  /// Owner's user ID (reference to /users/{userId}).
  final String ownerId;

  /// Shop name/business name.
  final String name;

  /// Detailed description of the shop.
  final String description;

  /// Shop category: grocery, pharmacy, electronics, food, other.
  final ShopCategory category;

  /// GPS latitude coordinate.
  final double latitude;

  /// GPS longitude coordinate.
  final double longitude;

  /// Physical address of the shop.
  final String address;

  /// Contact phone number.
  final String phone;

  /// Whether the shop is currently open.
  final bool isOpen;

  /// Whether the shop has been approved by admin (must be true to appear in listings).
  final bool isApproved;

  /// Average rating from 0.0 to 5.0.
  final double rating;

  /// Total number of reviews/ratings received.
  final int totalReviews;

  /// Timestamp when the shop was created.
  final DateTime createdAt;

  /// Optional URL to shop image stored in Firebase Storage.
  final String? imageUrl;

  /// Returns distance in kilometres from the given coordinates using Haversine formula.
  ///
  /// [lat] and [lng] are the target coordinates in decimal degrees.
  /// Returns the distance in km.
  double distanceTo(double lat, double lng) {
    const double earthRadiusKm = 6371;
    final dLat = _toRadians(lat - latitude);
    final dLng = _toRadians(lng - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(lat)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Converts degrees to radians.
  double _toRadians(double degree) => degree * pi / 180;

  @override
  List<Object?> get props => [id, ownerId, name, isOpen, isApproved, rating];
}
