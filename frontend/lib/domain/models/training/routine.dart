import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';
import '../../enums/visibility.dart';

part 'routine.freezed.dart';

/// Peso de referencia cuando el usuario no tiene peso en su perfil.
const double kDefaultBodyWeightKg = 70;

/// Parámetros de un ejercicio planificado (mismos rangos que la API).
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

  /// Duración estimada en segundos (≈ 3 s por repetición más descansos).
  int get estimatedDurationSeconds {
    final target = targetDurationSeconds;
    if (target != null) return target;
    final work = isometricSeconds != null
        ? sets * isometricSeconds!
        : sets * reps * 3;
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
  }) = _PlannedExercise;

  const PlannedExercise._();

  String? get thumbnailUrl => previewUrl ?? gifUrl;
}

/// Día de una semana de rutina (1 = lunes … 7 = domingo).
@freezed
abstract class RoutineDay with _$RoutineDay {
  const factory RoutineDay({
    required String id,
    required int dayNumber,
    String? name,
    required ProgressStatus status,
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
  }) = _RoutineSummary;

  const RoutineSummary._();

  /// Progreso entre 0 y 1.
  double get progress =>
      totalDays == 0 ? 0 : (completedDays / totalDays).clamp(0, 1).toDouble();
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
    RoutineOrigin? origin,
    DateTime? createdAt,
    @Default(<RoutineWeek>[]) List<RoutineWeek> weeks,
  }) = _Routine;

  const Routine._();

  double get progress =>
      totalDays == 0 ? 0 : (completedDays / totalDays).clamp(0, 1).toDouble();

  /// Busca un día por id en todas las semanas.
  RoutineDay? dayById(String dayId) {
    for (final week in weeks) {
      for (final day in week.days) {
        if (day.id == dayId) return day;
      }
    }
    return null;
  }
}

/// Próximo día de entrenamiento pendiente de la rutina activa.
@freezed
abstract class PendingDay with _$PendingDay {
  const factory PendingDay({
    required String routineId,
    required String routineName,
    required String weekId,
    required int weekNumber,
    String? weekName,
    required String dayId,
    required int dayNumber,
    String? dayName,
    required ProgressStatus dayStatus,
    @Default(<PlannedExercise>[]) List<PlannedExercise> exercises,
  }) = _PendingDay;
}
