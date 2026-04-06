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

/// Registration screen for new users.
///
/// Material 3 polished design with name, email, password fields,
/// role selector with icon-based cards, and comprehensive validation.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  UserRole? _selectedRole;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _selectedRole = UserRole.customer;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return AppStrings.errorEmailRequired;
    if (!email.contains('@')) return AppStrings.errorEmailInvalid;
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return AppStrings.errorPasswordRequired;
    if (password.length < 8) return AppStrings.errorPasswordTooShort;
    return null;
  }

  String? _validatePasswords(String password, String confirm) {
    if (confirm.isEmpty) return AppStrings.errorConfirmPasswordRequired;
    if (password != confirm) return AppStrings.errorPasswordMismatch;
    return null;
  }

  String? _validateName(String name) {
    if (name.isEmpty) return AppStrings.errorNameRequired;
    return null;
  }

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final nameError = _validateName(name);
    final emailError = _validateEmail(email);
    final passwordError = _validatePassword(password);
    final confirmError = _validatePasswords(password, confirmPassword);

    if (nameError != null) {
      _showError(nameError);
      return;
    }
    if (emailError != null) {
      _showError(emailError);
      return;
    }
    if (passwordError != null) {
      _showError(passwordError);
      return;
    }
    if (confirmError != null) {
      _showError(confirmError);
      return;
    }

    if (_selectedRole == null) {
      _showError(AppStrings.errorRoleRequired);
      return;
    }

    final roleString = _selectedRole == UserRole.customer
        ? 'customer'
        : _selectedRole == UserRole.shopOwner
            ? 'shop_owner'
            : 'admin';

    final registerNotifier = ref.read(registerProvider.notifier);
    await registerNotifier.register(
      email: email,
      password: password,
      name: name,
      role: roleString,
    );
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

  String _mapRegisterError(Object error) {
    if (error is AuthFailure) {
      switch (error.code) {
        case 'email-already-in-use':
          return AppStrings.errorAuthUserExists;
        case 'weak-password':
          return AppStrings.errorAuthWeakPassword;
        case 'invalid-email':
          return AppStrings.errorAuthInvalidEmail;
        case 'network-request-failed':
        case 'network-error':
          return AppStrings.errorAuthNetworkError;
        default:
          return error.message.isNotEmpty
              ? error.message
              : AppStrings.errorRegistrationFailed;
      }
    }

    return AppStrings.errorRegistrationFailed;
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    ref.listen(registerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (context.mounted) {
            if (_selectedRole == UserRole.shopOwner) {
              context.go(Routes.ownerCreateShop);
              return;
            }
            if (_selectedRole == UserRole.admin) {
              context.go(Routes.adminDashboard);
              return;
            }
            context.go(Routes.customerHome);
          }
        },
        error: (error, stack) {
          if (context.mounted) {
            _showError(_mapRegisterError(error));
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
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: registerState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? AppSizes.lg : AppSizes.xxxl,
                        vertical: AppSizes.md,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
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
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    color: Colors.white,
                                    onPressed: registerState.isLoading
                                        ? null
                                        : () => context.go(Routes.login),
                                  ),
                                  const SizedBox(width: AppSizes.xxs),
                                  Text(
                                    'Create Account',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Text(
                                'Join HyperLocal Market today',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.86),
                                    ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              TextField(
                                controller: _nameController,
                                decoration: _authInputDecoration('Full Name')
                                    .copyWith(
                                  hintText: 'John Doe',
                                  prefixIcon: const Icon(Icons.person_outlined),
                                ),
                                enabled: !registerState.isLoading,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              TextField(
                                controller: _emailController,
                                decoration: _authInputDecoration('Email Address')
                                    .copyWith(
                                  hintText: 'you@example.com',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                enabled: !registerState.isLoading,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              TextField(
                                controller: _passwordController,
                                decoration:
                                    _authInputDecoration('Password').copyWith(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: !registerState.isLoading
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
                                enabled: !registerState.isLoading,
                              ),
                              const SizedBox(height: AppSizes.lg),
                              TextField(
                                controller: _confirmPasswordController,
                                decoration:
                                    _authInputDecoration('Confirm Password')
                                        .copyWith(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: !registerState.isLoading
                                        ? () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          }
                                        : null,
                                  ),
                                ),
                                obscureText: _obscureConfirmPassword,
                                enabled: !registerState.isLoading,
                              ),
                              const SizedBox(height: AppSizes.xl),
                              Text(
                                'I want to',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: AppSizes.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RoleCard(
                                      icon: Icons.shopping_cart_outlined,
                                      title: 'Shop',
                                      subtitle: 'I want to buy',
                                      isSelected:
                                          _selectedRole == UserRole.customer,
                                      onTap: registerState.isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedRole = UserRole.customer;
                                              });
                                            },
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.md),
                                  Expanded(
                                    child: _RoleCard(
                                      icon: Icons.store_outlined,
                                      title: 'Sell',
                                      subtitle: 'I want to sell',
                                      isSelected:
                                          _selectedRole == UserRole.shopOwner,
                                      onTap: registerState.isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedRole = UserRole.shopOwner;
                                              });
                                            },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.xl),
                              ElevatedButton(
                                onPressed: registerState.isLoading
                                    ? null
                                    : _handleRegister,
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
                                  registerState.isLoading
                                      ? 'Creating account...'
                                      : 'Create Account',
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
                                    'Already have an account? ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                  TextButton(
                                    onPressed: registerState.isLoading
                                        ? null
                                        : () => context.go(Routes.login),
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
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

  InputDecoration _authInputDecoration(String label) {
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

/// Role selector card widget.
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryLight
                : Colors.white.withValues(alpha: 0.32),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
