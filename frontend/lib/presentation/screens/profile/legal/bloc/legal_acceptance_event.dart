part of 'legal_acceptance_bloc.dart';

@freezed
sealed class LegalAcceptanceEvent with _$LegalAcceptanceEvent {
  /// Al iniciar sesión (o cambiar de cuenta).
  const factory LegalAcceptanceEvent.checked() = LegalAcceptanceChecked;

  /// «Aceptar y seguir»: acepta la versión que se está enseñando y, si se
  /// marcó [healthUpdate], también el texto nuevo del permiso de salud.
  const factory LegalAcceptanceEvent.accepted({
    @Default(false) bool healthUpdate,
  }) = LegalAcceptanceAccepted;

  /// Al cerrar sesión: la siguiente cuenta se comprueba de nuevo.
  const factory LegalAcceptanceEvent.reset() = LegalAcceptanceReset;
}
