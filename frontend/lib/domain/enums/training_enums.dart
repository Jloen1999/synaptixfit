// Enums del módulo de entrenamiento. Cada valor conoce su representación en la
// API (UPPER_SNAKE_CASE) para que los DTOs los traduzcan sin lógica adicional.

T _fromApi<T extends Enum>(
  List<T> values,
  String Function(T) api,
  String? value,
  T fallback,
) => values.firstWhere((v) => api(v) == value, orElse: () => fallback);

/// Dificultad de un ejercicio del catálogo.
enum ExerciseDifficulty {
  beginner('BEGINNER'),
  intermediate('INTERMEDIATE'),
  advanced('ADVANCED');

  const ExerciseDifficulty(this.apiValue);

  final String apiValue;

  static ExerciseDifficulty fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, beginner);
}

/// Modalidad de un ejercicio.
enum Modality {
  strength('STRENGTH'),
  mobility('MOBILITY'),
  metabolic('METABOLIC'),
  aerobic('AEROBIC');

  const Modality(this.apiValue);

  final String apiValue;

  static Modality fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, strength);
}

/// Tipo de ejercicio (más fino que [Modality]): estiramientos, pliometría…
/// Sirve para filtrar el catálogo y para el calentamiento y la vuelta a la calma.
enum ExerciseCategory {
  strength('STRENGTH'),
  calisthenics('CALISTHENICS'),
  stretching('STRETCHING'),
  mobility('MOBILITY'),
  cardio('CARDIO'),
  plyometrics('PLYOMETRICS'),
  yoga('YOGA'),
  pilates('PILATES'),
  isometric('ISOMETRIC'),
  olympic('OLYMPIC'),
  combat('COMBAT'),
  rehab('REHAB');

  const ExerciseCategory(this.apiValue);

  final String apiValue;

  static ExerciseCategory fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, strength);
}

/// Cómo se mide un ejercicio.
enum MeasurementType {
  repetitions('REPETITIONS'),
  weight('WEIGHT'),
  time('TIME'),
  distance('DISTANCE'),
  calories('CALORIES');

  const MeasurementType(this.apiValue);

  final String apiValue;

  static MeasurementType fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, repetitions);
}

/// Qué se apunta en cada serie de un ejercicio (lo decide el servidor, ADR
/// 0027): repeticiones (con o sin peso), segundos de aguante o un bloque de
/// tiempo y distancia.
enum TrackingKind {
  repetitions('REPETITIONS'),
  hold('HOLD'),
  cardio('CARDIO');

  const TrackingKind(this.apiValue);

  final String apiValue;

  /// Nulo si el servidor no lo envía (versiones anteriores).
  static TrackingKind? tryFromApi(String? value) =>
      values.where((v) => v.apiValue == value).firstOrNull;
}

/// Objetivo de entrenamiento (también finalidad de un ejercicio).
enum TrainingGoal {
  hypertrophy('HYPERTROPHY'),
  maxStrength('MAX_STRENGTH'),
  power('POWER'),
  strengthEndurance('STRENGTH_ENDURANCE'),
  mobility('MOBILITY'),
  stability('STABILITY'),
  metabolicConditioning('METABOLIC_CONDITIONING');

  const TrainingGoal(this.apiValue);

  final String apiValue;

  static TrainingGoal? tryFromApi(String? value) =>
      values.where((v) => v.apiValue == value).firstOrNull;

  static TrainingGoal fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, hypertrophy);
}

/// Tipo de semana dentro de la periodización.
enum WeekType {
  adaptation('ADAPTATION'),
  load('LOAD'),
  peak('PEAK'),
  deload('DELOAD');

  const WeekType(this.apiValue);

  final String apiValue;

  static WeekType? tryFromApi(String? value) =>
      values.where((v) => v.apiValue == value).firstOrNull;
}

/// Estado de una rutina.
enum RoutineStatus {
  active('ACTIVE'),
  paused('PAUSED'),
  completed('COMPLETED'),
  archived('ARCHIVED');

  const RoutineStatus(this.apiValue);

  final String apiValue;

  static RoutineStatus fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, active);
}

/// Progreso de una semana o un día. Solo un día queda saltado.
enum ProgressStatus {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED'),
  skipped('SKIPPED');

  const ProgressStatus(this.apiValue);

  final String apiValue;

  static ProgressStatus fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, pending);
}

/// Origen de una sesión de entrenamiento.
enum SessionType {
  free('FREE'),
  routine('ROUTINE'),
  weekly('WEEKLY');

  const SessionType(this.apiValue);

  final String apiValue;

  static SessionType fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, free);
}

/// Estado de una sesión.
enum SessionStatus {
  inProgress('IN_PROGRESS'),
  completed('COMPLETED');

  const SessionStatus(this.apiValue);

  final String apiValue;

  static SessionStatus fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, inProgress);
}

/// Tipo de sugerencia de entrenamiento.
enum RecommendationType {
  progression('PROGRESSION'),
  degradation('DEGRADATION'),
  deload('DELOAD'),
  variant('VARIANT'),
  academic('ACADEMIC');

  const RecommendationType(this.apiValue);

  final String apiValue;

  static RecommendationType fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, progression);
}

/// Intensidad del plan semanal.
enum PlanIntensity {
  low('LOW'),
  moderate('MODERATE'),
  high('HIGH');

  const PlanIntensity(this.apiValue);

  final String apiValue;

  static PlanIntensity fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, moderate);
}

/// Estado del plan semanal.
enum PlanStatus {
  active('ACTIVE'),
  paused('PAUSED'),
  completed('COMPLETED'),
  adjusted('ADJUSTED');

  const PlanStatus(this.apiValue);

  final String apiValue;

  static PlanStatus fromApi(String? value) =>
      _fromApi(values, (v) => v.apiValue, value, active);
}
