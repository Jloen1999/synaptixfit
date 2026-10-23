part of 'admin_hub_bloc.dart';

@freezed
sealed class AdminHubEvent with _$AdminHubEvent {
  const factory AdminHubEvent.started() = AdminHubStarted;

  /// El administrador ha confirmado activar o desactivar el bloqueo.
  const factory AdminHubEvent.lockdownChanged({required bool active}) =
      AdminHubLockdownChanged;
}
