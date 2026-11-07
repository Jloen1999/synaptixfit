part of 'exercise_progress_bloc.dart';

@freezed
sealed class ExerciseProgressEvent with _$ExerciseProgressEvent {
  /// Cargar (o recargar) la evolución de un ejercicio.
  const factory ExerciseProgressEvent.requested(String exerciseId) =
      ExerciseProgressRequested;
}
