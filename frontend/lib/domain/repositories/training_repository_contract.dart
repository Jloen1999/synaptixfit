import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/training/load_suggestion.dart';
import '../models/training/recommendation.dart';
import '../models/training/routine.dart';
import '../models/training/session.dart';
import '../models/training/session_adaptation.dart';
import '../models/training/training_page.dart';
import '../models/training/wellbeing.dart';

/// Sesiones, día pendiente, check-in, plan semanal y sugerencias (`/api/v1/training`).
abstract interface class TrainingRepositoryContract {
  /// Próximo día pendiente; `null` si no hay rutina activa con días pendientes.
  Future<AppResult<PendingDay?>> getPendingDay();

  /// Empieza (o recupera si ya está en curso) una sesión. Sin día: sesión libre.
  Future<AppResult<TrainingSession>> startSession({
    String? routineId,
    String? dayId,
  });

  Future<AppResult<TrainingSession>> getSession(String sessionId);

  /// Adaptación de hoy de la sesión (regulación cruzada).
  Future<AppResult<SessionAdaptation>> getSessionAdaptation(String sessionId);

  /// Propuestas de carga de hoy por ejercicio (vacía si no hay).
  Future<AppResult<List<LoadSuggestion>>> getLoadSuggestions(String sessionId);

  Future<AppResult<TrainingPage<TrainingSession>>> getSessions({
    bool? completed,
    int page = 0,
    int size = 20,
  });

  Future<AppResult<TrainingSession>> recordSet(
    String sessionId,
    SetRecord record,
  );

  Future<AppResult<TrainingSession>> deleteSet(String sessionId, String setId);

  /// [realDurations]: segundos reales por ejercicio planificado.
  Future<AppResult<FinishSessionResult>> finishSession(
    String sessionId, {
    required int durationSeconds,
    required int rpe,
    Map<String, int> realDurations = const {},
    List<SetRecord> sets = const [],
  });

  Future<AppResult<UnmarkSessionResult>> unmarkSession(String sessionId);

  /// Descarta una sesión sin terminar o elimina una terminada (el servidor
  /// resta su XP y retira su carga).
  Future<AppResult<Unit>> deleteSession(String sessionId);

  /// Sesiones sin terminar, más recientes primero.
  Future<AppResult<List<OpenSession>>> getOpenSessions();

  /// Corrige el RPE y la duración (minutos) de una sesión terminada.
  Future<AppResult<TrainingSession>> correctSession(
    String sessionId, {
    required int rpe,
    required int durationMinutes,
  });

  /// Registra un día de rutina entrenado sin la app (hoy o hasta 7 días antes).
  Future<AppResult<PastSessionResult>> logPastSession({
    required String routineId,
    required String dayId,
    required DateTime date,
    required int durationMinutes,
    required int rpe,
  });

  /// Check-in de hoy; `null` si todavía no se ha hecho.
  Future<AppResult<CheckIn?>> getTodayCheckIn();

  Future<AppResult<CheckInResult>> submitCheckIn(CheckInInput input);

  Future<AppResult<TrainingPage<CheckIn>>> getCheckIns({
    int page = 0,
    int size = 20,
  });

  /// Plan de la semana que contiene [weekStart]; `null` si no hay.
  Future<AppResult<WeeklyPlan?>> getWeeklyPlan(DateTime weekStart);

  Future<AppResult<WeeklyPlan>> saveWeeklyPlan(
    DateTime weekStart,
    WeeklyPlanInput input,
  );

  Future<AppResult<Unit>> deleteWeeklyPlan(DateTime weekStart);

  Future<AppResult<TrainingPage<WeeklyPlan>>> getWeeklyPlans({
    int page = 0,
    int size = 20,
  });

  Future<AppResult<TrainingPage<Recommendation>>> getRecommendations({
    bool? applied,
    int page = 0,
    int size = 20,
  });

  Future<AppResult<Recommendation>> applyRecommendation(
    String recommendationId,
  );

  Future<AppResult<Unit>> discardRecommendation(String recommendationId);

  /// Peso corporal del perfil de bienestar (para estimar calorías); `null` si no hay.
  Future<AppResult<double?>> getBodyWeight();
}
