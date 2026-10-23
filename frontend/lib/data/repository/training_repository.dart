import '../../domain/errors/app_error.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/models/training/recommendation.dart';
import '../../domain/models/training/routine.dart';
import '../../domain/models/training/session.dart';
import '../../domain/models/training/training_page.dart';
import '../../domain/models/training/wellbeing.dart';
import '../../domain/repositories/training_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/training/dto/routine_dto.dart';
import '../remote_data_source/training/dto/session_dto.dart';
import '../remote_data_source/training/dto/wellbeing_dto.dart';
import '../remote_data_source/training/training_remote_data_source.dart';

class TrainingRepository implements TrainingRepositoryContract {
  TrainingRepository(this._remote);

  final TrainingRemoteDataSource _remote;

  TrainingPage<R> _page<D, R>(TrainingPage<D> page, R Function(D) map) =>
      TrainingPage(
        items: page.items.map(map).toList(),
        page: page.page,
        totalPages: page.totalPages,
        totalItems: page.totalItems,
      );

  @override
  Future<AppResult<PendingDay?>> getPendingDay() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.pendingDay())?.toDomain(),
      );

  @override
  Future<AppResult<TrainingSession>> startSession({
    String? routineId,
    String? dayId,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.startSession(routineId, dayId)).toDomain(),
  );

  @override
  Future<AppResult<TrainingSession>> getSession(String sessionId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getSession(sessionId)).toDomain(),
      );

  @override
  Future<AppResult<TrainingPage<TrainingSession>>> getSessions({
    bool? completed,
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => _page(
      await _remote.listSessions(completed: completed, page: page, size: size),
      (SessionDto s) => s.toDomain(),
    ),
  );

  @override
  Future<AppResult<TrainingSession>> recordSet(
    String sessionId,
    SetRecord record,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.recordSet(
      sessionId,
      RecordSetRequestDto.fromDomain(record),
    )).toDomain(),
  );

  @override
  Future<AppResult<TrainingSession>> deleteSet(
    String sessionId,
    String setId,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.deleteSet(sessionId, setId)).toDomain(),
  );

  @override
  Future<AppResult<FinishSessionResult>> finishSession(
    String sessionId, {
    required int durationSeconds,
    required int rpe,
    Map<String, int> realDurations = const {},
    List<SetRecord> sets = const [],
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.finish(sessionId, {
      'durationSeconds': durationSeconds,
      'rpe': rpe,
      if (realDurations.isNotEmpty) 'realDurations': realDurations,
      if (sets.isNotEmpty)
        'sets': sets
            .map((s) => RecordSetRequestDto.fromDomain(s).toJson())
            .toList(),
    })).toDomain(),
  );

  @override
  Future<AppResult<UnmarkSessionResult>> unmarkSession(String sessionId) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.unmark(sessionId)).toDomain(),
      );

  @override
  Future<AppResult<Unit>> cancelSession(String sessionId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.cancel(sessionId);
        return unit;
      });

  @override
  Future<AppResult<CheckIn?>> getTodayCheckIn() => RepositoryErrorHandler.guard(
    () async => (await _remote.todayCheckIn())?.toDomain(),
  );

  @override
  Future<AppResult<CheckInResult>> submitCheckIn(CheckInInput input) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.submitCheckIn(
          CheckInRequestDto.fromDomain(input),
        )).toDomain(),
      );

  @override
  Future<AppResult<TrainingPage<CheckIn>>> getCheckIns({
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => _page(
      await _remote.listCheckIns(page: page, size: size),
      (CheckInDto c) => c.toDomain(),
    ),
  );

  @override
  Future<AppResult<WeeklyPlan?>> getWeeklyPlan(DateTime weekStart) async {
    final result = await RepositoryErrorHandler.guard<WeeklyPlan?>(
      () async =>
          (await _remote.getPlan(formatLocalDate(weekStart))).toDomain(),
    );
    // Sin plan para esa semana no es un error para la interfaz.
    return switch (result) {
      Failure(error: BusinessError(code: 'TRAINING_PLAN_NOT_FOUND')) ||
      Failure(error: NotFoundError()) => const Success(null),
      _ => result,
    };
  }

  @override
  Future<AppResult<WeeklyPlan>> saveWeeklyPlan(
    DateTime weekStart,
    WeeklyPlanInput input,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.savePlan(
      formatLocalDate(weekStart),
      WeeklyPlanRequestDto.fromDomain(input),
    )).toDomain(),
  );

  @override
  Future<AppResult<Unit>> deleteWeeklyPlan(DateTime weekStart) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deletePlan(formatLocalDate(weekStart));
        return unit;
      });

  @override
  Future<AppResult<TrainingPage<WeeklyPlan>>> getWeeklyPlans({
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => _page(
      await _remote.listPlans(page: page, size: size),
      (WeeklyPlanDto p) => p.toDomain(),
    ),
  );

  @override
  Future<AppResult<TrainingPage<Recommendation>>> getRecommendations({
    bool? applied,
    int page = 0,
    int size = 20,
  }) => RepositoryErrorHandler.guard(
    () async => _page(
      await _remote.recommendations(applied: applied, page: page, size: size),
      (r) => r.toDomain(),
    ),
  );

  @override
  Future<AppResult<Recommendation>> applyRecommendation(
    String recommendationId,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.apply(recommendationId)).toDomain(),
  );

  @override
  Future<AppResult<Unit>> discardRecommendation(String recommendationId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.discard(recommendationId);
        return unit;
      });

  @override
  Future<AppResult<double?>> getBodyWeight() =>
      RepositoryErrorHandler.guard(() async {
        final weight = (await _remote.bodyWeight()).weightKg;
        return weight == null || weight <= 0 ? null : weight;
      });
}
