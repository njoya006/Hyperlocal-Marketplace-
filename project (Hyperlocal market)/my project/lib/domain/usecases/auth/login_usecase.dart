import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

/// Usecase for logging in a user with email and password.
///
/// This callable usecase encapsulates the login business logic.
/// It takes email and password, delegates to the repository,
/// and returns a [UserEntity] if successful.
///
/// Usage:
/// ```dart
/// final loginUsecase = LoginUsecase(authRepository: repository);
/// final user = await loginUsecase(email: 'user@example.com', password: 'pass123');
/// ```
class LoginUsecase {
  /// Authentication repository instance.
  /// Injected via constructor to enable mocking in tests.
  final IAuthRepository _authRepository;

  /// Creates a new [LoginUsecase].
  ///
  /// Requires an [IAuthRepository] implementation to be injected.
  const LoginUsecase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  /// Logs in a user with email and password.
  ///
  /// Delegates to the repository's login method.
  /// Returns [UserEntity] if login succeeds.
  /// Throws [AuthFailure] if login fails.
  Future<UserEntity> call({
    required String email,
    required String password,
  }) async {
    return _authRepository.login(
      email: email,
      password: password,
    );
  }
}
