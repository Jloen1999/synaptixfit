import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/routine_draft.dart';
import '../../../../../domain/use_cases/training/create_routine_use_case.dart';
import '../../../../../domain/use_cases/training/generate_routine_use_case.dart';
import '../../../../../domain/use_cases/training/refine_routine_use_case.dart';
import '../../training_effect.dart';

part 'routine_editor_bloc.freezed.dart';
part 'routine_editor_event.dart';
part 'routine_editor_state.dart';

/// Creación de rutinas: con IA en pasos (parámetros → propuesta → edición →
/// refinar opcional → guardar) o manual con el mismo editor.
class RoutineEditorBloc extends Bloc<RoutineEditorEvent, RoutineEditorState> {
  RoutineEditorBloc({
    required this._generate,
    required this._refine,
    required this._create,
  }) : super(const RoutineEditorState()) {
    on<RoutineEditorStarted>(_onStarted);
    on<RoutineEditorWeeksParamChanged>(
      (e, emit) => emit(
        state.copyWith(weeksParam: e.weeks.clamp(1, RoutineDraft.maxWeeks)),
      ),
    );
    on<RoutineEditorGoalParamChanged>(
      (e, emit) => emit(state.copyWith(goalParam: e.goal)),
    );
    on<RoutineEditorGenerateRequested>(_onGenerate);
    on<RoutineEditorBackToParameters>(
      (_, emit) => emit(state.copyWith(step: EditorStep.parameters)),
    );
    on<RoutineEditorNameChanged>(
      (e, emit) => _draft(emit, state.draft.copyWith(name: e.name)),
    );
    on<RoutineEditorDescriptionChanged>(
      (e, emit) =>
          _draft(emit, state.draft.copyWith(description: e.description)),
    );
    on<RoutineEditorGoalChanged>(
      (e, emit) => _draft(emit, state.draft.copyWith(goal: e.goal)),
    );
    on<RoutineEditorVisibilityChanged>(
      (e, emit) => _draft(emit, state.draft.copyWith(visibility: e.visibility)),
    );
    on<RoutineEditorWeekAdded>(_onWeekAdded);
    on<RoutineEditorWeekRemoved>(_onWeekRemoved);
    on<RoutineEditorWeekRenamed>(
      (e, emit) =>
          _updateWeek(emit, e.weekIndex, (w) => w.copyWith(name: e.name)),
    );
    on<RoutineEditorDayAdded>(_onDayAdded);
    on<RoutineEditorDayRemoved>(
      (e, emit) => _updateWeek(
        emit,
        e.weekIndex,
        (w) => w.copyWith(days: [...w.days]..removeAt(e.dayIndex)),
      ),
    );
    on<RoutineEditorDayRenamed>(
      (e, emit) => _updateDay(
        emit,
        e.weekIndex,
        e.dayIndex,
        (d) => d.copyWith(name: e.name),
      ),
    );
    on<RoutineEditorExerciseAdded>(_onExerciseAdded);
    on<RoutineEditorExerciseRemoved>(
      (e, emit) => _updateDay(
        emit,
        e.weekIndex,
        e.dayIndex,
        (d) =>
            d.copyWith(exercises: [...d.exercises]..removeAt(e.exerciseIndex)),
      ),
    );
    on<RoutineEditorExerciseMoved>(_onExerciseMoved);
    on<RoutineEditorExerciseReplaced>(
      (e, emit) => _updateDay(emit, e.weekIndex, e.dayIndex, (d) {
        final list = [...d.exercises];
        final current = list[e.exerciseIndex];
        list[e.exerciseIndex] = current.copyWith(
          exerciseId: e.exercise.id,
          exerciseName: e.exercise.name,
          thumbnailUrl: e.exercise.thumbnailUrl,
          met: e.exercise.met,
          parameters: _replacementParameters(
            current.parameters,
            e.exercise.defaultParameters,
          ),
        );
        return d.copyWith(exercises: list);
      }),
    );
    on<RoutineEditorExerciseParametersChanged>(
      (e, emit) => _updateDay(emit, e.weekIndex, e.dayIndex, (d) {
        final list = [...d.exercises];
        list[e.exerciseIndex] = list[e.exerciseIndex].copyWith(
          parameters: e.parameters,
        );
        return d.copyWith(exercises: list);
      }),
    );
    on<RoutineEditorRefineRequested>(_onRefine);
    on<RoutineEditorSaveRequested>(_onSave);
  }

