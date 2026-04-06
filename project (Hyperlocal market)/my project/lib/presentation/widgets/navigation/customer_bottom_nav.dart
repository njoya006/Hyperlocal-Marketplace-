import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../router/app_router.dart';

/// Shared bottom navigation for customer-facing primary screens.
class CustomerBottomNav extends StatelessWidget {
  const CustomerBottomNav({
    required this.currentIndex,
    super.key,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 72,
      selectedIndex: currentIndex,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onDestinationSelected: (index) {
        final target = switch (index) {
          0 => Routes.customerHome,
          1 => Routes.customerOrders,
          2 => Routes.customerCart,
          3 => Routes.customerProfile,
          _ => Routes.customerHome,
        };

        if (target != GoRouterState.of(context).matchedLocation) {
          context.go(target);
        }
      },
    );
  }
}