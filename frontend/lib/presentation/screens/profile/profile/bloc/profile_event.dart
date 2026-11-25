part of 'profile_bloc.dart';

@freezed
sealed class ProfileEvent with _$ProfileEvent {
  /// [friendRequests] falso en las fichas Físico y Académico: solo el Perfil
  /// enseña el número de solicitudes, las fichas no lo piden.
  const factory ProfileEvent.started({@Default(true) bool friendRequests}) =
      ProfileStarted;

  /// Pull-to-refresh o vuelta de una pantalla de edición.
  const factory ProfileEvent.refreshed() = ProfileRefreshed;
}
