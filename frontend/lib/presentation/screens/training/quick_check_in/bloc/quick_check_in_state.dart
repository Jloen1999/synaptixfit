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
    AppError? error,
  }) = _QuickCheckInState;

  const QuickCheckInState._();

  /// Enseñar las tres preguntas (no hay registro hoy o se quiere cambiar).
  bool get asking => editing || !(adaptation?.checkInDone ?? false);
}
