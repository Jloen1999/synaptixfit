import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/session.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/training/cancel_session_use_case.dart';
import '../../../../../domain/use_cases/training/correct_session_use_case.dart';
import '../../../../../domain/use_cases/training/delete_session_use_case.dart';
import '../../../../../domain/use_cases/training/finish_session_use_case.dart';
import '../../../../../domain/use_cases/training/get_open_sessions_use_case.dart';
import '../../../../../domain/use_cases/training/get_personal_records_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_history_use_case.dart';
import '../../../../../domain/use_cases/training/unmark_session_use_case.dart';
import '../../training_effect.dart';

part 'session_history_bloc.freezed.dart';
part 'session_history_event.dart';
part 'session_history_state.dart';

/// Historial de sesiones: las que quedaron sin terminar (para terminarlas con
/// lo registrado o descartarlas), las completadas (nombre del día y récords) y
/// tus mejores marcas. Una sesión de hoy se desmarca; una de otro día se
/// corrige o se elimina (lo exige el servidor).
class SessionHistoryBloc
    extends Bloc<SessionHistoryEvent, SessionHistoryState> {
  SessionHistoryBloc({
    required this._getHistory,
    required this._getRecords,
    required this._unmark,
    required this._getAccount,
    required this._getOpen,
    required this._correct,
    required this._delete,
    required this._finish,
    required this._discard,
  }) : super(const SessionHistoryState()) {
    on<SessionHistoryStarted>(_onStarted);
    on<SessionHistoryRefreshed>(_onRefreshed);
    on<SessionHistoryMoreRequested>(_onMore);
    on<SessionHistoryUnmarkRequested>(_onUnmark);
    on<SessionHistoryCorrectRequested>(
      (e, emit) => _act(
        emit,
        e.sessionId,
        () => _correct(e.sessionId, rpe: e.rpe, durationMinutes: e.minutes),
        TrainingMessage.sessionCorrected,
      ),
    );
    on<SessionHistoryDeleteRequested>(
      (e, emit) => _act(
        emit,
        e.sessionId,
        () => _delete(e.sessionId),
        TrainingMessage.sessionDeleted,
        xpChanged: true,
      ),
    );
    on<SessionHistoryStaleFinished>(
      (e, emit) => _act(
        emit,
        e.sessionId,
        () => _finish(e.sessionId, durationSeconds: e.minutes * 60, rpe: e.rpe),
        TrainingMessage.sessionSavedOnItsDay,
        xpChanged: true,
      ),
    );
    on<SessionHistoryStaleDiscarded>(
      (e, emit) => _act(
        emit,
        e.sessionId,
        () => _discard(e.sessionId),
        TrainingMessage.sessionDiscarded,
      ),
    );
  }

  final GetSessionHistoryUseCaseContract _getHistory;
  final GetPersonalRecordsUseCaseContract _getRecords;
  final UnmarkSessionUseCaseContract _unmark;
  final GetAccountUseCaseContract _getAccount;
  final GetOpenSessionsUseCaseContract _getOpen;
  final CorrectSessionUseCaseContract _correct;
  final DeleteSessionUseCaseContract _delete;
  final FinishSessionUseCaseContract _finish;
  final CancelSessionUseCaseContract _discard;

  Future<void> _onStarted(
    SessionHistoryStarted event,
    Emitter<SessionHistoryState> emit,
  ) async {
    emit(const SessionHistoryState());
    await _loadFirst(emit);
  }

  Future<void> _onRefreshed(
    SessionHistoryRefreshed event,
    Emitter<SessionHistoryState> emit,
  ) async {
    emit(state.copyWith(refreshing: true));
    await _loadFirst(emit);
  }

  Future<void> _loadFirst(Emitter<SessionHistoryState> emit) async {
    final recordsFuture = _getRecords();
    final openFuture = _getOpen();
    final result = await _getHistory();
    // Récords y sesiones sin terminar son un extra: si fallan, el historial se
    // muestra igual.
    final records = (await recordsFuture).valueOrNull;
    final open = (await openFuture).valueOrNull;
    switch (result) {
      case Success(value: final page):
        emit(
          state.copyWith(
            status: HistoryStatus.ready,
            refreshing: false,
            items: page.items,
            open: open ?? state.open,
            records: records ?? state.records,
            page: page.page,
            hasMore: page.hasMore,
            error: null,
          ),
        );
      case Failure(:final error):
        if (state.status == HistoryStatus.ready) {
          emit(state.copyWith(refreshing: false));
          _effect(emit, TrainingEffect.error(error));
        } else {
          emit(
            state.copyWith(
              status: HistoryStatus.failure,
              refreshing: false,
              error: error,
            ),
          );
        }
    }
  }

  Future<void> _onMore(
    SessionHistoryMoreRequested event,
    Emitter<SessionHistoryState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    final result = await _getHistory(page: state.page + 1);
    emit(
      result.fold(
        (page) => state.copyWith(
          loadingMore: false,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ),
        (_) => state.copyWith(loadingMore: false),
      ),
    );
  }

  Future<void> _onUnmark(
    SessionHistoryUnmarkRequested event,
    Emitter<SessionHistoryState> emit,
  ) async {
    final id = event.sessionId;
    if (state.busyIds.contains(id)) return;
    emit(state.copyWith(busyIds: {...state.busyIds, id}));
    final result = await _unmark(id);
    final busy = {...state.busyIds}..remove(id);
    switch (result) {
      case Success():
        // Deja de estar completada: sale del historial.
        emit(
          state.copyWith(
            busyIds: busy,
            items: [
              for (final e in state.items)
                if (e.session.id != id) e,
            ],
          ),
        );
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.sessionUnmarked),
        );
        // Sin esa sesión los récords pueden cambiar.
        final records = (await _getRecords()).valueOrNull;
        if (records != null) emit(state.copyWith(records: records));
        final account = await _getAccount();
        if (account case Success(:final value)) {
          _effect(emit, TrainingEffect.accountChanged(value));
        }
      case Failure(:final error):
        emit(state.copyWith(busyIds: busy));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  /// Acción sobre una sesión: avisa y recarga (cambian el historial, los
  /// récords y, si cambia la XP, la cuenta).
  Future<void> _act(
    Emitter<SessionHistoryState> emit,
    String sessionId,
    Future<AppResult<Object?>> Function() call,
    TrainingMessage message, {
    bool xpChanged = false,
  }) async {
    if (state.busyIds.contains(sessionId)) return;
    emit(state.copyWith(busyIds: {...state.busyIds, sessionId}));
    final result = await call();
    final busy = {...state.busyIds}..remove(sessionId);
    switch (result) {
      case Success():
        emit(state.copyWith(busyIds: busy, refreshing: true));
        _effect(emit, TrainingEffect.message(message));
        await _loadFirst(emit);
        if (xpChanged) {
          final account = await _getAccount();
          if (account case Success(:final value)) {
            _effect(emit, TrainingEffect.accountChanged(value));
          }
        }
      case Failure(:final error):
        emit(state.copyWith(busyIds: busy));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  void _effect(Emitter<SessionHistoryState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
