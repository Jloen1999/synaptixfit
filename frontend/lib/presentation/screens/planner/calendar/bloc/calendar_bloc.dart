import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/planner/calendar_block.dart';
import '../../../../../domain/models/planner/planner_week.dart';
import '../../../../../domain/models/planner/weekly_planning.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/planner/delete_block_use_case.dart';
import '../../../../../domain/use_cases/planner/get_timeline_use_case.dart';
import '../../../../../domain/use_cases/planner/get_week_balance_use_case.dart';
import '../../../../../domain/use_cases/planner/get_week_blocks_use_case.dart';
import '../../../../../domain/use_cases/planner/get_week_conflicts_use_case.dart';
import '../../../../../domain/use_cases/planner/reschedule_block_use_case.dart';
import '../../../../../domain/use_cases/planner/save_week_plan_use_case.dart';
import '../../../../../domain/use_cases/planner/set_block_completion_use_case.dart';

part 'calendar_bloc.freezed.dart';
part 'calendar_event.dart';
part 'calendar_state.dart';

/// Calendario semanal: carga la semana, mueve/redimensiona bloques, marca
/// completados y guarda el plan.
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc({
    required this._getBlocks,
    required this._getConflicts,
    required this._getTimeline,
    required this._getBalance,
    required this._reschedule,
    required this._setCompletion,
    required this._savePlan,
    required this._getAccount,
    required this._deleteBlock,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(
         CalendarState(
           weekStart: PlannerWeek.mondayOf((now ?? DateTime.now)()),
         ),
       ) {
    on<CalendarStarted>(_onStarted);
    on<CalendarWeekShifted>(_onWeekShifted);
    on<CalendarTodayRequested>(_onToday);
    on<CalendarRefreshed>(_onRefreshed);
    on<CalendarSlotTapped>(_onSlotTapped);
    on<CalendarBlockRescheduled>(_onRescheduled);
    on<CalendarLockedBlockTouched>(_onLockedTouched);
    on<CalendarCompletionToggled>(_onCompletionToggled);
    on<CalendarPlanSaveRequested>(_onSavePlan);
    on<CalendarBlockDeleteRequested>(_onDeleteRequested);
    on<CalendarBlockDeleteUndone>(_onDeleteUndone);
    on<CalendarBlockDeleteCommitted>(_onDeleteCommitted);
  }

  /// Borrados que aún se pueden deshacer, en orden (el último es el de Ctrl+Z).
  final Set<String> _pendingDeletes = {};

  void _onDeleteRequested(
    CalendarBlockDeleteRequested event,
    Emitter<CalendarState> emit,
  ) {
    final id = event.block.id;
    if (!_pendingDeletes.add(id)) return;
    emit(
      _withNotice(
        CalendarNotice.blockDeleted(id),
      ).copyWith(pendingDeletionIds: {...state.pendingDeletionIds, id}),
    );
  }

  void _onDeleteUndone(
    CalendarBlockDeleteUndone event,
    Emitter<CalendarState> emit,
  ) {
    if (!_pendingDeletes.remove(event.blockId)) return;
    emit(
      state.copyWith(
        pendingDeletionIds: {...state.pendingDeletionIds}
          ..remove(event.blockId),
      ),
    );
  }

  Future<void> _onDeleteCommitted(
    CalendarBlockDeleteCommitted event,
    Emitter<CalendarState> emit,
  ) async {
    if (!_pendingDeletes.remove(event.blockId)) return;
    final result = await _deleteBlock(event.blockId);
    final pending = {...state.pendingDeletionIds}..remove(event.blockId);
    switch (result) {
      // Ya no existe (borrado desde otro dispositivo): el resultado es el mismo.
      case Success() || Failure(error: NotFoundError()):
        emit(
          state.copyWith(
            pendingDeletionIds: pending,
            blocks: [
              for (final b in state.blocks)
                if (b.id != event.blockId) b,
            ],
          ),
        );
        add(const CalendarEvent.refreshed());
      case Failure(:final error):
        // No se pudo borrar: el bloque vuelve a verse y se avisa.
        emit(
          _withNotice(
            CalendarNotice.failure(error),
          ).copyWith(pendingDeletionIds: pending),
        );
    }
  }

  /// Al salir de la pantalla, lo pendiente se borra ya (no se puede deshacer).
  /// Si la app se cierra antes, no se borra nada: es la dirección segura.
  @override
  Future<void> close() async {
    final pending = [..._pendingDeletes];
    _pendingDeletes.clear();
    await Future.wait(pending.map((id) => _deleteBlock(id)));
    return super.close();
  }

  final GetWeekBlocksUseCaseContract _getBlocks;
  final GetWeekConflictsUseCaseContract _getConflicts;
  final GetTimelineUseCaseContract _getTimeline;
  final GetWeekBalanceUseCaseContract _getBalance;
  final RescheduleBlockUseCaseContract _reschedule;
  final SetBlockCompletionUseCaseContract _setCompletion;
  final SaveWeekPlanUseCaseContract _savePlan;
  final GetAccountUseCaseContract _getAccount;
  final DeleteBlockUseCaseContract _deleteBlock;
  final DateTime Function() _now;

  CalendarState _withNotice(CalendarNotice notice) =>
      state.copyWith(notice: notice, noticeId: state.noticeId + 1);

  Future<void> _onStarted(CalendarStarted event, Emitter<CalendarState> emit) =>
      _load(emit, PlannerWeek.mondayOf(event.week ?? _now()), silent: false);

  Future<void> _onWeekShifted(
    CalendarWeekShifted event,
    Emitter<CalendarState> emit,
  ) => _load(
    emit,
    PlannerWeek.shift(state.weekStart, event.offset),
    silent: false,
  );

  Future<void> _onToday(
    CalendarTodayRequested event,
    Emitter<CalendarState> emit,
  ) => _load(emit, PlannerWeek.mondayOf(_now()), silent: false);

  Future<void> _onRefreshed(
    CalendarRefreshed event,
    Emitter<CalendarState> emit,
  ) => _load(
    emit,
    state.weekStart,
    silent: state.status == CalendarStatus.ready,
  );

  /// Carga bloques (obligatorio), conflictos, entregas y balance (opcionales).
  Future<void> _load(
    Emitter<CalendarState> emit,
    DateTime weekStart, {
    required bool silent,
  }) async {
    final weekChanged = weekStart != state.weekStart;
    if (!silent || weekChanged) {
      emit(
        state.copyWith(
          weekStart: weekStart,
          status: CalendarStatus.loading,
          error: null,
          blocks: weekChanged ? const [] : state.blocks,
          conflicts: weekChanged ? const [] : state.conflicts,
          deadlines: weekChanged ? const [] : state.deadlines,
          balance: weekChanged ? null : state.balance,
        ),
      );
    }
    final weekEnd = PlannerWeek.endOf(weekStart);
    final blocksF = _getBlocks(weekStart);
    final conflictsF = _getConflicts(weekStart);
    final timelineF = _getTimeline(from: weekStart, to: weekEnd);
    final balanceF = _getBalance(weekStart);
    final blocks = await blocksF;
    final conflicts = await conflictsF;
    final timeline = await timelineF;
    final balance = await balanceF;

    // Si el usuario ya ha cambiado de semana, se descarta este resultado.
    if (state.weekStart != weekStart) return;

    switch (blocks) {
      case Failure(:final error):
        if (silent && state.status == CalendarStatus.ready) {
          emit(_withNotice(CalendarNotice.failure(error)));
        } else {
          emit(state.copyWith(status: CalendarStatus.failure, error: error));
        }
      case Success(:final value):
        final entries = timeline.valueOrNull;
        emit(
          state.copyWith(
            status: CalendarStatus.ready,
            error: null,
            blocks: value,
            conflicts: conflicts.valueOrNull ?? state.conflicts,
            deadlines: entries == null
                ? state.deadlines
                : entries
                      .where((t) => t.kind == TimelineKind.deadline)
                      .toList(),
            blockTitles: entries == null
                ? state.blockTitles
                : {
                    for (final t in entries)
                      if (t.kind == TimelineKind.block &&
                          (t.subjectName ?? t.title) != null)
                        t.id: (t.subjectName ?? t.title)!,
                  },
            balance: balance.valueOrNull ?? state.balance,
          ),
        );
    }
  }

  void _onSlotTapped(CalendarSlotTapped event, Emitter<CalendarState> emit) {
    emit(
      _withNotice(
        event.start.isBefore(_now())
            ? const CalendarNotice.inPast()
            : CalendarNotice.createAt(event.start),
      ),
    );
  }

  void _onLockedTouched(
    CalendarLockedBlockTouched event,
    Emitter<CalendarState> emit,
  ) {
    final block = _find(event.blockId);
    if (block == null) return;
    emit(
      _withNotice(
        block.completed && !block.isLocked
            ? const CalendarNotice.completedLocked()
            : const CalendarNotice.blockLocked(),
      ),
    );
  }

  CalendarBlock? _find(String id) {
    for (final b in state.blocks) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<CalendarBlock> _replace(CalendarBlock block) => [
    for (final b in state.blocks) b.id == block.id ? block : b,
  ];

  Future<void> _onRescheduled(
    CalendarBlockRescheduled event,
    Emitter<CalendarState> emit,
  ) async {
    final original = _find(event.blockId);
    if (original == null || state.busyBlockIds.contains(original.id)) return;
    if (original.start == event.start && original.end == event.end) return;
    if (original.isLocked) {
      emit(_withNotice(const CalendarNotice.blockLocked()));
      return;
    }
    if (original.completed) {
      emit(_withNotice(const CalendarNotice.completedLocked()));
      return;
    }
    if (event.start.isBefore(_now())) {
      emit(_withNotice(const CalendarNotice.inPast()));
      return;
    }

    // Actualización optimista: el bloque se ve ya en su nuevo sitio.
    emit(
      state.copyWith(
        blocks: _replace(original.copyWith(start: event.start, end: event.end)),
        busyBlockIds: {...state.busyBlockIds, original.id},
      ),
    );
    final result = await _reschedule(
      original.id,
      start: event.start,
      end: event.end,
    );
    final busy = {...state.busyBlockIds}..remove(original.id);
    switch (result) {
      case Failure(:final error):
        emit(
          state
              .copyWith(blocks: _replace(original), busyBlockIds: busy)
              .copyWith(
                notice: CalendarNotice.failure(error),
                noticeId: state.noticeId + 1,
              ),
        );
      case Success(:final value):
        emit(state.copyWith(blocks: _replace(value.block), busyBlockIds: busy));
        if (value.conflicts.isNotEmpty) {
          emit(_withNotice(CalendarNotice.overlaps(value.conflicts.length)));
        }
        await _refreshConflicts(emit);
    }
  }

  Future<void> _refreshConflicts(Emitter<CalendarState> emit) async {
    final week = state.weekStart;
    final conflicts = await _getConflicts(week);
    final balance = await _getBalance(week);
    if (state.weekStart != week) return;
    emit(
      state.copyWith(
        conflicts: conflicts.valueOrNull ?? state.conflicts,
        balance: balance.valueOrNull ?? state.balance,
      ),
    );
  }

  Future<Account?> _refreshAccount(int xp) async =>
      xp == 0 ? null : (await _getAccount()).valueOrNull;

  Future<void> _onCompletionToggled(
    CalendarCompletionToggled event,
    Emitter<CalendarState> emit,
  ) async {
    final block = _find(event.blockId);
    if (block == null || state.busyBlockIds.contains(block.id)) return;
    emit(state.copyWith(busyBlockIds: {...state.busyBlockIds, block.id}));
    final result = await _setCompletion(block.id, completed: !block.completed);
    final busy = {...state.busyBlockIds}..remove(block.id);
    switch (result) {
      case Failure(:final error):
        emit(
          state
              .copyWith(busyBlockIds: busy)
              .copyWith(
                notice: CalendarNotice.failure(error),
                noticeId: state.noticeId + 1,
              ),
        );
      case Success(:final value):
        final account = await _refreshAccount(value.xpDelta);
        emit(
          state
              .copyWith(blocks: _replace(value.block), busyBlockIds: busy)
              .copyWith(
                notice: CalendarNotice.blockXp(
                  completed: value.block.completed,
                  xpDelta: value.xpDelta,
                  account: account,
                ),
                noticeId: state.noticeId + 1,
              ),
        );
        await _refreshConflicts(emit);
    }
  }

  Future<void> _onSavePlan(
    CalendarPlanSaveRequested event,
    Emitter<CalendarState> emit,
  ) async {
    if (state.savingPlan) return;
    emit(state.copyWith(savingPlan: true));
    final result = await _savePlan(state.weekStart);
    switch (result) {
      case Failure(:final error):
        emit(
          state
              .copyWith(savingPlan: false)
              .copyWith(
                notice: CalendarNotice.failure(error),
                noticeId: state.noticeId + 1,
              ),
        );
      case Success(:final value):
        final account = await _refreshAccount(value.xpAwarded);
        emit(
          state
              .copyWith(savingPlan: false)
              .copyWith(
                notice: CalendarNotice.planSaved(
                  xpAwarded: value.xpAwarded,
                  blockCount: value.blockCount,
                  account: account,
                ),
                noticeId: state.noticeId + 1,
              ),
        );
    }
  }
}
