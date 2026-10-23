part of 'challenges_list_bloc.dart';

@freezed
sealed class ChallengesListEvent with _$ChallengesListEvent {
  /// Primera carga: resumen, tareas pendientes y primera página.
  const factory ChallengesListEvent.started() = ChallengesListStarted;

  /// Pull-to-refresh o vuelta de otra pantalla: recarga sin esqueleto.
  const factory ChallengesListEvent.refreshed() = ChallengesListRefreshed;

  const factory ChallengesListEvent.queryChanged(ChallengeQuery query) =
      ChallengesListQueryChanged;

  const factory ChallengesListEvent.loadMoreRequested() =
      ChallengesListLoadMoreRequested;

  /// Completa una tarea desde la sección de tareas pendientes.
  const factory ChallengesListEvent.pendingCompleted(PendingMilestone pending) =
      ChallengesListPendingCompleted;
}
