import '../models/planner/block_draft.dart';
import '../models/planner/calendar_block.dart';
import '../models/planner/calendar_feed.dart';
import '../models/planner/planner_ai.dart';
import '../models/planner/planner_options.dart';
import '../models/planner/weekly_planning.dart';
import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/training/sport_activity.dart';

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

  /// Lleva el bloque al primer hueco libre de su duración (lo busca el servidor).
  Future<AppResult<BlockChange>> rescheduleToNextFreeSlot(String blockId);

  Future<AppResult<BlockCompletion>> setBlockCompletion(
    String blockId, {
    required bool completed,
    int? effort,
  });

  /// Actividad física ya pasada: bloque de deporte completado con su esfuerzo.
  Future<AppResult<BlockCompletion>> logPastActivity({
    required DateTime start,
    required int minutes,
    required int effort,
    String? title,
    ActivityKind? kind,
    int? distanceMeters,
  });

  /// Estudio ya hecho (últimos 7 días): bloque de estudio completado.
  Future<AppResult<BlockCompletion>> logPastStudy({
    required DateTime start,
    required int minutes,
    String? subjectId,
    String? title,
  });

  Future<AppResult<List<CalendarBlock>>> distributeRoutine(
    RoutineDistribution request,
  );

  Future<AppResult<List<BlockConflict>>> getConflicts(DateTime weekStart);

  // ------------------------------------------------------------ planificación
  // La experiencia de planificar la semana la da el servidor sola (ADR 0038).

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

  /// Suscripción al calendario (enlace privado .ics).
  Future<AppResult<CalendarFeedStatus>> getCalendarFeed();

  Future<AppResult<CalendarFeedLink>> createCalendarFeed();

  Future<AppResult<Unit>> revokeCalendarFeed();

  Future<AppResult<IcsImportResult>> importIcs({
    required String subjectId,
    String? url,
    bool force = false,
  });

  /// Calendario general (Campus Virtual): solo exámenes y entregas.
  Future<AppResult<IcsImportResult>> importGeneralCalendar({
    required String url,
  });

  /// Contenido `.ics` del calendario del usuario.
  Future<AppResult<String>> exportIcs();

  // ----------------------------------------------------------------- catálogos
  Future<AppResult<List<SubjectOption>>> getSubjects();

  Future<AppResult<List<RoutineOption>>> getRoutines();

  Future<AppResult<List<ChallengeOption>>> getChallenges();
}
