import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/admin_provider.dart';
import 'admin_shell_scaffold.dart';

/// Admin screen for approving and moderating shops.
class ManageShopsScreen extends ConsumerWidget {
  /// Creates [ManageShopsScreen].
  const ManageShopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(adminShopsProvider);

    return AdminShellScaffold(
      title: AppStrings.screenTitleManageShops,
      currentIndex: 1,
      body: shopsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Text(
              'Failed to load shops: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (shops) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminShopsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.lg),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _SectionHeader(
                  title: AppStrings.labelPendingApprovals,
                  count: shops.where((shop) => shop.isPending).length,
                ),
                const SizedBox(height: AppSizes.md),
                ..._buildShopCards(
                  context,
                  ref,
                  shops.where((shop) => shop.isPending).toList(),
                  emptyMessage: 'No shops waiting for approval',
                  showApprovalActions: true,
                ),
                const SizedBox(height: AppSizes.xl),
                _SectionHeader(
                  title: AppStrings.labelAllShops,
                  count: shops.length,
                ),
                const SizedBox(height: AppSizes.md),
                ..._buildShopCards(
                  context,
                  ref,
                  shops,
                  emptyMessage: AppStrings.messageNoData,
                  showApprovalActions: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildShopCards(
    BuildContext context,
    WidgetRef ref,
    List<AdminShopSummary> shops, {
    required String emptyMessage,
    required bool showApprovalActions,
  }) {
    if (shops.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
          child: Center(
            child: Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ),
      ];
    }

    return shops
        .map(
          (shop) => Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: _ShopCard(
              shop: shop,
              showApprovalActions: showApprovalActions,
              onApprove: () async {
                await updateShopModeration(
                  ref,
                  shopId: shop.id,
                  isApproved: true,
                  isOpen: true,
                );
                ref.invalidate(adminShopsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(AppStrings.messageShopApproved)),
                  );
                }
              },
              onReject: () async {
                await updateShopModeration(
                  ref,
                  shopId: shop.id,
                  isApproved: false,
                  isOpen: false,
                  moderationState: 'rejected',
                );
                ref.invalidate(adminShopsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(AppStrings.messageShopRejected)),
                  );
                }
              },
              onToggleOpen: () async {
                await updateShopModeration(
                  ref,
                  shopId: shop.id,
                  isApproved: true,
                  isOpen: !shop.isOpen,
                  moderationState: shop.isRejected ? 'rejected' : null,
                );
                ref.invalidate(adminShopsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        shop.isOpen ? 'Shop deactivated' : 'Shop reactivated',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        )
        .toList();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: AppSizes.sm),
        Chip(
          label: Text(count.toString()),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.showApprovalActions,
    required this.onApprove,
    required this.onReject,
    required this.onToggleOpen,
  });

  final AdminShopSummary shop;
  final bool showApprovalActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onToggleOpen;

  @override
  Widget build(BuildContext context) {
    final statusLabel = shop.isRejected
        ? AppStrings.labelShopStatusRejected
        : shop.isApproved
            ? AppStrings.labelShopStatusApproved
            : AppStrings.labelShopStatusPending;

    return Card(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop.ownerName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(statusLabel),
                  backgroundColor: shop.isApproved
                      ? Colors.green.withValues(alpha: 0.12)
                      : shop.isRejected
                          ? Colors.red.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                _InfoChip(label: shop.category),
                _InfoChip(label: shop.isOpen ? 'Open' : 'Closed'),
                _InfoChip(label: '${shop.rating.toStringAsFixed(1)} ★'),
                _InfoChip(label: '${shop.totalReviews} reviews'),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              shop.address,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.lg),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                if (showApprovalActions && !shop.isApproved)
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text(AppStrings.labelApproveShop),
                  ),
                if (showApprovalActions && !shop.isRejected)
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text(AppStrings.labelRejectShop),
                  ),
                if (shop.isApproved)
                  OutlinedButton.icon(
                    onPressed: onToggleOpen,
                    icon: Icon(shop.isOpen
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline),
                    label: Text(
                      shop.isOpen
                          ? AppStrings.labelDeactivateShop
                          : 'Reactivate Shop',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }
}
