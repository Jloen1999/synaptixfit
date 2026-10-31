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
    WeekBalance? balance,
    AppError? error,
    @Default(false) bool savingPlan,
    @Default(<String>{}) Set<String> busyBlockIds,

    /// Aviso puntual para la página; [noticeId] cambia en cada aviso nuevo.
    CalendarNotice? notice,
    @Default(0) int noticeId,

    /// Bloques borrados que aún se pueden deshacer (ya no se muestran).
    @Default(<String>{}) Set<String> pendingDeletionIds,
  }) = _CalendarState;

  const CalendarState._();

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
  const factory CalendarNotice.blockXp({
    required bool completed,
    required int xpDelta,
    Account? account,
  }) = CalendarNoticeBlockXp;

  const factory CalendarNotice.planSaved({
    required int xpAwarded,
    required int blockCount,
    Account? account,
  }) = CalendarNoticePlanSaved;

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

  /// Bloque reprogramado al primer hueco libre (empieza en [start]).
  const factory CalendarNotice.rescheduled(DateTime start) =
      CalendarNoticeRescheduled;

  /// Bloque quitado: el aviso ofrece «Deshacer» durante la ventana de borrado.
  const factory CalendarNotice.blockDeleted(String blockId) =
      CalendarNoticeBlockDeleted;
}
