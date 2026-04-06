import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/navigation/customer_bottom_nav.dart';

/// Profile and account actions for customers.
class CustomerProfileScreen extends ConsumerWidget {
  /// Creates [CustomerProfileScreen].
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 3),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Text(
              'Could not load your profile right now.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(AppStrings.messageSignInToContinue),
                    const SizedBox(height: AppSizes.md),
                    ElevatedButton(
                      onPressed: () => context.go(Routes.login),
                      child: const Text(AppStrings.buttonLogin),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person_outline,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    Text(
                      user.email,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.md),
              _ActionTile(
                icon: Icons.receipt_long_outlined,
                title: 'My Orders',
                subtitle: 'Track and review your orders',
                onTap: () => context.go(Routes.customerOrders),
              ),
              const SizedBox(height: AppSizes.sm),
              _ActionTile(
                icon: Icons.shopping_cart_outlined,
                title: 'My Cart',
                subtitle: 'Review items before checkout',
                onTap: () => context.go(Routes.customerCart),
              ),
              const SizedBox(height: AppSizes.sm),
              _ActionTile(
                icon: Icons.storefront_outlined,
                title: 'Browse Shops',
                subtitle: 'Find nearby stores and products',
                onTap: () => context.go(Routes.customerHome),
              ),
              const SizedBox(height: AppSizes.lg),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(logoutUsecaseProvider)();
                  if (context.mounted) {
                    context.go(Routes.login);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.buttonSignOut),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
