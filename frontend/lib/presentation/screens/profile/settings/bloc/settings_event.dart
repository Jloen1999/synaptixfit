part of 'settings_bloc.dart';

@freezed
sealed class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.exportRequested() = SettingsExportRequested;

  /// «Cerrar sesión»: el bloc mira si hay datos sin subir antes.
  const factory SettingsEvent.logoutRequested() = SettingsLogoutRequested;

  /// «Ver las guías otra vez» de la cuenta [accountId] (ADR 0049).
  const factory SettingsEvent.guidesResetRequested(String accountId) =
      SettingsGuidesResetRequested;

  /// Baja de la cuenta: contraseña si la tiene, o confirmación explícita si es
  /// solo de Google.
  const factory SettingsEvent.deleteRequested({
    String? password,
    @Default(false) bool confirm,
  }) = SettingsDeleteRequested;
}
