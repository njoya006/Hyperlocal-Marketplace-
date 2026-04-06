import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../router/app_router.dart';

/// Shared scaffold for admin screens with consistent navigation and visual style.
class AdminShellScaffold extends StatelessWidget {
  /// Creates [AdminShellScaffold].
  const AdminShellScaffold({
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
      backgroundColor: const Color(0xFFFAFBFF),
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
              'Admin Control Center',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
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
                Color(0xFF0E1B4D),
                Color(0xFF223A8F),
                Color(0xFF2B5BB3),
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
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                    Colors.indigo.withValues(alpha: 0.03),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigo.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.06),
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
          indicatorColor: Colors.indigo.withValues(alpha: 0.16),
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
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Shops',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Users',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: 'Reports',
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
        context.go(Routes.adminDashboard);
        break;
      case 1:
        context.go(Routes.adminShops);
        break;
      case 2:
        context.go(Routes.adminUsers);
        break;
      case 3:
        context.go(Routes.adminReports);
        break;
      default:
        break;
    }
  }
}
