import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/vmfs_widgets.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/registration_pending_screen.dart';
import '../../features/machines/machine_form_screen.dart';
import '../../features/machines/machine_slot_form_screen.dart';
import '../../features/machines/machines_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/products/product_form_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/support/support_ticket_detail_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;
      final isLoading = auth.isLoading;
      final isLoggedIn = auth.isAuthenticated;
      final onLogin = location == '/login';
      final onRegister = location.startsWith('/register');
      final onLoading = location == '/loading';

      if (isLoading) {
        return onLoading ? null : '/loading';
      }

      if (onLoading) {
        return isLoggedIn ? '/' : '/login';
      }

      if (!isLoggedIn && !onLogin && !onRegister) {
        return '/login';
      }

      if (isLoggedIn && (onLogin || onRegister)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (_, __) => const Scaffold(body: VmfsLoadingView()),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/register/pending',
        builder: (_, state) => RegistrationPendingScreen(
          email: state.extra as String? ?? '',
        ),
      ),
      GoRoute(path: '/', builder: (_, __) => const AppShell()),
      GoRoute(path: '/machines/new', builder: (_, __) => const MachineFormScreen()),
      GoRoute(
        path: '/machines/:id/edit',
        builder: (_, state) => MachineFormScreen(machineId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/machines/:id',
        builder: (_, state) => MachineDetailScreen(
          machineId: int.parse(state.pathParameters['id']!),
          showOnboardingOnOpen: state.uri.queryParameters['onboarding'] == '1',
        ),
      ),
      GoRoute(
        path: '/machines/:id/slots/new',
        builder: (_, state) => MachineSlotFormScreen(machineId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/machines/:machineId/slots/:slotId/edit',
        builder: (_, state) => MachineSlotFormScreen(
          machineId: int.parse(state.pathParameters['machineId']!),
          slotId: int.parse(state.pathParameters['slotId']!),
        ),
      ),
      GoRoute(path: '/products/new', builder: (_, __) => const ProductFormScreen()),
      GoRoute(
        path: '/products/:id/edit',
        builder: (_, state) => ProductFormScreen(productId: int.parse(state.pathParameters['id']!)),
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
