part of 'settings_bloc.dart';

/// [confirmLogout]: hay datos sin subir y la página pregunta antes de cerrar
/// sesión; [loggedOut]: se cierra sin preguntar.
enum SettingsOutcome {
  exported,
  exportCancelled,
  deleted,
  confirmLogout,
  loggedOut,
}

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool exporting,
    @Default(false) bool deleting,

    /// Resultado de la última acción (aviso o cierre de sesión).
    SettingsOutcome? outcome,
    AppError? error,
  }) = _SettingsState;
}
