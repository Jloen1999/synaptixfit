part of 'admin_exercises_bloc.dart';

@freezed
sealed class AdminExercisesEvent with _$AdminExercisesEvent {
  const factory AdminExercisesEvent.started() = AdminExercisesStarted;

  /// Recarga la página actual (p. ej. al volver del formulario).
  const factory AdminExercisesEvent.refreshed() = AdminExercisesRefreshed;

  const factory AdminExercisesEvent.queryChanged(AdminExerciseQuery query) =
      AdminExercisesQueryChanged;

  const factory AdminExercisesEvent.pageRequested(int page) =
      AdminExercisesPageRequested;

  /// Invierte el estado activo del ejercicio.
  const factory AdminExercisesEvent.activeToggled(AdminExercise exercise) =
      AdminExercisesActiveToggled;

  const factory AdminExercisesEvent.deleteRequested(AdminExercise exercise) =
      AdminExercisesDeleteRequested;
}
