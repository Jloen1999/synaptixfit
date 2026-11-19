import '../../enums/home_day_state.dart';
import '../../enums/home_event_kind.dart';
import '../../enums/home_event_type.dart';
import '../../enums/item_time_status.dart';
import 'home_dashboard.dart';

/// Botón de la fila «ahora o a continuación» de «Tu día» (ADR 0059):
/// concentrarse (Pomodoro del evento) o marcar como hecho; sin nada que
/// nombrar, añadir al calendario. El entreno de hoy tiene su propia fila con
/// «Empezar». Qué evento se nombra lo decide el servidor
/// ([HomeTodaySummary.spotlightEventId]); aquí solo se elige el botón.
enum TodayAction {
  focus,
  markDone,
  addEvent;

  /// Botón para el evento [event] de la fila; nulo si no tiene uno directo
  /// (una clase o un partido por empezar se ven, y se abren al tocarlos).
  static TodayAction? forEvent(HomeTodayEvent event) {
    if (event.completed) return null;
    // Una entrega se puede adelantar: se marca en cuanto se tiene.
    if (event.kind == HomeEventKind.deadline) return markDone;
    if (event.type == HomeEventType.classSession) return null;
    // Lo que pasó sin hacerse aún se puede marcar.
    if (event.status == ItemTimeStatus.missed) return markDone;
    return switch (event.type) {
      HomeEventType.study || HomeEventType.review => focus,
      HomeEventType.personal || HomeEventType.sport
          when event.status == ItemTimeStatus.inProgress =>
        markDone,
      _ => null,
    };
  }
}

/// Lo que toca hoy según el resumen del servidor.
extension TodayNext on HomeDashboard {
  /// El evento de la fila «ahora o a continuación»: en curso, si no el
  /// próximo y, si ya no queda nada por empezar, el último sin hacer (clases
  /// incluidas, sin entregas ni días de rutina). Nulo sin nada que nombrar.
  HomeTodayEvent? get spotlight {
    final id = todaySummary.spotlightEventId;
    if (id == null) return null;
    return todayEvents.where((e) => e.id == id).firstOrNull;
  }

  /// El entreno de hoy de «Tu día»: el próximo día de la rutina si toca hoy
  /// o va con retraso (lo dice el servidor, `dueToday`).
  HomeNextTrainingDay? get trainingToday {
    final next = nextTrainingDay;
    return next != null && next.dueToday ? next : null;
  }

  /// ¿Queda algo de hoy y ya está todo? Solo si el servidor lo dice.
  bool get dayAllDone => todaySummary.state == HomeDayState.allDone;

  /// Lo demás de hoy que aún queda por hacer y no nombra ninguna fila de «Tu
  /// día» («y 2 más»): ni lo hecho o pasado, ni las clases (no se marcan),
  /// ni [shownIds], ni los días de rutina si ya sale la fila del entreno.
  int othersPending({
    required Set<String> shownIds,
    required bool trainingShown,
  }) => todayEvents
      .where(
        (e) =>
            !e.completed &&
            e.status != ItemTimeStatus.done &&
            e.status != ItemTimeStatus.past &&
            !(e.kind == HomeEventKind.block &&
                e.type == HomeEventType.classSession) &&
            !shownIds.contains(e.id) &&
            !(trainingShown && e.isRoutineDay),
      )
      .length;
}

/// Lo que se puede decir de un evento sin pedir nada al servidor.
extension HomeTodayEventKind on HomeTodayEvent {
  /// Refleja un día de rutina: se empieza o se apunta como sesión de ese día
  /// (marcarlo a mano no avanzaría la rutina, `BLOCK_ROUTINE_LINKED`).
  bool get isRoutineDay => routineId != null && routineDayId != null;
}
