import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_info.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/reset_password_usecase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ============================================================================
// DATASOURCES
// ============================================================================

/// Provides singleton instance of FirebaseAuth.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provides singleton instance of FirebaseFirestore.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provides singleton instance of Connectivity for network checks.
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Provides INetworkInfo implementation with connectivity check.
final networkInfoProvider = Provider<INetworkInfo>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return NetworkInfo(connectivity: connectivity);
});

/// Provides IAuthDatasource implementation.
final authDatasourceProvider = Provider<IAuthDatasource>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return FirebaseAuthDatasource(
    firebaseAuth: firebaseAuth,
    firestore: firestore,
  );
});

// ============================================================================
// REPOSITORIES
// ============================================================================

/// Provides IAuthRepository implementation.
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authDatasource = ref.watch(authDatasourceProvider);
  return AuthRepository(authDatasource: authDatasource);
});

// ============================================================================
// USECASES
// ============================================================================

/// Provides LoginUsecase.
final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LoginUsecase(authRepository: authRepository);
});

/// Provides RegisterUsecase.
final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return RegisterUsecase(authRepository: authRepository);
});

/// Provides LogoutUsecase.
final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LogoutUsecase(authRepository: authRepository);
});

/// Provides ResetPasswordUsecase.
final resetPasswordUsecaseProvider = Provider<ResetPasswordUsecase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ResetPasswordUsecase(authRepository: authRepository);
});

// ============================================================================
// STATE MANAGEMENT — AUTH
// ============================================================================

/// Watches authentication state changes in real-time.
///
/// This stream provider emits [UserEntity] when a user is authenticated,
/// or null when signed out. It's used throughout the app to:
/// - Check if user is logged in
/// - Redirect to login screen if not authenticated
/// - Display user info in UI
/// - Trigger role-based routing
///
/// Usage in screens:
/// ```dart
/// final authState = ref.watch(authStateProvider);
/// authState.when(
///   data: (user) => user != null ? HomeScreen() : LoginScreen(),
///   loading: () => SplashScreen(),
///   error: (err, stack) => ErrorScreen(error: err),
/// );
/// ```
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.watchAuthState();
});

// ============================================================================
// ASYNC NOTIFIERS — LOGIN & REGISTER
// ============================================================================

/// State for login provider (holds loading/error states).
typedef LoginState = AsyncValue<UserEntity>;

/// Notifier for Login operations with state management.
class LoginNotifier extends AsyncNotifier<UserEntity> {
  @override
  Future<UserEntity> build() async {
    // Don't auto-load on build, wait for explicit call()
    throw UnimplementedError();
  }

  /// Performs login with email and password.
  ///
  /// Updates state to loading, then either data or error state.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final loginUsecase = ref.read(loginUsecaseProvider);
    state = await AsyncValue.guard(() => loginUsecase(
          email: email,
          password: password,
        ));
  }
}

/// Provides the login async notifier for state management.
///
/// Usage in screens:
/// ```dart
/// final loginNotifier = ref.read(loginProvider.notifier);
/// await loginNotifier.login(email: 'user@example.com', password: 'pass123');
///
/// // Watch for state changes
/// final loginState = ref.watch(loginProvider);
/// loginState.whenData((user) => print('Logged in: ${user.name}'));
/// ```
final loginProvider =
    AsyncNotifierProvider<LoginNotifier, UserEntity>(() => LoginNotifier());

/// State for register provider (holds loading/error states).
typedef RegisterState = AsyncValue<UserEntity>;

/// Notifier for Register operations with state management.
class RegisterNotifier extends AsyncNotifier<UserEntity> {
  @override
  Future<UserEntity> build() async {
    // Don't auto-load on build, wait for explicit call()
    throw UnimplementedError();
  }

  /// Performs registration with email, password, name, and role.
  ///
  /// Updates state to loading, then either data or error state.
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    final registerUsecase = ref.read(registerUsecaseProvider);
    state = await AsyncValue.guard(() => registerUsecase(
          email: email,
          password: password,
          name: name,
          role: role,
        ));
  }
}

/// Provides the register async notifier for state management.
///
/// Usage in screens:
/// ```dart
/// final registerNotifier = ref.read(registerProvider.notifier);
/// await registerNotifier.register(
///   email: 'user@example.com',
///   password: 'pass123',
///   name: 'John Doe',
///   role: 'customer',
/// );
///
/// // Watch for state changes
/// final registerState = ref.watch(registerProvider);
/// registerState.whenData((user) => print('Registered: ${user.name}'));
/// ```
final registerProvider = AsyncNotifierProvider<RegisterNotifier, UserEntity>(
    () => RegisterNotifier());

/// Provides the logout usecase for direct invocation.
///
/// Usage in screens:
/// ```dart
/// final logoutUsecase = ref.read(logoutUsecaseProvider);
/// await logoutUsecase();
/// ```
