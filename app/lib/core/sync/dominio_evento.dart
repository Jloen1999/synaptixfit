/// Eventos del dominio que modifican el estado global de la aplicación.
/// Cada evento dispara una cascada de invalidación de providers.
enum DominioEvento {
  planGuardado,
  bloqueEstudioCompletado,
  bloqueEstudioDesmarcado,
  sesionCompletada,
  sesionDesmarcada,
  checkInRealizado,
  entregaCompletada,
  retoCompletado,
  pomodoroCompletado,
  xpOtorgado,
  practicaCompletada,
  shadowbanToggled,
  lockdownToggled,
}

/// Datos opcionales que acompañan a un evento para propagación contextual.
class EventoPayload {
  final String? planId;
  final String? bloqueId;
  final String? sesionId;
  final String? entregaId;
  final String? retoId;
  final String? horarioId;
  final int? xpGanado;
  final int? duracionMinutos;
  final bool? subeNivel;
  final String? materialId;

  const EventoPayload({
    this.planId,
    this.bloqueId,
    this.sesionId,
    this.entregaId,
    this.retoId,
    this.horarioId,
    this.xpGanado,
    this.duracionMinutos,
    this.subeNivel,
    this.materialId,
  });
}
