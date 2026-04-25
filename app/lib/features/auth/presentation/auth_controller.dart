import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/auth_repository.dart';

class AuthState {
  const AuthState({
    this.loading = false,
    this.error,
    this.requiereOnboarding = true,
    this.autenticado = false,
  });

  final bool loading;
  final String? error;
  final bool requiereOnboarding;
  final bool autenticado;

  AuthState copyWith({
    bool? loading,
    String? error,
    bool? requiereOnboarding,
    bool? autenticado,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      error: error,
      requiereOnboarding: requiereOnboarding ?? this.requiereOnboarding,
      autenticado: autenticado ?? this.autenticado,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, error: null);
    final result = await _repo.login(email: email, password: password);
    state = state.copyWith(
      loading: false,
      requiereOnboarding: result.requiereOnboarding,
      autenticado: result.autenticado,
      error: result.error,
    );
  }

  Future<void> registro(
      {required String email, required String password}) async {
    state = state.copyWith(loading: true, error: null);
    final result = await _repo.registro(email: email, password: password);
    state = state.copyWith(
      loading: false,
      requiereOnboarding: result.requiereOnboarding,
      autenticado: result.autenticado,
      error: result.error,
    );
  }

  Future<void> loginConGoogle() async {
    state = state.copyWith(loading: true, error: null);
    final result = await _repo.loginConGoogle();
    state = state.copyWith(
      loading: false,
      requiereOnboarding: result.requiereOnboarding,
      autenticado: result.autenticado,
      error: result.error,
    );
  }

  Future<void> sincronizarSesionActiva() async {
    final result = await _repo.estadoSesionActual();
    state = state.copyWith(
      loading: false,
      requiereOnboarding: result.requiereOnboarding,
      autenticado: result.autenticado,
      error: result.autenticado ? null : result.error,
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }
}

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => const AuthRepository());
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
