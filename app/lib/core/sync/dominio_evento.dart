/// Eventos del dominio que modifican el estado global de la aplicación.
/// Cada evento dispara una cascada de invalidación de providers.
enum DominioEvento {
  planGuardado,
  bloqueEstudioCompletado,
  sesionCompletada,
  checkInRealizado,
  entregaCompletada,
  retoCompletado,
  pomodoroCompletado,
  xpOtorgado,
  practicaCompletada,
}

/// Datos opcionales que acompañan a un evento para propagación contextual.
class EventoPayload {
  final String? planId;
  final String? bloqueId;
  final String? sesionId;
  final String? entregaId;
  final String? retoId;
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
    this.xpGanado,
    this.duracionMinutos,
    this.subeNivel,
    this.materialId,
  });
}
