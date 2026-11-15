part of 'shared_routine_bloc.dart';

@freezed
sealed class SharedRoutineEvent with _$SharedRoutineEvent {
  const factory SharedRoutineEvent.started(String token) = SharedRoutineStarted;

  /// «Copiar a mis rutinas».
  const factory SharedRoutineEvent.copyRequested() = SharedRoutineCopyRequested;
}
