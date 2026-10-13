import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../screens/customers/customer_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/billing/billing_screen.dart';
import '../screens/billing/invoice_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/products/product_form_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/sales/sales_history_screen.dart';
import '../widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(authProvider, (previous, next) => refresh.refresh());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, routeState) {
      final auth = ref.read(authProvider);
      final location = routeState.matchedLocation;
      if (auth.status == AuthStatus.loading) {
        return location == '/login' ? null : '/login';
      }
      final isLogin = location == '/login';
      if (auth.status != AuthStatus.authenticated) {
        return isLogin ? null : '/login';
      }
      if (isLogin || location == '/') {
        return auth.user?.isAdmin == true ? '/dashboard' : '/billing';
      }
      final adminOnly =
          location == '/dashboard' ||
          location == '/reports' ||
          location == '/products/new' ||
          location.startsWith('/products/edit/');
      if (adminOnly && auth.user?.isAdmin != true) {
        return '/billing';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _transitionPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _transitionPage(
          state,
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(selectedPath: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                _transitionPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                _transitionPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/billing',
            pageBuilder: (context, state) =>
                _transitionPage(state, const BillingScreen()),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) =>
                _transitionPage(state, const ProductListScreen()),
          ),
          GoRoute(
            path: '/products/new',
            pageBuilder: (context, state) =>
                _transitionPage(state, const ProductFormScreen()),
          ),
          GoRoute(
            path: '/products/edit/:id',
            pageBuilder: (context, state) => _transitionPage(
              state,
              ProductFormScreen(
                product: state.extra is Product ? state.extra as Product : null,
                productId: state.pathParameters['id'],
              ),
            ),
          ),
          GoRoute(
            path: '/sales',
            pageBuilder: (context, state) =>
                _transitionPage(state, const SalesHistoryScreen()),
          ),
          GoRoute(
            path: '/customers',
            pageBuilder: (context, state) =>
                _transitionPage(state, const CustomerScreen()),
          ),
          GoRoute(
            path: '/invoice',
            pageBuilder: (context, state) => _transitionPage(
              state,
              InvoiceScreen(sale: state.extra! as Sale),
            ),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _transitionPage(
  GoRouterState state,
  Widget child,
) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 200),
  reverseTransitionDuration: const Duration(milliseconds: 200),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  },
);

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
