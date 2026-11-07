part of 'deadlines_bloc.dart';

enum DeadlinesStatus { loading, ready, failure }

@freezed
abstract class DeadlinesState with _$DeadlinesState {
  const factory DeadlinesState({
    @Default(DeadlinesStatus.loading) DeadlinesStatus status,
    @Default(<Deadline>[]) List<Deadline> items,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,
    @Default(true) bool pendingOnly,
    String? subjectId,
    @Default(<SubjectOption>[]) List<SubjectOption> subjects,
    AppError? error,
    @Default(false) bool saving,
    @Default(<String>{}) Set<String> busyIds,
    DeadlinesNotice? notice,
    @Default(0) int noticeId,

    /// Entregas borradas que aún se pueden deshacer (ya no se muestran).
    @Default(<String>{}) Set<String> pendingDeletionIds,

    /// Entrega abierta desde su aviso: va la primera y destacada.
    String? focusId,

    /// El aviso apuntaba a una entrega que ya no existe (se borró): la
    /// pantalla lo dice en vez de abrir la lista sin más.
    @Default(false) bool focusMissing,
  }) = _DeadlinesState;

  const DeadlinesState._();

  /// Entregas que se pintan: sin las pendientes de borrar.
  List<Deadline> get visibleItems => pendingDeletionIds.isEmpty
      ? items
      : [
          for (final d in items)
            if (!pendingDeletionIds.contains(d.id)) d,
        ];

  String? subjectName(String? id) {
    if (id == null) return null;
    for (final s in subjects) {
      if (s.id == id) return s.name;
    }
    return null;
  }
}

@freezed
sealed class DeadlinesNotice with _$DeadlinesNotice {
  const factory DeadlinesNotice.saved({required bool created}) =
      DeadlinesNoticeSaved;

  /// Entrega quitada: el aviso ofrece «Deshacer».
  const factory DeadlinesNotice.deleted(String id) = DeadlinesNoticeDeleted;

  const factory DeadlinesNotice.completion({
    required bool completed,
    required int xpDelta,
    Account? account,
  }) = DeadlinesNoticeCompletion;

  const factory DeadlinesNotice.failure(AppError error) =
      DeadlinesNoticeFailure;
}
