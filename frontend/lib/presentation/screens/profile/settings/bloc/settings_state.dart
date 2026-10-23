part of 'settings_bloc.dart';

enum SettingsOutcome { exported, exportCancelled, deleted }

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
