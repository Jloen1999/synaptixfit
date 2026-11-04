part of 'past_activity_bloc.dart';

@freezed
sealed class PastActivityEvent with _$PastActivityEvent {
  const factory PastActivityEvent.submitted({
    required DateTime start,
    required int minutes,
    required int effort,
    String? title,
    ActivityKind? kind,
    int? distanceMeters,
  }) = PastActivitySubmitted;

  /// Carga la rutina en curso para apuntar uno de sus días.
  const factory PastActivityEvent.routineRequested() =
      PastActivityRoutineRequested;

  /// Apunta un día de la rutina entrenado sin la app.
  const factory PastActivityEvent.routineSessionSubmitted({
    required String routineId,
    required String dayId,
    required DateTime date,
    required int minutes,
    required int rpe,
  }) = PastActivityRoutineSessionSubmitted;
}
