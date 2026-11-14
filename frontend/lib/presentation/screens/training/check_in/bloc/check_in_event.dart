part of 'check_in_bloc.dart';

@freezed
sealed class CheckInEvent with _$CheckInEvent {
  /// [initial]: lo ya contestado en la tarjeta de Gimnasio («Añadir detalles»).
  const factory CheckInEvent.started({
    @Default(CheckInAnswers()) CheckInAnswers initial,
  }) = CheckInStarted;

  /// Un toque en una de las tres preguntas; [withDetails]: «Añadir detalles»
  /// abierto (entonces se guarda con «Guardar»).
  const factory CheckInEvent.answered(
    CheckInQuestion question,
    int value, {
    required bool withDetails,
  }) = CheckInAnswered;

  /// Respuesta a «¿Cuánto estrés tienes?» (en «Añadir detalles»).
  const factory CheckInEvent.stressChanged(int value) = CheckInStressChanged;

  const factory CheckInEvent.inputChanged(CheckInInput input) =
      CheckInInputChanged;

  const factory CheckInEvent.submitted() = CheckInSubmitted;
}
