part of 'quick_check_in_bloc.dart';

@freezed
sealed class QuickCheckInEvent with _$QuickCheckInEvent {
  const factory QuickCheckInEvent.started() = QuickCheckInStarted;

  const factory QuickCheckInEvent.submitted(QuickCheckIn input) =
      QuickCheckInSubmitted;

  /// Volver a preguntar aunque ya esté hecho hoy («Cambiar»).
  const factory QuickCheckInEvent.editRequested() = QuickCheckInEditRequested;
}
