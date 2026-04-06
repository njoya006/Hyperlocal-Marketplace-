import '../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../../core/errors/exceptions.dart';

/// Concrete implementation of [IAuthRepository].
///
/// This repository handles all authentication business logic by delegating
/// to the [IAuthDatasource] for Firebase operations. It handles error mapping,
/// converting between Firebase types and domain entities, and managing
/// the conversion from [UserModel] (Firestore) to [UserEntity] (domain).
///
/// All Firebase operations are performed through the injected [IAuthDatasource],
/// ensuring the repository stays independent of Firebase and testable through mocking.
class AuthRepository implements IAuthRepository {
  /// Authentication datasource providing Firebase Auth operations.
  /// Injected via constructor to enable mocking in tests.
  final IAuthDatasource _authDatasource;

  /// Creates a new [AuthRepository].
  ///
  /// Requires an [IAuthDatasource] implementation to be injected.
  const AuthRepository({required IAuthDatasource authDatasource})
      : _authDatasource = authDatasource;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth
      final credential = await _authDatasource.signInWithEmail(
        email: email,
        password: password,
      );

      // Fetch full user profile from Firestore
      if (credential.user == null) {
        throw const AuthFailure(
          code: 'user_not_found',
          message: 'User not found after login',
        );
      }

      try {
        final userModel =
            await _authDatasource.getUserData(credential.user!.uid);
        return userModel.toEntity();
      } on AuthException catch (e) {
        // Allow login even when profile doc is missing or blocked by rules.
        if (e.code == 'permission-denied' ||
            e.code == 'not-found' ||
            e.code == 'user_not_found') {
          return _fallbackUserEntity(
            uid: credential.user!.uid,
            email: credential.user!.email ?? email,
            name: credential.user!.displayName ?? 'User',
          );
        }
        rethrow;
      }
    } on AuthException catch (e) {
      throw AuthFailure(code: e.code, message: e.message);
    } catch (e) {
      throw AuthFailure(
        code: 'login_error',
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // Register with Firebase Auth and save to Firestore
      final credential = await _authDatasource.registerWithEmail(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      // Fetch full user profile from Firestore
      if (credential.user == null) {
        throw const AuthFailure(
          code: 'user_not_found',
          message: 'User not found after registration',
        );
      }

      try {
        final userModel =
            await _authDatasource.getUserData(credential.user!.uid);
        return userModel.toEntity();
      } on AuthException catch (e) {
        // Registration can succeed in Firebase Auth even if profile write/read is
        // denied by Firestore rules in some environments.
        if (e.code == 'permission-denied' ||
            e.code == 'not-found' ||
            e.code == 'user_not_found' ||
            e.code == 'registration_error') {
          return _fallbackUserEntity(
            uid: credential.user!.uid,
            email: credential.user!.email ?? email,
            name: name,
          );
        }
        rethrow;
      }
    } on AuthException catch (e) {
      throw AuthFailure(code: e.code, message: e.message);
    } catch (e) {
      throw AuthFailure(
        code: 'register_error',
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _authDatasource.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(code: e.code, message: e.message);
    } catch (e) {
      throw AuthFailure(
        code: 'logout_error',
        message: 'Logout failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _authDatasource.sendPasswordResetEmail(email: email);
    } on AuthException catch (e) {
      throw AuthFailure(code: e.code, message: e.message);
    } catch (e) {
      throw AuthFailure(
        code: 'password_reset_error',
        message: 'Password reset failed: ${e.toString()}',
      );
    }
  }

  @override
  Stream<UserEntity?> watchAuthState() {
    return _authDatasource.authStateChanges().asyncMap((firebaseUser) async {
      // When user is not authenticated, emit null
      if (firebaseUser == null) {
        return null;
      }

      try {
        // Fetch full user profile from Firestore and convert to entity
        final userModel = await _authDatasource.getUserData(firebaseUser.uid);
        return userModel.toEntity();
      } on AuthException catch (e) {
        // If user document doesn't exist yet (permission denied or not found),
        // return a basic UserEntity with just Firebase auth data
        // The user role will default to 'customer' and can be updated later
        if (e.code == 'permission-denied' || 
            e.code == 'not-found' ||
            e.code == 'user_not_found') {
          return UserEntity(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? 'unknown@example.com',
            name: firebaseUser.displayName ?? 'User',
            role: UserRole.customer,
            isActive: true,
            createdAt: DateTime.now(),
          );
        }
        throw AuthFailure(code: e.code, message: e.message);
      } catch (e) {
        // Handle any other errors gracefully by creating a basic user entity
        return UserEntity(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? 'unknown@example.com',
          name: firebaseUser.displayName ?? 'User',
          role: UserRole.customer,
          isActive: true,
          createdAt: DateTime.now(),
        );
      }
    });
  }

  UserEntity _fallbackUserEntity({
    required String uid,
    required String email,
    required String name,
  }) {
    return UserEntity(
      uid: uid,
      email: email,
      name: name,
      role: UserRole.customer,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }
}
