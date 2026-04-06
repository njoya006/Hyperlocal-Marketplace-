import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../router/app_router.dart';

/// Shared scaffold for shop-owner account screens.
class OwnerShellScaffold extends StatelessWidget {
  /// Creates [OwnerShellScaffold].
  const OwnerShellScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.body,
    this.actions,
  });

  final String title;
  final int currentIndex;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        toolbarHeight: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              'Owner Workspace',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
            ),
          ],
        ),
        actions: actions,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06),
                    Colors.transparent,
                    AppColors.secondary.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -70,
            child: Container(
              height: 240,
              width: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.05),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: TweenAnimationBuilder<double>(
              key: ValueKey<int>(currentIndex),
              duration: const Duration(milliseconds: 320),
              tween: Tween<double>(begin: 0.96, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0, 1),
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: body,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 74,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.divider.withValues(alpha: 0.7)),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            backgroundColor: AppColors.surface,
            elevation: 2,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            onDestinationSelected: (index) => _onSelectTab(context, index),
          ),
        ),
      ),
    );
  }

  void _onSelectTab(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }
    switch (index) {
      case 0:
        context.go(Routes.ownerDashboard);
        break;
      case 1:
        context.go(Routes.ownerOrders);
        break;
      case 2:
        context.go(Routes.ownerProducts);
        break;
      case 3:
        context.go(Routes.ownerProfile);
        break;
      default:
        break;
    }
  }
}
