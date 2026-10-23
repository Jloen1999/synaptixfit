part of 'admin_hub_bloc.dart';

@freezed
abstract class AdminHubState with _$AdminHubState {
  const factory AdminHubState({
    LockdownStatus? lockdown,
    @Default(false) bool loading,
    @Default(false) bool updating,

    /// Fallo al leer el estado del bloqueo.
    AppError? loadError,

    /// Fallo al cambiarlo (se muestra una vez en un aviso).
    AppError? actionError,
  }) = _AdminHubState;
}
