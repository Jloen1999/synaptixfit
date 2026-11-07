part of 'run_home_bloc.dart';

enum RunHomeStatus { loading, ready, failure }

/// Avisos de éxito de Correr.
enum RunHomeNotice {
  /// «Puesto en el calendario».
  scheduled,

  /// Carreras que esperaban conexión ya subidas.
  uploaded,
}

@freezed
abstract class RunHomeState with _$RunHomeState {
  const factory RunHomeState({
    @Default(RunHomeStatus.loading) RunHomeStatus status,
    AppError? error,

    /// Si este dispositivo graba con GPS (no en web ni escritorio).
    @Default(true) bool supported,
    RunWeek? week,
    @Default(<SportActivity>[]) List<SportActivity> activities,
    @Default(0) int totalActivities,
    @Default(<RunWorkout>[]) List<RunWorkout> workouts,
    @Default(<RunWorkout>[]) List<RunWorkout> templates,
    @Default(<PlannedRun>[]) List<PlannedRun> planned,

    /// Carreras terminadas que esperan conexión.
    @Default(0) int pendingUploads,

    /// Carrera sin terminar guardada en el teléfono («Seguir grabando»).
    RunRecording? unfinished,

    /// «Estás aquí» (solo con el permiso ya dado).
    (double, double)? here,
    RunHomeNotice? notice,
    AppError? actionError,
  }) = _RunHomeState;
}
