part of 'check_in_bloc.dart';

enum CheckInStatus { loading, ready, failure }

@freezed
abstract class CheckInState with _$CheckInState {
  const factory CheckInState({
    @Default(CheckInStatus.loading) CheckInStatus status,

    /// Check-in ya guardado hoy (o `null`).
    CheckIn? today,
    @Default(CheckInInput()) CheckInInput input,
    @Default(<CheckIn>[]) List<CheckIn> history,

    /// Último guardado: indica si era el primero del día y la experiencia.
    CheckInResult? lastResult,
    @Default(false) bool submitting,
    AppError? error,
    TrainingEffect? effect,
  }) = _CheckInState;
}
