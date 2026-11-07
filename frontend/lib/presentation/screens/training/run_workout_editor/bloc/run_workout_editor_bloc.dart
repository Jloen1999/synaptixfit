import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/run.dart';
import '../../../../../domain/use_cases/training/create_run_workout_use_case.dart';
import '../../../../../domain/use_cases/training/list_run_workout_templates_use_case.dart';
import '../../../../../domain/use_cases/training/list_run_workouts_use_case.dart';
import '../../../../../domain/use_cases/training/update_run_workout_use_case.dart';

part 'run_workout_editor_bloc.freezed.dart';
part 'run_workout_editor_event.dart';
part 'run_workout_editor_state.dart';

/// Crear o cambiar un entreno de carrera por pasos (ADR 0037): nombre, grupos
/// de pasos y cuántas veces se repite cada grupo. Los límites los valida el
/// servidor; aquí solo se ofrecen valores razonables.
class RunWorkoutEditorBloc
    extends Bloc<RunWorkoutEditorEvent, RunWorkoutEditorState> {
  RunWorkoutEditorBloc({
    required this._create,
    required this._update,
    required this._listWorkouts,
    required this._listTemplates,
  }) : super(const RunWorkoutEditorState()) {
    on<RunWorkoutEditorStarted>(_onStarted);
    on<RunWorkoutEditorNameChanged>(
      (e, emit) => emit(state.copyWith(name: e.name)),
    );
    on<RunWorkoutEditorGroupAdded>(
      (_, emit) => emit(
        state.copyWith(
          groups: [
            ...state.groups,
            const RunStepGroup(
              repeat: 4,
              steps: [
                RunStep(
                  type: RunStepType.run,
                  measure: RunMeasure.time,
                  value: 60,
                ),
                RunStep(
                  type: RunStepType.recover,
                  measure: RunMeasure.time,
                  value: 60,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    on<RunWorkoutEditorGroupRemoved>((e, emit) {
      if (state.groups.length <= 1) return;
      emit(state.copyWith(groups: [...state.groups]..removeAt(e.index)));
    });
    on<RunWorkoutEditorRepeatChanged>(
      (e, emit) =>
          _setGroup(emit, e.index, (g) => g.copyWith(repeat: e.repeat)),
    );
    on<RunWorkoutEditorStepAdded>(
      (e, emit) => _setGroup(
        emit,
        e.index,
        (g) => g.steps.length >= maxSteps
            ? g
            : g.copyWith(
                steps: [
                  ...g.steps,
                  const RunStep(
                    type: RunStepType.recover,
                    measure: RunMeasure.time,
                    value: 60,
                  ),
                ],
              ),
      ),
    );
    on<RunWorkoutEditorStepRemoved>(
      (e, emit) => _setGroup(
        emit,
        e.index,
        (g) => g.steps.length <= 1
            ? g
            : g.copyWith(steps: [...g.steps]..removeAt(e.step)),
      ),
    );
    on<RunWorkoutEditorStepChanged>(
      (e, emit) => _setGroup(
        emit,
        e.index,
        (g) => g.copyWith(steps: [...g.steps]..[e.step] = e.value),
      ),
    );
    on<RunWorkoutEditorSaveRequested>(_onSave);
  }

  /// Pasos por grupo (como el servidor).
  static const maxSteps = 6;

  final CreateRunWorkoutUseCaseContract _create;
  final UpdateRunWorkoutUseCaseContract _update;
  final ListRunWorkoutsUseCaseContract _listWorkouts;
  final ListRunWorkoutTemplatesUseCaseContract _listTemplates;

  static const _blank = [
    RunStepGroup(
      steps: [
        RunStep(type: RunStepType.warmup, measure: RunMeasure.time, value: 300),
      ],
    ),
    RunStepGroup(
      steps: [
        RunStep(type: RunStepType.run, measure: RunMeasure.time, value: 1200),
      ],
    ),
    RunStepGroup(
      steps: [
        RunStep(
          type: RunStepType.cooldown,
          measure: RunMeasure.time,
          value: 300,
        ),
      ],
    ),
  ];

  Future<void> _onStarted(
    RunWorkoutEditorStarted e,
    Emitter<RunWorkoutEditorState> emit,
  ) async {
    var workout = e.workout;
    if (workout == null && e.workoutId != null) {
      final result = await _listWorkouts();
      if (result case Failure(:final error)) {
        emit(state.copyWith(loading: false, error: error));
        return;
      }
      workout = result.valueOrNull!
          .where((w) => w.id == e.workoutId)
          .firstOrNull;
    }
    if (workout != null) {
      emit(
        state.copyWith(
          loading: false,
          workoutId: workout.id,
          name: workout.name,
          templateCode: workout.templateCode,
          groups: workout.groups,
        ),
      );
      return;
    }
    if (e.templateCode != null) {
      final template = (await _listTemplates()).valueOrNull
          ?.where((t) => t.templateCode == e.templateCode)
          .firstOrNull;
      if (template != null) {
        emit(
          state.copyWith(
            loading: false,
            name: e.defaultName,
            templateCode: template.templateCode,
            groups: template.groups,
          ),
        );
        return;
      }
    }
    emit(state.copyWith(loading: false, name: e.defaultName, groups: _blank));
  }

  void _setGroup(
    Emitter<RunWorkoutEditorState> emit,
    int index,
    RunStepGroup Function(RunStepGroup) change,
  ) {
    if (index < 0 || index >= state.groups.length) return;
    emit(
      state.copyWith(
        groups: [...state.groups]..[index] = change(state.groups[index]),
      ),
    );
  }

  Future<void> _onSave(
    RunWorkoutEditorSaveRequested e,
    Emitter<RunWorkoutEditorState> emit,
  ) async {
    if (state.saving || state.name.trim().isEmpty) return;
    emit(state.copyWith(saving: true));
    final workout = RunWorkout(
      id: state.workoutId,
      name: state.name.trim(),
      templateCode: state.templateCode,
      groups: state.groups,
    );
    final result = state.workoutId == null
        ? await _create(workout)
        : await _update(workout);
    switch (result) {
      case Success():
        emit(state.copyWith(saving: false, saved: true));
      case Failure(:final error):
        emit(state.copyWith(saving: false, actionError: error));
        emit(state.copyWith(actionError: null));
    }
  }
}
