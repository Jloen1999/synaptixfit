part of 'quick_check_in_bloc.dart';

@freezed
abstract class QuickCheckInState with _$QuickCheckInState {
  const factory QuickCheckInState({
    @Default(true) bool loading,

    /// Adaptación de hoy y si ya hay registro (nula hasta cargar).
    TodayAdaptation? adaptation,

    /// Preguntando de nuevo aunque ya estuviera hecho.
    @Default(false) bool editing,
    @Default(false) bool sending,

    /// Se acaba de enviar: la explicación se anuncia al lector solo entonces,
    /// no cada vez que se abre Rutinas con el registro ya hecho.
    @Default(false) bool justSent,

    /// Lo contestado en las tres preguntas.
    @Default(CheckInAnswers()) CheckInAnswers answers,

    /// Sube cada vez que toca guardar solo (regla de los tres toques): la
    /// tarjeta pide antes el permiso de datos de salud y envía.
    @Default(0) int saveRequest,
    AppError? error,
  }) = _QuickCheckInState;

  const QuickCheckInState._();

  /// Enseñar las tres preguntas (no hay registro hoy o se quiere cambiar).
  bool get asking => editing || !(adaptation?.checkInDone ?? false);
}
