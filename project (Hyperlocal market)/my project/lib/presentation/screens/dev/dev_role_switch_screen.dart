import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';

/// Debug-only screen for switching the current account role.
class DevRoleSwitchScreen extends ConsumerStatefulWidget {
  /// Creates [DevRoleSwitchScreen].
  const DevRoleSwitchScreen({super.key});

  @override
  ConsumerState<DevRoleSwitchScreen> createState() =>
      _DevRoleSwitchScreenState();
}

class _DevRoleSwitchScreenState extends ConsumerState<DevRoleSwitchScreen> {
  bool _isSaving = false;
  static const String _debugAdminEmail = 'admin@hyperlocal.dev';
  static const String _debugAdminPassword = 'Admin@12345';
  static const String _debugAdminName = 'Debug Admin';

  Future<void> _createDebugAdminAccount() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final firebaseAuth = ref.read(firebaseAuthProvider);
      final firestore = ref.read(firestoreProvider);

      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: _debugAdminEmail,
        password: _debugAdminPassword,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Admin account could not be created');
      }

      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': _debugAdminEmail,
        'name': _debugAdminName,
        'role': 'admin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await ref.read(logoutUsecaseProvider)();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debug admin created. Sign in with admin@hyperlocal.dev / Admin@12345',
          ),
        ),
      );
      context.go(Routes.login);
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Debug admin already exists. Use admin@hyperlocal.dev / Admin@12345',
            ),
          ),
        );
        context.go(Routes.login);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create debug admin: ${e.message}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create debug admin: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _promoteToAdmin() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Grant Admin Access'),
            content: const Text(
              'This will promote the signed-in account to admin role and sign out immediately. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(AppStrings.buttonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Promote'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }
    await _switchRole('admin');
  }

  Future<void> _switchRole(String role) async {
    final currentUser = ref.read(authStateProvider).maybeWhen(
          data: (user) => user,
          orElse: () => null,
        );
    if (currentUser == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('users').doc(currentUser.uid).update({
        'role': role,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await ref.read(logoutUsecaseProvider)();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Role updated to ${_roleLabel(role)}. Sign in again to continue.'),
        ),
      );
      context.go(Routes.login);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch role: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'customer':
        return 'Customer';
      case 'shop_owner':
        return 'Shop Owner';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).maybeWhen(
          data: (user) => user,
          orElse: () => null,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Role Switch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: currentUser == null
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_outline, size: 48),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        'Sign in first to switch roles.',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.lg),
                      FilledButton(
                        onPressed: _isSaving ? null : () => context.go(Routes.login),
                        child: const Text(AppStrings.buttonLogin),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => context.go(Routes.register),
                        child: const Text(AppStrings.buttonRegister),
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create debug admin account',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              const Text('Email: admin@hyperlocal.dev'),
                              const Text('Password: Admin@12345'),
                              const SizedBox(height: AppSizes.md),
                              FilledButton.icon(
                                onPressed:
                                    _isSaving ? null : _createDebugAdminAccount,
                                icon: const Icon(Icons.admin_panel_settings_outlined),
                                label: const Text('Create Admin'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isSaving) ...[
                        const SizedBox(height: AppSizes.md),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Account',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            Text(currentUser.name),
                            const SizedBox(height: 4),
                            Text(currentUser.email),
                            const SizedBox(height: AppSizes.sm),
                            Chip(
                              label: Text(_roleLabel(currentUser.role.name)),
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'Choose a new role for this account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _RoleTile(
                      title: 'Customer',
                      subtitle: 'Browse shops and place orders',
                      icon: Icons.shopping_bag_outlined,
                      selected: currentUser.role.name == 'customer',
                      enabled: !_isSaving,
                      onTap: () => _switchRole('customer'),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    _RoleTile(
                      title: 'Shop Owner',
                      subtitle: 'Access owner dashboard and orders',
                      icon: Icons.storefront_outlined,
                      selected: currentUser.role.name == 'shopOwner',
                      enabled: !_isSaving,
                      onTap: () => _switchRole('shop_owner'),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    _RoleTile(
                      title: 'Admin',
                      subtitle: 'Access admin dashboard and moderation',
                      icon: Icons.admin_panel_settings_outlined,
                      selected: currentUser.role.name == 'admin',
                      enabled: !_isSaving,
                      onTap: () => _switchRole('admin'),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Row(
                          children: [
                            const Icon(Icons.admin_panel_settings_outlined,
                                color: AppColors.primary),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                'Quick setup: promote this account to admin',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            FilledButton(
                              onPressed: _isSaving ? null : _promoteToAdmin,
                              child: const Text('Promote'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    if (_isSaving) const LinearProgressIndicator(),
                    const SizedBox(height: AppSizes.lg),
                    OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => context.go(Routes.login),
                      child: const Text(AppStrings.buttonBack),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primary : Colors.grey.shade200;
    final backgroundColor =
        selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
