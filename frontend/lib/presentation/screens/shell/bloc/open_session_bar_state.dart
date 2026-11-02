part of 'open_session_bar_bloc.dart';

@freezed
abstract class OpenSessionBarState with _$OpenSessionBarState {
  const factory OpenSessionBarState({
    /// Sesión abierta y no abandonada (nula: no hay barra).
    TrainingSession? session,
  }) = _OpenSessionBarState;
}
