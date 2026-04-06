import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';

/// UserModel handles Firestore serialization for User data.
///
/// This model bridges the gap between Firestore (where role is stored as string)
/// and the domain layer (where role is a UserRole enum). It provides factory
/// constructors for parsing Firestore documents and methods for converting
/// to/from domain entities.
///
/// Key differences from UserEntity:
/// - [role] is stored as String (Firestore format)
/// - Includes factory methods for Firestore serialization
/// - Provides conversion between UserModel and UserEntity
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.phone,
    this.photoUrl,
    this.fcmToken,
  });

  /// Unique identifier from Firebase Authentication.
  final String uid;

  /// User's email address (unique).
  final String email;

  /// User's display name.
  final String name;

  /// User's role as string ('customer', 'shop_owner', 'admin').
  /// Stored as string in Firestore for flexibility.
  final String role;

  /// Whether the user account is active.
  final bool isActive;

  /// Account creation timestamp.
  final DateTime createdAt;

  /// Optional phone number.
  final String? phone;

  /// Optional profile photo URL.
  final String? photoUrl;

  /// Firebase Cloud Messaging token for push notifications.
  final String? fcmToken;

  /// Creates a UserModel from a Firestore document snapshot.
  ///
  /// Converts Firestore Timestamp to DateTime.
  /// Defaults [isActive] to true if not present in Firestore.
  /// Uses safe defaults for partially populated documents.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];

    DateTime parsedCreatedAt;
    if (createdAt is Timestamp) {
      parsedCreatedAt = createdAt.toDate();
    } else if (createdAt is DateTime) {
      parsedCreatedAt = createdAt;
    } else {
      parsedCreatedAt = DateTime.now();
    }

    final rawRole = data['role']?.toString().trim();

    return UserModel(
      uid: doc.id,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? 'User',
      role: (rawRole == null || rawRole.isEmpty) ? 'customer' : rawRole,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: parsedCreatedAt,
      phone: data['phone']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      fcmToken: data['fcmToken']?.toString(),
    );
  }

  /// Converts this UserModel to a Firestore document map.
  ///
  /// Uses [FieldValue.serverTimestamp()] for both createdAt and updatedAt
  /// to ensure server-side consistency.
  /// Omits null fields (phone, photoUrl, fcmToken) to reduce storage.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  /// Creates a UserModel from a UserEntity.
  ///
  /// Converts the [UserRole] enum to a string representation
  /// ('customer', 'shop_owner', or 'admin').
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      name: entity.name,
      role: _roleToString(entity.role),
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      phone: entity.phone,
      photoUrl: entity.photoUrl,
      fcmToken: entity.fcmToken,
    );
  }

  /// Converts this UserModel to a UserEntity.
  ///
  /// Converts the string role representation back to a [UserRole] enum.
  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      email: email,
      name: name,
      role: _roleFromString(role),
      isActive: isActive,
      createdAt: createdAt,
      phone: phone,
      photoUrl: photoUrl,
      fcmToken: fcmToken,
    );
  }

  /// Converts a UserRole enum to its string representation.
  ///
  /// Used when converting from domain entity to data model:
  /// - [UserRole.customer] → 'customer'
  /// - [UserRole.shopOwner] → 'shop_owner'
  /// - [UserRole.admin] → 'admin'
  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'customer';
      case UserRole.shopOwner:
        return 'shop_owner';
      case UserRole.admin:
        return 'admin';
    }
  }

  /// Converts a string role representation to a UserRole enum.
  ///
  /// Used when converting from data model to domain entity:
  /// - 'shop_owner' → [UserRole.shopOwner]
  /// - 'admin' → [UserRole.admin]
  /// - Default ('customer' or unrecognized) → [UserRole.customer]
  static UserRole _roleFromString(String role) {
    switch (role) {
      case 'shop_owner':
        return UserRole.shopOwner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }
}
