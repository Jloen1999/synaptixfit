import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/enums/visibility.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/app_result.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/use_cases/training/add_routine_day_use_case.dart';
import '../../../../../domain/use_cases/training/add_routine_exercise_use_case.dart';
import '../../../../../domain/use_cases/training/add_routine_week_use_case.dart';
import '../../../../../domain/use_cases/training/change_routine_status_use_case.dart';
import '../../../../../domain/use_cases/training/clone_routine_use_case.dart';
import '../../../../../domain/use_cases/training/delete_routine_day_use_case.dart';
import '../../../../../domain/use_cases/training/delete_routine_use_case.dart';
import '../../../../../domain/use_cases/training/delete_routine_week_use_case.dart';
import '../../../../../domain/use_cases/training/duplicate_routine_use_case.dart';
import '../../../../../domain/use_cases/training/get_body_weight_use_case.dart';
import '../../../../../domain/use_cases/training/get_routine_use_case.dart';
import '../../../../../domain/use_cases/training/remove_routine_exercise_use_case.dart';
import '../../../../../domain/use_cases/training/rename_routine_day_use_case.dart';
import '../../../../../domain/use_cases/training/reorder_routine_exercises_use_case.dart';
import '../../../../../domain/use_cases/training/start_session_use_case.dart';
import '../../../../../domain/use_cases/training/update_routine_exercise_use_case.dart';
import '../../../../../domain/use_cases/training/update_routine_use_case.dart';
import '../../../../../domain/use_cases/training/update_routine_week_use_case.dart';
import '../../training_effect.dart';

part 'routine_detail_bloc.freezed.dart';
part 'routine_detail_event.dart';
part 'routine_detail_state.dart';

/// Casos de uso que necesita el detalle de rutina (agrupados para no
/// alargar el constructor del bloc).
class RoutineDetailUseCases {
  const RoutineDetailUseCases({
    required this.getRoutine,
    required this.getBodyWeight,
    required this.updateRoutine,
    required this.changeStatus,
    required this.deleteRoutine,
    required this.duplicateRoutine,
    required this.cloneRoutine,
    required this.addWeek,
    required this.updateWeek,
    required this.deleteWeek,
    required this.addDay,
    required this.renameDay,
    required this.deleteDay,
    required this.addExercise,
    required this.reorderExercises,
    required this.updateExercise,
    required this.removeExercise,
    required this.startSession,
  });

  final GetRoutineUseCaseContract getRoutine;
  final GetBodyWeightUseCaseContract getBodyWeight;
  final UpdateRoutineUseCaseContract updateRoutine;
  final ChangeRoutineStatusUseCaseContract changeStatus;
  final DeleteRoutineUseCaseContract deleteRoutine;
  final DuplicateRoutineUseCaseContract duplicateRoutine;
  final CloneRoutineUseCaseContract cloneRoutine;
  final AddRoutineWeekUseCaseContract addWeek;
  final UpdateRoutineWeekUseCaseContract updateWeek;
  final DeleteRoutineWeekUseCaseContract deleteWeek;
  final AddRoutineDayUseCaseContract addDay;
  final RenameRoutineDayUseCaseContract renameDay;
  final DeleteRoutineDayUseCaseContract deleteDay;
  final AddRoutineExerciseUseCaseContract addExercise;
  final ReorderRoutineExercisesUseCaseContract reorderExercises;
  final UpdateRoutineExerciseUseCaseContract updateExercise;
  final RemoveRoutineExerciseUseCaseContract removeExercise;
  final StartSessionUseCaseContract startSession;
}

/// Detalle de rutina con edición en sitio (cada cambio se guarda en la API y
/// devuelve la rutina actualizada), estado, visibilidad, duplicar, borrar y clonar.
class RoutineDetailBloc extends Bloc<RoutineDetailEvent, RoutineDetailState> {
  RoutineDetailBloc(this._uc) : super(const RoutineDetailState()) {
    on<RoutineDetailStarted>(_onStarted);
    on<RoutineDetailRefreshed>(_onRefreshed);
    on<RoutineDetailWeekAdded>(
      (e, emit) => _mutate(emit, (id) => _uc.addWeek(id)),
    );
    on<RoutineDetailWeekRenamed>(
      (e, emit) =>
          _mutate(emit, (id) => _uc.updateWeek(id, e.weekId, name: e.name)),
    );
    on<RoutineDetailWeekDeleted>(
      (e, emit) => _mutate(emit, (id) => _uc.deleteWeek(id, e.weekId)),
    );
    on<RoutineDetailDayAdded>(
      (e, emit) => _mutate(
        emit,
        (id) => _uc.addDay(id, e.weekId, dayNumber: e.dayNumber),
      ),
    );
    on<RoutineDetailDayRenamed>(
      (e, emit) => _mutate(emit, (id) => _uc.renameDay(id, e.dayId, e.name)),
    );
    on<RoutineDetailDayDeleted>(
      (e, emit) => _mutate(emit, (id) => _uc.deleteDay(id, e.dayId)),
    );
    on<RoutineDetailExerciseAdded>(
      (e, emit) => _mutate(
        emit,
        (id) => _uc.addExercise(
          id,
          e.dayId,
          exerciseId: e.exercise.id,
          parameters: e.exercise.defaultParameters,
        ),
      ),
    );
    on<RoutineDetailExerciseRemoved>(
      (e, emit) =>
          _mutate(emit, (id) => _uc.removeExercise(id, e.plannedExerciseId)),
    );
    on<RoutineDetailExerciseMoved>(_onMoved);
    on<RoutineDetailExerciseUpdated>(
      (e, emit) => _mutate(
        emit,
        (id) => _uc.updateExercise(id, e.plannedExerciseId, e.parameters),
      ),
    );
    on<RoutineDetailStatusChanged>(
      (e, emit) => _mutate(emit, (id) => _uc.changeStatus(id, e.status)),
    );
    on<RoutineDetailDetailsUpdated>(
      (e, emit) => _mutate(
        emit,
        (id) => _uc.updateRoutine(
          id,
          name: e.name,
          description: e.description,
          visibility: e.visibility,
          goal: e.goal,
        ),
        message: TrainingMessage.routineUpdated,
      ),
    );
    on<RoutineDetailDuplicated>(_onDuplicated);
    on<RoutineDetailDeleted>(_onDeleted);
    on<RoutineDetailCloned>(_onCloned);
    on<RoutineDetailSessionStarted>(_onSessionStarted);
  }

