part of 'settings_bloc.dart';

@freezed
sealed class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.exportRequested() = SettingsExportRequested;

  /// Baja de la cuenta: contraseña si la tiene, o confirmación explícita si es
  /// solo de Google.
  const factory SettingsEvent.deleteRequested({
    String? password,
    @Default(false) bool confirm,
  }) = SettingsDeleteRequested;
}
