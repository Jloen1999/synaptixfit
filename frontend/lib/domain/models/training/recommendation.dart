import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/training_enums.dart';
import 'routine.dart';

part 'recommendation.freezed.dart';

/// Parámetros propuestos para un ejercicio planificado.
@freezed
abstract class ExerciseAdjustment with _$ExerciseAdjustment {
  const factory ExerciseAdjustment({
    String? plannedExerciseId,
    String? exerciseId,
    String? exerciseName,
    String? reason,
    required ExerciseParameters parameters,
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
  }) = _Recommendation;
}
