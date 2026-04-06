import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../screens/customer/order_history_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/shop_owner/owner_orders_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/customer_profile_screen.dart';
import '../screens/customer/home_screen.dart';
import '../screens/customer/shop_detail_screen.dart';
import '../screens/customer/order_tracking_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../screens/admin/manage_shops_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/dev/dev_role_switch_screen.dart';
import '../screens/shop_owner/awaiting_approval_screen.dart';
import '../screens/shop_owner/create_shop_screen.dart';
import '../screens/shop_owner/owner_dashboard_screen.dart';
import '../screens/shop_owner/owner_products_screen.dart';
import '../screens/shop_owner/owner_profile_screen.dart';

// ============================================================================
// ROUTE PATHS
// ============================================================================

/// Route paths for the entire app.
abstract class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';

  // Customer prefix and routes
  static const String customer = '/customer';
  static const String customerHome = '/customer/home';
  static const String shop = '/shop/';
  static const String customerShop = '/customer/shop/:shopId';
  static const String customerCart = '/customer/cart';
  static const String customerCheckout = '/customer/checkout';
  static const String customerOrders = '/customer/orders';
  static const String customerTrack = '/customer/track/:orderId';
  static const String customerProfile = '/customer/profile';

  // Shop Owner routes
  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerCreateShop = '/owner/create-shop';
  static const String ownerAwaitingApproval = '/owner/awaiting-approval';
  static const String ownerProducts = '/owner/products';
  static const String ownerOrders = '/owner/orders';
  static const String ownerProfile = '/owner/profile';

  // Admin routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminShops = '/admin/shops';
  static const String adminUsers = '/admin/users';
  static const String adminReports = '/admin/reports';

  // Developer tools
  static const String devRoleSwitch = '/dev/role-switch';
}

// ============================================================================
// ROUTE GUARDS & REFRESH
// ============================================================================

/// Watches authentication state for route changes.
///
/// This is used by go_router to automatically refresh routes when
/// the authentication state changes (login, logout, role change).
class AuthRefresh extends ChangeNotifier {
  late final Ref _ref;

  void initialize(Ref ref) {
    _ref = ref;
    // Listen for auth state changes
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

/// Global provider for auth refresh listener.
final authRefreshProvider = ChangeNotifierProvider((ref) {
  final refresh = AuthRefresh();
  refresh.initialize(ref);
  return refresh;
});

// ============================================================================
// GO_ROUTER SETUP
// ============================================================================

/// Provides the configured GoRouter for the app.
///
/// Handles:
/// - Route definitions for all screens
/// - Authentication redirect (unauthenticated → /login)
/// - Role-based redirect (after login → role-specific home)
/// - Error handling for missing routes
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = ref.watch(authRefreshProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      try {
        // Get current auth state
        final authState = ref.read(authStateProvider);
        final isLoggedIn = authState.maybeWhen(
          data: (user) => user != null,
          orElse: () => false,
        );

        // If trying to access a public route, allow
        if (state.matchedLocation == Routes.splash ||
            state.matchedLocation == Routes.login ||
            state.matchedLocation == Routes.register ||
            (kDebugMode && state.matchedLocation == Routes.devRoleSwitch)) {
          // If logged in and on login/register, redirect to appropriate home
          if (isLoggedIn &&
              state.matchedLocation != Routes.devRoleSwitch) {
            return _getRoleBasedRoute(authState);
          }
          return null;
        }

        // If not logged in and trying to access protected route, go to login
        if (!isLoggedIn) {
          return Routes.login;
        }

        // If logged in, check role-based routes
        final isCustomerRoute = state.matchedLocation.startsWith('/customer');
        final isOwnerRoute = state.matchedLocation.startsWith('/owner');
        final isAdminRoute = state.matchedLocation.startsWith('/admin');

        final userRole = authState.maybeWhen(
          data: (user) => user?.role,
          orElse: () => null,
        );

        // Validate route matches user role
        if (isCustomerRoute && userRole != UserRole.customer) {
          return _getRoleBasedRoute(authState);
        }
        if (isOwnerRoute && userRole != UserRole.shopOwner) {
          return _getRoleBasedRoute(authState);
        }
        if (isAdminRoute && userRole != UserRole.admin) {
          return _getRoleBasedRoute(authState);
        }

        return null;
      } catch (e) {
        // Silently handle ref read errors during provider updates
        // The next redirect call will succeed after provider rebuilds
        debugPrint('[ROUTER] Skipping redirect during provider update: $e');
        return null;
      }
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer Routes
      GoRoute(
        path: Routes.customerHome,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const CustomerHomeScreen()),
      ),
      GoRoute(
        path: Routes.customerShop,
        pageBuilder: (context, state) {
          final shopId = state.pathParameters['shopId'] ?? '';
          return _fadeTransitionPage(state, ShopDetailScreen(shopId: shopId));
        },
      ),
      GoRoute(
        path: Routes.customerCart,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const CartScreen()),
      ),
      GoRoute(
        path: Routes.customerCheckout,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const CheckoutScreen()),
      ),
      GoRoute(
        path: Routes.customerOrders,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const OrderHistoryScreen()),
      ),
      GoRoute(
        path: Routes.customerTrack,
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return _fadeTransitionPage(state, OrderTrackingScreen(orderId: orderId));
        },
      ),
      GoRoute(
        path: Routes.customerProfile,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const CustomerProfileScreen()),
      ),

      // Shop Owner Routes
      GoRoute(
        path: Routes.ownerDashboard,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const OwnerDashboardScreen()),
      ),
      GoRoute(
        path: Routes.ownerCreateShop,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const CreateShopScreen()),
      ),
      GoRoute(
        path: Routes.ownerAwaitingApproval,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const AwaitingApprovalScreen()),
      ),
      GoRoute(
        path: Routes.ownerProducts,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const OwnerProductsScreen()),
      ),
      GoRoute(
        path: Routes.ownerOrders,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const OwnerOrdersScreen()),
      ),
      GoRoute(
        path: Routes.ownerProfile,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const OwnerProfileScreen()),
      ),

      // Admin Routes
      GoRoute(
        path: Routes.adminDashboard,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const AdminDashboardScreen()),
      ),
      GoRoute(
        path: Routes.adminShops,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const ManageShopsScreen()),
      ),
      GoRoute(
        path: Routes.adminUsers,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const ManageUsersScreen()),
      ),
      GoRoute(
        path: Routes.adminReports,
        pageBuilder: (context, state) =>
            _fadeTransitionPage(state, const AdminReportsScreen()),
      ),
      if (kDebugMode)
        GoRoute(
          path: Routes.devRoleSwitch,
          builder: (context, state) => const DevRoleSwitchScreen(),
        ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: _ErrorBody(),
    ),
  );
});

/// Root navigator key used for notification tap routing.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _fadeTransitionPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(
        begin: const Offset(0.015, 0),
        end: Offset.zero,
      ).animate(fade);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: pageChild,
        ),
      );
    },
  );
}

/// Gets the role-based home route for a user.
String _getRoleBasedRoute(AsyncValue<UserEntity?> authState) {
  return authState.maybeWhen(
    data: (user) {
      if (user == null) return Routes.login;
      switch (user.role) {
        case UserRole.customer:
          return Routes.customerHome;
        case UserRole.shopOwner:
          return Routes.ownerDashboard;
        case UserRole.admin:
          return Routes.adminDashboard;
      }
    },
    orElse: () => Routes.login,
  );
}

/// Error body for unmatched routes.
class _ErrorBody extends StatelessWidget {
  const _ErrorBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Route not found'),
    );
  }
}
