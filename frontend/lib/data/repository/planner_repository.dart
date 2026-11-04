import '../../domain/enums/planner_enums.dart';
import '../../domain/models/planner/block_draft.dart';
import '../../domain/models/planner/calendar_block.dart';
import '../../domain/models/planner/calendar_feed.dart';
import '../../domain/models/planner/planner_ai.dart';
import '../../domain/models/planner/planner_options.dart';
import '../../domain/models/planner/planner_week.dart';
import '../../domain/models/planner/weekly_planning.dart';
import '../../domain/models/result/app_result.dart';
import '../../domain/models/result/result.dart';
import '../../domain/repositories/planner_repository_contract.dart';
import '../errors/repository_error_handler.dart';
import '../remote_data_source/planner/dto/planner_json.dart';
import '../remote_data_source/planner/planner_remote_data_source.dart';

class PlannerRepository implements PlannerRepositoryContract {
  PlannerRepository(this._remote);

  final PlannerRemoteDataSource _remote;

  /// Cuerpo común de alta/edición de un bloque.
  static Map<String, dynamic> blockDetailsBody(BlockDraft d) => {
    'type': d.type.apiValue,
    'subjectId': d.subjectId,
    'topics': _blankToNull(d.topics),
    'location': _blankToNull(d.location),
    'priority': d.priority?.apiValue,
    'privateBlock': d.privateBlock,
    'classKind': d.classKind?.apiValue,
    'routineId': d.routineId,
    'routineWeekId': d.routineId == null ? null : d.routineWeekId,
    'routineDayId': d.routineId == null ? null : d.routineDayId,
    'challengeId': d.challengeId,
    'milestoneId': d.challengeId == null ? null : d.milestoneId,
    'deadlineId': d.deadlineId,
  };

  static String? _blankToNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  @override
  Future<AppResult<List<CalendarBlock>>> getBlocks({
    required DateTime from,
    required DateTime to,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.getBlocks(
      PlannerJson.toInstant(from),
      PlannerJson.toInstant(to),
    )).map((b) => b.toDomain()).toList(),
  );

