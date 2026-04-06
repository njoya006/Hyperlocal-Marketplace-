import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/auth/auth_video_background.dart';

/// Login screen for authenticating existing users.
///
/// Material 3 polished design with email/password validation, visibility toggle,
/// forgot password link, and register navigation.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(AppStrings.errorLoginRequiredFields);
      return;
    }

    final loginNotifier = ref.read(loginProvider.notifier);
    await loginNotifier.login(email: email, password: password);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSizes.lg),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSizes.lg),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final resetEmail = await _promptForResetEmail();
    if (resetEmail == null) {
      return;
    }

    final email = resetEmail.trim();
    if (email.isEmpty) {
      _showError(AppStrings.errorEmailRequired);
      return;
    }

    try {
      await ref.read(resetPasswordUsecaseProvider)(email: email);
      if (!mounted) {
        return;
      }
      _showSuccess(
        'If an account exists for this email, a password reset link has been sent.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(_mapPasswordResetError(error));
    }
  }

  Future<String?> _promptForResetEmail() async {
    final controller = TextEditingController(text: _emailController.text.trim());

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'you@example.com',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.buttonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Send Link'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  String _mapAuthError(Object error) {
    if (error is AuthFailure) {
      switch (error.code) {
        case 'invalid-email':
          return AppStrings.errorAuthInvalidEmail;
        case 'user-not-found':
          return AppStrings.errorAuthUserNotFound;
        case 'wrong-password':
        case 'invalid-credential':
          return AppStrings.errorAuthWrongPassword;
        case 'user-disabled':
          return AppStrings.errorAuthUserDisabled;
        case 'network-request-failed':
        case 'network-error':
          return AppStrings.errorAuthNetworkError;
        default:
          return error.message.isNotEmpty
              ? error.message
              : AppStrings.errorAuthUnknown;
      }
    }

    if (error is String && error.isNotEmpty) {
      return error;
    }

    return AppStrings.errorAuthUnknown;
  }

  String _mapPasswordResetError(Object error) {
    if (error is AuthFailure) {
      switch (error.code) {
        case 'invalid-email':
          return AppStrings.errorAuthInvalidEmail;
        case 'network-request-failed':
        case 'network-error':
          return AppStrings.errorAuthNetworkError;
        case 'too-many-requests':
          return 'Too many attempts. Please try again shortly.';
        default:
          return error.message.isNotEmpty
              ? error.message
              : 'Could not send reset link right now. Please try again.';
      }
    }
    return 'Could not send reset link right now. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    ref.listen(loginProvider, (previous, next) {
      next.when(
        data: (user) {
          if (context.mounted) {
            switch (user.role) {
              case UserRole.shopOwner:
                context.go(Routes.ownerDashboard);
                break;
              case UserRole.admin:
                context.go(Routes.adminDashboard);
                break;
              case UserRole.customer:
                context.go(Routes.customerHome);
                break;
            }
          }
        },
        error: (error, stack) {
          if (context.mounted) {
            _showError(_mapAuthError(error));
          }
        },
        loading: () {},
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AuthVideoBackground()),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: loginState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(
                        isMobile ? AppSizes.lg : AppSizes.xxxl,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.xl),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusXl),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.24),
                                blurRadius: 26,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(AppSizes.radiusLg),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),
                              Text(
                                'Welcome Back',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Text(
                                'Log in to your account',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.88),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSizes.xl),
                              TextField(
                                controller: _emailController,
                                decoration:
                                    _authInputDecoration(context, 'Email Address')
                                        .copyWith(
                                  hintText: 'you@example.com',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                enabled: !loginState.isLoading,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              TextField(
                                controller: _passwordController,
                                decoration: _authInputDecoration(context, 'Password')
                                    .copyWith(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: !loginState.isLoading
                                        ? () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          }
                                        : null,
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                enabled: !loginState.isLoading,
                              ),
                              const SizedBox(height: AppSizes.md),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: loginState.isLoading
                                      ? null
                                      : _handleForgotPassword,
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              ElevatedButton(
                                onPressed:
                                    loginState.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSizes.md,
                                  ),
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppSizes.radiusMd),
                                  ),
                                ),
                                child: Text(
                                  loginState.isLoading
                                      ? 'Signing in...'
                                      : 'Sign In',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                  TextButton(
                                    onPressed: loginState.isLoading
                                        ? null
                                        : () => context.go(Routes.register),
                                    child: const Text(
                                      'Create account',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              if (kDebugMode) ...[
                                const SizedBox(height: AppSizes.sm),
                                TextButton.icon(
                                  onPressed: loginState.isLoading
                                      ? null
                                      : () => context.go(Routes.devRoleSwitch),
                                  icon: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                  ),
                                  label: const Text('Developer tools'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _authInputDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.92)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
      prefixIconColor: Colors.white.withValues(alpha: 0.9),
      suffixIconColor: Colors.white.withValues(alpha: 0.9),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(
          color: AppColors.secondaryLight,
          width: 1.8,
        ),
      ),
    );
  }
}
