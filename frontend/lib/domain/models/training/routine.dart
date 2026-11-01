import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';
import '../../enums/visibility.dart';

part 'routine.freezed.dart';

/// Peso de referencia cuando el usuario no tiene peso en su perfil.
const double kDefaultBodyWeightKg = 70;

/// Parámetros de un ejercicio planificado (mismos rangos que la API).
///
/// Valores por serie (ADR 0027): [weightsKg], [repsPerSet] e
/// [isometricSecondsPerSet] detallan la serie n en la posición n-1; si faltan,
/// esa serie usa el valor común ([weightKg], [reps], [isometricSeconds]).
@freezed
abstract class ExerciseParameters with _$ExerciseParameters {
  const factory ExerciseParameters({
    @Default(3) int sets,
    @Default(10) int reps,
    @Default(90) int restSeconds,
    double? weightKg,
    List<double>? weightsKg,
    int? targetDurationSeconds,
    int? distanceMeters,
    int? isometricSeconds,
    List<int>? repsPerSet,
    List<int>? isometricSecondsPerSet,
  }) = _ExerciseParameters;

  const ExerciseParameters._();

  static const minSets = 1;
  static const maxSets = 10;
  static const minReps = 1;
  static const maxReps = 100;
  static const minRest = 30;
  static const maxRest = 300;
  static const maxWeight = 500.0;
  static const maxDuration = 14400;
  static const maxDistance = 100000;
  static const maxIsometric = 600;

  /// Repeticiones previstas de la serie [setNumber] (desde 1).
  int repsForSet(int setNumber) => _forSet(repsPerSet, setNumber) ?? reps;

  /// Peso previsto de la serie [setNumber] (nulo sin carga).
  double? weightForSet(int setNumber) =>
      _forSet(weightsKg, setNumber) ?? weightKg;

  /// Segundos de aguante previstos de la serie [setNumber] (nulo si no es
  /// isométrico).
  int? holdForSet(int setNumber) =>
      _forSet(isometricSecondsPerSet, setNumber) ?? isometricSeconds;

  static T? _forSet<T>(List<T>? values, int setNumber) =>
      values != null && setNumber >= 1 && setNumber <= values.length
      ? values[setNumber - 1]
      : null;

  /// Los mismos parámetros con [count] series: la nueva copia los valores de
  /// la última, y al quitar se recortan las listas por serie.
  ExerciseParameters withSetCount(int count) {
    final n = count.clamp(minSets, maxSets);
    int from(int i) => i > sets ? sets : i;
    return copyWith(
      sets: n,
      repsPerSet: [for (var i = 1; i <= n; i++) repsForSet(from(i))],
      weightsKg: weightKg == null && weightsKg == null
          ? null
          : [for (var i = 1; i <= n; i++) weightForSet(from(i)) ?? 0],
      isometricSecondsPerSet: isometricSeconds == null
          ? null
          : [
              for (var i = 1; i <= n; i++)
                holdForSet(from(i)) ?? isometricSeconds!,
            ],
    )._normalized();
  }

  /// Quita la serie [setNumber]; las siguientes suben un puesto con sus
  /// valores. Nunca deja menos de [minSets].
  ExerciseParameters withoutSet(int setNumber) {
    if (sets <= minSets || setNumber < 1 || setNumber > sets) return this;
    List<T> without<T>(T Function(int set) at) => [
      for (var i = 1; i <= sets; i++)
        if (i != setNumber) at(i),
    ];
    return copyWith(
      sets: sets - 1,
      repsPerSet: without(repsForSet),
      weightsKg: weightKg == null && weightsKg == null
          ? null
          : without((i) => weightForSet(i) ?? 0),
      isometricSecondsPerSet: isometricSeconds == null
          ? null
          : without((i) => holdForSet(i) ?? isometricSeconds!),
    )._normalized();
  }

  /// Cambia lo previsto de la serie [setNumber]; las demás conservan su valor.
  /// [weight] nulo con [clearWeight] quita la carga del ejercicio.
  ExerciseParameters withSetValues(
    int setNumber, {
    int? setReps,
    double? weight,
    bool clearWeight = false,
    int? hold,
  }) {
    List<T> patched<T>(T Function(int set) current, T? value) => [
      for (var i = 1; i <= sets; i++)
        i == setNumber && value != null ? value : current(i),
    ];
    return copyWith(
      repsPerSet: patched(repsForSet, setReps),
      weightsKg: clearWeight
          ? null
          : weight == null && weightKg == null && weightsKg == null
          ? null
          : patched((i) => weightForSet(i) ?? weight ?? 0, weight),
      weightKg: clearWeight ? null : weightKg ?? weight,
      isometricSecondsPerSet: hold == null && isometricSeconds == null
          ? null
          : patched((i) => holdForSet(i) ?? hold!, hold),
      isometricSeconds: isometricSeconds ?? hold,
    )._normalized();
  }

