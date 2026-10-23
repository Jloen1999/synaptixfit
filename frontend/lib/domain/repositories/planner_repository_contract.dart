import '../models/planner/block_draft.dart';
import '../models/planner/calendar_block.dart';
import '../models/planner/planner_ai.dart';
import '../models/planner/planner_options.dart';
import '../models/planner/weekly_planning.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';

/// Calendario semanal, planificación, IA, ICS y catálogos auxiliares del planner.
abstract interface class PlannerRepositoryContract {
  // ------------------------------------------------------------------ bloques
  /// Bloques que se solapan con [from, to).
  Future<AppResult<List<CalendarBlock>>> getBlocks({
    required DateTime from,
    required DateTime to,
  });

  Future<AppResult<BlockChange>> createBlock(BlockDraft draft);

  Future<AppResult<CalendarBlock>> updateBlock(
    String blockId,
    BlockDraft draft,
  );

  /// Nuevo horario (mover o redimensionar).
  Future<AppResult<BlockChange>> rescheduleBlock(
    String blockId, {
    required DateTime start,
    required DateTime end,
  });

  Future<AppResult<Unit>> deleteBlock(String blockId);

  Future<AppResult<BlockCompletion>> setBlockCompletion(
    String blockId, {
    required bool completed,
  });

  Future<AppResult<List<CalendarBlock>>> distributeRoutine(
    RoutineDistribution request,
  );

  Future<AppResult<List<BlockConflict>>> getConflicts(DateTime weekStart);

  // ------------------------------------------------------------ planificación
  Future<AppResult<SavedPlan>> savePlan(DateTime weekStart);

  /// Carga guardada de la semana; `null` si aún no existe.
  Future<AppResult<WeeklyLoad?>> getWeeklyLoad(DateTime weekStart);

  Future<AppResult<WeeklyLoad>> updateWellbeing(
    DateTime weekStart, {
    int? stressLevel,
    double? sleepHours,
    String? notes,
  });

  Future<AppResult<WeeklyLoadSync>> syncWeeklyLoad(DateTime weekStart);

  Future<AppResult<WeekBalance>> getBalance(DateTime weekStart);

  Future<AppResult<List<TimelineEntry>>> getTimeline({
    required DateTime from,
    required DateTime to,
  });

  // ------------------------------------------------------------------- IA/ICS
  Future<AppResult<WeekSuggestion>> suggestWeek({
    required DateTime weekStart,
    required double studyHours,
    required int sportSessions,
  });

  Future<AppResult<ScheduleScanResult>> scanSchedule(
    ScheduleFile file, {
    void Function(double progress)? onProgress,
  });

  /// Guarda las fechas del semestre en el perfil académico.
  Future<AppResult<Unit>> saveSemesterDates({
    required DateTime start,
    required DateTime end,
  });

  Future<AppResult<IcsImportResult>> importIcs({
    required String subjectId,
    String? url,
    bool force = false,
  });

  /// Contenido `.ics` del calendario del usuario.
  Future<AppResult<String>> exportIcs();

  // ----------------------------------------------------------------- catálogos
  Future<AppResult<List<SubjectOption>>> getSubjects();

  Future<AppResult<List<RoutineOption>>> getRoutines();

  Future<AppResult<List<ChallengeOption>>> getChallenges();
}
