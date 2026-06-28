import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_provider.dart';
import '../../academico/application/balance_semanal_provider.dart';
import '../../admin/application/admin_provider.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../bienestar/application/sesion_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../dashboard/application/timeline_provider.dart';
import '../../insignias/application/insignias_provider.dart';
import '../../perfil/application/perfil_provider.dart';
import '../../retos/application/retos_core.dart';

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
  AuthController(this._repo, this._ref) : super(const AuthState());

  final AuthRepository _repo;
  final Ref _ref;

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(loading: true, error: null);
    final result = await _repo.login(email: email, password: password);
    if (result.autenticado && !state.autenticado) {
      invalidarProveedoresUsuario();
    }
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
    if (result.autenticado && !state.autenticado) {
      invalidarProveedoresUsuario();
    }
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
    if (result.autenticado && !state.autenticado) {
      invalidarProveedoresUsuario();
    }
    state = state.copyWith(
      loading: false,
      requiereOnboarding: result.requiereOnboarding,
      autenticado: result.autenticado,
      error: result.error,
    );
  }

  Future<void> sincronizarSesionActiva() async {
    final result = await _repo.estadoSesionActual();
    if (result.autenticado && !state.autenticado) {
      invalidarProveedoresUsuario();
    }
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

  /// Invalida todos los providers que cachean datos del usuario actual.
  ///
  /// Se ejecuta en cada inicio de sesion exitoso (login, registro, Google,
  /// sincronizacion de sesion activa) ANTES de notificar el estado autenticado,
  /// garantizando que los providers se invaliden con [currentUser] ya disponible
  /// y que el dashboard los re-fetchee con los datos del nuevo usuario.
  void invalidarProveedoresUsuario() {
    // Perfil
    _ref.invalidate(perfilUsuarioProvider);
    _ref.invalidate(perfilBienestarCompletoProvider);
    _ref.invalidate(perfilActividadProvider);
    _ref.invalidate(perfilAcademicoProvider);
    _ref.invalidate(perfilPreferenciasProvider);
    _ref.invalidate(perfilCompletoProvider);
    _ref.invalidate(perfilBienestarProvider);
    // Dashboard
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(timelineHoyProvider);
    // Bienestar
    _ref.invalidate(rutinasUsuarioProvider);
    _ref.invalidate(rutinasComunidadProvider);
    _ref.invalidate(estadoDiarioHoyProvider);
    _ref.invalidate(sesionesProvider);
    _ref.invalidate(cargaAcademicaSemanalProvider);
    _ref.invalidate(adherenciaAcademicaProvider);
    _ref.invalidate(estadoEnergeticoProvider);
    _ref.invalidate(contextoAcademicoProvider);
    _ref.invalidate(cargaCognitivaProvider);
    // Retos
    _ref.invalidate(retosProvider);
    _ref.invalidate(retosPublicosProvider);
    _ref.invalidate(logrosCountProvider);
    _ref.invalidate(hitosPendientesProvider);
    // Insignias
    _ref.invalidate(insigniasUsuarioProvider);
    _ref.invalidate(insigniasRecienObtenidasProvider);
    _ref.invalidate(rachaStateProvider);
    // Admin
    _ref.invalidate(esAdminProvider);
    // Académico
    _ref.invalidate(balanceSemanalProvider);
    _ref.invalidate(asignaturasUsuarioSemestreProvider);
    _ref.invalidate(asignaturasSinSemestreProvider);
    _ref.invalidate(carreraConAsignaturasProvider);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});
