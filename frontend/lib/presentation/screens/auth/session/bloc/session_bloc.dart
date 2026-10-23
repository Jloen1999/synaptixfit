import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/auth/logout_use_case.dart';
import '../../../../../domain/use_cases/auth/restore_session_use_case.dart';
import '../../../../../domain/use_cases/auth/watch_session_expired_use_case.dart';

part 'session_bloc.freezed.dart';
part 'session_event.dart';
part 'session_state.dart';

/// Estado global de la sesión. El router redirige según este estado.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required this._restoreSession,
    required this._logout,
    required WatchSessionExpiredUseCaseContract watchSessionExpired,
  }) : super(const SessionState.unknown()) {
    on<SessionStarted>(_onStarted);
    on<SessionAuthenticated>(
      (e, emit) => emit(SessionState.authenticated(e.account)),
    );
    on<SessionAccountUpdated>(
      (e, emit) => emit(SessionState.authenticated(e.account)),
    );
    on<SessionLogoutRequested>(_onLogout);
    on<SessionExpired>(
      (_, emit) => emit(const SessionState.unauthenticated(expired: true)),
    );
    _expiredSubscription = watchSessionExpired().listen(
      (_) => add(const SessionEvent.expired()),
    );
  }

  final RestoreSessionUseCaseContract _restoreSession;
  final LogoutUseCaseContract _logout;
  late final StreamSubscription<void> _expiredSubscription;

  Account? get account => switch (state) {
    SessionAuthenticatedState(:final account) => account,
    _ => null,
  };

  Future<void> _onStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    final result = await _restoreSession();
    emit(
      result.fold(
        (account) => account == null
            ? const SessionState.unauthenticated()
            : SessionState.authenticated(account),
        (_) => const SessionState.unauthenticated(),
      ),
    );
  }

  Future<void> _onLogout(
    SessionLogoutRequested event,
    Emitter<SessionState> emit,
  ) async {
    await _logout();
    emit(const SessionState.unauthenticated());
  }

  @override
  Future<void> close() async {
    await _expiredSubscription.cancel();
    return super.close();
  }
}
