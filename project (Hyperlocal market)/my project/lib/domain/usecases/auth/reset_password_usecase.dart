import '../../repositories/auth_repository.dart';

/// Usecase for requesting a password reset email.
class ResetPasswordUsecase {
  const ResetPasswordUsecase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  final IAuthRepository _authRepository;

  Future<void> call({required String email}) {
    return _authRepository.sendPasswordResetEmail(email: email);
  }
}
