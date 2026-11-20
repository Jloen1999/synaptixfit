part of 'calendar_bloc.dart';

@freezed
sealed class CalendarEvent with _$CalendarEvent {
  /// Abre el calendario en la semana de [week] (la actual si es nulo).
  const factory CalendarEvent.started({DateTime? week}) = CalendarStarted;

  /// Avanza o retrocede [offset] semanas.
  const factory CalendarEvent.weekShifted(int offset) = CalendarWeekShifted;

  const factory CalendarEvent.todayRequested() = CalendarTodayRequested;

  /// Recarga la semana (tras pull-to-refresh o al volver del editor).
  const factory CalendarEvent.refreshed() = CalendarRefreshed;

  /// Toque en una celda vacía que empieza en [start].
  const factory CalendarEvent.slotTapped(DateTime start) = CalendarSlotTapped;

  /// Bloque movido o redimensionado en el lienzo.
  const factory CalendarEvent.blockRescheduled({
    required String blockId,
    required DateTime start,
    required DateTime end,
  }) = CalendarBlockRescheduled;

  /// Intento de mover un bloque que no se puede mover.
  const factory CalendarEvent.lockedBlockTouched(String blockId) =
      CalendarLockedBlockTouched;

  /// [effort] (1-10): esfuerzo al marcar hecho un bloque de deporte sin rutina.
  /// [completed] fija el estado en vez de alternarlo («No fui» en una clase
  /// que aún no se ha dado por asistida).
  const factory CalendarEvent.completionToggled(
    String blockId, {
    int? effort,
    bool? completed,
  }) = CalendarCompletionToggled;

  /// Borra el bloque: desaparece ya y se borra de verdad al cerrarse el aviso
  /// sin deshacer (o al salir de la pantalla).
  const factory CalendarEvent.blockDeleteRequested(CalendarBlock block) =
      CalendarBlockDeleteRequested;

  /// «Pasar a otro día» de la ficha: misma hora en el día elegido. Como
  /// [CalendarEvent.blockRescheduled], pero avisa de adónde fue (con «Ver»).
  const factory CalendarEvent.blockMoved({
    required String blockId,
    required DateTime start,
    required DateTime end,
  }) = CalendarBlockMoved;

  /// «Empezar el entreno» de la ficha de un día de rutina de hoy: abre la
  /// sesión de ese día (la misma que «Empezar» de Inicio).
  const factory CalendarEvent.trainingStartRequested(String blockId) =
      CalendarTrainingStartRequested;

  /// «Deshacer» del aviso: el bloque vuelve y no se borra.
  const factory CalendarEvent.blockDeleteUndone(String blockId) =
      CalendarBlockDeleteUndone;

  /// El aviso se cerró sin deshacer: se borra en el servidor.
  const factory CalendarEvent.blockDeleteCommitted(String blockId) =
      CalendarBlockDeleteCommitted;
}
