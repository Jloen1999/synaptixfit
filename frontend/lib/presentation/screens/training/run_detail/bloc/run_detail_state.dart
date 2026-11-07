part of 'run_detail_bloc.dart';

@freezed
abstract class RunDetailState with _$RunDetailState {
  const factory RunDetailState({
    String? blockId,
    @Default(true) bool loading,
    RunDetail? run,
    AppError? error,

    /// Borrada en pantalla, esperando a que se cierre «Deshacer».
    @Default(false) bool pendingDelete,

    /// Ya borrada en el servidor.
    @Default(false) bool deleted,
    AppError? actionError,
  }) = _RunDetailState;
}