  /// Espejo de la regla del servidor (`ExerciseParameters` del dominio, ADR
  /// 0027) solo para pintar al instante una edición en línea: la respuesta del
  /// servidor sustituye a este estado. Listas del tamaño de las series; si
  /// todas coinciden, basta el común; el común es la media de repeticiones, el
  /// peso de trabajo (el mayor) y el aguante más largo.
  ExerciseParameters _normalized() {
    List<T>? fit<T>(List<T>? values) => values == null
        ? null
        : values.length > sets
        ? values.sublist(0, sets)
        : values;
    final r = fit(repsPerSet);
    final w = fit(weightsKg);
    final h = fit(isometricSecondsPerSet);
    bool uniform<T>(List<T>? v) => v != null && v.toSet().length <= 1;
    return copyWith(
      repsPerSet: r == null || uniform(r) ? null : r,
      reps: r == null || r.isEmpty
          ? reps
          : (r.reduce((a, b) => a + b) / r.length).round(),
      weightsKg: w == null || uniform(w) ? null : w,
      weightKg: w == null || w.isEmpty ? weightKg : w.reduce(math.max),
      isometricSecondsPerSet: h == null || uniform(h) ? null : h,
      isometricSeconds: h == null || h.isEmpty
          ? isometricSeconds
          : h.reduce(math.max),
    );
  }

  /// Duración estimada en segundos (≈ 3 s por repetición, o el aguante de
  /// cada serie, más descansos).
  int get estimatedDurationSeconds {
    final target = targetDurationSeconds;
    if (target != null) return target;
    var work = 0;
    for (var n = 1; n <= sets; n++) {
      work += holdForSet(n) ?? repsForSet(n) * 3;
    }
    return work + (sets - 1) * restSeconds;
  }

  /// Calorías estimadas con la fórmula MET: `MET × kg × horas`.
  double estimatedCalories({required double met, double? bodyWeightKg}) =>
      met *
      (bodyWeightKg ?? kDefaultBodyWeightKg) *
      estimatedDurationSeconds /
      3600;
}

/// Ejercicio planificado dentro de un día de rutina.
@freezed
abstract class PlannedExercise with _$PlannedExercise {
  const factory PlannedExercise({
    required String id,
    required String exerciseId,
    required String exerciseName,
    String? gifUrl,
    String? previewUrl,
    required Modality modality,
    @Default(<MeasurementType>[]) List<MeasurementType> measurementTypes,
    required double met,
    @Default(true) bool exerciseActive,
    required int order,
    required ExerciseParameters parameters,
    int? realDurationSeconds,

    /// Cómo se apunta cada serie (del servidor; nulo con versiones antiguas).
    TrackingKind? trackingKind,
  }) = _PlannedExercise;

  const PlannedExercise._();

  String? get thumbnailUrl => previewUrl ?? gifUrl;
}

/// Día de una semana de rutina. [dayNumber] es el día de la semana preferido
/// (1 = lunes … 7 = domingo): la rutina avanza por orden, no por fechas.
@freezed
abstract class RoutineDay with _$RoutineDay {
  const factory RoutineDay({
    required String id,
    required int dayNumber,
    String? name,
    required ProgressStatus status,

    /// Día en que se completó o se saltó.
    DateTime? closedOn,
    @Default(<PlannedExercise>[]) List<PlannedExercise> exercises,
  }) = _RoutineDay;
}

/// Semana de una rutina.
@freezed
abstract class RoutineWeek with _$RoutineWeek {
  const factory RoutineWeek({
    required String id,
    required int number,
    String? name,
    WeekType? type,
    required ProgressStatus status,
    @Default(<RoutineDay>[]) List<RoutineDay> days,
  }) = _RoutineWeek;
}

/// Rutina original de la que se clonó otra.
@freezed
abstract class RoutineOrigin with _$RoutineOrigin {
  const factory RoutineOrigin({
    required String routineId,
    String? ownerId,
    String? ownerName,
  }) = _RoutineOrigin;
}

/// Rutina sin estructura (listados).
@freezed
abstract class RoutineSummary with _$RoutineSummary {
  const factory RoutineSummary({
    required String id,
    required String ownerId,
    String? authorName,
    required String name,
    String? description,
    required Visibility visibility,
    required RoutineStatus status,
    TrainingGoal? goal,
    DateTime? startDate,
    required int durationWeeks,
    required int exerciseCount,
    required int totalDays,
    required int completedDays,
    RoutineOrigin? origin,
    DateTime? createdAt,
    @Default(0) int skippedDays,

    /// Foto del ejercicio que representa la rutina (fondo de su tarjeta) y su
    /// modalidad, para un fondo por tipo si no hay foto.
    String? coverImageUrl,
    Modality? coverModality,
  }) = _RoutineSummary;

