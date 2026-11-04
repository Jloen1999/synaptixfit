import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/training/cycle.dart';
import '../../../../../domain/use_cases/training/change_cycle_tracking_use_case.dart';
import '../../../../../domain/use_cases/training/delete_cycle_day_use_case.dart';
import '../../../../../domain/use_cases/training/delete_cycle_history_use_case.dart';
import '../../../../../domain/use_cases/training/get_cycle_overview_use_case.dart';
import '../../../../../domain/use_cases/training/list_cycle_days_use_case.dart';
import '../../../../../domain/use_cases/training/log_cycle_day_use_case.dart';

part 'cycle_bloc.freezed.dart';
part 'cycle_event.dart';
part 'cycle_state.dart';

/// «Mi ciclo» (opcional, ADR 0033): activar con consentimiento, apuntar el día,
/// ver el mes y borrar. La estimación del momento la hace el servidor.
class CycleBloc extends Bloc<CycleEvent, CycleState> {
  CycleBloc({
    required this._getOverview,
    required this._change,
    required this._logDay,
    required this._listDays,
    required this._deleteDay,
    required this._deleteHistory,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(CycleState(month: _firstOfMonth((now ?? DateTime.now)()))) {
    on<CycleStarted>((_, emit) => _load(emit));
    on<CycleMonthChanged>((event, emit) async {
      emit(state.copyWith(month: _firstOfMonth(event.month)));
      await _loadDays(emit);
    });
    on<CycleEnabled>(
      (event, emit) => _apply(
        emit,
        () => _change(enabled: true, consent: event.consent),
        CycleNotice.saved,
      ),
    );
    on<CycleDisabled>(
      (event, emit) => _apply(
        emit,
        () => _change(enabled: false, deleteHistory: event.deleteHistory),
        CycleNotice.disabled,
      ),
    );
    on<CycleDayLogged>(
      (event, emit) =>
          _apply(emit, () => _logDay(event.day), CycleNotice.saved),
    );
    on<CycleDayDeleted>((event, emit) async {
      emit(state.copyWith(saving: true, actionError: null, notice: null));
      final result = await _deleteDay(event.date);
      await _afterAction(emit, result.errorOrNull, CycleNotice.deleted);
    });
    on<CycleHistoryDeleted>((_, emit) async {
      emit(state.copyWith(saving: true, actionError: null, notice: null));
      final result = await _deleteHistory();
      await _afterAction(emit, result.errorOrNull, CycleNotice.historyDeleted);
    });
  }

  final GetCycleOverviewUseCaseContract _getOverview;
  final ChangeCycleTrackingUseCaseContract _change;
  final LogCycleDayUseCaseContract _logDay;
  final ListCycleDaysUseCaseContract _listDays;
  final DeleteCycleDayUseCaseContract _deleteDay;
  final DeleteCycleHistoryUseCaseContract _deleteHistory;
  final DateTime Function() _now;

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _load(Emitter<CycleState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    final result = await _getOverview();
    switch (result.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(loading: false, error: error));
        return;
      case null:
        break;
    }
    final overview = result.valueOrNull!;
    emit(state.copyWith(loading: false, overview: overview));
    if (overview.enabled) await _loadDays(emit);
  }

  Future<void> _loadDays(Emitter<CycleState> emit) async {
    if (!(state.overview?.enabled ?? false)) return;
    final from = state.month;
    var to = DateTime(from.year, from.month + 1, 0);
    final today = _dateOnly(_now());
    if (to.isAfter(today)) to = today;
    if (from.isAfter(today)) {
      emit(state.copyWith(days: const {}, daysLoading: false, daysError: null));
      return;
    }
    emit(state.copyWith(daysLoading: true, daysError: null));
    final result = await _listDays(from, to);
    switch (result.errorOrNull) {
      case final AppError error:
        // Sin conexión no se pintan días vacíos: se avisa con «Reintentar».
        emit(state.copyWith(days: const {}, daysLoading: false, daysError: error));
      case null:
        emit(
          state.copyWith(
            daysLoading: false,
            days: {for (final d in result.valueOrNull!) _dateOnly(d.date): d},
          ),
        );
    }
  }

  Future<void> _apply(
    Emitter<CycleState> emit,
    Future<AppResult<CycleOverview>> Function() action,
    CycleNotice notice,
  ) async {
    emit(state.copyWith(saving: true, actionError: null, notice: null));
    final result = await action();
    if (result.valueOrNull case final overview?) {
      emit(state.copyWith(overview: overview));
    }
    await _afterAction(emit, result.errorOrNull, notice);
  }

  Future<void> _afterAction(
    Emitter<CycleState> emit,
    AppError? error,
    CycleNotice notice,
  ) async {
    if (error != null) {
      emit(state.copyWith(saving: false, actionError: error));
      return;
    }
    emit(state.copyWith(saving: false, notice: notice));
    if (notice != CycleNotice.saved) {
      final overview = await _getOverview();
      if (overview.valueOrNull case final o?) {
        emit(state.copyWith(overview: o, days: o.enabled ? state.days : {}));
      }
    }
    await _loadDays(emit);
    if (!(state.overview?.enabled ?? false)) {
      emit(state.copyWith(days: const {}));
    }
  }
}
