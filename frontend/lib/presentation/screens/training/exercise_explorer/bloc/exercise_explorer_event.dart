part of 'exercise_explorer_bloc.dart';

@freezed
sealed class ExerciseExplorerEvent with _$ExerciseExplorerEvent {
  const factory ExerciseExplorerEvent.started() = ExerciseExplorerStarted;

  /// Nuevo texto o filtros: vuelve a la primera página.
  const factory ExerciseExplorerEvent.criteriaChanged(
    ExerciseSearchCriteria criteria,
  ) = ExerciseExplorerCriteriaChanged;

  const factory ExerciseExplorerEvent.refreshed() = ExerciseExplorerRefreshed;

  const factory ExerciseExplorerEvent.moreRequested() =
      ExerciseExplorerMoreRequested;
}
