import '../../enums/home_day_state.dart';
import '../../enums/home_event_kind.dart';
import '../../enums/home_event_type.dart';
import '../../enums/item_time_status.dart';
import 'home_dashboard.dart';

/// El único botón de «Tu día» (vocabulario §4, ADR 0038): concentrarse
/// (Pomodoro del evento), empezar el entreno, marcar como hecho o, sin nada
/// pendiente, añadir al calendario. Qué evento toca y en qué punto está el día
/// lo dice el servidor ([HomeTodaySummary], ADR 0050); aquí solo se elige el
/// botón para ese evento.
enum TodayAction {
  focus,
  train,
  markDone,
  addEvent;

  /// Acción para el evento destacado ([next]) según el estado del día; nula
  /// si no hay ninguna directa (una clase o un partido por empezar: se ven y
  /// se marcan en la agenda) o si [next] ya se marcó y falta el refresco.
  static TodayAction? of(HomeTodaySummary summary, HomeTodayEvent? next) {
    if (next == null) {
      return switch (summary.state) {
        HomeDayState.nothingPlanned || HomeDayState.allDone => addEvent,
        _ => null,
      };
    }
    if (next.completed) return null;
    // Igual que la agenda: un día de rutina se empieza (aunque se pasara la
    // hora); un partido o una carrera sueltos no arrancan otra rutina.
    final routineDay =
        next.kind == HomeEventKind.block &&
        next.type == HomeEventType.sport &&
        next.routineId != null &&
        next.routineDayId != null;
    if (summary.state == HomeDayState.missedLeft) {
      return routineDay ? train : markDone;
    }
    // Una entrega se puede adelantar: se marca en cuanto se tiene.
    if (next.kind == HomeEventKind.deadline) return markDone;
    return switch (next.type) {
      HomeEventType.study || HomeEventType.review => focus,
      HomeEventType.sport when routineDay => train,
      HomeEventType.personal when next.status == ItemTimeStatus.inProgress =>
        markDone,
      _ => null,
    };
  }
}

/// Lo que toca hoy según el resumen del servidor.
extension TodayNext on HomeDashboard {
  /// El evento que destaca «Tu día» ([HomeTodaySummary.nextEventId]): el que
  /// está en curso, si no el próximo y, si ya no queda nada por empezar, el
  /// último sin hacer. Nulo sin nada pendiente.
  HomeTodayEvent? get nextUp {
    final id = todaySummary.nextEventId;
    if (id == null) return null;
    return todayEvents.where((e) => e.id == id).firstOrNull;
  }

  /// El botón de «Tu día» para lo que toca.
  TodayAction? get todayAction => TodayAction.of(todaySummary, nextUp);
}
