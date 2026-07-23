import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/vmfs_repository.dart';
import '../../models/auth_user.dart';
import '../../models/registration_result.dart';

final repositoryProvider = Provider<VmfsRepository>((ref) {
  return VmfsRepository(
    onUnauthorized: () => ref.read(authProvider.notifier).handleUnauthorized(),
  );
});

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.sessionReady = false,
    this.error,
  });

  final AuthUser? user;
  final bool isLoading;
  final bool sessionReady;
  final String? error;

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState(isLoading: true)) {
    _bootstrap();
  }

  final VmfsRepository _repository;

  Future<void> _bootstrap() async {
    try {
      await _repository.warmSession();
      final user = await _repository.restoreSession();
      state = AuthState(
        user: user,
        isLoading: false,
        sessionReady: user != null,
      );
    } catch (_) {
      state = const AuthState(isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(isLoading: true, error: null);
    try {
      await _repository.login(email: email, password: password);
      await _repository.warmSession();
      final user = await _repository.restoreSession();
      if (user == null) {
        throw Exception('Session could not be established. Please try again.');
      }
      state = AuthState(user: user, isLoading: false, sessionReady: true);
    } catch (e) {
      state = AuthState(isLoading: false, error: _formatError(e));
    }
  }

  Future<RegistrationResult?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AuthState(isLoading: true, error: null);
    try {
      final result = await _repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = const AuthState(isLoading: false);
      return result;
    } catch (e) {
      state = AuthState(isLoading: false, error: _formatError(e));
      return null;
    }
  }

  String _formatError(Object error) {
    return error.toString();
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(isLoading: false);
  }

  Future<void> handleUnauthorized() async {
    await _repository.clearSession();
    state = const AuthState(isLoading: false);
  }

  Future<void> refreshSession() async {
    final user = await _repository.restoreSession();
    state = AuthState(
      user: user,
      isLoading: false,
      sessionReady: user != null,
    );
  }
}

final StateNotifierProvider<AuthNotifier, AuthState> authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(repositoryProvider));
});