  final GenerateRoutineUseCaseContract _generate;
  final RefineRoutineUseCaseContract _refine;
  final CreateRoutineUseCaseContract _create;

  void _onStarted(
    RoutineEditorStarted event,
    Emitter<RoutineEditorState> emit,
  ) {
    if (!event.manual) {
      emit(const RoutineEditorState());
      return;
    }
    emit(
      const RoutineEditorState(
        aiMode: false,
        step: EditorStep.editing,
        draft: RoutineDraft(
          weeks: [
            DraftWeek(days: [DraftDay(dayNumber: 1)]),
          ],
        ),
      ),
    );
  }

  Future<void> _onGenerate(
    RoutineEditorGenerateRequested event,
    Emitter<RoutineEditorState> emit,
  ) async {
    if (state.busy) return;
    emit(state.copyWith(step: EditorStep.generating));
    final result = await _generate(
      durationWeeks: state.weeksParam,
      goal: state.goalParam,
    );
    switch (result) {
      case Success(value: final proposal):
        emit(
          state.copyWith(
            step: EditorStep.editing,
            proposal: proposal,
            draft: proposal.draft.copyWith(
              goal: proposal.draft.goal ?? state.goalParam,
              visibility: state.draft.visibility,
            ),
            showValidation: false,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(step: EditorStep.parameters));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  void _onWeekAdded(
    RoutineEditorWeekAdded event,
    Emitter<RoutineEditorState> emit,
  ) {
    final weeks = state.draft.weeks;
    if (weeks.length >= RoutineDraft.maxWeeks) return;
    final template = event.copyPrevious && weeks.isNotEmpty
        ? weeks.last.copyWith(name: null, type: null)
        : const DraftWeek(days: [DraftDay(dayNumber: 1)]);
    _draft(emit, state.draft.copyWith(weeks: [...weeks, template]));
  }

  void _onWeekRemoved(
    RoutineEditorWeekRemoved event,
    Emitter<RoutineEditorState> emit,
  ) {
    final weeks = state.draft.weeks;
    if (weeks.length <= 1) return;
    _draft(
      emit,
      state.draft.copyWith(weeks: [...weeks]..removeAt(event.weekIndex)),
    );
  }

  void _onDayAdded(
    RoutineEditorDayAdded event,
    Emitter<RoutineEditorState> emit,
  ) {
    _updateWeek(emit, event.weekIndex, (w) {
      if (w.days.any((d) => d.dayNumber == event.dayNumber)) return w;
      final days = [...w.days, DraftDay(dayNumber: event.dayNumber)]
        ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
      return w.copyWith(days: days);
    });
  }

  void _onExerciseAdded(
    RoutineEditorExerciseAdded event,
    Emitter<RoutineEditorState> emit,
  ) {
    final exercise = event.exercise;
    _updateDay(emit, event.weekIndex, event.dayIndex, (d) {
      if (d.exercises.length >= RoutineDraft.maxExercisesPerDay) return d;
      return d.copyWith(
        exercises: [
          ...d.exercises,
          DraftExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            thumbnailUrl: exercise.thumbnailUrl,
            met: exercise.met,
            parameters: exercise.defaultParameters,
          ),
        ],
      );
    });
  }

  /// Mismo tipo de medida (peso, tiempo, distancia, isométrico): se conservan
  /// los parámetros del usuario. Si cambia, los del nuevo ejercicio con las
  /// series y el descanso que ya tenía (repeticiones con peso no encajan en un
  /// estiramiento por tiempo).
  static ExerciseParameters _replacementParameters(
    ExerciseParameters current,
    ExerciseParameters defaults,
  ) {
    bool sameShape(ExerciseParameters a, ExerciseParameters b) =>
        (a.targetDurationSeconds == null) ==
            (b.targetDurationSeconds == null) &&
        (a.distanceMeters == null) == (b.distanceMeters == null) &&
        (a.isometricSeconds == null) == (b.isometricSeconds == null);
    return sameShape(current, defaults)
        ? current
        : defaults.copyWith(
            sets: current.sets,
            restSeconds: current.restSeconds,
          );
  }

  void _onExerciseMoved(
    RoutineEditorExerciseMoved event,
    Emitter<RoutineEditorState> emit,
  ) {
    _updateDay(emit, event.weekIndex, event.dayIndex, (d) {
      final from = event.exerciseIndex;
      final to = event.up ? from - 1 : from + 1;
      if (to < 0 || to >= d.exercises.length) return d;
      final list = [...d.exercises];
      final item = list.removeAt(from);
      list.insert(to, item);
      return d.copyWith(exercises: list);
    });
  }

  Future<void> _onRefine(
    RoutineEditorRefineRequested event,
    Emitter<RoutineEditorState> emit,
  ) async {
    if (state.busy || state.draft.weeks.isEmpty) return;
    emit(state.copyWith(refining: true));
    final current = state.proposal ?? RoutineProposal(draft: state.draft);
    final result = await _refine(current.copyWith(draft: state.draft));
    switch (result) {
      case Success(value: final refined):
        emit(
          state.copyWith(
            refining: false,
            proposal: refined,
            draft: _keepLocalData(state.draft, refined.draft),
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(refining: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  Future<void> _onSave(
    RoutineEditorSaveRequested event,
    Emitter<RoutineEditorState> emit,
  ) async {
    if (state.busy) return;
    if (!state.canSave) {
      emit(state.copyWith(showValidation: true));
      return;
    }
    emit(state.copyWith(saving: true, showValidation: false));
    final result = await _create(state.draft);
    emit(state.copyWith(saving: false));
    switch (result) {
      case Success(value: final routine):
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.routineSaved),
        );
        _effect(emit, TrainingEffect.openRoutine(routine.id, replace: true));
      case Failure(:final error):
        _effect(emit, TrainingEffect.error(error));
    }
  }

  // ---------------------------------------------------------- utilidades

  /// Conserva datos que la IA no devuelve (visibilidad, fecha, miniaturas, MET).
  RoutineDraft _keepLocalData(RoutineDraft before, RoutineDraft after) {
    final known = <String, DraftExercise>{
      for (final w in before.weeks)
        for (final d in w.days)
          for (final e in d.exercises) e.exerciseId: e,
    };
    return after.copyWith(
      name: after.name.trim().isEmpty ? before.name : after.name,
      description: after.description ?? before.description,
      goal: after.goal ?? before.goal,
      visibility: before.visibility,
      startDate: before.startDate,
      weeks: [
        for (final w in after.weeks)
          w.copyWith(
            days: [
              for (final d in w.days)
                d.copyWith(
                  exercises: [
                    for (final e in d.exercises)
                      e.copyWith(
                        exerciseName: e.exerciseName.isEmpty
                            ? known[e.exerciseId]?.exerciseName ?? ''
                            : e.exerciseName,
                        thumbnailUrl:
                            e.thumbnailUrl ?? known[e.exerciseId]?.thumbnailUrl,
                        met: e.met ?? known[e.exerciseId]?.met,
                      ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  void _draft(Emitter<RoutineEditorState> emit, RoutineDraft draft) =>
      emit(state.copyWith(draft: draft));

  void _updateWeek(
    Emitter<RoutineEditorState> emit,
    int weekIndex,
    DraftWeek Function(DraftWeek week) update,
  ) {
    final weeks = [...state.draft.weeks];
    if (weekIndex < 0 || weekIndex >= weeks.length) return;
    weeks[weekIndex] = update(weeks[weekIndex]);
    _draft(emit, state.draft.copyWith(weeks: weeks));
  }

  void _updateDay(
    Emitter<RoutineEditorState> emit,
    int weekIndex,
    int dayIndex,
    DraftDay Function(DraftDay day) update,
  ) => _updateWeek(emit, weekIndex, (w) {
    if (dayIndex < 0 || dayIndex >= w.days.length) return w;
    final days = [...w.days];
    days[dayIndex] = update(days[dayIndex]);
    return w.copyWith(days: days);
  });

  void _effect(Emitter<RoutineEditorState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
