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
  }) = _HealthConsent;
}
