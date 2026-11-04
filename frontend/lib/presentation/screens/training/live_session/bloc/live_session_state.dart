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

    /// Inicio de la sesión: el cronómetro total se calcula con el reloj desde
    /// aquí (no sumando tics, que se pierden con la app en segundo plano).
    DateTime? startedAt,

    /// Hasta qué instante se ha sumado ya tiempo al ejercicio activo.
    DateTime? countedUntil,
    String? activeExerciseId,

    /// Duración real acumulada por ejercicio planificado.
    @Default(<String, int>{}) Map<String, int> exerciseSeconds,

    /// Segundos que quedan del descanso en curso (nulo si no hay).
    int? restRemaining,

    /// Cuándo acaba el descanso en curso; [restRemaining] se calcula desde aquí.
    DateTime? restEndsAt,

    /// Adaptación de hoy (examen, carga alta o fatiga); sin motivos si no hay.
    @Default(SessionAdaptation()) SessionAdaptation adaptation,

    /// Series planificadas de cada ejercicio antes de adaptar la sesión: para
    /// enseñar «4 → 3 series» y para «Hacerla completa».
    @Default(<String, int>{}) Map<String, int> plannedSetsById,

    /// Sube cada vez que un descanso llega a cero solo (no al saltarlo): la
    /// pantalla avisa.
    @Default(0) int restFinishedCount,

    /// Duración inicial del descanso en curso (para el anillo de progreso).
    @Default(0) int restTotal,
    @Default(false) bool saving,
    @Default(false) bool finishing,
    TrainingEffect? effect,

    /// Mejor serie de la última vez en cada ejercicio (por id de ejercicio).
    @Default(<String, PersonalRecord>{})
    Map<String, PersonalRecord> lastPerformance,

    /// Propuesta de carga de hoy por id de ejercicio planificado (servidor).
    @Default(<String, LoadSuggestion>{})
    Map<String, LoadSuggestion> loadSuggestions,

    /// Ejercicios cuya propuesta de carga se ha aceptado: sus series sin
    /// apuntar toman la cifra propuesta.
    @Default(<String>{}) Set<String> acceptedLoad,

    /// Calentamiento y vuelta a la calma sugeridos para los ejercicios del día.
    SessionBookends? bookends,

    /// Series apuntadas sin conexión que aún no ha recibido el servidor (en
    /// orden). Se ven en la lista y se suben solas al volver la cobertura.
    @Default(<SetRecord>[]) List<SetRecord> pendingSets,

    /// Cronómetro de la serie (ADR 0030): qué serie se cronometra, desde
    /// cuándo corre (nulo si está en pausa) y los segundos ya contados antes de
    /// la última pausa. Nulo [timerSet]: no hay cronómetro de serie.
    String? timerExerciseId,
    int? timerSet,
    DateTime? timerSince,
    @Default(0) int timerBanked,

    /// Segundos que marca el cronómetro de la serie (para pintar).
    @Default(0) int timerSeconds,

    /// Sesión recién empezada: se explica que el cronómetro está en marcha
    /// (salvo que se pidiera no volver a explicarlo).
    @Default(false) bool explainClock,

    /// Cuándo se reanudó sin que el servidor lo supiera (sin conexión). Se
    /// reintenta con esta hora y, mientras no llegue, no se puede terminar.
    DateTime? resumePendingAt,

    /// Huecos con el ejercicio cambiado solo hoy («Usar hoy», ADR 0031): el
    /// ejercicio de la rutina, para enseñarlo y poder volver a él.
    @Default(<String, PlannedExercise>{})
    Map<String, PlannedExercise> originals,
  }) = _LiveSessionState;

  const LiveSessionState._();

  bool get isFree => exercises.isEmpty;

  bool get completed => session?.isCompleted ?? false;

  /// La sesión está en pausa: el tiempo no corre.
  bool get paused => session?.isPaused ?? false;

  /// El cronómetro de la serie [set] de [exercise] existe (en marcha o en pausa).
  bool timerOn(PlannedExercise exercise, int set) =>
      timerSet == set && timerExerciseId == exercise.id;

  /// Corre el cronómetro de alguna serie.
  bool get timerRunning => timerSet != null && timerSince != null;

  /// Series completadas frente a las planificadas.
  int get completedSets => session?.sets.where((s) => s.completed).length ?? 0;

  int get plannedSets => exercises.fold(0, (sum, e) => sum + e.parameters.sets);

  /// Minutos que quedan según la duración prevista de cada ejercicio (del
  /// servidor), en proporción a sus series sin apuntar. Nulo si el servidor
  /// no la manda; solo orienta: la duración que cuenta es la real.
  int? get remainingEstimatedMinutes {
    if (!exercises.any((e) => e.estimatedSeconds != null)) return null;
    var seconds = 0.0;
    for (final e in exercises) {
      final estimate = e.estimatedSeconds;
      // El servidor la calculó con las series planificadas (no las adaptadas).
      final sets = plannedSetsById[e.id] ?? e.parameters.sets;
      if (estimate == null || sets <= 0) continue;
      final left = (e.parameters.sets - loggedSetsOf(e)).clamp(0, sets);
      seconds += estimate * left / sets;
    }
    return (seconds / 60).ceil();
  }

  /// Series previstas ya apuntadas, enteras o con repeticiones de menos: son
  /// las que cuentan para avanzar y para saber cuántas faltan.
  int get loggedSets =>
      exercises.fold(0, (sum, e) => sum + _loggedSets(session, e));

  /// Series previstas de [exercise] ya apuntadas (ver [loggedSets]).
  int loggedSetsOf(PlannedExercise exercise) => _loggedSets(session, exercise);

  /// Siguiente serie prevista de [exercise] sin apuntar (nula si ya están todas).
  int? nextSetOf(PlannedExercise exercise) {
    final sets = session?.setsFor(exercise.id) ?? const <SessionSet>[];
    for (var n = 1; n <= exercise.parameters.sets; n++) {
      if (!sets.any((s) => s.setNumber == n)) return n;
    }
    return null;
  }

  /// Clave de lo escrito en una serie aún sin marcar (borradores de la
  /// pantalla): ejercicio, serie y campo.
  static String draftKey(String exerciseId, int set, SetField field) =>
      '$exerciseId/$set/${field.name}';

  /// Lo que se propone para la serie [set] de [e] en el campo [f].
  ///
  /// Si la rutina detalla esa serie (pirámide de repeticiones o de pesos)
  /// manda el plan; si no, lo que se hizo en la serie anterior de hoy (lo
  /// real), la última vez (solo el peso) y, por último, lo previsto.
  num? proposedValue(PlannedExercise e, int set, SetField f) {
    final load = acceptedLoad.contains(e.id) ? loadSuggestions[e.id] : null;
    if (load != null && load.metric.field == f) {
      final value = load.forSet(set);
      // El campo de duración va en minutos; los demás, tal cual.
      return switch (load.metric) {
        LoadMetric.weight => value,
        LoadMetric.durationSeconds => (value / 60).round(),
        _ => value.round(),
      };
    }
    final p = e.parameters;
    final previous = session
        ?.setsFor(e.id)
        .where((x) => x.setNumber == set - 1)
        .firstOrNull;
    return switch (f) {
      SetField.reps =>
        p.repsPerSet != null
            ? p.repsForSet(set)
            : previous?.repsDone ?? p.repsForSet(set),
      SetField.weight =>
        p.weightsKg != null
            ? p.weightForSet(set)
            : previous?.weightKg ??
                  lastPerformance[e.exerciseId]?.weightKg ??
                  p.weightForSet(set),
      SetField.hold =>
        p.isometricSecondsPerSet != null
            ? p.holdForSet(set)
            : previous?.durationSeconds ?? p.holdForSet(set),
      SetField.duration =>
        previous?.durationSeconds != null
            ? (previous!.durationSeconds! / 60).round()
            : p.targetDurationSeconds == null
            ? null
            : (p.targetDurationSeconds! / 60).round(),
      SetField.distance => previous?.distanceMeters ?? p.distanceMeters,
    };
  }

  /// Cifras de la serie [set] de [e] para marcarla: lo escrito en [drafts] o
  /// lo propuesto.
  Map<SetField, num?> valuesFor(
    PlannedExercise e,
    int set,
    Map<String, num?> drafts,
  ) => {
    for (final f in SetFields.of(e).fields)
      f: drafts.containsKey(draftKey(e.id, set, f))
          ? drafts[draftKey(e.id, set, f)]
          : proposedValue(e, set, f),
  };

  /// Ejercicio que se está mirando: el activo o, si ya no queda ninguno por
  /// hacer, el siguiente con series o el último.
  PlannedExercise get viewed =>
      exercises.where((e) => e.id == activeExerciseId).firstOrNull ??
      upNext ??
      exercises.last;

  /// Ejercicios con todas sus series previstas apuntadas.
  int get finishedExercises =>
      exercises.where((e) => loggedSetsOf(e) >= e.parameters.sets).length;

  /// Ejercicio que toca: el activo si le quedan series; si no, el primero con
  /// series por apuntar. Nulo cuando ya no queda ninguna (toca terminar).
  PlannedExercise? get upNext {
    final active = exercises.where((e) => e.id == activeExerciseId).firstOrNull;
    if (active != null && nextSetOf(active) != null) return active;
    return exercises.where((e) => nextSetOf(e) != null).firstOrNull;
  }
}

/// Campo de la serie que mueve cada cifra de una propuesta de carga.
extension LoadMetricField on LoadMetric {
  SetField get field => switch (this) {
    LoadMetric.weight => SetField.weight,
    LoadMetric.reps => SetField.reps,
    LoadMetric.holdSeconds => SetField.hold,
    LoadMetric.durationSeconds => SetField.duration,
    LoadMetric.distanceMeters => SetField.distance,
  };
}

/// Números de serie previstos de [exercise] que ya tienen registro en
/// [session]: una serie con repeticiones de menos también cuenta como hecha
/// para avanzar (el servidor sabe por `failedReps` que no fue completa).
int _loggedSets(TrainingSession? session, PlannedExercise exercise) {
  final numbers = {
    for (final s in session?.setsFor(exercise.id) ?? const <SessionSet>[])
      if (s.setNumber <= exercise.parameters.sets) s.setNumber,
  };
  return numbers.length;
}
