part of 'live_session_bloc.dart';

enum LiveStatus { loading, ready, failure }

@freezed
abstract class LiveSessionState with _$LiveSessionState {
  const factory LiveSessionState({
    @Default(LiveStatus.loading) LiveStatus status,
    String? sessionId,
    TrainingSession? session,
    AppError? error,

    /// Ejercicios planificados del día (vacío en sesión libre).
    @Default(<PlannedExercise>[]) List<PlannedExercise> exercises,
    String? routineName,
    int? dayNumber,
    String? dayName,

    /// Cronómetro total en segundos desde el inicio de la sesión.
    @Default(0) int elapsedSeconds,
    String? activeExerciseId,

    /// Duración real acumulada por ejercicio planificado.
    @Default(<String, int>{}) Map<String, int> exerciseSeconds,

    /// Descanso en curso (segundos restantes) y su duración inicial.
    int? restRemaining,
    @Default(0) int restTotal,
    @Default(false) bool saving,
    @Default(false) bool finishing,
    TrainingEffect? effect,

    /// Mejor serie de la última vez en cada ejercicio (por id de ejercicio).
    @Default(<String, PersonalRecord>{})
    Map<String, PersonalRecord> lastPerformance,

    /// Calentamiento y vuelta a la calma sugeridos para los ejercicios del día.
    SessionBookends? bookends,
  }) = _LiveSessionState;

  const LiveSessionState._();

  bool get isFree => exercises.isEmpty;

  bool get completed => session?.isCompleted ?? false;

  /// Series completadas frente a las planificadas.
  int get completedSets => session?.sets.where((s) => s.completed).length ?? 0;

  int get plannedSets => exercises.fold(0, (sum, e) => sum + e.parameters.sets);
}
