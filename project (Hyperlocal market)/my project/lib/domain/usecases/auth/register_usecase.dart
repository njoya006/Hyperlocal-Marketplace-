import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

/// Usecase for registering a new user account.
///
/// This callable usecase encapsulates the registration business logic.
/// It takes email, password, name, and role, delegates to the repository,
/// and returns a [UserEntity] if successful.
///
/// The [role] parameter should be 'customer' or 'shop_owner'.
/// Admin accounts must be created manually in Firebase Console.
///
/// Usage:
/// ```dart
/// final registerUsecase = RegisterUsecase(authRepository: repository);
/// final user = await registerUsecase(
///   email: 'user@example.com',
///   password: 'pass123',
///   name: 'John Doe',
///   role: 'customer',
/// );
/// ```
class RegisterUsecase {
  /// Authentication repository instance.
  /// Injected via constructor to enable mocking in tests.
  final IAuthRepository _authRepository;

  /// Creates a new [RegisterUsecase].
  ///
  /// Requires an [IAuthRepository] implementation to be injected.
  const RegisterUsecase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  /// Registers a new user account.
  ///
  /// Delegates to the repository's register method.
  /// Returns [UserEntity] if registration succeeds.
  /// Throws [AuthFailure] if registration fails.
  Future<UserEntity> call({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    return _authRepository.register(
      email: email,
      password: password,
      name: name,
      role: role,
    );
  }
}
