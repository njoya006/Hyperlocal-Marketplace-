import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/cart_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/navigation/customer_bottom_nav.dart';

/// Displays the current shopping cart.
class CartScreen extends ConsumerStatefulWidget {
  /// Creates a [CartScreen].
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  void _showCartInfo(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleIncrementItem(String productId) {
    final cartState = ref.read(cartProvider);
    final itemIndex =
        cartState.items.indexWhere((item) => item.product.id == productId);
    if (itemIndex < 0) {
      return;
    }

    final item = cartState.items[itemIndex];
    if (item.quantity >= item.product.stockQuantity) {
      _showCartInfo('Maximum stock reached for ${item.product.name}.');
      return;
    }

    ref.read(cartProvider.notifier).incrementItem(productId);
  }

  void _removeItemWithUndo(String productId) {
    final cartState = ref.read(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final removedItemIndex =
        cartState.items.indexWhere((item) => item.product.id == productId);
    if (removedItemIndex < 0) {
      return;
    }
    final removedItem = cartState.items[removedItemIndex];

    cartNotifier.removeItem(productId);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${removedItem.product.name} removed from cart.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref
                  .read(cartProvider.notifier)
                  .addItem(removedItem.product, quantity: removedItem.quantity);
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text(AppStrings.screenTitleCart),
        actions: [
          if (!cartState.isEmpty)
            IconButton(
              onPressed: cartNotifier.clearCart,
              icon: const Icon(Icons.delete_outline),
              tooltip: AppStrings.buttonClearCart,
            ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 2),
      body: cartState.isEmpty
          ? _EmptyCartView(onBrowseShops: () => context.go(Routes.customerHome))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    itemCount: cartState.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return Dismissible(
                        key: ValueKey(item.product.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) => _removeItemWithUndo(item.product.id),
                        child: Card(
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: item.product.imageUrl == null || item.product.imageUrl!.isEmpty
                                          ? Container(
                                              color: AppColors.divider,
                                              child: const Icon(Icons.inventory_2_outlined),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: item.product.imageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(
                                                color: AppColors.divider,
                                              ),
                                              errorWidget: (_, __, ___) => Container(
                                                color: AppColors.divider,
                                                child: const Icon(Icons.inventory_2_outlined),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: AppSizes.xxs),
                                        Text(
                                          CurrencyFormatter.formatXAF(item.product.price),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: AppSizes.sm),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () => cartNotifier.decrementItem(item.product.id),
                                              icon: const Icon(Icons.remove_circle_outline),
                                            ),
                                            Text(
                                              '${item.quantity}',
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            IconButton(
                                              onPressed: () => _handleIncrementItem(item.product.id),
                                              icon: const Icon(Icons.add_circle_outline),
                                            ),
                                            const Spacer(),
                                            TextButton.icon(
                                              onPressed: () => _removeItemWithUndo(item.product.id),
                                              icon: const Icon(Icons.delete_outline),
                                              label: const Text(AppStrings.labelRemoveItem),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                    },
                  ),
                ),
                _CartSummary(
                  total: cartState.total,
                  onCheckout: () => context.go(Routes.customerCheckout),
                ),
              ],
            ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView({required this.onBrowseShops});

  final VoidCallback onBrowseShops;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.textSecondary),
            const SizedBox(height: AppSizes.md),
            Text(
              AppStrings.labelCartEmpty,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'Add products from a nearby shop to begin your order.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: onBrowseShops,
              child: const Text('Browse Shops'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.total,
    required this.onCheckout,
  });

  final double total;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(AppStrings.labelGrandTotal),
                Text(
                  CurrencyFormatter.formatXAF(total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            ElevatedButton(
              onPressed: onCheckout,
              child: const Text(AppStrings.buttonCheckout),
            ),
          ],
        ),
      ),
    );
  }
}