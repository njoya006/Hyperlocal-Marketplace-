import '../entities/user_entity.dart';

/// Abstract interface for authentication repository operations.
///
/// This repository interface defines all authentication-related business logic
/// that needs to be implemented. It serves as a contract between the presentation
/// layer (via usecases) and the data layer (datasources).
///
/// The repository handles:
/// - User login and registration
/// - Logout and auth state management
/// - Error mapping from datasource exceptions to failures
/// - User data conversion from Firebase to domain entities
abstract class IAuthRepository {
  /// Authenticates a user with email and password.
  ///
  /// Returns a [UserEntity] if login succeeds.
  /// Throws [AuthFailure] if authentication fails.
  Future<UserEntity> login({
    required String email,
    required String password,
  });

  /// Registers a new user account.
  ///
  /// Creates a new Firebase Auth account and saves user profile to Firestore.
  /// The [role] parameter must be 'customer' or 'shop_owner'.
  /// Admin accounts must be created manually in Firebase Console.
  ///
  /// Returns a [UserEntity] if registration succeeds.
  /// Throws [AuthFailure] if registration fails.
  Future<UserEntity> register({
    required String email,
    required String password,
    required String name,
    required String role,
  });

  /// Signs out the currently authenticated user.
  ///
  /// Clears all cached authentication state.
  /// Throws [AuthFailure] if sign out fails.
  Future<void> logout();

  /// Sends a password reset email.
  ///
  /// Throws [AuthFailure] if reset request fails.
  Future<void> sendPasswordResetEmail({required String email});

  /// Watches authentication state changes.
  ///
  /// Returns a stream that emits [UserEntity] when a user is authenticated,
  /// or null when the user is signed out. This stream persists across
  /// app sessions and is used to implement role-based routing.
  ///
  /// Throws [AuthFailure] if subscription fails.
  Stream<UserEntity?> watchAuthState();
}
