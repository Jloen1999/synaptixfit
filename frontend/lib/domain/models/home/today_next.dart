import '../../enums/home_event_kind.dart';
import '../../enums/home_event_type.dart';
import '../../enums/item_time_status.dart';
import 'home_dashboard.dart';

/// El único botón de «Tu día» (vocabulario §4, ADR 0038): concentrarse
/// (Pomodoro del evento), empezar el entreno, marcar como hecho o, sin nada
/// pendiente, añadir al calendario. La regla vive aquí, no en la tarjeta.
enum TodayAction {
  focus,
  train,
  markDone,
  addEvent;

  /// Acción para lo que toca ([next]); nula si no hay ninguna directa (una
  /// clase o una comida: se ven y se marcan en la agenda).
  static TodayAction? of(HomeTodayEvent? next) => switch (next?.type) {
    null => addEvent,
    HomeEventType.study || HomeEventType.review => focus,
    // Solo con día de rutina: un partido o una carrera sueltos no deben
    // arrancar otra rutina (se marcan en la agenda con «Ya lo hice»).
    HomeEventType.sport when next?.routineDayId != null => train,
    HomeEventType.personal when next!.status == ItemTimeStatus.inProgress =>
      markDone,
    _ => null,
  };
}

/// Lo que toca hoy, según los eventos de Inicio.
extension TodayNext on Iterable<HomeTodayEvent> {
  /// Evento en curso o, si no hay, el siguiente que aún no ha empezado (lo ya
  /// pasado sin hacer no cuenta: está en la agenda como «Sin hacer»).
  HomeTodayEvent? get nextUp {
    final pending = where(
      (e) => e.kind == HomeEventKind.block && !e.completed,
    ).toList();
    return pending
            .where((e) => e.status == ItemTimeStatus.inProgress)
            .firstOrNull ??
        pending.where((e) => e.status == ItemTimeStatus.upcoming).firstOrNull;
  }
}
