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

    /// Calentamiento y vuelta a la calma sugeridos para los ejercicios del día.
    SessionBookends? bookends,

    /// Series apuntadas sin conexión que aún no ha recibido el servidor (en
    /// orden). Se ven en la lista y se suben solas al volver la cobertura.
    @Default(<SetRecord>[]) List<SetRecord> pendingSets,
  }) = _LiveSessionState;

  const LiveSessionState._();

  bool get isFree => exercises.isEmpty;

  bool get completed => session?.isCompleted ?? false;

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