  @override
  Future<AppResult<BlockChange>> createBlock(BlockDraft draft) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.createBlock({
          'start': PlannerJson.toInstant(draft.start),
          'end': PlannerJson.toInstant(draft.end),
          ...blockDetailsBody(draft),
          'deadlineTitle': ?_blankToNull(draft.deadlineTitle),
          'deadlineDifficulty': ?draft.deadlineDifficulty?.apiValue,
          if (draft.repeatWeeks > 0) 'repeatWeeks': draft.repeatWeeks,
        })).toDomain(),
      );

  @override
  Future<AppResult<CalendarBlock>> updateBlock(
    String blockId,
    BlockDraft draft,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.updateBlock(
      blockId,
      blockDetailsBody(draft),
    )).toDomain(),
  );

  @override
  Future<AppResult<BlockChange>> rescheduleToNextFreeSlot(String blockId) =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.rescheduleToNextFreeSlot(blockId)).toDomain(),
      );

  @override
  Future<AppResult<BlockChange>> rescheduleBlock(
    String blockId, {
    required DateTime start,
    required DateTime end,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.rescheduleBlock(
      blockId,
      PlannerJson.toInstant(start),
      PlannerJson.toInstant(end),
    )).toDomain(),
  );

  @override
  Future<AppResult<Unit>> deleteBlock(String blockId) =>
      RepositoryErrorHandler.guard(() async {
        await _remote.deleteBlock(blockId);
        return unit;
      });

  @override
  Future<AppResult<BlockCompletion>> setBlockCompletion(
    String blockId, {
    required bool completed,
    int? effort,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.setBlockCompletion(
      blockId,
      completed: completed,
      effort: effort,
    )).toDomain(),
  );

  @override
  Future<AppResult<BlockCompletion>> logPastActivity({
    required DateTime start,
    required int minutes,
    required int effort,
    String? title,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.logPastActivity({
      'start': PlannerJson.toInstant(start),
      'minutes': minutes,
      'effort': effort,
      if (title != null && title.isNotEmpty) 'title': title,
    })).toDomain(),
  );

  @override
  Future<AppResult<BlockCompletion>> logPastStudy({
    required DateTime start,
    required int minutes,
    String? subjectId,
    String? title,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.logPastActivity({
      'start': PlannerJson.toInstant(start),
      'minutes': minutes,
      'type': BlockType.study.apiValue,
      'subjectId': ?subjectId,
      if (title != null && title.isNotEmpty) 'title': title,
    })).toDomain(),
  );

  @override
  Future<AppResult<List<CalendarBlock>>> distributeRoutine(
    RoutineDistribution request,
  ) => RepositoryErrorHandler.guard(
    () async => (await _remote.distributeRoutine({
      'routineId': request.routineId,
      'weekdays': (request.weekdays.toList()..sort()),
      'startDate': PlannerJson.toDate(request.startDate),
      'preferredStart': PlannerJson.toLocalTime(request.preferredStartMinutes),
      'durationMinutes': request.durationMinutes,
    })).map((b) => b.toDomain()).toList(),
  );

  @override
  Future<AppResult<List<BlockConflict>>> getConflicts(DateTime weekStart) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getConflicts(
          PlannerJson.toDate(weekStart),
        )).map((c) => c.toDomain()).toList(),
      );

  @override
  Future<AppResult<SavedPlan>> savePlan(DateTime weekStart) =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.savePlan(PlannerJson.toDate(weekStart))).toDomain(),
      );

  @override
  Future<AppResult<bool>> isWeekClosed(DateTime weekStart) =>
      RepositoryErrorHandler.guard(
        () => _remote.isWeekClosed(PlannerJson.toDate(weekStart)),
      );

  @override
  Future<AppResult<WeeklyLoad?>> getWeeklyLoad(DateTime weekStart) =>
      RepositoryErrorHandler.guard(() async {
        final date = PlannerJson.toDate(weekStart);
        final loads = await _remote.getWeeklyLoads(date, date);
        return loads.isEmpty ? null : loads.first.toDomain();
      });

  @override
  Future<AppResult<WeeklyLoad>> updateWellbeing(
    DateTime weekStart, {
    int? stressLevel,
    double? sleepHours,
    String? notes,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.updateWellbeing(PlannerJson.toDate(weekStart), {
      'stressLevel': ?stressLevel,
      'sleepHours': ?sleepHours,
      'notes': ?notes,
    })).toDomain(),
  );

  @override
  Future<AppResult<WeeklyLoadSync>> syncWeeklyLoad(DateTime weekStart) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.syncWeeklyLoad(
          PlannerJson.toDate(weekStart),
        )).toDomain(),
      );

  @override
  Future<AppResult<WeekBalance>> getBalance(DateTime weekStart) =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.getBalance(
          PlannerJson.toDate(weekStart),
        )).toDomain(),
      );

  @override
  Future<AppResult<List<TimelineEntry>>> getTimeline({
    required DateTime from,
    required DateTime to,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.getTimeline(
      PlannerJson.toInstant(from),
      PlannerJson.toInstant(to),
    )).map((t) => t.toDomain()).toList(),
  );

  @override
  Future<AppResult<WeekSuggestion>> suggestWeek({
    required DateTime weekStart,
    required double studyHours,
    required int sportSessions,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.suggest({
      'weekStart': PlannerJson.toDate(PlannerWeek.mondayOf(weekStart)),
      'studyHours': studyHours,
      'sportSessions': sportSessions,
    })).toDomain(),
  );

  @override
  Future<AppResult<ScheduleScanResult>> scanSchedule(
    ScheduleFile file, {
    void Function(double progress)? onProgress,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.scanSchedule(
      bytes: file.bytes,
      fileName: file.name,
      mimeType: file.mimeType,
      onProgress: onProgress,
    )).toDomain(),
  );

  @override
  Future<AppResult<Unit>> saveSemesterDates({
    required DateTime start,
    required DateTime end,
  }) => RepositoryErrorHandler.guard(() async {
    await _remote.updateAcademicProfile({
      'classesStartDate': PlannerJson.toDate(start),
      'classesEndDate': PlannerJson.toDate(end),
    });
    return unit;
  });

  @override
  Future<AppResult<IcsImportResult>> importIcs({
    required String subjectId,
    String? url,
    bool force = false,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.importIcs({
      'subjectId': subjectId,
      'url': ?_blankToNull(url),
      'force': force,
    })).toDomain(),
  );

  @override
  Future<AppResult<IcsImportResult>> importGeneralCalendar({
    required String url,
  }) => RepositoryErrorHandler.guard(
    () async => (await _remote.importIcs({'url': url})).toDomain(),
  );

  @override
  Future<AppResult<CalendarFeedStatus>> getCalendarFeed() =>
      RepositoryErrorHandler.guard(
        () async => (await _remote.calendarFeed()).toDomain(),
      );

  @override
  Future<AppResult<CalendarFeedLink>> createCalendarFeed() =>
      RepositoryErrorHandler.guard(() async {
        final dto = await _remote.createCalendarFeed();
        return dto.toDomain(_remote.calendarFeedUrl(dto.token));
      });

  @override
  Future<AppResult<Unit>> revokeCalendarFeed() =>
      RepositoryErrorHandler.guard(() async {
        await _remote.revokeCalendarFeed();
        return unit;
      });

  @override
  Future<AppResult<String>> exportIcs() =>
      RepositoryErrorHandler.guard(_remote.exportIcs);

  @override
  Future<AppResult<List<SubjectOption>>> getSubjects() =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.getSubjects()).map((s) => s.toDomain()).toList(),
      );

  @override
  Future<AppResult<List<RoutineOption>>> getRoutines() =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.getRoutines()).map((r) => r.toDomain()).toList(),
      );

  @override
  Future<AppResult<List<ChallengeOption>>> getChallenges() =>
      RepositoryErrorHandler.guard(
        () async =>
            (await _remote.getChallenges()).map((c) => c.toDomain()).toList(),
      );
}
