import '../../repositories/auth_repository.dart';

/// Usecase for logging out the currently authenticated user.
///
/// This callable usecase encapsulates the logout business logic.
/// It delegates to the repository and completes when logout succeeds.
///
/// Usage:
/// ```dart
/// final logoutUsecase = LogoutUsecase(authRepository: repository);
/// await logoutUsecase();
/// ```
class LogoutUsecase {
  /// Authentication repository instance.
  /// Injected via constructor to enable mocking in tests.
  final IAuthRepository _authRepository;

  /// Creates a new [LogoutUsecase].
  ///
  /// Requires an [IAuthRepository] implementation to be injected.
  const LogoutUsecase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  /// Logs out the currently authenticated user.
  ///
  /// Delegates to the repository's logout method.
  /// Completes successfully if logout succeeds.
  /// Throws [AuthFailure] if logout fails.
  Future<void> call() async {
    return _authRepository.logout();
  }
}