  const RoutineSummary._();

  /// Avance entre 0 y 1: días hechos o saltados (como en el detalle).
  double get progress => totalDays == 0
      ? 0
      : ((completedDays + skippedDays) / totalDays).clamp(0, 1).toDouble();
}

/// Rutina completa con sus semanas, días y ejercicios.
@freezed
abstract class Routine with _$Routine {
  const factory Routine({
    required String id,
    required String ownerId,
    String? authorName,

    /// Si es del usuario. Si no, es de la comunidad y solo se puede clonar.
    required bool owned,
    required String name,
    String? description,
    required Visibility visibility,
    required RoutineStatus status,
    TrainingGoal? goal,
    DateTime? startDate,
    required int durationWeeks,
    required int exerciseCount,
    required int totalDays,
    required int completedDays,
    @Default(0) int skippedDays,
    RoutineOrigin? origin,
    DateTime? createdAt,
    @Default(<RoutineWeek>[]) List<RoutineWeek> weeks,
  }) = _Routine;

  const Routine._();

  /// Avance entre 0 y 1: días hechos o saltados (los saltados también cierran
  /// el ciclo).
  double get progress => totalDays == 0
      ? 0
      : ((completedDays + skippedDays) / totalDays).clamp(0, 1).toDouble();

  /// Busca un día por id en todas las semanas.
  RoutineDay? dayById(String dayId) {
    for (final week in weeks) {
      for (final day in week.days) {
        if (day.id == dayId) return day;
      }
    }
    return null;
  }

  /// La misma rutina con los parámetros de [plannedExerciseId] cambiados
  /// (para mostrar una edición en línea al instante).
  Routine withExerciseParameters(
    String plannedExerciseId,
    ExerciseParameters parameters,
  ) => copyWith(
    weeks: [
      for (final week in weeks)
        week.copyWith(
          days: [
            for (final day in week.days)
              day.copyWith(
                exercises: [
                  for (final e in day.exercises)
                    e.id == plannedExerciseId
                        ? e.copyWith(parameters: parameters)
                        : e,
                ],
              ),
          ],
        ),
    ],
  );

  /// La misma rutina con los ejercicios de [dayId] en el orden de
  /// [plannedExerciseIds] (para mostrar un cambio de orden al instante).
  Routine withExerciseOrder(String dayId, List<String> plannedExerciseIds) =>
      copyWith(
        weeks: [
          for (final week in weeks)
            week.copyWith(
              days: [
                for (final day in week.days)
                  if (day.id != dayId)
                    day
                  else
                    day.copyWith(
                      exercises: [
                        for (final id in plannedExerciseIds)
                          ?day.exercises.where((e) => e.id == id).firstOrNull,
                      ],
                    ),
              ],
            ),
        ],
      );
}

/// Próximo día de la rutina en curso. Lo calcula el servidor (regla única):
/// el cliente solo lo muestra.
@freezed
abstract class PendingDay with _$PendingDay {
  const factory PendingDay({
    required String routineId,
    required String routineName,
    required String weekId,
    required int weekNumber,
    @Default(1) int totalWeeks,
    String? weekName,
    required String dayId,
    required int dayNumber,
    String? dayName,
    required ProgressStatus dayStatus,

    /// Cuándo toca (bloque del calendario o día de la semana preferido).
    DateTime? scheduledDate,

    /// La fecha prevista ya pasó.
    @Default(false) bool overdue,
    @Default(1) int sessionOfWeek,
    @Default(1) int sessionsInWeek,

    /// Sesión abandonada de ese día: hay que terminarla o descartarla antes.
    String? staleSessionId,
    @Default(<PlannedExercise>[]) List<PlannedExercise> exercises,

    /// Avance del ciclo de la rutina (días hechos y saltados de [totalDays]).
    @Default(0) int totalDays,
    @Default(0) int completedDays,
    @Default(0) int skippedDays,

    /// Foto y modalidad del ejercicio que representa la rutina.
    String? coverImageUrl,
    Modality? coverModality,
  }) = _PendingDay;

  const PendingDay._();

  /// Avance del ciclo entre 0 y 1.
  double get cycleProgress => totalDays == 0
      ? 0
      : ((completedDays + skippedDays) / totalDays).clamp(0, 1).toDouble();
}
