import 'package:equatable/equatable.dart';

/// Enum representing the three user roles in HyperLocal Market.
///
/// - [customer]: Regular customer using the app to browse and order
/// - [shopOwner]: Shop owner managing products and orders
/// - [admin]: System administrator with full access
enum UserRole { customer, shopOwner, admin }

/// UserEntity represents a user in the domain layer.
///
/// This entity is platform and framework agnostic, containing only
/// business logic related fields. It uses Equatable for value equality
/// comparison, enabling proper testing and state management.
///
/// The [UserRole] enum defines the three supported user types:
/// - Customer: Can browse shops, add to cart, checkout
/// - Shop Owner: Can manage shop details, products, orders, and ratingsA
/// - Admin: Full system access and management capabilities
class UserEntity extends Equatable {
  const UserEntity({
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

  /// User's role ([UserRole]).
  final UserRole role;

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

  /// Convenience getter to check if user is a customer.
  bool get isCustomer => role == UserRole.customer;

  /// Convenience getter to check if user is a shop owner.
  bool get isShopOwner => role == UserRole.shopOwner;

  /// Convenience getter to check if user is an admin.
  bool get isAdmin => role == UserRole.admin;

  /// Creates a copy of this UserEntity with optional field overrides.
  ///
  /// Immutable fields (uid, email, role, createdAt) cannot be changed.
  /// This method is useful for updating user profile information.
  UserEntity copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? fcmToken,
    bool? isActive,
  }) {
    return UserEntity(
      uid: uid,
      email: email,
      name: name ?? this.name,
      role: role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  List<Object?> get props => [uid, email, name, role, isActive, createdAt];

  @override
  String toString() => 'UserEntity(uid: $uid, email: $email, name: $name, '
      'role: $role, isActive: $isActive, createdAt: $createdAt)';
}
