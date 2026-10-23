import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/wellbeing.dart';
import '../../../../../domain/use_cases/training/delete_weekly_plan_use_case.dart';
import '../../../../../domain/use_cases/training/get_weekly_plan_use_case.dart';
import '../../../../../domain/use_cases/training/get_weekly_plans_use_case.dart';
import '../../../../../domain/use_cases/training/save_weekly_plan_use_case.dart';
import '../../training_effect.dart';

part 'weekly_plan_bloc.freezed.dart';
part 'weekly_plan_event.dart';
part 'weekly_plan_state.dart';

/// Lunes de la semana que contiene [date] (sin hora).
DateTime mondayOf(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// Plan semanal de entrenamiento (sesiones, intensidad, minutos) con cumplimiento.
class WeeklyPlanBloc extends Bloc<WeeklyPlanEvent, WeeklyPlanState> {
  WeeklyPlanBloc({
    required this._getPlan,
    required this._getPlans,
    required this._savePlan,
    required this._deletePlan,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const WeeklyPlanState()) {
    on<WeeklyPlanStarted>(_onStarted);
    on<WeeklyPlanWeekChanged>(_onWeekChanged);
    on<WeeklyPlanInputChanged>(
      (e, emit) => emit(state.copyWith(input: e.input)),
    );
    on<WeeklyPlanSaved>(_onSaved);
    on<WeeklyPlanDeleted>(_onDeleted);
  }

  final GetWeeklyPlanUseCaseContract _getPlan;
  final GetWeeklyPlansUseCaseContract _getPlans;
  final SaveWeeklyPlanUseCaseContract _savePlan;
  final DeleteWeeklyPlanUseCaseContract _deletePlan;
  final DateTime Function() _clock;

  Future<void> _onStarted(
    WeeklyPlanStarted event,
    Emitter<WeeklyPlanState> emit,
  ) async {
    final week = mondayOf(_clock());
    emit(WeeklyPlanState(weekStart: week, currentWeek: week));
    final historyFuture = _getPlans(size: 12);
    await _loadWeek(emit, week);
    final history = await historyFuture;
    emit(state.copyWith(history: history.valueOrNull?.items ?? const []));
  }

  Future<void> _onWeekChanged(
    WeeklyPlanWeekChanged event,
    Emitter<WeeklyPlanState> emit,
  ) async {
    final current = state.weekStart;
    if (current == null) return;
    final week = mondayOf(current.add(Duration(days: 7 * event.delta)));
    emit(state.copyWith(weekStart: week, status: PlanLoadStatus.loading));
    await _loadWeek(emit, week);
  }

  Future<void> _loadWeek(Emitter<WeeklyPlanState> emit, DateTime week) async {
    final result = await _getPlan(week);
    if (state.weekStart != week) return;
    switch (result) {
      case Success(value: final plan):
        emit(
          state.copyWith(
            status: PlanLoadStatus.ready,
            plan: plan,
            input: plan == null
                ? const WeeklyPlanInput()
                : WeeklyPlanInput.fromPlan(plan),
            error: null,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(status: PlanLoadStatus.failure, error: error));
    }
  }

  Future<void> _onSaved(
    WeeklyPlanSaved event,
    Emitter<WeeklyPlanState> emit,
  ) async {
    final week = state.weekStart;
    if (week == null || state.saving) return;
    emit(state.copyWith(saving: true));
    final result = await _savePlan(week, state.input);
    switch (result) {
      case Success(value: final plan):
        emit(
          state.copyWith(
            saving: false,
            plan: plan,
            history: [
              plan,
              ...state.history.where((p) => p.weekStart != plan.weekStart),
            ]..sort((a, b) => b.weekStart.compareTo(a.weekStart)),
          ),
        );
        _effect(emit, const TrainingEffect.message(TrainingMessage.planSaved));
      case Failure(:final error):
        emit(state.copyWith(saving: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  Future<void> _onDeleted(
    WeeklyPlanDeleted event,
    Emitter<WeeklyPlanState> emit,
  ) async {
    final week = state.weekStart;
    if (week == null || state.saving || state.plan == null) return;
    emit(state.copyWith(saving: true));
    final result = await _deletePlan(week);
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            saving: false,
            plan: null,
            input: const WeeklyPlanInput(),
            history: state.history.where((p) => p.weekStart != week).toList(),
          ),
        );
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.planDeleted),
        );
      case Failure(:final error):
        emit(state.copyWith(saving: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  void _effect(Emitter<WeeklyPlanState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
