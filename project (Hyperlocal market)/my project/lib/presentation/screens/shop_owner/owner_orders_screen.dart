import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/order_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/shop_provider.dart';
import 'owner_shell_scaffold.dart';

/// Live order management screen for shop owners.
class OwnerOrdersScreen extends ConsumerWidget {
  /// Creates an [OwnerOrdersScreen].
  const OwnerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return OwnerShellScaffold(
      title: AppStrings.screenTitleOrdersToFulfill,
      currentIndex: 1,
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text(AppStrings.errorOwnerAccountLoad)),
        data: (user) {
          if (user == null) {
            return const Center(
                child: Text(AppStrings.messageSignInToContinue));
          }

          final shopAsync = ref.watch(ownerShopProvider(user.uid));

          return shopAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                const Center(child: Text(AppStrings.errorOwnerShopLoad)),
            data: (shop) {
              if (shop == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.lg),
                    child: Text('Create a shop first to manage orders.'),
                  ),
                );
              }

              final ordersAsync = ref.watch(ownerOrdersProvider(shop.id));

              return ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    const Center(child: Text(AppStrings.errorOwnerOrdersLoad)),
                data: (orders) {
                  final pendingCount = orders
                      .where((order) => order.status == OrderStatus.pending)
                      .length;
                  final activeCount = orders
                      .where((order) =>
                          order.status != OrderStatus.delivered &&
                          order.status != OrderStatus.cancelled)
                      .length;

                  if (orders.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            side: const BorderSide(color: AppColors.divider),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  child: const Icon(Icons.inbox_outlined,
                                      color: AppColors.primary, size: 30),
                                ),
                                const SizedBox(height: AppSizes.md),
                                Text(
                                  'No incoming orders yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSizes.xxs),
                                Text(
                                  'New orders from customers will appear here in real time.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(ownerOrdersProvider(shop.id));
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      children: [
                        _OrdersHeader(
                          totalCount: orders.length,
                          pendingCount: pendingCount,
                          activeCount: activeCount,
                        ),
                        const SizedBox(height: AppSizes.lg),
                        ...orders.map(
                          (order) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.md),
                            child: _OwnerOrderCard(order: order),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _OwnerOrderCard extends ConsumerWidget {
  const _OwnerOrderCard({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = _actionsFor(order.status);
    final createdAt = order.createdAt;
    final createdLabel =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0.6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: _StatusBadge.borderColor(order.status),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.customerName.isNotEmpty
                        ? order.customerName
                        : order.customerId,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: AppSizes.xxs),
            Text(
                '${order.items.length} item(s) • ${CurrencyFormatter.formatXAF(order.total)}'),
            const SizedBox(height: AppSizes.xxs),
            Text(
              'Placed $createdLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Order #${order.id.isEmpty ? 'pending' : order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: actions
                  .map(
                  (action) => action.nextStatus == OrderStatus.cancelled
                    ? OutlinedButton.icon(
                      onPressed: action.enabled
                        ? () async {
                          final update = ref
                            .read(updateOrderStatusUsecaseProvider);
                          await update(
                            orderId: order.id,
                            status: action.nextStatus);
                          ref.invalidate(
                            ownerOrdersProvider(order.shopId));
                          }
                        : null,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(action.label),
                      )
                    : FilledButton.icon(
                      onPressed: action.enabled
                          ? () async {
                              final update =
                                  ref.read(updateOrderStatusUsecaseProvider);
                              await update(
                                  orderId: order.id, status: action.nextStatus);
                              ref.invalidate(ownerOrdersProvider(order.shopId));
                            }
                          : null,
                      icon: const Icon(Icons.playlist_add_check_circle_outlined,
                          size: 18),
                      label: Text(action.label),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<_OrderAction> _actionsFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const [
          _OrderAction(label: 'Confirm', nextStatus: OrderStatus.confirmed),
          _OrderAction(label: 'Cancel', nextStatus: OrderStatus.cancelled),
        ];
      case OrderStatus.confirmed:
        return const [
          _OrderAction(label: 'Preparing', nextStatus: OrderStatus.preparing),
          _OrderAction(label: 'Cancel', nextStatus: OrderStatus.cancelled),
        ];
      case OrderStatus.preparing:
        return const [
          _OrderAction(
              label: 'Out for Delivery',
              nextStatus: OrderStatus.outForDelivery),
        ];
      case OrderStatus.outForDelivery:
        return const [
          _OrderAction(label: 'Delivered', nextStatus: OrderStatus.delivered),
        ];
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return const [];
    }
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.totalCount,
    required this.pendingCount,
    required this.activeCount,
  });

  final int totalCount;
  final int pendingCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Wrap(
        spacing: AppSizes.sm,
        runSpacing: AppSizes.sm,
        children: [
          _HeaderChip(label: 'Total', value: '$totalCount'),
          _HeaderChip(label: 'Pending', value: '$pendingCount'),
          _HeaderChip(label: 'Active', value: '$activeCount'),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  Color _color(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  static Color borderColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.withValues(alpha: 0.35);
      case OrderStatus.confirmed:
        return Colors.blue.withValues(alpha: 0.35);
      case OrderStatus.preparing:
        return Colors.purple.withValues(alpha: 0.3);
      case OrderStatus.outForDelivery:
        return Colors.teal.withValues(alpha: 0.3);
      case OrderStatus.delivered:
        return Colors.green.withValues(alpha: 0.3);
      case OrderStatus.cancelled:
        return Colors.red.withValues(alpha: 0.28);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 4),
      decoration: BoxDecoration(
        color: _color(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Text(
        status.name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _color(status),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _OrderAction {
  const _OrderAction({
    required this.label,
    required this.nextStatus,
  });

  final String label;
  final OrderStatus nextStatus;

  bool get enabled => true;
}
