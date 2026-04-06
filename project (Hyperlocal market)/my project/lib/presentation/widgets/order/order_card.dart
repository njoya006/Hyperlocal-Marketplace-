import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/order_entity.dart';
import '../../router/app_router.dart';

/// Card widget for displaying a customer order.
class OrderCard extends StatelessWidget {
  /// Creates an [OrderCard].
  const OrderCard({
    required this.order,
    this.onReorder,
    super.key,
  });

  /// Order data rendered by the card.
  final OrderEntity order;

  /// Optional callback to reorder this order.
  final VoidCallback? onReorder;

  Color _statusColor(OrderStatus status) {
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

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppStrings.labelOrderPending;
      case OrderStatus.confirmed:
        return AppStrings.labelOrderConfirmed;
      case OrderStatus.preparing:
        return AppStrings.labelOrderPreparing;
      case OrderStatus.outForDelivery:
        return AppStrings.labelOrderOutForDelivery;
      case OrderStatus.delivered:
        return AppStrings.labelOrderDelivered;
      case OrderStatus.cancelled:
        return AppStrings.labelOrderCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = MaterialLocalizations.of(context)
      .formatMediumDate(order.createdAt);
    final previewLength = math.min(order.id.length, 8);
    final orderCode =
      previewLength == 0 ? 'N/A' : order.id.substring(0, previewLength);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #$orderCode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Text(
                    _statusLabel(order.status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _statusColor(order.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Customer: ${order.customerName.isNotEmpty ? order.customerName : order.customerId}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.xxs),
            Text(
              '${order.items.length} item(s)',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.xxs),
            Text(
              'Delivery: ${order.deliveryAddress}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.xxs),
            Text(
              formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Text(
                  CurrencyFormatter.formatXAF(order.total),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (onReorder != null)
                  TextButton.icon(
                    onPressed: onReorder,
                    icon: const Icon(Icons.replay),
                    label: const Text('Reorder'),
                  ),
                if (onReorder != null) const SizedBox(width: AppSizes.xs),
                TextButton(
                  onPressed: () => context.go('${Routes.customer}/track/${order.id}'),
                  child: const Text(AppStrings.buttonTrackOrder),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}