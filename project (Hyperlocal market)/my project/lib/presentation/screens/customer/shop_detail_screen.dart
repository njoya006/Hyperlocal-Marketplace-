import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/shop_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/shop/product_card.dart';

/// Displays shop details and products for customers.
class ShopDetailScreen extends ConsumerWidget {
  /// Creates a [ShopDetailScreen].
  const ShopDetailScreen({
    required this.shopId,
    super.key,
  });

  /// Shop id from route path parameter.
  final String shopId;

  void _showCartMessage(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel == null || action == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                onPressed: action,
              ),
      ),
    );
  }

  void _onAddToCart(
    BuildContext context,
    WidgetRef ref,
    ProductEntity product,
  ) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final result = cartNotifier.addItem(product);

    switch (result) {
      case CartActionResult.added:
        _showCartMessage(
          context,
          '${product.name} added to cart',
          actionLabel: 'View Cart',
          action: () => context.go(Routes.customerCart),
        );
      case CartActionResult.differentShop:
        _showCartMessage(
          context,
          'Your cart already has items from another shop.',
          actionLabel: 'Replace Cart',
          action: () {
            cartNotifier.clearCart();
            final retryResult = cartNotifier.addItem(product);
            if (retryResult == CartActionResult.added) {
              _showCartMessage(
                context,
                '${product.name} added to cart',
                actionLabel: 'View Cart',
                action: () => context.go(Routes.customerCart),
              );
            }
          },
        );
      case CartActionResult.unavailable:
        _showCartMessage(context, 'This product is not available right now.');
      case CartActionResult.outOfStock:
        _showCartMessage(context, 'This product is out of stock.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final shopAsync = ref.watch(watchShopProvider(shopId));
    final productsAsync = ref.watch(shopProductsProvider(shopId));
    final userLocationAsync = ref.watch(singleLocationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text(AppStrings.screenTitleShopDetail),
        actions: [
          IconButton(
            onPressed: () => context.go(Routes.customerCart),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      bottomNavigationBar: cartState.isEmpty
          ? null
          : _StickyMiniCartBar(
              itemCount: cartState.items.length,
              total: cartState.total,
              onCartTap: () => context.go(Routes.customerCart),
              onCheckoutTap: () => context.go(Routes.customerCheckout),
            ),
      body: shopAsync.when(
        loading: () => const _ShopDetailLoadingView(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load shop: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(watchShopProvider(shopId));
                    ref.invalidate(shopProductsProvider(shopId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (shop) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(watchShopProvider(shopId));
              ref.invalidate(shopProductsProvider(shopId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: shop.imageUrl == null || shop.imageUrl!.isEmpty
                      ? Container(
                          color: AppColors.divider,
                          child: const Center(
                            child: Icon(Icons.storefront_outlined, size: 56),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: shop.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.divider,
                            child: const Center(
                              child: Icon(Icons.storefront_outlined, size: 56),
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      side: BorderSide(color: AppColors.divider),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber),
                              const SizedBox(width: AppSizes.xxs),
                              Text(
                                '${shop.rating.toStringAsFixed(1)} (${shop.totalReviews})',
                              ),
                              const SizedBox(width: AppSizes.lg),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.sm,
                                  vertical: AppSizes.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: shop.isOpen
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusSm),
                                ),
                                child: Text(shop.isOpen ? 'Open' : 'Closed'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Text(shop.description),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            '${AppStrings.labelShopCategory}: ${shop.category.name}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSizes.xxs),
                          userLocationAsync.when(
                            data: (location) => Text(
                              'Distance: ${shop.distanceTo(location.latitude, location.longitude).toStringAsFixed(2)} km',
                            ),
                            loading: () => const Text('Distance: ...'),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  child: Text(
                    AppStrings.labelProducts,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (!cartState.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg,
                      AppSizes.sm,
                      AppSizes.lg,
                      0,
                    ),
                    child: Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.xs,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.shopping_basket_outlined, size: 18),
                          label: Text('${cartState.items.length} items in cart'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.payments_outlined, size: 18),
                          label: Text('${CurrencyFormatter.formatXAF(cartState.total)} total'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.shopping_cart_checkout_outlined, size: 18),
                          label: const Text('Open Cart'),
                          onPressed: () => context.go(Routes.customerCart),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSizes.sm),
                productsAsync.when(
                  loading: () => const _ProductsLoadingGrid(),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Text('Failed to load products: $error'),
                  ),
                  data: (products) {
                    if (products.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSizes.lg),
                        child: Text(AppStrings.labelNoProducts),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.lg,
                        0,
                        AppSizes.lg,
                        AppSizes.lg,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        mainAxisSpacing: AppSizes.md,
                        crossAxisSpacing: AppSizes.md,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          key: ValueKey(product.id),
                          product: product,
                          onAddToCart: () => _onAddToCart(context, ref, product),
                        );
                      },
                    );
                  },
                ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StickyMiniCartBar extends StatelessWidget {
  const _StickyMiniCartBar({
    required this.itemCount,
    required this.total,
    required this.onCartTap,
    required this.onCheckoutTap,
  });

  final int itemCount;
  final double total;
  final VoidCallback onCartTap;
  final VoidCallback onCheckoutTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.divider.withValues(alpha: 0.75)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppSizes.sm),
                child: Icon(Icons.shopping_basket_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$itemCount item${itemCount == 1 ? '' : 's'} in cart',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total ${CurrencyFormatter.formatXAF(total)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onCartTap,
              child: const Text('Cart'),
            ),
            const SizedBox(width: AppSizes.xs),
            FilledButton(
              onPressed: onCheckoutTap,
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopDetailLoadingView extends StatelessWidget {
  const _ShopDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonBox(height: 200),
          Padding(
            padding: EdgeInsets.all(AppSizes.lg),
            child: _SkeletonBox(height: 180),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: _SkeletonBox(height: 24, width: 130),
          ),
          _ProductsLoadingGrid(),
        ],
      ),
    );
  }
}

class _ProductsLoadingGrid extends StatelessWidget {
  const _ProductsLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.md,
        AppSizes.lg,
        AppSizes.lg,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        mainAxisSpacing: AppSizes.md,
        crossAxisSpacing: AppSizes.md,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => const _SkeletonBox(),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    this.height = 220,
    this.width,
  });

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
          ],
        ),
      ),
    );
  }
}
