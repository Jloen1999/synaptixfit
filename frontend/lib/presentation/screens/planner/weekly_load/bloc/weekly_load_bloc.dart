import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/planner/weekly_planning.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/planner/get_week_balance_use_case.dart';
import '../../../../../domain/use_cases/planner/get_weekly_load_use_case.dart';
import '../../../../../domain/use_cases/planner/sync_weekly_load_use_case.dart';
import '../../../../../domain/use_cases/planner/update_weekly_wellbeing_use_case.dart';

part 'weekly_load_bloc.freezed.dart';
part 'weekly_load_event.dart';
part 'weekly_load_state.dart';

/// Carga y balance de una semana: horas, estrés, sueño y sincronización.
class WeeklyLoadBloc extends Bloc<WeeklyLoadEvent, WeeklyLoadState> {
  WeeklyLoadBloc({
    required this._getBalance,
    required this._getLoad,
    required this._updateWellbeing,
    required this._syncLoad,
    required this._getAccount,
  }) : super(const WeeklyLoadState()) {
    on<WeeklyLoadStarted>(_onStarted);
    on<WeeklyLoadWellbeingSaved>(_onWellbeing);
    on<WeeklyLoadSyncRequested>(_onSync);
  }

  final GetWeekBalanceUseCaseContract _getBalance;
  final GetWeeklyLoadUseCaseContract _getLoad;
  final UpdateWeeklyWellbeingUseCaseContract _updateWellbeing;
  final SyncWeeklyLoadUseCaseContract _syncLoad;
  final GetAccountUseCaseContract _getAccount;

  WeeklyLoadState _notice(WeeklyLoadState next, WeeklyLoadNotice notice) =>
      next.copyWith(notice: notice, noticeId: state.noticeId + 1);

  Future<void> _onStarted(
    WeeklyLoadStarted event,
    Emitter<WeeklyLoadState> emit,
  ) async {
    emit(
      state.copyWith(
        weekStart: event.weekStart,
        status: WeeklyLoadStatus.loading,
        error: null,
      ),
    );
    final balanceF = _getBalance(event.weekStart);
    final loadF = _getLoad(event.weekStart);
    final balance = await balanceF;
    final load = await loadF;
    final error = balance.errorOrNull ?? load.errorOrNull;
    if (error != null) {
      emit(state.copyWith(status: WeeklyLoadStatus.failure, error: error));
      return;
    }
    emit(
      state.copyWith(
        status: WeeklyLoadStatus.ready,
        balance: balance.valueOrNull,
        load: load.valueOrNull,
      ),
    );
  }

  Future<void> _onWellbeing(
    WeeklyLoadWellbeingSaved event,
    Emitter<WeeklyLoadState> emit,
  ) async {
    final week = state.weekStart;
    if (week == null || state.saving) return;
    emit(state.copyWith(saving: true));
    final result = await _updateWellbeing(
      week,
      stressLevel: event.stressLevel,
      sleepHours: event.sleepHours,
      notes: event.notes,
    );
    switch (result) {
      case Failure(:final error):
        emit(
          _notice(
            state.copyWith(saving: false),
            WeeklyLoadNotice.failure(error),
          ),
        );
      case Success(:final value):
        emit(
          _notice(
            state.copyWith(saving: false, load: value),
            const WeeklyLoadNotice.saved(),
          ),
        );
    }
  }

  Future<void> _onSync(
    WeeklyLoadSyncRequested event,
    Emitter<WeeklyLoadState> emit,
  ) async {
    final week = state.weekStart;
    if (week == null || state.syncing) return;
    emit(state.copyWith(syncing: true));
    final result = await _syncLoad(week);
    switch (result) {
      case Failure(:final error):
        emit(
          _notice(
            state.copyWith(syncing: false),
            WeeklyLoadNotice.failure(error),
          ),
        );
      case Success(:final value):
        final balance = await _getBalance(week);
        final account = value.xpAwarded > 0
            ? (await _getAccount()).valueOrNull
            : null;
        emit(
          _notice(
            state.copyWith(
              syncing: false,
              load: value.load,
              balance: balance.valueOrNull ?? state.balance,
            ),
            WeeklyLoadNotice.synced(
              xpAwarded: value.xpAwarded,
              account: account,
            ),
          ),
        );
    }
  }
}
