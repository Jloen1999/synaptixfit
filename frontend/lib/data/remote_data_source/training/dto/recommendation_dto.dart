import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/models/training/recommendation.dart';
import '../../../../domain/models/training/routine.dart';

part 'recommendation_dto.freezed.dart';
part 'recommendation_dto.g.dart';

@freezed
abstract class AdjustmentDto with _$AdjustmentDto {
  const factory AdjustmentDto({
    String? plannedExerciseId,
    String? exerciseId,
    String? exerciseName,
    String? reason,
    required int sets,
    required int reps,
    required int restSeconds,
    double? weightKg,
    List<double>? weightsKg,
    int? targetDurationSeconds,
    int? distanceMeters,
    int? isometricSeconds,
    List<int>? repsPerSet,
    List<int>? isometricSecondsPerSet,
  }) = _AdjustmentDto;

  const AdjustmentDto._();

  factory AdjustmentDto.fromJson(Map<String, dynamic> json) =>
      _$AdjustmentDtoFromJson(json);

  ExerciseAdjustment toDomain() => ExerciseAdjustment(
    plannedExerciseId: plannedExerciseId,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    reason: reason,
    parameters: ExerciseParameters(
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
      weightKg: weightKg,
      weightsKg: weightsKg,
      targetDurationSeconds: targetDurationSeconds,
      distanceMeters: distanceMeters,
      isometricSeconds: isometricSeconds,
      repsPerSet: repsPerSet,
      isometricSecondsPerSet: isometricSecondsPerSet,
    ),
  );
}

@freezed
abstract class RecommendationDto with _$RecommendationDto {
  const factory RecommendationDto({
    required String id,
    String? type,
    @Default('') String title,
    String? description,
    String? exerciseId,
    String? routineId,
    @Default(false) bool applied,
    DateTime? createdAt,
    List<AdjustmentDto>? adjustments,
  }) = _RecommendationDto;

  const RecommendationDto._();

  factory RecommendationDto.fromJson(Map<String, dynamic> json) =>
      _$RecommendationDtoFromJson(json);

  Recommendation toDomain() => Recommendation(
    id: id,
    type: RecommendationType.fromApi(type),
    title: title,
    description: description,
    exerciseId: exerciseId,
    routineId: routineId,
    applied: applied,
    createdAt: createdAt?.toLocal(),
    adjustments: (adjustments ?? const []).map((a) => a.toDomain()).toList(),
  );
}
