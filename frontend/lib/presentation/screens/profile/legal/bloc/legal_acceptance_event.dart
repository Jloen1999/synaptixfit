part of 'legal_acceptance_bloc.dart';

@freezed
sealed class LegalAcceptanceEvent with _$LegalAcceptanceEvent {
  /// Al iniciar sesión (o cambiar de cuenta).
  const factory LegalAcceptanceEvent.checked() = LegalAcceptanceChecked;

  /// «Aceptar y seguir»: acepta la versión que se está enseñando.
  const factory LegalAcceptanceEvent.accepted() = LegalAcceptanceAccepted;

  /// Al cerrar sesión: la siguiente cuenta se comprueba de nuevo.
  const factory LegalAcceptanceEvent.reset() = LegalAcceptanceReset;
}
