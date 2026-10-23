import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';
import 'recommendation.dart';

part 'session.freezed.dart';

/// Serie registrada en una sesión.
@freezed
abstract class SessionSet with _$SessionSet {
  const factory SessionSet({
    required String id,
    String? plannedExerciseId,
    required int setNumber,
    int? repsDone,
    double? weightKg,
    required bool completed,
    @Default(0) int failedReps,
  }) = _SessionSet;
}

/// Sesión de entrenamiento (en curso o finalizada).
@freezed
abstract class TrainingSession with _$TrainingSession {
  const factory TrainingSession({
    required String id,
    String? routineId,
    String? dayId,
    required SessionType type,
    required SessionStatus status,
    required DateTime startedAt,
    DateTime? completedAt,
    @Default(0) int durationMinutes,
    int? rpe,
    double? calories,
    @Default(0) int xpAwarded,
    @Default(<SessionSet>[]) List<SessionSet> sets,
  }) = _TrainingSession;

  const TrainingSession._();

  bool get isCompleted => status == SessionStatus.completed;

  /// Series de un ejercicio planificado (o libres si es nulo), ordenadas.
  List<SessionSet> setsFor(String? plannedExerciseId) =>
      sets.where((s) => s.plannedExerciseId == plannedExerciseId).toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
}

/// Datos de una serie para registrarla.
@freezed
abstract class SetRecord with _$SetRecord {
  const factory SetRecord({
    String? plannedExerciseId,
    required int setNumber,
    int? repsDone,
    double? weightKg,
    @Default(true) bool completed,
    @Default(0) int failedReps,
  }) = _SetRecord;
}

/// Cambio de experiencia tras una acción.
@freezed
abstract class ExperienceChange with _$ExperienceChange {
  const factory ExperienceChange({
    required int level,
    required int levelXp,
    @Default(0) int levelUps,
    required int xpDelta,
  }) = _ExperienceChange;
}

/// Resultado de finalizar una sesión.
@freezed
abstract class FinishSessionResult with _$FinishSessionResult {
  const factory FinishSessionResult({
    required TrainingSession session,
    required ExperienceChange experience,
    @Default(<Recommendation>[]) List<Recommendation> recommendations,
  }) = _FinishSessionResult;
}

/// Resultado de desmarcar una sesión finalizada.
@freezed
abstract class UnmarkSessionResult with _$UnmarkSessionResult {
  const factory UnmarkSessionResult({
    required TrainingSession session,
    required ExperienceChange experience,
  }) = _UnmarkSessionResult;
}
