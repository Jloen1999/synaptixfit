import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/models/training/routine_share.dart';

part 'routine_share_dto.freezed.dart';
part 'routine_share_dto.g.dart';

/// Respuesta de `POST /routines/{id}/share-links`: token (solo ahora) y caducidad.
@freezed
abstract class RoutineShareLinkDto with _$RoutineShareLinkDto {
  const factory RoutineShareLinkDto({
    required String token,
    required DateTime expiresAt,
  }) = _RoutineShareLinkDto;

  factory RoutineShareLinkDto.fromJson(Map<String, dynamic> json) =>
      _$RoutineShareLinkDtoFromJson(json);
}

/// Respuesta de `GET /routines/{id}/share-links`.
@freezed
abstract class RoutineShareStatusDto with _$RoutineShareStatusDto {
  const factory RoutineShareStatusDto({DateTime? sharedUntil}) =
      _RoutineShareStatusDto;

  factory RoutineShareStatusDto.fromJson(Map<String, dynamic> json) =>
      _$RoutineShareStatusDtoFromJson(json);
}

@freezed
abstract class SharedRoutineExerciseDto with _$SharedRoutineExerciseDto {
  const factory SharedRoutineExerciseDto({
    required String exerciseId,
    required String name,
    String? imageUrl,
    @Default(0) int sets,
  }) = _SharedRoutineExerciseDto;

  const SharedRoutineExerciseDto._();

  factory SharedRoutineExerciseDto.fromJson(Map<String, dynamic> json) =>
      _$SharedRoutineExerciseDtoFromJson(json);

  SharedRoutineExercise toDomain() => SharedRoutineExercise(
    exerciseId: exerciseId,
    name: name,
    imageUrl: imageUrl,
    sets: sets,
  );
}

@freezed
abstract class SharedRoutineDayDto with _$SharedRoutineDayDto {
  const factory SharedRoutineDayDto({
    required int dayNumber,
    String? name,
    @Default(0) int estimatedMinutes,
    @Default(<SharedRoutineExerciseDto>[])
    List<SharedRoutineExerciseDto> exercises,
  }) = _SharedRoutineDayDto;

  const SharedRoutineDayDto._();

  factory SharedRoutineDayDto.fromJson(Map<String, dynamic> json) =>
      _$SharedRoutineDayDtoFromJson(json);

  SharedRoutineDay toDomain() => SharedRoutineDay(
    dayNumber: dayNumber,
    name: name,
    estimatedMinutes: estimatedMinutes,
    exercises: [for (final e in exercises) e.toDomain()],
  );
}

/// Respuesta de `POST /shared-routines/preview` (sin datos del dueño).
@freezed
abstract class SharedRoutinePreviewDto with _$SharedRoutinePreviewDto {
  const factory SharedRoutinePreviewDto({
    required String name,
    String? description,
    String? goal,
    @Default(1) int durationWeeks,
    @Default(0) int daysPerWeek,
    @Default(0) int exerciseCount,
    @Default(<SharedRoutineDayDto>[]) List<SharedRoutineDayDto> firstWeek,
  }) = _SharedRoutinePreviewDto;

  const SharedRoutinePreviewDto._();

  factory SharedRoutinePreviewDto.fromJson(Map<String, dynamic> json) =>
      _$SharedRoutinePreviewDtoFromJson(json);

  SharedRoutinePreview toDomain() => SharedRoutinePreview(
    name: name,
    description: description,
    goal: TrainingGoal.tryFromApi(goal),
    durationWeeks: durationWeeks,
    daysPerWeek: daysPerWeek,
    exerciseCount: exerciseCount,
    firstWeek: [for (final d in firstWeek) d.toDomain()],
  );
}