  final RoutineDetailUseCases _uc;

  Future<void> _onStarted(
    RoutineDetailStarted event,
    Emitter<RoutineDetailState> emit,
  ) async {
    emit(
      RoutineDetailState(
        routineId: event.routineId,
        bodyWeightKg: state.bodyWeightKg,
      ),
    );
    final routineFuture = _uc.getRoutine(event.routineId);
    final weightFuture = _uc.getBodyWeight();
    final result = await routineFuture;
    final weight = (await weightFuture).valueOrNull;
    emit(
      result.fold(
        (routine) => state.copyWith(
          status: RoutineDetailStatus.ready,
          routine: routine,
          bodyWeightKg: weight,
        ),
        (error) => state.copyWith(
          status: RoutineDetailStatus.failure,
          error: error,
          bodyWeightKg: weight,
        ),
      ),
    );
  }

  Future<void> _onRefreshed(
    RoutineDetailRefreshed event,
    Emitter<RoutineDetailState> emit,
  ) async {
    final id = state.routineId;
    if (id == null) return;
    final result = await _uc.getRoutine(id);
    switch (result) {
      case Success(value: final routine):
        emit(
          state.copyWith(
            status: RoutineDetailStatus.ready,
            routine: routine,
            error: null,
          ),
        );
      case Failure(:final error):
        if (state.routine == null) {
          emit(
            state.copyWith(status: RoutineDetailStatus.failure, error: error),
          );
        } else {
          _effect(emit, TrainingEffect.error(error));
        }
    }
  }

  Future<void> _onMoved(
    RoutineDetailExerciseMoved event,
    Emitter<RoutineDetailState> emit,
  ) async {
    final day = state.routine?.dayById(event.dayId);
    if (day == null) return;
    final ids = day.exercises.map((e) => e.id).toList();
    final from = ids.indexOf(event.plannedExerciseId);
    final to = event.up ? from - 1 : from + 1;
    if (from < 0 || to < 0 || to >= ids.length) return;
    ids.insert(to, ids.removeAt(from));
    await _mutate(emit, (id) => _uc.reorderExercises(id, event.dayId, ids));
  }

  Future<void> _onDuplicated(
    RoutineDetailDuplicated event,
    Emitter<RoutineDetailState> emit,
  ) async {
    final id = state.routineId;
    if (id == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _uc.duplicateRoutine(id, name: event.name);
    emit(state.copyWith(busy: false));
    switch (result) {
      case Success(value: final copy):
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.routineDuplicated),
        );
        _effect(emit, TrainingEffect.openRoutine(copy.id, replace: true));
      case Failure(:final error):
        _effect(emit, TrainingEffect.error(error));
    }
  }

  Future<void> _onCloned(
    RoutineDetailCloned event,
    Emitter<RoutineDetailState> emit,
  ) async {
    final id = state.routineId;
    if (id == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _uc.cloneRoutine(id);
    emit(state.copyWith(busy: false));
    switch (result) {
      case Success(value: final copy):
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.routineCloned),
        );
        _effect(emit, TrainingEffect.openRoutine(copy.id, replace: true));
      case Failure(:final error):
        _effect(emit, TrainingEffect.error(error));
    }
  }

  Future<void> _onDeleted(
    RoutineDetailDeleted event,
    Emitter<RoutineDetailState> emit,
  ) async {
    final id = state.routineId;
    if (id == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _uc.deleteRoutine(id);
    emit(state.copyWith(busy: false));
    switch (result) {
      case Success():
        _effect(
          emit,
          const TrainingEffect.message(TrainingMessage.routineDeleted),
        );
        _effect(emit, const TrainingEffect.close());
      case Failure(:final error):
        _effect(emit, TrainingEffect.error(error));
    }
  }

  Future<void> _onSessionStarted(
    RoutineDetailSessionStarted event,
    Emitter<RoutineDetailState> emit,
  ) async {
    final id = state.routineId;
    if (id == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await _uc.startSession(routineId: id, dayId: event.dayId);
    emit(state.copyWith(busy: false));
    _effect(
      emit,
      result.fold(
        (session) => TrainingEffect.openSession(session.id),
        TrainingEffect.error,
      ),
    );
  }

  /// Ejecuta una edición que devuelve la rutina actualizada.
  Future<void> _mutate(
    Emitter<RoutineDetailState> emit,
    Future<AppResult<Routine>> Function(String routineId) call, {
    TrainingMessage? message,
  }) async {
    final id = state.routineId;
    if (id == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final result = await call(id);
    switch (result) {
      case Success(value: final routine):
        emit(state.copyWith(busy: false, routine: routine));
        if (message != null) _effect(emit, TrainingEffect.message(message));
      case Failure(:final error):
        emit(state.copyWith(busy: false));
        _effect(emit, TrainingEffect.error(error));
    }
  }

  void _effect(Emitter<RoutineDetailState> emit, TrainingEffect effect) {
    emit(state.copyWith(effect: effect));
    emit(state.copyWith(effect: null));
  }
}
