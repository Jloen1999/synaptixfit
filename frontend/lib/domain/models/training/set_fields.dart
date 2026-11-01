import '../../enums/training_enums.dart';
import 'routine.dart';
import 'session.dart';

/// Qué se apunta en cada serie de un ejercicio.
enum SetField {
  /// Repeticiones de la serie.
  reps,

  /// Kilos de la serie.
  weight,

  /// Segundos de aguante (plancha, sentadilla isométrica…).
  hold,

  /// Minutos de trabajo continuo (correr, bici…).
  duration,

  /// Metros recorridos.
  distance,
}

/// Columnas de la tabla de series de un ejercicio según cómo se apunta.
///
/// El tipo de seguimiento lo decide el servidor ([PlannedExercise.trackingKind],
/// ADR 0027); aquí solo se traduce a columnas y se añade la de kilos si el
/// ejercicio lleva carga. Sin ese dato (servidor antiguo o borrador sin
/// catálogo) se aplica la misma regla con lo que se sabe.
class SetFields {
  const SetFields._(this.fields);

  /// A partir de un ejercicio planificado.
  factory SetFields.of(PlannedExercise exercise) => SetFields.from(
    types: exercise.measurementTypes,
    modality: exercise.modality,
    parameters: exercise.parameters,
    kind: exercise.trackingKind,
  );

  /// A partir de sus piezas.
  factory SetFields.from({
    required List<MeasurementType> types,
    Modality? modality,
    required ExerciseParameters parameters,
    TrackingKind? kind,
  }) {
    final p = parameters;
    final loaded =
        types.contains(MeasurementType.weight) ||
        p.weightKg != null ||
        p.weightsKg != null;
    return switch (kind ?? _fallbackKind(types, modality, p)) {
      TrackingKind.cardio => const SetFields._([
        SetField.duration,
        SetField.distance,
      ]),
      TrackingKind.hold => SetFields._([
        SetField.hold,
        if (loaded) SetField.weight,
      ]),
      TrackingKind.repetitions => SetFields._([
        SetField.reps,
        if (loaded) SetField.weight,
      ]),
    };
  }

  /// Misma regla que `PlannedExercise.trackingKind` del servidor: primero los
  /// datos planificados y después el catálogo.
  static TrackingKind _fallbackKind(
    List<MeasurementType> types,
    Modality? modality,
    ExerciseParameters p,
  ) {
    if (p.targetDurationSeconds != null || p.distanceMeters != null) {
      return TrackingKind.cardio;
    }
    if (p.isometricSeconds != null) return TrackingKind.hold;
    final timeOnly =
        types.contains(MeasurementType.time) &&
        !types.contains(MeasurementType.repetitions);
    if (types.contains(MeasurementType.distance) ||
        timeOnly && modality == Modality.aerobic) {
      return TrackingKind.cardio;
    }
    return timeOnly ? TrackingKind.hold : TrackingKind.repetitions;
  }

  /// Columnas en orden de importancia (la primera es la principal).
  final List<SetField> fields;

  bool get isCardio => fields.contains(SetField.duration);

  bool get isHold => fields.contains(SetField.hold);

  bool has(SetField field) => fields.contains(field);
}

/// Rangos válidos de cada campo (mismos que la API).
extension SetFieldRange on SetField {
  (num, num) get range => switch (this) {
    SetField.reps => (ExerciseParameters.minReps, ExerciseParameters.maxReps),
    SetField.weight => (0, ExerciseParameters.maxWeight),
    SetField.hold => (1, ExerciseParameters.maxIsometric),
    SetField.duration => (1, ExerciseParameters.maxDuration ~/ 60),
    SetField.distance => (1, ExerciseParameters.maxDistance),
  };

  bool get decimal => this == SetField.weight;
}

/// Cifras de una serie apuntada por campo (el aguante y los minutos se guardan
/// en `durationSeconds`).
extension SessionSetFields on SessionSet {
  num? valueOf(SetField f) => switch (f) {
    SetField.reps => repsDone,
    SetField.weight => weightKg,
    SetField.hold => durationSeconds,
    SetField.duration =>
      durationSeconds == null ? null : (durationSeconds! / 60).round(),
    SetField.distance => distanceMeters,
  };
}

/// Serie para registrar la [set] de [exercise] con los [values] de cada campo.
/// Una serie ya apuntada ([existing]) conserva si fue completa y sus
/// repeticiones fallidas.
SetRecord setRecordFor(
  PlannedExercise exercise,
  int set,
  Map<SetField, num?> values, {
  SessionSet? existing,
}) => SetRecord(
  plannedExerciseId: exercise.id,
  setNumber: set,
  repsDone: values[SetField.reps]?.toInt(),
  weightKg: values[SetField.weight]?.toDouble(),
  durationSeconds: values.containsKey(SetField.hold)
      ? values[SetField.hold]?.toInt()
      : values[SetField.duration] == null
      ? null
      : (values[SetField.duration]! * 60).round(),
  distanceMeters: values[SetField.distance]?.toInt(),
  completed: existing?.completed ?? true,
  failedReps: existing?.failedReps ?? 0,
);
