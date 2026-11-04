import '../../domain/enums/training_enums.dart';
import '../../domain/enums/visibility.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/training/routine.dart';
import '../../domain/models/training/routine_draft.dart';
import '../../domain/models/training/training_page.dart';
import '../../domain/repositories/routine_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/training/dto/proposal_dto.dart';
import '../remote_data_source/training/dto/routine_dto.dart';
import '../remote_data_source/training/routine_remote_data_source.dart';
import '../../domain/models/training/routine_template.dart';

class RoutineRepository implements RoutineRepositoryContract {
  RoutineRepository(this._remote);

  final RoutineRemoteDataSource _remote;

  Future<AppResult<Routine>> _routine(Future<RoutineDto> Function() call) =>
      RepositoryErrorHandler.guard(() async => (await call()).toDomain());

  TrainingPage<RoutineSummary> _page(TrainingPage<RoutineSummaryDto> page) =>
      TrainingPage(
        items: page.items.map((r) => r.toDomain()).toList(),
        page: page.page,
        totalPages: page.totalPages,
        totalItems: page.totalItems,
      );

  @override
  Future<AppResult<TrainingPage<RoutineSummary>>> getMyRoutines({
    RoutineStatus? status,
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => _page(
      await _remote.listMine(status: status?.apiValue, page: page, size: size),
    ),
  );

  @override
  Future<AppResult<TrainingPage<RoutineSummary>>> getCommunityRoutines({
    String? query,
    TrainingGoal? goal,
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(() async {
    final q = query?.trim();
    return _page(
      await _remote.community(
        query: q == null || q.isEmpty ? null : q,
        goal: goal?.apiValue,
        page: page,
        size: size,
      ),
    );
  });

  @override
  Future<AppResult<Routine>> getRoutine(String routineId) =>
      _routine(() => _remote.get(routineId));

  @override
  Future<AppResult<Routine>> createRoutine(RoutineDraft draft) =>
      _routine(() => _remote.create(CreateRoutineRequestDto.fromDomain(draft)));

  @override
  Future<AppResult<Routine>> updateRoutine(
    String routineId, {
    String? name,
    String? description,
    Visibility? visibility,
    TrainingGoal? goal,
    DateTime? startDate,
    bool clearStartDate = false,
  }) => _routine(
    () => _remote.update(routineId, {
      'name': ?name?.trim(),
      'description': ?description,
      'visibility': ?visibility?.apiValue,
      'goal': ?goal?.apiValue,
      if (startDate != null) 'startDate': formatLocalDate(startDate),
      if (clearStartDate) 'clearStartDate': true,
    }),
  );

  @override
  Future<AppResult<Routine>> changeStatus(
    String routineId,
    RoutineStatus status,
  ) => _routine(() => _remote.changeStatus(routineId, status.apiValue));

  @override
  Future<AppResult<Routine>> skipDay(String routineId, String dayId) =>
      _routine(() => _remote.skipDay(routineId, dayId));

  @override
  Future<AppResult<Routine>> unskipDay(String routineId, String dayId) =>
      _routine(() => _remote.unskipDay(routineId, dayId));

  @override
  Future<AppResult<Routine>> restartRoutine(String routineId) =>
      _routine(() => _remote.restart(routineId));

  @override
  Future<AppResult<Unit>> deleteRoutine(String routineId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.delete(routineId);
        return unit;
      });

  @override
  Future<AppResult<Routine>> duplicateRoutine(
    String routineId, {
    String? name,
  }) => _routine(() => _remote.duplicate(routineId, name));

  @override
  Future<AppResult<Routine>> cloneRoutine(String routineId) =>
      _routine(() => _remote.clone(routineId));

  @override
  Future<AppResult<Routine>> addWeek(
    String routineId, {
    String? name,
    WeekType? type,
  }) => _routine(() => _remote.addWeek(routineId, name, type?.apiValue));

  @override
  Future<AppResult<Routine>> updateWeek(
    String routineId,
    String weekId, {
    String? name,
    WeekType? type,
  }) => _routine(
    () => _remote.updateWeek(routineId, weekId, name, type?.apiValue),
  );

  @override
  Future<AppResult<Routine>> deleteWeek(String routineId, String weekId) =>
      _routine(() => _remote.deleteWeek(routineId, weekId));

  @override
  Future<AppResult<Routine>> addDay(
    String routineId,
    String weekId, {
    required int dayNumber,
    String? name,
  }) => _routine(() => _remote.addDay(routineId, weekId, dayNumber, name));

  @override
  Future<AppResult<Routine>> renameDay(
    String routineId,
    String dayId,
    String name,
  ) => _routine(() => _remote.renameDay(routineId, dayId, name.trim()));

  @override
  Future<AppResult<Routine>> deleteDay(String routineId, String dayId) =>
      _routine(() => _remote.deleteDay(routineId, dayId));

  @override
  Future<AppResult<Routine>> addExercise(
    String routineId,
    String dayId, {
    required String exerciseId,
    required ExerciseParameters parameters,
  }) => _routine(
    () => _remote.addExercise(
      routineId,
      dayId,
      ProposedExerciseDto.fromDomain(
        DraftExercise(
          exerciseId: exerciseId,
          exerciseName: '',
          parameters: parameters,
        ),
      ),
    ),
  );

  @override
  Future<AppResult<Routine>> reorderExercises(
    String routineId,
    String dayId,
    List<String> plannedExerciseIds,
  ) => _routine(() => _remote.reorder(routineId, dayId, plannedExerciseIds));

  @override
  Future<AppResult<Routine>> updateExercise(
    String routineId,
    String plannedExerciseId,
    ExerciseParameters parameters,
  ) => _routine(
    () => _remote.updateExercise(
      routineId,
      plannedExerciseId,
      parametersToJson(parameters),
    ),
  );

  @override
  Future<AppResult<Routine>> replaceExercise(
    String routineId,
    String plannedExerciseId,
    String exerciseId,
  ) => _routine(
    () => _remote.replaceExercise(routineId, plannedExerciseId, exerciseId),
  );

  @override
  Future<AppResult<Routine>> removeExercise(
    String routineId,
    String plannedExerciseId,
  ) => _routine(() => _remote.removeExercise(routineId, plannedExerciseId));

  @override
  Future<AppResult<RoutineProposal>> generateRoutine({
    required int durationWeeks,
    TrainingGoal? goal,
    bool useAi = true,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.generate(
      durationWeeks: durationWeeks,
      goal: goal?.apiValue,
      useAi: useAi,
    )).toDomain(),
  );

  @override
  Future<AppResult<RoutineProposal>> refineRoutine(RoutineProposal proposal) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.refine(
          RoutineProposalDto.fromDomain(proposal),
        )).toDomain(),
      );

  @override
  Future<AppResult<List<RoutineTemplate>>> listTemplates() =>
      RepositoryErrorHandler.guard(
        () async => [for (final t in await _remote.templates()) t.toDomain()],
      );

  @override
  Future<AppResult<Routine>> useTemplate(String templateId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.useTemplate(templateId)).toDomain(),
      );
}

/// Cuerpo `ExerciseParametersRequest` sin campos nulos.
Map<String, dynamic> parametersToJson(ExerciseParameters p) => {
  'sets': p.sets,
  'reps': p.reps,
  'restSeconds': p.restSeconds,
  'weightKg': ?p.weightKg,
  'weightsKg': ?p.weightsKg,
  'targetDurationSeconds': ?p.targetDurationSeconds,
  'distanceMeters': ?p.distanceMeters,
  'isometricSeconds': ?p.isometricSeconds,
  'repsPerSet': ?p.repsPerSet,
  'isometricSecondsPerSet': ?p.isometricSecondsPerSet,
};
