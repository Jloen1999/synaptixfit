part of 'quick_check_in_bloc.dart';

@freezed
sealed class QuickCheckInEvent with _$QuickCheckInEvent {
  const factory QuickCheckInEvent.started() = QuickCheckInStarted;

  /// Otra pantalla cambió el registro de hoy (p. ej. el registro completo).
  const factory QuickCheckInEvent.refreshed() = QuickCheckInRefreshed;

  const factory QuickCheckInEvent.submitted(QuickCheckIn input) =
      QuickCheckInSubmitted;

  /// Un toque en una de las tres preguntas.
  const factory QuickCheckInEvent.answered(
    CheckInQuestion question,
    int value,
  ) = QuickCheckInAnswered;

  /// Volver a preguntar aunque ya esté hecho hoy («Cambiar»).
  const factory QuickCheckInEvent.editRequested() = QuickCheckInEditRequested;

  /// Dejar las respuestas como estaban («Cancelar»).
  const factory QuickCheckInEvent.editCancelled() = QuickCheckInEditCancelled;
}
