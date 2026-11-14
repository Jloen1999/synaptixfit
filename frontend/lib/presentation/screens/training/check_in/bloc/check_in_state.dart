part of 'check_in_bloc.dart';

enum CheckInStatus { loading, ready, failure }

@freezed
abstract class CheckInState with _$CheckInState {
  const factory CheckInState({
    @Default(CheckInStatus.loading) CheckInStatus status,

    /// Check-in ya guardado hoy (o `null`).
    CheckIn? today,
    @Default(CheckInInput()) CheckInInput input,

    /// Lo contestado de las tres preguntas (el valor por defecto del
    /// formulario no cuenta como respuesta).
    @Default(CheckInAnswers()) CheckInAnswers answers,

    /// Si el estrés se ha contestado: sin contestar no sale ninguno marcado.
    @Default(false) bool stressAnswered,

    /// Sube cada vez que toca guardar solo (regla de los tres toques): la
    /// pantalla pide antes el permiso de datos de salud y envía.
    @Default(0) int saveRequest,
    @Default(<CheckIn>[]) List<CheckIn> history,

    /// Último guardado: indica si era el primero del día y la experiencia.
    CheckInResult? lastResult,
    @Default(false) bool submitting,
    AppError? error,
    TrainingEffect? effect,
  }) = _CheckInState;
}
