import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/order_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/navigation/customer_bottom_nav.dart';
import '../../widgets/order/order_card.dart';

/// Displays the authenticated customer's order history.
class OrderHistoryScreen extends ConsumerWidget {
  /// Creates an [OrderHistoryScreen].
  const OrderHistoryScreen({super.key});

  void _handleReorder(BuildContext context, WidgetRef ref, OrderEntity order) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final result = cartNotifier.addOrderItems(order);

    switch (result) {
      case CartActionResult.added:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Items added to cart.'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () => context.go(Routes.customerCart),
            ),
          ),
        );
      case CartActionResult.differentShop:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Your cart contains items from another shop.',
            ),
            action: SnackBarAction(
              label: 'Replace Cart',
              onPressed: () {
                cartNotifier.clearCart();
                final retry = cartNotifier.addOrderItems(order);
                if (retry == CartActionResult.added) {
                  context.go(Routes.customerCart);
                }
              },
            ),
          ),
        );
      case CartActionResult.unavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No reorderable items in this order.')),
        );
      case CartActionResult.outOfStock:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Some items are unavailable right now.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text(AppStrings.screenTitleOrderHistory),
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 1),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load user: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(authStateProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Sign in to view your orders.'));
          }

          final ordersAsync = ref.watch(customerOrdersProvider(user.uid));

          return ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load orders: $error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.md),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(customerOrdersProvider(user.uid)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        side: BorderSide(color: AppColors.divider),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.xl),
                        child: Text(
                          AppStrings.labelNoOrders,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(customerOrdersProvider(user.uid));
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(
                      order: order,
                      onReorder: () => _handleReorder(context, ref, order),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}