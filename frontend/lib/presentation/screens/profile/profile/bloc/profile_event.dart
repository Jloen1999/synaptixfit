part of 'profile_bloc.dart';

@freezed
sealed class ProfileEvent with _$ProfileEvent {
  const factory ProfileEvent.started() = ProfileStarted;

  /// Pull-to-refresh o vuelta de una pantalla de edición.
  const factory ProfileEvent.refreshed() = ProfileRefreshed;
}
