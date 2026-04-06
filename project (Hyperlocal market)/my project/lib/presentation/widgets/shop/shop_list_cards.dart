import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../router/app_router.dart';

/// Horizontal scrollable list of shop cards.
///
/// Displays nearby shops in a carousel-like layout. Tapping a card navigates
/// to the shop detail screen.
///
/// Features:
/// - Shop image with placeholder on load error  - Shop name, category badge
/// - Star rating and review count
/// - Distance with "km" label
/// - Open/closed status badge
/// - Tap to navigate to shop detail
class ShopListCards extends StatelessWidget {
  /// Creates a new [ShopListCards].
  const ShopListCards({
    required this.shops,
    required this.userLatitude,
    required this.userLongitude,
    super.key,
  });

  /// List of shops to display.
  final List<ShopEntity> shops;

  /// User's current latitude for distance calculation.
  final double userLatitude;

  /// User's current longitude for distance calculation.
  final double userLongitude;

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.md),
            child: _ShopCard(
              shop: shop,
              userLatitude: userLatitude,
              userLongitude: userLongitude,
            ),
          );
        },
      ),
    );
  }
}

/// Individual shop card widget.
class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.userLatitude,
    required this.userLongitude,
  });

  final ShopEntity shop;
  final double userLatitude;
  final double userLongitude;

  /// Calculate distance from user to shop.
  double _calculateDistance() {
    return shop.distanceTo(userLatitude, userLongitude);
  }

  /// Navigate to shop detail screen.
  void _navigateToShop(BuildContext context) {
    context.go('${Routes.customer}/shop/${shop.id}');
  }

  /// Capitalize first letter of a string.
  String _capitalizeString(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();
    final isOpen = shop.isOpen;

    return GestureDetector(
      onTap: () => _navigateToShop(context),
      child: SizedBox(
        width: 180,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop image or placeholder
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusMd),
                  ),
                  child: Stack(
                    children: [
                      // Image or placeholder
                      if (shop.imageUrl != null && shop.imageUrl!.isNotEmpty)
                        Image.network(
                          shop.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildImagePlaceholder(),
                        )
                      else
                        _buildImagePlaceholder(),
                      // Open/closed badge
                      Positioned(
                        top: AppSizes.sm,
                        right: AppSizes.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOpen ? 'Open' : 'Closed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Shop info
              Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shop name
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        _capitalizeString(shop.category.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Rating row
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${shop.rating.toStringAsFixed(1)} (${shop.totalReviews})',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Distance
                    Text(
                      '${distance.toStringAsFixed(1)} km away',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _navigateToShop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          minimumSize: const Size.fromHeight(30),
                        ),
                        child: const Text(AppStrings.buttonViewShop),
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

  /// Build image placeholder.
  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.store_outlined,
          size: 40,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
