part of 'session_bloc.dart';

@freezed
sealed class SessionEvent with _$SessionEvent {
  /// Arranque de la app: intenta recuperar la sesión guardada.
  const factory SessionEvent.started() = SessionStarted;

  /// Login o registro correctos.
  const factory SessionEvent.authenticated(Account account) =
      SessionAuthenticated;

  /// La cuenta ha cambiado (nivel, nombre…).
  const factory SessionEvent.accountUpdated(Account account) =
      SessionAccountUpdated;

  const factory SessionEvent.logoutRequested() = SessionLogoutRequested;

  const factory SessionEvent.expired() = SessionExpired;
}
