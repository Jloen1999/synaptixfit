import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_consent.freezed.dart';

/// Permiso expreso para guardar el registro diario (sueño, energía, agujetas,
/// dolor), que son datos de salud (ADR 0034). Es aparte de aceptar la política.
@freezed
abstract class HealthConsent with _$HealthConsent {
  const factory HealthConsent({
    required bool given,
    DateTime? givenAt,
    DateTime? withdrawnAt,

    /// Dado con un texto anterior, que no incluye usar el peso para proponer
    /// los kilos de partida (ADR 0054). Se ofrece aceptar el nuevo, sin obligar.
    @Default(false) bool outdated,
  }) = _HealthConsent;
}
