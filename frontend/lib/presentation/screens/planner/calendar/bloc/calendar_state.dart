part of 'calendar_bloc.dart';

enum CalendarStatus { loading, ready, failure }

@freezed
abstract class CalendarState with _$CalendarState {
  const factory CalendarState({
    required DateTime weekStart,
    @Default(CalendarStatus.loading) CalendarStatus status,
    @Default(<CalendarBlock>[]) List<CalendarBlock> blocks,
    @Default(<BlockConflict>[]) List<BlockConflict> conflicts,

    /// Entregas y exámenes de la semana (línea de tiempo).
    @Default(<TimelineEntry>[]) List<TimelineEntry> deadlines,

    /// Título visible de cada bloque (asignatura o título de la línea de tiempo).
    @Default(<String, String>{}) Map<String, String> blockTitles,

    /// Nombre de la asignatura de cada bloque que la tiene (ficha del evento).
    @Default(<String, String>{}) Map<String, String> blockSubjects,

    /// Retos activos con sus tareas, para nombrar en la ficha la tarea que
    /// adelanta un evento. Nulo: aún no se han pedido (solo se piden si algún
    /// evento de la semana va con un reto).
    List<ChallengeOption>? challenges,

    /// Se está abriendo la sesión de un día de rutina («Empezar el entreno»).
    @Default(false) bool startingTraining,
    WeekBalance? balance,
    AppError? error,
    @Default(<String>{}) Set<String> busyBlockIds,

    /// Aviso puntual para la página; [noticeId] cambia en cada aviso nuevo.
    CalendarNotice? notice,
    @Default(0) int noticeId,

    /// Bloques borrados que aún se pueden deshacer (ya no se muestran).
    @Default(<String>{}) Set<String> pendingDeletionIds,
  }) = _CalendarState;

  const CalendarState._();

  /// Tarea de reto que adelanta [block] y su reto, si se conocen.
  ({String challenge, String? task})? challengeOf(CalendarBlock block) {
    final id = block.challengeId;
    if (id == null) return null;
    for (final c in challenges ?? const <ChallengeOption>[]) {
      if (c.id != id) continue;
      String? task;
      for (final t in c.tasks) {
        if (t.id == block.milestoneId) task = t.title;
      }
      return (challenge: c.title, task: task);
    }
    return null;
  }

  /// Bloques que se pintan: sin los que están pendientes de borrar.
  List<CalendarBlock> get visibleBlocks => pendingDeletionIds.isEmpty
      ? blocks
      : [
          for (final b in blocks)
            if (!pendingDeletionIds.contains(b.id)) b,
        ];
}

/// Avisos puntuales que la página muestra (SnackBar, abrir hoja…).
@freezed
sealed class CalendarNotice with _$CalendarNotice {
  /// Bloque marcado/desmarcado: XP sumada o restada y cuenta actualizada.
  /// [absent]: era una clase y quedó marcada «No fui».
  const factory CalendarNotice.blockXp({
    required bool completed,
    required int xpDelta,
    Account? account,
    @Default(false) bool absent,
  }) = CalendarNoticeBlockXp;

  /// El bloque movido se solapa con otros.
  const factory CalendarNotice.overlaps(int count) = CalendarNoticeOverlaps;

  const factory CalendarNotice.blockLocked() = CalendarNoticeBlockLocked;

  const factory CalendarNotice.completedLocked() =
      CalendarNoticeCompletedLocked;

  const factory CalendarNotice.inPast() = CalendarNoticeInPast;

  /// Abrir la hoja de creación en [start].
  const factory CalendarNotice.createAt(DateTime start) =
      CalendarNoticeCreateAt;

  const factory CalendarNotice.failure(AppError error) = CalendarNoticeFailure;

  /// Bloque pasado a otro día desde su ficha (empieza en [start]).
  const factory CalendarNotice.moved(DateTime start) = CalendarNoticeMoved;

  /// Sesión de entreno abierta desde la ficha: la página la abre.
  const factory CalendarNotice.sessionOpened(String sessionId) =
      CalendarNoticeSessionOpened;

  /// Bloque quitado: el aviso ofrece «Deshacer» durante la ventana de borrado.
  const factory CalendarNotice.blockDeleted(String blockId) =
      CalendarNoticeBlockDeleted;
}
