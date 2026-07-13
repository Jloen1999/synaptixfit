import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/providers/hive_cache_provider.dart';
import '../../../core/session_reset.dart';
import '../application/auth_provider.dart';
import '../../academico/application/asignaturas_provider.dart';
import '../../academico/application/balance_semanal_provider.dart';
import '../../academico/application/materiales_estudio_provider.dart';
import '../../admin/application/admin_provider.dart';
import '../../analitica/application/analitica_provider.dart';
import '../../bienestar/application/neurofisiologia_provider.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../bienestar/application/sesion_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../dashboard/application/smart_banner_provider.dart';
import '../../dashboard/application/timeline_provider.dart';
import '../../insignias/application/insignias_provider.dart';
import '../../notificaciones/application/notificaciones_provider.dart';
import '../../perfil/application/perfil_provider.dart';
import '../../retos/application/retos_core.dart';
import '../../social/application/social_provider.dart';

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

  /// Cierra la sesion actual siguiendo una secuencia estricta para
  /// evitar redibujados fantasma (data flash) con datos del usuario
  /// anterior cuando otro usuario inicia sesion inmediatamente despues.
  ///
  /// La UI DEBE navegar a [/acceso] ANTES de llamar a este metodo.
  /// Secuencia interna:
  ///   1. Invalidar TODOS los providers del usuario (global teardown)
  ///   2. Limpiar persistencia local (Hive)
  ///   3. Cerrar sesion en Supabase
  ///   4. Resetear estado de autenticacion
  Future<void> logout() async {
    // 1. Destruccion masiva del estado en Riverpod
    invalidarProveedoresUsuario();

    // 2. Limpieza profunda de persistencia local
    await _limpiarHive();

    // 3. Cierre de sesion en Supabase
    await _repo.logout();

    // 4. Resetear estado de autenticacion
    state = const AuthState();

    // 5. Tree Hard Reset: destruir ProviderScope completo para que
    //    el siguiente usuario arranque con un contenedor de providers
    //    virgen, sin AsyncLoading.previousValue residual alguno.
    resetAllProvidersOnSessionChange();
  }

  /// Vacia las cajas de cache registradas en el proyecto.
  ///
  /// Las cajas [smartcache] y [offline_dash] se abren en [HiveConfig.init]
  /// al arrancar la app, por lo que siempre estan disponibles. La caja
  /// [offline_queue] se abre de manera perezosa desde [OfflineQueueService];
  /// usamos [Hive.isBoxOpen] para no forzar su apertura si nunca se uso.
  Future<void> _limpiarHive() async {
    const boxes = ['smartcache', 'offline_dash', 'offline_queue'];
    for (final nombre in boxes) {
      try {
        if (Hive.isBoxOpen(nombre)) {
          await Hive.box<Map>(nombre).clear();
        }
      } catch (_) {
        // Si una caja no existe o falla, continuamos con las demas.
      }
    }
  }

  /// Invalida todos los providers que cachean datos del usuario actual.
  ///
  /// Se ejecuta en cada inicio de sesion exitoso (login, registro, Google,
  /// sincronizacion de sesion activa) ANTES de notificar el estado autenticado,
  /// y tambien durante el logout como teardown global.
  void invalidarProveedoresUsuario() {
    // ── Cache Hive ──
    _ref.invalidate(hiveSmartCacheProvider);
    _ref.invalidate(hiveOfflineDashProvider);

    // ── Barrera de identidad ──
    _ref.invalidate(currentUserIdProvider);

    // ── Perfil ──
    _ref.invalidate(perfilUsuarioProvider);
    _ref.invalidate(perfilBienestarCompletoProvider);
    _ref.invalidate(perfilActividadProvider);
    _ref.invalidate(perfilAcademicoProvider);
    _ref.invalidate(perfilPreferenciasProvider);
    _ref.invalidate(perfilCompletoProvider);
    _ref.invalidate(perfilBienestarProvider);

    // ── Dashboard ──
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(timelineHoyProvider);
    _ref.invalidate(consejoSmartProvider);
    _ref.invalidate(completionOverlayProvider);
    _ref.invalidate(selectedDiaProvider);

    // ── Bienestar / Rutinas ──
    _ref.invalidate(rutinasUsuarioProvider);
    _ref.invalidate(rutinasComunidadProvider);
    _ref.invalidate(estadoDiarioHoyProvider);
    _ref.invalidate(sesionesProvider);
    _ref.invalidate(cargaAcademicaSemanalProvider);
    _ref.invalidate(adherenciaAcademicaProvider);
    _ref.invalidate(estadoEnergeticoProvider);
    _ref.invalidate(contextoAcademicoProvider);
    _ref.invalidate(cargaCognitivaProvider);

    // ── Neurofisiologia ──
    _ref.invalidate(caloriasEstudioHoyProvider);
    _ref.invalidate(cargaFisicaHoyProvider);
    _ref.invalidate(cargaFisicaMaximaProvider);
    _ref.invalidate(tMaxEstudioProvider);
    _ref.invalidate(estadoCognitivoProvider);
    _ref.invalidate(estadoRegulacionCruzadaProvider);

    // ── Retos ──
    _ref.invalidate(retosProvider);
    _ref.invalidate(retosPublicosProvider);
    _ref.invalidate(logrosCountProvider);
    _ref.invalidate(hitosPendientesProvider);

    // ── Insignias ──
    _ref.invalidate(insigniasUsuarioProvider);
    _ref.invalidate(insigniasRecienObtenidasProvider);
    _ref.invalidate(rachaStateProvider);

    // ── Admin ──
    _ref.invalidate(esAdminProvider);

    // ── Academico ──
    _ref.invalidate(balanceSemanalProvider);
    _ref.invalidate(asignaturasUsuarioSemestreProvider);
    _ref.invalidate(asignaturasSinSemestreProvider);
    _ref.invalidate(carreraConAsignaturasProvider);
    _ref.invalidate(asignaturasActivasProvider);
    _ref.invalidate(asignaturasArchivadasProvider);
    _ref.invalidate(repasoUrgenteGlobalProvider(null));

    // ── Analitica ──
    _ref.invalidate(analiticaSemanalProvider);
    _ref.invalidate(tendenciaRpeProvider);
    _ref.invalidate(volumenSemanalProvider);
    _ref.invalidate(correlacionCargaProvider);

    // ── Social ──
    _ref.invalidate(socialFeedProvider);

    // ── Notificaciones ──
    _ref.invalidate(notificacionesProvider);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});
