import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';
import 'routine.dart';

part 'recommendation.freezed.dart';

/// Parámetros propuestos para un ejercicio planificado; [before], los que
/// tenía (para enseñar «40 → 42,5 kg») y [reasonCode], por qué cambia. Ambos
/// faltan en sugerencias antiguas.
@freezed
abstract class ExerciseAdjustment with _$ExerciseAdjustment {
  const factory ExerciseAdjustment({
    String? plannedExerciseId,
    String? exerciseId,
    String? exerciseName,
    String? reason,
    required ExerciseParameters parameters,
    ExerciseParameters? before,
    AdjustmentReason? reasonCode,
  }) = _ExerciseAdjustment;
}

/// Sugerencia de entrenamiento generada tras una sesión o por la carga académica.
@freezed
abstract class Recommendation with _$Recommendation {
  const factory Recommendation({
    required String id,
    required RecommendationType type,
    required String title,
    String? description,
    String? exerciseId,
    String? routineId,
    required bool applied,
    DateTime? createdAt,
    @Default(<ExerciseAdjustment>[]) List<ExerciseAdjustment> adjustments,

    /// Datos del porqué que manda el servidor: esfuerzo de la sesión,
    /// repeticiones fallidas y días sin entrenar (si aplican).
    int? rpe,
    int? failedReps,
    int? daysInactive,

    /// Motivo de toda la sugerencia (lo elige el servidor; nulo en antiguas).
    AdjustmentReason? reasonCode,
  }) = _Recommendation;
}
