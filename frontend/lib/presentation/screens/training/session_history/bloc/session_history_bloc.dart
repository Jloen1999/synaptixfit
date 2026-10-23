import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/session_history.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/training/get_personal_records_use_case.dart';
import '../../../../../domain/use_cases/training/get_session_history_use_case.dart';
import '../../../../../domain/use_cases/training/unmark_session_use_case.dart';
import '../../training_effect.dart';

part 'session_history_bloc.freezed.dart';
part 'session_history_event.dart';
part 'session_history_state.dart';

/// Historial de sesiones completadas (nombre del día y récords batidos), tus
/// mejores marcas y la opción de desmarcar una sesión.
class SessionHistoryBloc
    extends Bloc<SessionHistoryEvent, SessionHistoryState> {
  SessionHistoryBloc({
    required this._getHistory,
    required this._getRecords,
    required this._unmark,
    required this._getAccount,
  }) : super(const SessionHistoryState()) {
    on<SessionHistoryStarted>(_onStarted);
    on<SessionHistoryRefreshed>(_onRefreshed);
    on<SessionHistoryMoreRequested>(_onMore);
    on<SessionHistoryUnmarkRequested>(_onUnmark);
  }

  final GetSessionHistoryUseCaseContract _getHistory;
  final GetPersonalRecordsUseCaseContract _getRecords;
  final UnmarkSessionUseCaseContract _unmark;
  final GetAccountUseCaseContract _getAccount;

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
    final result = await _getHistory();
    // Los récords son un extra: si fallan, el historial se muestra igual.
    final records = (await recordsFuture).valueOrNull;
    switch (result) {
      case Success(value: final page):
        emit(
          state.copyWith(
            status: HistoryStatus.ready,
            refreshing: false,
            items: page.items,
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

  void _effect(Emitter<SessionHistoryState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
