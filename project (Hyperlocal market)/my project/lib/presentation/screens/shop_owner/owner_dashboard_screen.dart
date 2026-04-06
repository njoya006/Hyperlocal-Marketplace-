import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../router/app_router.dart';
import 'owner_shell_scaffold.dart';

/// Real dashboard for shop owners.
///
/// Guides owners to the right next action based on shop availability
/// and approval state.
class OwnerDashboardScreen extends ConsumerWidget {
  /// Creates [OwnerDashboardScreen].
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return OwnerShellScaffold(
      title: AppStrings.screenTitleShopOwnerDashboard,
      currentIndex: 0,
      actions: [
        IconButton(
          tooltip: AppStrings.buttonSignOut,
          onPressed: () async {
            final logout = ref.read(logoutUsecaseProvider);
            await logout();
            if (context.mounted) {
              context.go(Routes.login);
            }
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: const Text(AppStrings.errorOwnerAccountLoad),
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

          final ownerShopAsync = ref.watch(ownerShopProvider(user.uid));
          return ownerShopAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: const Text(AppStrings.errorOwnerShopLoad),
              ),
            ),
            data: (shop) {
              if (shop == null) {
                return _OwnerDashboardBody(
                  title: 'Welcome, ${user.name}',
                  subtitle:
                      'Create your shop profile to start receiving orders.',
                  statusIcon: Icons.store_mall_directory_outlined,
                  primaryLabel: AppStrings.screenTitleCreateShop,
                  onPrimaryTap: () => context.go(Routes.ownerCreateShop),
                  secondaryLabel: AppStrings.screenTitleOrdersToFulfill,
                  onSecondaryTap: () => context.go(Routes.ownerOrders),
                );
              }

              if (!shop.isApproved) {
                return _OwnerDashboardBody(
                  title: shop.name,
                  subtitle: AppStrings.messageAwaitingApproval,
                  statusIcon: Icons.hourglass_top_rounded,
                  primaryLabel: 'View Approval Status',
                  onPrimaryTap: () => context.go(Routes.ownerAwaitingApproval),
                  secondaryLabel: AppStrings.screenTitleOrdersToFulfill,
                  onSecondaryTap: () => context.go(Routes.ownerOrders),
                );
              }

              return _OwnerDashboardBody(
                title: shop.name,
                subtitle: 'Your shop is live. Manage incoming orders now.',
                statusIcon: Icons.verified_rounded,
                primaryLabel: AppStrings.screenTitleOrdersToFulfill,
                onPrimaryTap: () => context.go(Routes.ownerOrders),
                secondaryLabel: 'Manage Products',
                onSecondaryTap: () => context.go(Routes.ownerProducts),
              );
            },
          );
        },
      ),
    );
  }
}

class _OwnerDashboardBody extends StatelessWidget {
  const _OwnerDashboardBody({
    required this.title,
    required this.subtitle,
    required this.statusIcon,
    required this.primaryLabel,
    required this.onPrimaryTap,
    required this.secondaryLabel,
    required this.onSecondaryTap,
  });

  final String title;
  final String subtitle;
  final IconData statusIcon;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Reveal(
                delay: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Icon(statusIcon,
                            size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      ElevatedButton.icon(
                        onPressed: onPrimaryTap,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(primaryLabel),
                      ),
                      if (secondaryLabel != null && onSecondaryTap != null) ...[
                        const SizedBox(height: AppSizes.md),
                        OutlinedButton.icon(
                          onPressed: onSecondaryTap,
                          icon: const Icon(Icons.tune_rounded),
                          label: Text(secondaryLabel!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              _Reveal(
                delay: 110,
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Orders',
                        subtitle: 'Track and update incoming orders.',
                        onTap: () => context.go(Routes.ownerOrders),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'Products',
                        subtitle: 'Keep your catalog fresh and accurate.',
                        onTap: () => context.go(Routes.ownerProducts),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 320 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, builtChild) {
        final y = (1 - value) * 14;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, y),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
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
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: AppSizes.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSizes.xxs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
