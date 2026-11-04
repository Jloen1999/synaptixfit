part of 'legal_acceptance_bloc.dart';

/// En qué punto está la aceptación de la política de quien ha iniciado sesión.
enum LegalGateStatus {
  /// Aún no se ha comprobado (o no hay sesión).
  unknown,

  /// Hay que aceptar la versión vigente antes de seguir.
  required,

  /// Ya está aceptada (o no se pudo comprobar: sin conexión no se bloquea).
  accepted,
}

@freezed
abstract class LegalAcceptanceState with _$LegalAcceptanceState {
  const factory LegalAcceptanceState({
    @Default(LegalGateStatus.unknown) LegalGateStatus status,

    /// Versión que se enseña y que se acepta al pulsar «Aceptar y seguir».
    String? currentVersion,

    /// Ya había aceptado una versión anterior: la política ha cambiado.
    @Default(false) bool updated,
    @Default(false) bool accepting,
    AppError? error,
  }) = _LegalAcceptanceState;
}
