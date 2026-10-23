part of 'session_bloc.dart';

@freezed
sealed class SessionState with _$SessionState {
  const factory SessionState.unknown() = SessionUnknown;

  const factory SessionState.authenticated(Account account) =
      SessionAuthenticatedState;

  const factory SessionState.unauthenticated({@Default(false) bool expired}) =
      SessionUnauthenticated;
}
