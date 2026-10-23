part of 'deadlines_bloc.dart';

@freezed
sealed class DeadlinesEvent with _$DeadlinesEvent {
  const factory DeadlinesEvent.started() = DeadlinesStarted;

  const factory DeadlinesEvent.refreshed() = DeadlinesRefreshed;

  /// `true` = solo pendientes; `false` = todas.
  const factory DeadlinesEvent.pendingFilterChanged(bool pendingOnly) =
      DeadlinesPendingFilterChanged;

  /// Filtra por asignatura (`null` = todas).
  const factory DeadlinesEvent.subjectFilterChanged(String? subjectId) =
      DeadlinesSubjectFilterChanged;

  const factory DeadlinesEvent.moreRequested() = DeadlinesMoreRequested;

  /// Crea ([id] nulo) o edita una entrega.
  const factory DeadlinesEvent.saved({
    String? id,
    required DeadlineDraft draft,
  }) = DeadlinesSaved;

  /// Borra la entrega: desaparece ya y se borra de verdad al cerrarse el aviso
  /// sin deshacer (o al salir de la pantalla).
  const factory DeadlinesEvent.deleted(String id) = DeadlinesDeleted;

  /// «Deshacer» del aviso.
  const factory DeadlinesEvent.deleteUndone(String id) = DeadlinesDeleteUndone;

  /// El aviso se cerró sin deshacer: se borra en el servidor.
  const factory DeadlinesEvent.deleteCommitted(String id) =
      DeadlinesDeleteCommitted;

  const factory DeadlinesEvent.completionToggled(String id) =
      DeadlinesCompletionToggled;
}
