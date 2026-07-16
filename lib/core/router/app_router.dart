import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/machines/machines_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/support/support_ticket_detail_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final isLoading = auth.isLoading;
      final isLoggedIn = auth.isAuthenticated;
      final onLogin = state.matchedLocation == '/login';

      if (isLoading) {
        return null;
      }

      if (!isLoggedIn && !onLogin) {
        return '/login';
      }

      if (isLoggedIn && onLogin) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const AppShell()),
      GoRoute(
        path: '/machines/:id',
        builder: (_, state) => MachineDetailScreen(machineId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) => ProductDetailScreen(productId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) => OrderDetailScreen(orderId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/support/:id',
        builder: (_, state) => SupportTicketDetailScreen(ticketId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
