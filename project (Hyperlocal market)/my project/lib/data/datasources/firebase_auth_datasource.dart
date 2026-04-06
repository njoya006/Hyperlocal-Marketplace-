import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Abstract interface for Firebase authentication operations.
///
/// This interface defines all authentication-related methods that
/// must be implemented by concrete datasources. It serves as a contract
/// between the data layer and the repository/domain layers, enabling
/// easy mocking for unit tests.
abstract class IAuthDatasource {
  /// Signs in a user with email and password.
  ///
  /// Throws [AuthException] if authentication fails.
  /// Returns [UserCredential] containing the authenticated user.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registers a new user with email and password.
  ///
  /// Also creates a Firestore user document with the provided name and role.
  /// Throws [AuthException] if registration fails.
  /// Returns [UserCredential] containing the newly created user.
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  });

  /// Signs out the currently authenticated user.
  ///
  /// Throws [AuthException] if sign out fails.
  Future<void> signOut();

  /// Sends a password reset email to the provided address.
  ///
  /// Throws [AuthException] if request fails.
  Future<void> sendPasswordResetEmail({required String email});

  /// Returns a stream of authentication state changes.
  ///
  /// Emits [User] when a user is authenticated, null when signed out.
  /// This stream is used to watch auth state across the app.
  Stream<User?> authStateChanges();

  /// Gets the currently authenticated user.
  ///
  /// Returns the current [User] if authenticated, null if not.
  /// This is a snapshot getter, not a stream.
  User? get currentUser;

  /// Fetches the user profile document from Firestore by user ID.
  ///
  /// Returns [UserModel] if the user document exists.
  /// Throws [AuthException] if the document is not found or read fails.
  Future<UserModel> getUserData(String uid);
}

/// Concrete implementation of [IAuthDatasource] using Firebase Authentication.
///
/// This datasource handles all direct Firebase Auth SDK calls.
/// All [FirebaseAuthException]s are caught and converted to app-level
/// [AuthException] for consistent error handling throughout the app.
///
/// The datasource saves user profile data to Firestore on registration
/// to store additional fields like name, role, phone, etc. that Firebase
/// Auth doesn't support natively.
class FirebaseAuthDatasource implements IAuthDatasource {
  /// Firebase Authentication instance.
  /// Injected via constructor to allow mocking in tests.
  final FirebaseAuth _firebaseAuth;

  /// Firestore instance for storing user profile data.
  /// Injected via constructor to allow mocking in tests.
  final FirebaseFirestore _firestore;

  /// Creates a new [FirebaseAuthDatasource].
  ///
  /// Requires [FirebaseAuth] and [FirebaseFirestore] to be injected,
  /// ensuring this datasource can be easily tested with mocks.
  const FirebaseAuthDatasource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Sign in failed',
      );
    }
  }

  @override
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // Create Firebase Auth account
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user data to Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
          'role': role,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Registration failed',
      );
    } catch (e) {
      throw AuthException(
        code: 'registration_error',
        message: 'Failed to save user profile: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Sign out failed',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Password reset request failed',
      );
    }
  }

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserModel> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw const AuthException(
          code: 'user_not_found',
          message: 'User profile not found in Firestore',
        );
      }
      return UserModel.fromFirestore(doc);
    } on AuthException {
      // Re-throw app-level auth exceptions
      rethrow;
    } on FirebaseException catch (e) {
      // Preserve Firestore error codes (permission-denied, not-found, etc)
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Failed to fetch user data',
      );
    } catch (e) {
      throw AuthException(
        code: 'fetch_user_error',
        message: 'Failed to fetch user data: ${e.toString()}',
      );
    }
  }
}
