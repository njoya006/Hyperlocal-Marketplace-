import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../router/app_router.dart';

/// Bottom sheet previewing shop information.
///
/// Displayed when user taps a shop marker. Shows:
/// - Shop image (if available)
/// - Shop name and category badge
/// - Open/closed status
/// - Star rating and review count
/// - Distance from user
/// - "View Shop" button to navigate to shop detail screen
class ShopPreviewBottomSheet extends StatelessWidget {
  /// Creates a new [ShopPreviewBottomSheet].
  const ShopPreviewBottomSheet({
    required this.shop,
    required this.userLat,
    required this.userLng,
    super.key,
  });

  /// The shop to display.
  final ShopEntity shop;

  /// User's current latitude for distance calculation.
  final double userLat;

  /// User's current longitude for distance calculation.
  final double userLng;

  @override
  Widget build(BuildContext context) {
    final distance = shop.distanceTo(userLat, userLng);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Shop image or placeholder
            if (shop.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Image.network(
                  shop.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                ),
              )
            else
              _buildImagePlaceholder(),

            const SizedBox(height: AppSizes.lg),

            // Shop name and status row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Row(
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm,
                              vertical: AppSizes.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Text(
                              _categoryLabel(shop.category),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm,
                              vertical: AppSizes.xs,
                            ),
                            decoration: BoxDecoration(
                              color: shop.isOpen
                                  ? Colors.green.withAlpha(25)
                                  : Colors.red.withAlpha(25),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusSm),
                            ),
                            child: Text(
                              shop.isOpen ? 'Open' : 'Closed',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                color: shop.isOpen ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.lg),

            // Rating and distance row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rating
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      '${shop.rating.toStringAsFixed(1)} (${shop.totalReviews})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // Distance
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      '${distance.toStringAsFixed(2)} km',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSizes.lg),

            // Description (truncated)
            Text(
              shop.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // View Shop button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.md,
                  ),
                ),
                onPressed: () {
                  context.go('${Routes.customer}${Routes.shop}${shop.id}');
                },
                child: Text(
                  'View Shop',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build image placeholder when no image available.
  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: const Center(
        child: Icon(
          Icons.store_outlined,
          size: 64,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Get display label for shop category.
  String _categoryLabel(ShopCategory category) {
    switch (category) {
      case ShopCategory.grocery:
        return '🛒 Grocery';
      case ShopCategory.pharmacy:
        return '🏥 Pharmacy';
      case ShopCategory.electronics:
        return '⚡ Electronics';
      case ShopCategory.food:
        return '🍔 Food';
      case ShopCategory.other:
        return '📦 Other';
    }
  }
}
