part of 'health_consent_bloc.dart';

@freezed
abstract class HealthConsentState with _$HealthConsentState {
  const factory HealthConsentState({
    @Default(true) bool loading,
    HealthConsent? consent,

    /// No se pudo leer el permiso.
    AppError? error,
    @Default(false) bool saving,

    /// No se pudo dar o retirar el permiso.
    AppError? saveError,

    /// Cuántas veces se ha retirado en esta pantalla (para el aviso de hecho).
    @Default(0) int withdrawals,
  }) = _HealthConsentState;

  const HealthConsentState._();

  bool get given => consent?.given ?? false;
}
