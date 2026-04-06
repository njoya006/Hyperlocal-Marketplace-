import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/order_entity.dart';
import '../../providers/order_provider.dart';

/// Displays live status updates for a specific order.
class OrderTrackingScreen extends ConsumerWidget {
  /// Creates an [OrderTrackingScreen].
  const OrderTrackingScreen({
    required this.orderId,
    super.key,
  });

  /// Order id from route path.
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingAsync = ref.watch(trackingProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text(AppStrings.screenTitleOrderTracking),
      ),
      body: trackingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Text(
              'Failed to track this order: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (order) {
          final steps = _buildSteps(order.status);
          final currentStep = _stepIndex(order.status);
          final eta = _etaText(order.status, order.createdAt);

          return ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  side: BorderSide(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, order.id.length.clamp(0, 8))}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xxs),
                      Text('Total: \$${order.total.toStringAsFixed(2)}'),
                      const SizedBox(height: AppSizes.xxs),
                      Text('Delivery: ${order.deliveryAddress}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  side: BorderSide(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule, color: AppColors.primary),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          eta,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  side: BorderSide(color: AppColors.divider),
                ),
                child: Stepper(
                  currentStep: currentStep,
                  controlsBuilder: (_, __) => const SizedBox.shrink(),
                  steps: steps,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Step> _buildSteps(OrderStatus status) {
    final statuses = <OrderStatus>[
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    final index = _stepIndex(status);

    return List<Step>.generate(statuses.length, (i) {
      final stepStatus = statuses[i];
      final isComplete = i < index;
      final isActive = i == index;

      return Step(
        title: Text(_statusLabel(stepStatus)),
        content: Text(_statusDescription(stepStatus)),
        isActive: isActive,
        state: isComplete ? StepState.complete : StepState.indexed,
      );
    });
  }

  int _stepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return 0;
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

  String _statusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'We have received your order and are waiting for confirmation.';
      case OrderStatus.confirmed:
        return 'The shop accepted your order and will prepare it shortly.';
      case OrderStatus.preparing:
        return 'Your order is currently being prepared.';
      case OrderStatus.outForDelivery:
        return 'Your rider is on the way to your location.';
      case OrderStatus.delivered:
        return 'Order delivered successfully.';
      case OrderStatus.cancelled:
        return 'This order was cancelled.';
    }
  }

  String _etaText(OrderStatus status, DateTime createdAt) {
    if (status == OrderStatus.delivered) {
      return 'Delivered';
    }
    if (status == OrderStatus.cancelled) {
      return 'This order was cancelled.';
    }

    final eta = createdAt.add(const Duration(minutes: 45));
    final hour = eta.hour.toString().padLeft(2, '0');
    final minute = eta.minute.toString().padLeft(2, '0');
    return 'Estimated delivery around $hour:$minute';
  }
}