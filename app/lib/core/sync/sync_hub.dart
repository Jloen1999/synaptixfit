import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/academico/application/entregas_examenes_provider.dart';
import '../../features/academico/application/inbox_config_provider.dart'
    show horariosFijosProvider;
import '../../features/academico/application/planes_estudio_provider.dart';
import '../../features/bienestar/application/rutina_provider.dart';
import '../../features/dashboard/application/dashboard_provider.dart';
import '../../features/dashboard/application/timeline_provider.dart';
import '../../features/insignias/application/insignias_provider.dart';
import '../../features/perfil/application/perfil_provider.dart';
import '../../features/retos/application/retos_provider.dart';
import '../../features/social/application/social_provider.dart';
import 'dominio_evento.dart';

/// Orquestador central de sincronización entre módulos.
///
/// Principio: "Un evento, una cascada predecible".
/// Cada módulo solo notifica al SyncHub; no conoce los providers de otros módulos.
class SyncHub {
  final Ref _ref;

  const SyncHub(this._ref);

  /// Dispara un evento de dominio con su cascada de invalidación completa.
  void dispatch(DominioEvento evento, {EventoPayload? payload}) {
    switch (evento) {
      case DominioEvento.planGuardado:
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(timelineHoyProvider);
        _ref.invalidate(cargaAcademicaSemanalProvider);
        _ref.invalidate(adherenciaAcademicaProvider);
        _ref.invalidate(estadoEnergeticoProvider);
        _ref.invalidate(contextoAcademicoProvider);
        _ref.invalidate(horariosSemanaActualProvider);
        _ref.invalidate(horariosFijosProvider);
        _ref.invalidate(entregasPendientesProvider);
        if (payload?.planId != null) {
          _ref.invalidate(bloquesPlanActualProvider(payload!.planId!));
        }

      case DominioEvento.bloqueEstudioCompletado:
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(timelineHoyProvider);
        _ref.invalidate(cargaAcademicaSemanalProvider);
        _ref.invalidate(adherenciaAcademicaProvider);
        _ref.invalidate(estadoEnergeticoProvider);
        _ref.invalidate(contextoAcademicoProvider);
        _ref.invalidate(horariosSemanaActualProvider);

      case DominioEvento.sesionCompletada:
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(timelineHoyProvider);
        _ref.invalidate(rachaStateProvider);
        _ref.invalidate(insigniasRecienObtenidasProvider);
        _ref.invalidate(perfilActividadProvider);
        if (payload?.sesionId != null) {
          _ref.invalidate(diasDeSemanaProvider);
        }

      case DominioEvento.checkInRealizado:
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(timelineHoyProvider);
        _ref.invalidate(estadoDiarioHoyProvider);
        _ref.invalidate(estadoEnergeticoProvider);
        _ref.invalidate(contextoAcademicoProvider);
        _ref.invalidate(rachaStateProvider);

      case DominioEvento.entregaCompletada:
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(timelineHoyProvider);
        _ref.invalidate(cargaAcademicaSemanalProvider);
        _ref.invalidate(adherenciaAcademicaProvider);
        _ref.invalidate(estadoEnergeticoProvider);
        _ref.invalidate(contextoAcademicoProvider);
        _ref.invalidate(entregasPendientesProvider);

      case DominioEvento.retoCompletado:
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(timelineHoyProvider);
        _ref.invalidate(retosProvider);
        _ref.invalidate(hitosPendientesProvider);
        _ref.invalidate(insigniasRecienObtenidasProvider);
        _ref.invalidate(socialFeedProvider);

      case DominioEvento.pomodoroCompletado:
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(timelineHoyProvider);
        _ref.invalidate(cargaAcademicaSemanalProvider);
        _ref.invalidate(adherenciaAcademicaProvider);

      case DominioEvento.xpOtorgado:
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(perfilUsuarioProvider);

      case DominioEvento.practicaCompletada:
        _ref.invalidate(dashboardProvider);
        _ref.invalidate(timelineHoyProvider);
        _ref.invalidate(cargaAcademicaSemanalProvider);
        _ref.invalidate(adherenciaAcademicaProvider);
        _ref.invalidate(estadoEnergeticoProvider);
        _ref.invalidate(contextoAcademicoProvider);
        _ref.invalidate(horariosSemanaActualProvider);
    }
  }
}

/// Provider singleton del SyncHub para inyección vía Riverpod.
final syncHubProvider = Provider<SyncHub>((ref) => SyncHub(ref));
