import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/cart_provider.dart';
import '../../providers/shop_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/map/mapbox_widget.dart';
import '../../widgets/navigation/customer_bottom_nav.dart';

/// Customer home screen with Mapbox map and shop discovery.
///
/// Features:
/// - Full-screen Mapbox map showing nearby shops
/// - Floating radius selector (5km, 10km, 20km)
/// - Floating refresh button
/// - Top app bar with search and profile icons
/// - Shop count badge
class CustomerHomeScreen extends ConsumerWidget {
  /// Creates a new [CustomerHomeScreen].
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final currentRadius = ref.watch(shopRadiusProvider);
    final nearbyShopsAsync = ref.watch(nearbyShopsProvider);
    final loadingShops = nearbyShopsAsync.isLoading && !nearbyShopsAsync.hasValue;
    final shopCountLabel = nearbyShopsAsync.maybeWhen(
      data: (shops) => '${shops.length} shops nearby',
      orElse: () => null,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: _buildAppBar(context),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!cartState.isEmpty)
            _StickyMiniCartBar(
              itemCount: cartState.items.length,
              total: cartState.total,
              onCartTap: () => context.go(Routes.customerCart),
              onCheckoutTap: () => context.go(Routes.customerCheckout),
            ),
          const CustomerBottomNav(currentIndex: 0),
        ],
      ),
      body: Stack(
        children: [
          // MapboxWidget with integrated shop cards (60/40 split)
          const MapboxWidget(),

          // Radius selector at top-left
          Positioned(
            top: 100,
            left: AppSizes.lg,
            right: AppSizes.lg,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRadiusChip(
                    context,
                    ref,
                    label: '5 km',
                    value: 5.0,
                    isSelected: currentRadius == 5.0,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  _buildRadiusChip(
                    context,
                    ref,
                    label: '10 km',
                    value: 10.0,
                    isSelected: currentRadius == 10.0,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  _buildRadiusChip(
                    context,
                    ref,
                    label: '20 km',
                    value: 20.0,
                    isSelected: currentRadius == 20.0,
                  ),
                ],
              ),
            ),
          ),

          // Refresh button (bottom-right)
          Positioned(
            bottom: AppSizes.xl + 80,
            right: AppSizes.lg,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'customer_refresh_fab',
                  onPressed: () {
                    ref.invalidate(nearbyShopsProvider);
                  },
                  backgroundColor: AppColors.primary,
                  child: const Icon(
                    Icons.refresh_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                FloatingActionButton.small(
                  heroTag: 'customer_cart_fab',
                  onPressed: () => context.go(Routes.customerCart),
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          if (nearbyShopsAsync.hasError)
            Positioned(
              left: AppSizes.lg,
              right: AppSizes.lg,
              bottom: AppSizes.xl + 172,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  side: BorderSide(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_outlined, color: AppColors.textSecondary),
                      const SizedBox(width: AppSizes.sm),
                      const Expanded(
                        child: Text('Could not refresh nearby shops.'),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(nearbyShopsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (loadingShops)
            Positioned(
              left: AppSizes.lg,
              right: AppSizes.lg,
              bottom: AppSizes.xl + 172,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  side: BorderSide(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Refreshing nearby shops...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Container(
                        height: 8,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (shopCountLabel != null)
            Positioned(
              left: AppSizes.lg,
              bottom: AppSizes.xl + 132,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  child: Text(
                    shopCountLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build the app bar with search and profile icons.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Nearby Shops'),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined),
          onPressed: () {
            context.go(Routes.customerOrders);
          },
          tooltip: AppStrings.screenTitleOrderHistory,
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            context.go(Routes.customerProfile);
          },
          tooltip: 'Profile',
        ),
      ],
    );
  }

  /// Build a single radius selector chip.
  Widget _buildRadiusChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required double value,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            ref.read(shopRadiusProvider.notifier).state = value;
          },
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sticky mini-cart bar displayed above bottom navigation.
class _StickyMiniCartBar extends StatelessWidget {
  /// Creates a [_StickyMiniCartBar].
  const _StickyMiniCartBar({
    required this.itemCount,
    required this.total,
    required this.onCartTap,
    required this.onCheckoutTap,
  });

  /// Number of items in the cart.
  final int itemCount;

  /// Total cart price.
  final double total;

  /// Callback when cart button is tapped.
  final VoidCallback onCartTap;

  /// Callback when checkout button is tapped.
  final VoidCallback onCheckoutTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        child: Row(
          children: [
            // Cart icon with badge
            Stack(
              children: [
                const Icon(
                  Icons.shopping_basket_outlined,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
                if (itemCount > 0)
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          itemCount > 9 ? '9+' : '$itemCount',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSizes.md),
            // Item count and total
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$itemCount item${itemCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    CurrencyFormatter.formatXAF(total),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.md),
            // Action buttons
            TextButton(
              onPressed: onCartTap,
              child: const Text('Cart'),
            ),
            const SizedBox(width: AppSizes.xs),
            ElevatedButton(
              onPressed: onCheckoutTap,
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
