import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';

part 'wellbeing.freezed.dart';

/// Check-in diario (escalas 1-5) con su puntuación de fatiga (0-100).
@freezed
abstract class CheckIn with _$CheckIn {
  const factory CheckIn({
    required String id,
    required DateTime date,
    required int sleepQuality,
    required int stress,
    required int energy,
    required int soreness,
    @Default(<String>[]) List<String> painZones,
    required bool readyToTrain,
    String? notes,
    required int fatigueScore,

    /// Si conviene adaptar el entrenamiento (fatiga > 50).
    required bool requiresAdaptation,
    DateTime? createdAt,
  }) = _CheckIn;
}

/// Valores que el usuario introduce en el check-in.
@freezed
abstract class CheckInInput with _$CheckInInput {
  const factory CheckInInput({
    @Default(3) int sleepQuality,
    @Default(3) int stress,
    @Default(3) int energy,
    @Default(3) int soreness,
    @Default(<String>[]) List<String> painZones,
    @Default(true) bool readyToTrain,
    String? notes,
  }) = _CheckInInput;

  const CheckInInput._();

  static const maxPainZones = 12;

  factory CheckInInput.fromCheckIn(CheckIn c) => CheckInInput(
    sleepQuality: c.sleepQuality,
    stress: c.stress,
    energy: c.energy,
    soreness: c.soreness,
    painZones: c.painZones,
    readyToTrain: c.readyToTrain,
    notes: c.notes,
  );
}

/// Resultado de guardar el check-in: la experiencia solo llega con el primero del día.
@freezed
abstract class CheckInResult with _$CheckInResult {
  const factory CheckInResult({
    required CheckIn checkIn,
    required bool firstOfDay,
    required int xpAwarded,
  }) = _CheckInResult;
}

/// Plan semanal de entrenamiento con su cumplimiento.
@freezed
abstract class WeeklyPlan with _$WeeklyPlan {
  const factory WeeklyPlan({
    required String id,
    required DateTime weekStart,
    required int plannedSessions,
    required PlanIntensity intensity,
    required int minutesPerSession,
    required PlanStatus status,
    String? notes,
    required int completedSessions,

    /// Cumplimiento entre 0 y 1.
    required double compliance,
  }) = _WeeklyPlan;
}

/// Valores editables del plan semanal.
@freezed
abstract class WeeklyPlanInput with _$WeeklyPlanInput {
  const factory WeeklyPlanInput({
    @Default(3) int plannedSessions,
    @Default(PlanIntensity.moderate) PlanIntensity intensity,
    @Default(45) int minutesPerSession,
    @Default(PlanStatus.active) PlanStatus status,
    String? notes,
  }) = _WeeklyPlanInput;

  const WeeklyPlanInput._();

  static const minSessions = 1;
  static const maxSessions = 7;
  static const minMinutes = 10;
  static const maxMinutes = 180;

  factory WeeklyPlanInput.fromPlan(WeeklyPlan p) => WeeklyPlanInput(
    plannedSessions: p.plannedSessions,
    intensity: p.intensity,
    minutesPerSession: p.minutesPerSession,
    status: p.status,
    notes: p.notes,
  );
}
