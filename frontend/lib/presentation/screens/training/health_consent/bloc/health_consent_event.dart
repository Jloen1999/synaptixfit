part of 'health_consent_bloc.dart';

@freezed
sealed class HealthConsentEvent with _$HealthConsentEvent {
  const factory HealthConsentEvent.started() = HealthConsentStarted;

  /// La persona marcó la casilla y pulsó «Dar permiso».
  const factory HealthConsentEvent.given() = HealthConsentGiven;

  /// Retira el permiso; con [deleteRecords] borra también los registros anteriores.
  const factory HealthConsentEvent.withdrawn({required bool deleteRecords}) =
      HealthConsentWithdrawn;
}
