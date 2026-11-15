part of 'routine_share_bloc.dart';

@freezed
sealed class RoutineShareEvent with _$RoutineShareEvent {
  const factory RoutineShareEvent.started(String routineId) =
      RoutineShareStarted;

  /// Crea un enlace y abre el menú de compartir con [message] delante.
  const factory RoutineShareEvent.shareRequested(String message) =
      RoutineShareRequested;

  /// «Dejar de compartir» (ya confirmado en la hoja).
  const factory RoutineShareEvent.stopRequested() = RoutineShareStopRequested;
}
