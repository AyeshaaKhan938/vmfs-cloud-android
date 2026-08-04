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
import '../../features/support/support_ticket_form_screen.dart';
import 'vmfs_page_transitions.dart';

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
      _vmfsRoute(
        path: '/loading',
        kind: VmfsTransitionKind.fade,
        builder: (_, __) => const Scaffold(body: VmfsLoadingView()),
      ),
      _vmfsRoute(
        path: '/login',
        kind: VmfsTransitionKind.fade,
        builder: (_, __) => const LoginScreen(),
      ),
      _vmfsRoute(
        path: '/register',
        kind: VmfsTransitionKind.fade,
        builder: (_, __) => const RegisterScreen(),
      ),
      _vmfsRoute(
        path: '/register/pending',
        kind: VmfsTransitionKind.fade,
        builder: (_, state) => RegistrationPendingScreen(
          email: state.extra as String? ?? '',
        ),
      ),
      _vmfsRoute(path: '/', builder: (_, __) => const AppShell()),
      _vmfsRoute(path: '/machines/new', builder: (_, __) => const MachineFormScreen()),
      _vmfsRoute(
        path: '/machines/:id/edit',
        builder: (_, state) => MachineFormScreen(machineId: int.parse(state.pathParameters['id']!)),
      ),
      _vmfsRoute(
        path: '/machines/:id',
        builder: (_, state) => MachineDetailScreen(
          machineId: int.parse(state.pathParameters['id']!),
          showOnboardingOnOpen: state.uri.queryParameters['onboarding'] == '1',
        ),
      ),
      _vmfsRoute(
        path: '/machines/:id/slots/new',
        builder: (_, state) => MachineSlotFormScreen(machineId: int.parse(state.pathParameters['id']!)),
      ),
      _vmfsRoute(
        path: '/machines/:machineId/slots/:slotId/edit',
        builder: (_, state) => MachineSlotFormScreen(
          machineId: int.parse(state.pathParameters['machineId']!),
          slotId: int.parse(state.pathParameters['slotId']!),
        ),
      ),
      _vmfsRoute(path: '/products/new', builder: (_, __) => const ProductFormScreen()),
      _vmfsRoute(
        path: '/products/:id/edit',
        builder: (_, state) => ProductFormScreen(productId: int.parse(state.pathParameters['id']!)),
      ),
      _vmfsRoute(
        path: '/products/:id',
        builder: (_, state) => ProductDetailScreen(productId: int.parse(state.pathParameters['id']!)),
      ),
      _vmfsRoute(
        path: '/orders/:id',
        builder: (_, state) => OrderDetailScreen(orderId: int.parse(state.pathParameters['id']!)),
      ),
      _vmfsRoute(
        path: '/support/new',
        builder: (_, state) => SupportTicketFormScreen(
          initialIssueType: state.uri.queryParameters['issue_type'],
        ),
      ),
      _vmfsRoute(
        path: '/support/:id',
        builder: (_, state) => SupportTicketDetailScreen(ticketId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});

GoRoute _vmfsRoute({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
  VmfsTransitionKind kind = VmfsTransitionKind.slide,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => buildVmfsPage(
      key: state.pageKey,
      child: builder(context, state),
      kind: kind,
    ),
  );
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this.ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
